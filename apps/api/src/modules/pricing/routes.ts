import type { FastifyInstance } from 'fastify';
import { PromotionType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { requirePermission } from '../auth/context.js';
import { notFound } from '../../lib/errors.js';

export async function pricingRoutes(app: FastifyInstance) {
  app.get('/v1/price-lists', { preHandler: requirePermission('pricing.read') }, async request => ({
    priceLists: await prisma.priceList.findMany({ where: { tenantId: request.auth.tenantId }, include: { items: true }, orderBy: [{ priority: 'desc' }, { name: 'asc' }] })
  }));

  app.post('/v1/price-lists', { preHandler: requirePermission('pricing.write') }, async request => {
    const body = z.object({ name: z.string().min(1).max(120), currency: z.string().length(3).default('XCD'), priority: z.coerce.number().int().default(0), startsAt: z.coerce.date().optional(), endsAt: z.coerce.date().optional() }).parse(request.body);
    return prisma.priceList.create({ data: { tenantId: request.auth.tenantId, ...body } });
  });

  app.put('/v1/price-lists/:id/items/:variantId', { preHandler: requirePermission('pricing.write') }, async request => {
    const params = z.object({ id: z.string(), variantId: z.string() }).parse(request.params);
    const body = z.object({ price: z.coerce.number().nonnegative() }).parse(request.body);
    const list = await prisma.priceList.findFirst({ where: { id: params.id, tenantId: request.auth.tenantId } });
    const variant = await prisma.productVariant.findFirst({ where: { id: params.variantId, tenantId: request.auth.tenantId } });
    if (!list || !variant) throw notFound('Price list or product not found');
    return prisma.priceListItem.upsert({ where: { priceListId_productVariantId: { priceListId: list.id, productVariantId: variant.id } }, create: { priceListId: list.id, productVariantId: variant.id, price: body.price }, update: { price: body.price } });
  });

  app.get('/v1/promotions', { preHandler: requirePermission('pricing.read') }, async request => ({
    promotions: await prisma.promotion.findMany({ where: { tenantId: request.auth.tenantId }, include: { products: true }, orderBy: { createdAt: 'desc' } })
  }));

  app.post('/v1/promotions', { preHandler: requirePermission('pricing.write') }, async request => {
    const body = z.object({
      name: z.string().min(1).max(160), code: z.string().min(2).max(50).optional(), type: z.enum(['PERCENTAGE','FIXED_AMOUNT']),
      value: z.coerce.number().positive(), minimumSubtotal: z.coerce.number().nonnegative().optional(), maximumDiscount: z.coerce.number().positive().optional(),
      appliesToAll: z.boolean().default(false), stackable: z.boolean().default(false), startsAt: z.coerce.date().optional(), endsAt: z.coerce.date().optional(),
      productVariantIds: z.array(z.string()).default([])
    }).parse(request.body);
    return prisma.$transaction(async tx => {
      const promo = await tx.promotion.create({ data: { tenantId: request.auth.tenantId, name: body.name, code: body.code?.toUpperCase(), type: PromotionType[body.type], value: body.value, minimumSubtotal: body.minimumSubtotal, maximumDiscount: body.maximumDiscount, appliesToAll: body.appliesToAll, stackable: body.stackable, startsAt: body.startsAt, endsAt: body.endsAt } });
      if (body.productVariantIds.length) await tx.promotionProduct.createMany({ data: [...new Set(body.productVariantIds)].map(productVariantId => ({ promotionId: promo.id, productVariantId })) });
      return promo;
    });
  });

  app.patch('/v1/customers/:id/price-list', { preHandler: requirePermission('pricing.write') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    const body = z.object({ priceListId: z.string().nullable() }).parse(request.body);
    const customer = await prisma.customer.findFirst({ where: { id, tenantId: request.auth.tenantId } });
    if (!customer) throw notFound('Customer not found');
    if (body.priceListId) {
      const list = await prisma.priceList.findFirst({ where: { id: body.priceListId, tenantId: request.auth.tenantId } });
      if (!list) throw notFound('Price list not found');
    }
    return prisma.customer.update({ where: { id }, data: { priceListId: body.priceListId } });
  });
}
