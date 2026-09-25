import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { emitEvent } from '../../lib/outbox.js';
import { serializable } from '../../lib/transactions.js';
import { requirePermission } from '../auth/context.js';

const customerSchema = z.object({
  name: z.string().min(1).max(160),
  email: z.string().email().optional(),
  phone: z.string().max(50).optional(),
  marketingConsent: z.boolean().default(false),
  notes: z.string().max(2000).optional()
});

export async function customerRoutes(app: FastifyInstance) {
  app.get('/v1/customers', { preHandler: requirePermission('customers.read') }, async request => {
    const query = z.object({ q: z.string().max(160).optional(), limit: z.coerce.number().int().min(1).max(200).default(50) }).parse(request.query);
    const q = query.q?.trim();
    const customers = await prisma.customer.findMany({
      where: {
        tenantId: request.auth.tenantId,
        ...(q ? { OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { email: { contains: q, mode: 'insensitive' } },
          { phone: { contains: q } }
        ] } : {})
      },
      orderBy: { updatedAt: 'desc' },
      take: query.limit
    });
    return { customers };
  });

  app.post('/v1/customers', { preHandler: requirePermission('customers.write') }, async request => {
    const body = customerSchema.parse(request.body);
    return serializable(async tx => {
      const customer = await tx.customer.create({ data: { tenantId: request.auth.tenantId, ...body } });
      await emitEvent(tx, {
        tenantId: request.auth.tenantId,
        eventType: 'customer.created',
        aggregateType: 'Customer',
        aggregateId: customer.id,
        payload: { id: customer.id, name: customer.name, email: customer.email, phone: customer.phone, marketingConsent: customer.marketingConsent }
      });
      return customer;
    });
  });
}
