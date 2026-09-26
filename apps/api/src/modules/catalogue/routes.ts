import type { FastifyInstance } from 'fastify';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { requirePermission } from '../auth/context.js';

const createProductSchema = z.object({
  name: z.string().min(1).max(160),
  description: z.string().max(2000).optional(),
  productType: z.enum(['STANDARD', 'VARIANT', 'SERVICE', 'BUNDLE', 'KIT', 'SERIALIZED', 'LOT_TRACKED', 'WEIGHTED', 'NON_STOCK']),
  category: z.string().max(100).optional(),
  brand: z.string().max(100).optional(),
  variants: z.array(z.object({
    sku: z.string().min(1).max(100),
    barcode: z.string().max(100).optional(),
    name: z.string().min(1).max(160),
    baseCost: z.coerce.number().min(0).default(0),
    sellPrice: z.coerce.number().min(0),
    taxRate: z.coerce.number().min(0).max(1).default(0),
    trackStock: z.boolean().default(true),
  requiresExpiry: z.boolean().default(false),
    attributes: z.record(z.unknown()).optional()
  })).min(1)
});

export async function catalogueRoutes(app: FastifyInstance) {
  app.get('/v1/products', { preHandler: requirePermission('catalogue.read') }, async request => {
    const products = await prisma.product.findMany({
      where: { tenantId: request.auth.tenantId, active: true },
      include: { variants: { where: { active: true }, orderBy: { name: 'asc' } } },
      orderBy: { name: 'asc' }
    });
    return { products };
  });

  app.post('/v1/products', { preHandler: requirePermission('catalogue.write') }, async request => {
    const body = createProductSchema.parse(request.body);
    return prisma.product.create({
      data: {
        tenantId: request.auth.tenantId,
        name: body.name,
        description: body.description,
        productType: body.productType,
        category: body.category,
        brand: body.brand,
        variants: {
          create: body.variants.map(v => ({
            tenantId: request.auth.tenantId,
            sku: v.sku,
            barcode: v.barcode,
            name: v.name,
            baseCost: v.baseCost,
            sellPrice: v.sellPrice,
            taxRate: v.taxRate,
            trackStock: v.trackStock,
            requiresExpiry: v.requiresExpiry,
            attributes: v.attributes as Prisma.InputJsonValue | undefined
          }))
        }
      },
      include: { variants: true }
    });
  });
}
