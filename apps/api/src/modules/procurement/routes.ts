import type { FastifyInstance } from 'fastify';
import { InventoryMovementType, Prisma, PurchaseOrderStatus } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { serializable } from '../../lib/transactions.js';
import { businessNumber } from '../../lib/numbering.js';
import { conflict, notFound } from '../../lib/errors.js';
import { emitEvent } from '../../lib/outbox.js';
import { writeAudit } from '../../lib/audit.js';
import { assertLocationAccess, requirePermission } from '../auth/context.js';
import { postInventoryMovement } from '../inventory/service.js';

const supplierSchema = z.object({
  name: z.string().min(1).max(160),
  currency: z.string().length(3).default('XCD'),
  quotedLeadDays: z.coerce.number().int().min(0).max(365).optional(),
  email: z.string().email().optional(),
  phone: z.string().max(50).optional(),
  paymentTerms: z.string().max(200).optional(),
  minimumOrderValue: z.coerce.number().min(0).optional()
});

const supplierProductSchema = z.object({
  productVariantId: z.string().min(1),
  supplierSku: z.string().max(100).optional(),
  unitCost: z.coerce.number().min(0),
  minimumOrderQty: z.coerce.number().min(0).default(0),
  casePack: z.coerce.number().positive().default(1),
  preferred: z.boolean().default(false)
});

const poSchema = z.object({
  supplierId: z.string().min(1),
  shipToLocationId: z.string().min(1),
  expectedAt: z.coerce.date().optional(),
  notes: z.string().max(2000).optional(),
  lines: z.array(z.object({
    productVariantId: z.string().min(1),
    orderedQty: z.coerce.number().positive(),
    unitCost: z.coerce.number().min(0).optional()
  })).min(1)
});

const receiptSchema = z.object({
  lines: z.array(z.object({
    purchaseOrderLineId: z.string().min(1),
    receivedQty: z.coerce.number().positive(),
    lots: z.array(z.object({ lotNumber: z.string().min(1).max(100), quantity: z.coerce.number().positive(), expiryDate: z.coerce.date().optional() })).default([]),
    serialNumbers: z.array(z.string().min(1).max(200)).default([])
  })).min(1),
  additionalCosts: z.coerce.number().min(0).default(0),
  notes: z.string().max(2000).optional()
});

