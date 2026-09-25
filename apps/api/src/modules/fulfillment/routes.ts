import type { FastifyInstance } from 'fastify';
import { FulfillmentMethod, FulfillmentStatus } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { businessNumber } from '../../lib/numbering.js';
import { conflict, notFound } from '../../lib/errors.js';
import { assertLocationAccess, requirePermission } from '../auth/context.js';
import { emitEvent } from '../../lib/outbox.js';

export async function fulfillmentRoutes(app: FastifyInstance) {
  app.get('/v1/fulfillments', { preHandler: requirePermission('fulfillment.read') }, async request => {
    const q=z.object({status:z.enum(['PENDING','PICKING','READY','DISPATCHED','DELIVERED','CANCELLED']).optional(),driverUserId:z.string().optional(),limit:z.coerce.number().int().min(1).max(200).default(100)}).parse(request.query);
    const rows=await prisma.fulfillment.findMany({where:{tenantId:request.auth.tenantId,status:q.status as FulfillmentStatus|undefined,driverUserId:q.driverUserId},include:{lines:true,events:{orderBy:{occurredAt:'asc'}}},orderBy:{createdAt:'desc'},take:q.limit});
    return {fulfillments:rows.filter(r=>request.auth.allLocations||request.auth.locationIds.has(r.locationId))};
  });

  app.post('/v1/fulfillments', { preHandler: requirePermission('fulfillment.write') }, async request => {
    const body=z.object({saleId:z.string().optional(),commerceOrderId:z.string().optional(),method:z.enum(['PICKUP','LOCAL_DELIVERY','SHIPMENT']),recipientName:z.string().max(160).optional(),recipientPhone:z.string().max(50).optional(),deliveryAddress:z.record(z.string(),z.unknown()).optional(),promisedAt:z.coerce.date().optional(),notes:z.string().max(1000).optional()}).refine(v=>Boolean(v.saleId)!==Boolean(v.commerceOrderId),{message:'Provide exactly one of saleId or commerceOrderId'}).parse(request.body);
    return prisma.$transaction(async tx=>{
      let locationId:string; let lineData:{productVariantId:string;quantity:any;saleLineId?:string;commerceOrderLineId?:string}[]=[];
      if(body.saleId){const sale=await tx.sale.findFirst({where:{id:body.saleId,tenantId:request.auth.tenantId},include:{lines:true}});if(!sale) throw notFound('Sale not found');locationId=sale.locationId;lineData=sale.lines.map(l=>({productVariantId:l.productVariantId,quantity:l.quantity,saleLineId:l.id}));}
      else {const order=await tx.commerceOrder.findFirst({where:{id:body.commerceOrderId!,tenantId:request.auth.tenantId},include:{lines:true}});if(!order) throw notFound('Order not found');locationId=order.locationId;lineData=order.lines.map(l=>({productVariantId:l.productVariantId,quantity:l.quantity,commerceOrderLineId:l.id}));}
      assertLocationAccess(request,locationId);
      const f=await tx.fulfillment.create({data:{tenantId:request.auth.tenantId,locationId,saleId:body.saleId,commerceOrderId:body.commerceOrderId,number:businessNumber('FUL'),method:FulfillmentMethod[body.method],recipientName:body.recipientName,recipientPhone:body.recipientPhone,deliveryAddress:body.deliveryAddress,promisedAt:body.promisedAt,notes:body.notes,createdBy:request.auth.userId,lines:{create:lineData}}});
      await tx.fulfillmentEvent.create({data:{fulfillmentId:f.id,status:FulfillmentStatus.PENDING,actorUserId:request.auth.userId}});
      return tx.fulfillment.findUnique({where:{id:f.id},include:{lines:true,events:true}});
    });
  });

  app.patch('/v1/fulfillments/:id/pick', { preHandler: requirePermission('fulfillment.write') }, async request=>{
    const {id}=z.object({id:z.string()}).parse(request.params);const body=z.object({lines:z.array(z.object({lineId:z.string(),pickedQty:z.coerce.number().nonnegative()})).min(1)}).parse(request.body);
    return prisma.$transaction(async tx=>{const f=await tx.fulfillment.findFirst({where:{id,tenantId:request.auth.tenantId,status:{in:[FulfillmentStatus.PENDING,FulfillmentStatus.PICKING]},},include:{lines:true}});if(!f) throw notFound('Pickable fulfillment not found');assertLocationAccess(request,f.locationId);const byId=new Map(f.lines.map(l=>[l.id,l]));for(const input of body.lines){const line=byId.get(input.lineId);if(!line||input.pickedQty>line.quantity.toNumber()) throw conflict('Invalid picked quantity');await tx.fulfillmentLine.update({where:{id:line.id},data:{pickedQty:input.pickedQty}});}const refreshed=await tx.fulfillmentLine.findMany({where:{fulfillmentId:id}});const ready=refreshed.every(l=>l.pickedQty.gte(l.quantity));const status=ready?FulfillmentStatus.READY:FulfillmentStatus.PICKING;await tx.fulfillment.update({where:{id},data:{status}});await tx.fulfillmentEvent.create({data:{fulfillmentId:id,status,actorUserId:request.auth.userId}});return {status,lines:refreshed};});
  });

  app.post('/v1/fulfillments/:id/dispatch', { preHandler: requirePermission('fulfillment.dispatch') }, async request=>{
    const {id}=z.object({id:z.string()}).parse(request.params);const body=z.object({driverUserId:z.string().optional(),trackingNumber:z.string().max(200).optional(),notes:z.string().max(500).optional()}).parse(request.body);
    return prisma.$transaction(async tx=>{const f=await tx.fulfillment.findFirst({where:{id,tenantId:request.auth.tenantId,status:FulfillmentStatus.READY}});if(!f) throw notFound('Ready fulfillment not found');assertLocationAccess(request,f.locationId);const updated=await tx.fulfillment.update({where:{id},data:{status:FulfillmentStatus.DISPATCHED,driverUserId:body.driverUserId,trackingNumber:body.trackingNumber,dispatchedAt:new Date()}});await tx.fulfillmentEvent.create({data:{fulfillmentId:id,status:FulfillmentStatus.DISPATCHED,notes:body.notes,actorUserId:request.auth.userId}});await emitEvent(tx,{tenantId:request.auth.tenantId,eventType:'fulfillment.dispatched',aggregateType:'Fulfillment',aggregateId:id,payload:{number:updated.number,method:updated.method,driverUserId:updated.driverUserId,trackingNumber:updated.trackingNumber}});return updated;});
  });

  app.post('/v1/fulfillments/:id/deliver', { preHandler: requirePermission('fulfillment.dispatch') }, async request=>{
    const {id}=z.object({id:z.string()}).parse(request.params);const body=z.object({proof:z.record(z.string(),z.unknown()).optional(),notes:z.string().max(500).optional()}).parse(request.body);
    return prisma.$transaction(async tx=>{const f=await tx.fulfillment.findFirst({where:{id,tenantId:request.auth.tenantId,status:{in:[FulfillmentStatus.READY,FulfillmentStatus.DISPATCHED]}}});if(!f) throw notFound('Active fulfillment not found');assertLocationAccess(request,f.locationId);const updated=await tx.fulfillment.update({where:{id},data:{status:FulfillmentStatus.DELIVERED,deliveredAt:new Date(),proof:body.proof}});await tx.fulfillmentEvent.create({data:{fulfillmentId:id,status:FulfillmentStatus.DELIVERED,notes:body.notes,actorUserId:request.auth.userId}});await emitEvent(tx,{tenantId:request.auth.tenantId,eventType:'fulfillment.delivered',aggregateType:'Fulfillment',aggregateId:id,payload:{number:updated.number,deliveredAt:updated.deliveredAt?.toISOString()}});return updated;});
  });
}
