import type { FastifyInstance } from 'fastify';
import { InventoryMovementType, StockTransferStatus } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { serializable } from '../../lib/transactions.js';
import { businessNumber } from '../../lib/numbering.js';
import { conflict, notFound } from '../../lib/errors.js';
import { emitEvent } from '../../lib/outbox.js';
import { writeAudit } from '../../lib/audit.js';
import { assertLocationAccess, requirePermission } from '../auth/context.js';
import { postInventoryMovement } from './service.js';
import { consumeFifoCost } from './costing.js';

const transferSchema = z.object({
  fromLocationId: z.string().min(1),
  toLocationId: z.string().min(1),
  notes: z.string().max(1000).optional(),
  lines: z.array(z.object({ productVariantId: z.string().min(1), quantity: z.coerce.number().positive(), lotAllocations: z.array(z.object({lotId:z.string(),quantity:z.coerce.number().positive()})).default([]), serialNumberIds:z.array(z.string()).default([]) })).min(1)
});

export async function transferRoutes(app: FastifyInstance) {
  app.get('/v1/transfers', { preHandler: requirePermission('inventory.read') }, async request => {
    const rows = await prisma.stockTransfer.findMany({
      where: { tenantId: request.auth.tenantId }, include: { fromLocation: true, toLocation: true, lines: { include: { productVariant: true } } }, orderBy: { createdAt: 'desc' }, take: 100
    });
    return { transfers: rows.filter(row => request.auth.allLocations || request.auth.locationIds.has(row.fromLocationId) || request.auth.locationIds.has(row.toLocationId)) };
  });

  app.post('/v1/transfers', { preHandler: requirePermission('inventory.transfer') }, async request => {
    const body = transferSchema.parse(request.body);
    if (body.fromLocationId === body.toLocationId) throw conflict('Transfer locations must be different');
    assertLocationAccess(request, body.fromLocationId);
    assertLocationAccess(request, body.toLocationId);
    if (new Set(body.lines.map(l=>l.productVariantId)).size !== body.lines.length) throw conflict('Duplicate product lines are not allowed in a transfer');
    const variants = await prisma.productVariant.findMany({ where: { tenantId: request.auth.tenantId, id: { in: body.lines.map(l => l.productVariantId) }, trackStock: true, active: true }, include: { product: true } });
    if (variants.length !== new Set(body.lines.map(l => l.productVariantId)).size) throw notFound('One or more transfer products were not found');
    return serializable(async tx => {
      const byId = new Map(variants.map(v=>[v.id,v]));
      for (const input of body.lines) {
        const variant=byId.get(input.productVariantId)!;
        if (variant.product.productType==='SERIALIZED') {
          if(!Number.isInteger(input.quantity)||input.serialNumberIds.length!==input.quantity) throw conflict('Serialized transfer requires one serial per unit');
          const serials=await tx.inventorySerial.findMany({where:{id:{in:input.serialNumberIds},tenantId:request.auth.tenantId,locationId:body.fromLocationId,productVariantId:variant.id,status:'AVAILABLE'}});
          if(serials.length!==input.serialNumberIds.length) throw conflict('One or more serials are not available at the source location');
        } else if(input.serialNumberIds.length) throw conflict('Serials supplied for a non-serialized product');
        if(variant.product.productType==='LOT_TRACKED'||variant.requiresExpiry){const sum=input.lotAllocations.reduce((a,l)=>a+l.quantity,0);if(Math.abs(sum-input.quantity)>0.0001) throw conflict('Transfer lot allocation must equal line quantity');for(const a of input.lotAllocations){const lot=await tx.inventoryLot.findFirst({where:{id:a.lotId,tenantId:request.auth.tenantId,locationId:body.fromLocationId,productVariantId:variant.id}});if(!lot||lot.quantityOnHand.lt(a.quantity)) throw conflict('Lot is unavailable or insufficient');}} else if(input.lotAllocations.length) throw conflict('Lots supplied for a non-lot product');
      }
      const transfer=await tx.stockTransfer.create({data:{tenantId:request.auth.tenantId,number:businessNumber('TRF'),fromLocationId:body.fromLocationId,toLocationId:body.toLocationId,notes:body.notes,createdBy:request.auth.userId,lines:{create:body.lines.map(line=>({productVariantId:line.productVariantId,quantity:line.quantity}))}},include:{lines:true}});
      const lineMap=new Map(transfer.lines.map(l=>[l.productVariantId,l]));
      for(const input of body.lines){const line=lineMap.get(input.productVariantId)!;if(input.lotAllocations.length) await tx.stockTransferLotAllocation.createMany({data:input.lotAllocations.map(a=>({stockTransferLineId:line.id,lotId:a.lotId,quantity:a.quantity}))});if(input.serialNumberIds.length) await tx.stockTransferSerialAllocation.createMany({data:input.serialNumberIds.map(serialId=>({stockTransferLineId:line.id,serialId}))});}
      return tx.stockTransfer.findUnique({where:{id:transfer.id},include:{lines:{include:{lotAllocations:true,serialAllocations:true}}}});
    });
  });

  app.post('/v1/transfers/:id/approve', { preHandler: requirePermission('inventory.transfer') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    const transfer = await prisma.stockTransfer.findFirst({ where: { id, tenantId: request.auth.tenantId } });
    if (!transfer) throw notFound('Transfer not found');
    assertLocationAccess(request, transfer.fromLocationId);
    assertLocationAccess(request, transfer.toLocationId);
    if (transfer.status !== StockTransferStatus.REQUESTED) throw conflict('Transfer is not awaiting approval');
    return prisma.stockTransfer.update({ where: { id }, data: { status: StockTransferStatus.APPROVED, approvedBy: request.auth.userId } });
  });

  app.post('/v1/transfers/:id/dispatch', { preHandler: requirePermission('inventory.transfer') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    return serializable(async tx => {
      const transfer = await tx.stockTransfer.findFirst({ where: { id, tenantId: request.auth.tenantId }, include: { lines: { include: { productVariant: true, lotAllocations: { include: { lot: true } }, serialAllocations: true } } } });
      if (!transfer) throw notFound('Transfer not found');
      assertLocationAccess(request, transfer.fromLocationId);
      if (transfer.status !== StockTransferStatus.APPROVED) throw conflict('Transfer must be approved before dispatch');
      for (const line of transfer.lines) {
        for (const allocation of line.lotAllocations) await tx.inventoryLot.update({ where:{id:allocation.lotId}, data:{quantityOnHand:{decrement:allocation.quantity}} });
        for (const allocation of line.serialAllocations) await tx.inventorySerial.update({ where:{id:allocation.serialId}, data:{status:'IN_TRANSIT'} });
        await postInventoryMovement(tx, {
          tenantId: request.auth.tenantId,
          locationId: transfer.fromLocationId,
          productVariantId: line.productVariantId,
          movementType: InventoryMovementType.TRANSFER_OUT,
          quantity: line.quantity,
          referenceType: 'STOCK_TRANSFER',
          referenceId: transfer.id,
          performedBy: request.auth.userId
        });
        const cost = await consumeFifoCost(tx, {
          tenantId: request.auth.tenantId,
          locationId: transfer.fromLocationId,
          productVariantId: line.productVariantId,
          quantity: line.quantity,
          fallbackUnitCost: line.productVariant.baseCost
        });
        await tx.stockTransferLine.update({ where: { id: line.id }, data: { unitCostSnapshot: cost } });
      }
      const updated = await tx.stockTransfer.update({ where: { id: transfer.id }, data: { status: StockTransferStatus.IN_TRANSIT, dispatchedBy: request.auth.userId, dispatchedAt: new Date() } });
      await writeAudit(tx, { tenantId: request.auth.tenantId, actorUserId: request.auth.userId, action: 'inventory.transfer_dispatched', resourceType: 'StockTransfer', resourceId: transfer.id });
      return updated;
    });
  });

  app.post('/v1/transfers/:id/receive', { preHandler: requirePermission('inventory.transfer') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    return serializable(async tx => {
      const transfer = await tx.stockTransfer.findFirst({ where: { id, tenantId: request.auth.tenantId }, include: { lines: { include: { lotAllocations: { include: { lot: true } }, serialAllocations: { include: { serial: true } } } } } });
      if (!transfer) throw notFound('Transfer not found');
      assertLocationAccess(request, transfer.toLocationId);
      if (transfer.status !== StockTransferStatus.IN_TRANSIT) throw conflict('Only in-transit stock can be received');
      for (const line of transfer.lines) {
        if (line.unitCostSnapshot == null) throw conflict('Transfer cost snapshot is missing');
        await postInventoryMovement(tx, {
          tenantId: request.auth.tenantId,
          locationId: transfer.toLocationId,
          productVariantId: line.productVariantId,
          movementType: InventoryMovementType.TRANSFER_IN,
          quantity: line.quantity,
          referenceType: 'STOCK_TRANSFER',
          referenceId: transfer.id,
          performedBy: request.auth.userId
        });
        for (const allocation of line.lotAllocations) {
          await tx.inventoryLot.upsert({ where:{tenantId_locationId_productVariantId_lotNumber:{tenantId:request.auth.tenantId,locationId:transfer.toLocationId,productVariantId:line.productVariantId,lotNumber:allocation.lot.lotNumber}}, create:{tenantId:request.auth.tenantId,locationId:transfer.toLocationId,productVariantId:line.productVariantId,lotNumber:allocation.lot.lotNumber,expiryDate:allocation.lot.expiryDate,quantityOnHand:allocation.quantity}, update:{quantityOnHand:{increment:allocation.quantity},expiryDate:allocation.lot.expiryDate} });
        }
        for (const allocation of line.serialAllocations) await tx.inventorySerial.update({ where:{id:allocation.serialId}, data:{locationId:transfer.toLocationId,status:'AVAILABLE'} });
        await tx.inventoryCostLayer.create({
          data: {
            tenantId: request.auth.tenantId,
            locationId: transfer.toLocationId,
            productVariantId: line.productVariantId,
            sourceType: 'STOCK_TRANSFER',
            sourceId: transfer.id,
            quantityReceived: line.quantity,
            quantityRemaining: line.quantity,
            unitCost: line.unitCostSnapshot,
            receivedAt: new Date()
          }
        });
      }
      const updated = await tx.stockTransfer.update({ where: { id: transfer.id }, data: { status: StockTransferStatus.RECEIVED, receivedBy: request.auth.userId, receivedAt: new Date() } });
      await emitEvent(tx, { tenantId: request.auth.tenantId, eventType: 'inventory.transferred', aggregateType: 'StockTransfer', aggregateId: transfer.id, payload: { number: transfer.number, fromLocationId: transfer.fromLocationId, toLocationId: transfer.toLocationId } });
      await writeAudit(tx, { tenantId: request.auth.tenantId, actorUserId: request.auth.userId, action: 'inventory.transfer_received', resourceType: 'StockTransfer', resourceId: transfer.id });
      return updated;
    });
  });
}