export async function procurementRoutes(app: FastifyInstance) {
  app.get('/v1/suppliers', { preHandler: requirePermission('procurement.read') }, async request => {
    return { suppliers: await prisma.supplier.findMany({ where: { tenantId: request.auth.tenantId, active: true }, include: { products: true }, orderBy: { name: 'asc' } }) };
  });

  app.post('/v1/suppliers', { preHandler: requirePermission('procurement.write') }, async request => {
    const body = supplierSchema.parse(request.body);
    return prisma.supplier.create({ data: { tenantId: request.auth.tenantId, ...body } });
  });

  app.post('/v1/suppliers/:supplierId/products', { preHandler: requirePermission('procurement.write') }, async request => {
    const params = z.object({ supplierId: z.string() }).parse(request.params);
    const body = supplierProductSchema.parse(request.body);
    const [supplier, variant] = await Promise.all([
      prisma.supplier.findFirst({ where: { id: params.supplierId, tenantId: request.auth.tenantId, active: true } }),
      prisma.productVariant.findFirst({ where: { id: body.productVariantId, tenantId: request.auth.tenantId } })
    ]);
    if (!supplier || !variant) throw notFound('Supplier or product not found');
    if (body.preferred) {
      await prisma.supplierProduct.updateMany({ where: { tenantId: request.auth.tenantId, productVariantId: body.productVariantId }, data: { preferred: false } });
    }
    return prisma.supplierProduct.upsert({
      where: { supplierId_productVariantId: { supplierId: supplier.id, productVariantId: variant.id } },
      create: { tenantId: request.auth.tenantId, supplierId: supplier.id, ...body },
      update: { supplierSku: body.supplierSku, unitCost: body.unitCost, minimumOrderQty: body.minimumOrderQty, casePack: body.casePack, preferred: body.preferred, active: true }
    });
  });

  app.get('/v1/purchase-orders', { preHandler: requirePermission('procurement.read') }, async request => {
    const orders = await prisma.purchaseOrder.findMany({
      where: { tenantId: request.auth.tenantId },
      include: { supplier: true, shipTo: true, lines: { include: { productVariant: true } }, shipments: true },
      orderBy: { createdAt: 'desc' }, take: 100
    });
    return { purchaseOrders: orders.filter(po => request.auth.allLocations || request.auth.locationIds.has(po.shipToLocationId)) };
  });

  app.post('/v1/purchase-orders', { preHandler: requirePermission('procurement.write') }, async request => {
    const body = poSchema.parse(request.body);
    assertLocationAccess(request, body.shipToLocationId);
    return serializable(async tx => {
      const supplier = await tx.supplier.findFirst({ where: { id: body.supplierId, tenantId: request.auth.tenantId, active: true } });
      if (!supplier) throw notFound('Supplier not found');
      const mappings = await tx.supplierProduct.findMany({
        where: { supplierId: supplier.id, productVariantId: { in: body.lines.map(l => l.productVariantId) }, active: true }
      });
      const mapped = new Map(mappings.map(m => [m.productVariantId, m]));
      for (const line of body.lines) if (!mapped.has(line.productVariantId)) throw conflict('Every PO line must be linked to this supplier');

      const po = await tx.purchaseOrder.create({
        data: {
          tenantId: request.auth.tenantId,
          supplierId: supplier.id,
          shipToLocationId: body.shipToLocationId,
          number: businessNumber('PO'),
          status: PurchaseOrderStatus.DRAFT,
          expectedAt: body.expectedAt,
          currency: supplier.currency,
          notes: body.notes,
          createdBy: request.auth.userId,
          lines: { create: body.lines.map(line => ({
            productVariantId: line.productVariantId,
            orderedQty: line.orderedQty,
            unitCost: line.unitCost ?? mapped.get(line.productVariantId)!.unitCost
          })) }
        }, include: { lines: true, supplier: true }
      });
      await emitEvent(tx, { tenantId: request.auth.tenantId, eventType: 'purchase_order.created', aggregateType: 'PurchaseOrder', aggregateId: po.id, payload: { number: po.number, supplierId: po.supplierId, locationId: po.shipToLocationId } });
      return po;
    });
  });

  app.post('/v1/purchase-orders/:id/approve', { preHandler: requirePermission('procurement.approve') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    return serializable(async tx => {
      const po = await tx.purchaseOrder.findFirst({ where: { id, tenantId: request.auth.tenantId } });
      if (!po) throw notFound('Purchase order not found');
      assertLocationAccess(request, po.shipToLocationId);
      if (![PurchaseOrderStatus.DRAFT, PurchaseOrderStatus.PENDING_APPROVAL].includes(po.status)) throw conflict('Purchase order is not awaiting approval');
      const updated = await tx.purchaseOrder.update({ where: { id }, data: { status: PurchaseOrderStatus.APPROVED, approvedBy: request.auth.userId, approvedAt: new Date() } });
      await emitEvent(tx, { tenantId: request.auth.tenantId, eventType: 'purchase_order.approved', aggregateType: 'PurchaseOrder', aggregateId: po.id, payload: { number: po.number, approvedBy: request.auth.userId } });
      await writeAudit(tx, { tenantId: request.auth.tenantId, actorUserId: request.auth.userId, action: 'purchase_order.approved', resourceType: 'PurchaseOrder', resourceId: po.id });
      return updated;
    });
  });

  app.post('/v1/purchase-orders/:id/receive', { preHandler: requirePermission('receiving.write') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    const body = receiptSchema.parse(request.body);
    return serializable(async tx => {
      const po = await tx.purchaseOrder.findFirst({ where: { id, tenantId: request.auth.tenantId }, include: { lines: { include: { productVariant: { include: { product: true } } } } } });
      if (!po) throw notFound('Purchase order not found');
      assertLocationAccess(request, po.shipToLocationId);
      if ([PurchaseOrderStatus.CANCELLED, PurchaseOrderStatus.CLOSED, PurchaseOrderStatus.RECEIVED].includes(po.status)) throw conflict('Purchase order cannot receive stock in its current status');
      const lineMap = new Map(po.lines.map(line => [line.id, line]));
      const receiving = body.lines.map(input => {
        const line = lineMap.get(input.purchaseOrderLineId);
        if (!line) throw conflict('Receipt line does not belong to this purchase order');
        const outstanding = line.orderedQty.minus(line.receivedQty);
        const qty = new Prisma.Decimal(input.receivedQty);
        if (qty.gt(outstanding)) throw conflict('Received quantity exceeds outstanding purchase-order quantity');
        const productType = line.productVariant.product.productType;
        if (productType === 'SERIALIZED') {
          if (!qty.isInteger() || input.serialNumbers.length !== qty.toNumber()) throw conflict('Serialized receipts require one unique serial number per unit');
          if (new Set(input.serialNumbers).size !== input.serialNumbers.length) throw conflict('Duplicate serial number in receipt');
        }
        if (productType === 'LOT_TRACKED' || line.productVariant.requiresExpiry) {
          const lotQty = input.lots.reduce((a,l)=>a+l.quantity,0);
          if (Math.abs(lotQty-qty.toNumber()) > 0.0001) throw conflict('Lot quantities must equal received quantity');
          if (line.productVariant.requiresExpiry && input.lots.some(l=>!l.expiryDate)) throw conflict('Expiry date is required for this product');
        }
        return { input, line, qty, baseValue: qty.mul(line.unitCost) };
      });
      const baseTotal = receiving.reduce((sum, row) => sum.plus(row.baseValue), new Prisma.Decimal(0));
      const extra = new Prisma.Decimal(body.additionalCosts);
      const receipt = await tx.goodsReceipt.create({
        data: { tenantId: request.auth.tenantId, purchaseOrderId: po.id, locationId: po.shipToLocationId, number: businessNumber('GRN'), receivedBy: request.auth.userId, additionalCosts: extra, notes: body.notes }
      });

      for (const row of receiving) {
        const allocation = baseTotal.gt(0) ? extra.mul(row.baseValue.div(baseTotal)) : new Prisma.Decimal(0);
        const landedUnitCost = row.qty.gt(0) ? row.baseValue.plus(allocation).div(row.qty) : row.line.unitCost;
        const receiptLine = await tx.goodsReceiptLine.create({
          data: {
            goodsReceiptId: receipt.id,
            purchaseOrderLineId: row.line.id,
            productVariantId: row.line.productVariantId,
            receivedQty: row.qty,
            unitCost: row.line.unitCost,
            allocatedLandedCost: allocation,
            landedUnitCost
          }
        });
        for (const lot of row.input.lots) {
          await tx.inventoryLot.upsert({
            where: { tenantId_locationId_productVariantId_lotNumber: { tenantId: request.auth.tenantId, locationId: po.shipToLocationId, productVariantId: row.line.productVariantId, lotNumber: lot.lotNumber } },
            create: { tenantId: request.auth.tenantId, locationId: po.shipToLocationId, productVariantId: row.line.productVariantId, goodsReceiptLineId: receiptLine.id, lotNumber: lot.lotNumber, expiryDate: lot.expiryDate, quantityOnHand: lot.quantity },
            update: { quantityOnHand: { increment: lot.quantity }, expiryDate: lot.expiryDate }
          });
        }
        for (const serialNumber of row.input.serialNumbers) {
          await tx.inventorySerial.create({ data: { tenantId: request.auth.tenantId, locationId: po.shipToLocationId, productVariantId: row.line.productVariantId, goodsReceiptLineId: receiptLine.id, serialNumber } });
        }
        await tx.purchaseOrderLine.update({ where: { id: row.line.id }, data: { receivedQty: { increment: row.qty } } });
        await postInventoryMovement(tx, {
          tenantId: request.auth.tenantId,
          locationId: po.shipToLocationId,
          productVariantId: row.line.productVariantId,
          movementType: InventoryMovementType.PURCHASE_RECEIPT,
          quantity: row.qty,
          referenceType: 'GOODS_RECEIPT',
          referenceId: receipt.id,
          performedBy: request.auth.userId,
          metadata: { purchaseOrderId: po.id, receiptLineId: receiptLine.id, landedUnitCost: landedUnitCost.toString() }
        });
        await tx.inventoryCostLayer.create({
          data: {
            tenantId: request.auth.tenantId,
            locationId: po.shipToLocationId,
            productVariantId: row.line.productVariantId,
            sourceType: 'GOODS_RECEIPT',
            sourceId: receiptLine.id,
            quantityReceived: row.qty,
            quantityRemaining: row.qty,
            unitCost: landedUnitCost,
            receivedAt: receipt.receivedAt
          }
        });
      }

      const refreshed = await tx.purchaseOrderLine.findMany({ where: { purchaseOrderId: po.id } });
      const fullyReceived = refreshed.every(line => line.receivedQty.gte(line.orderedQty));
      await tx.purchaseOrder.update({ where: { id: po.id }, data: { status: fullyReceived ? PurchaseOrderStatus.RECEIVED : PurchaseOrderStatus.PARTIALLY_RECEIVED } });
      await emitEvent(tx, { tenantId: request.auth.tenantId, eventType: 'inventory.received', aggregateType: 'GoodsReceipt', aggregateId: receipt.id, payload: { purchaseOrderId: po.id, locationId: po.shipToLocationId, receiptNumber: receipt.number } });
      await writeAudit(tx, { tenantId: request.auth.tenantId, actorUserId: request.auth.userId, action: 'inventory.received', resourceType: 'GoodsReceipt', resourceId: receipt.id, after: { purchaseOrderId: po.id, additionalCosts: body.additionalCosts, lines: body.lines.length } });
      return tx.goodsReceipt.findUnique({ where: { id: receipt.id }, include: { lines: true } });
    });
  });
}
