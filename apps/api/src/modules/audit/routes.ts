import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { requirePermission } from '../auth/context.js';

export async function auditRoutes(app: FastifyInstance) {
  app.get('/v1/audit', { preHandler: requirePermission('audit.read') }, async request => {
    const q = z.object({ resourceType: z.string().max(100).optional(), actorUserId: z.string().max(200).optional(), from: z.coerce.date().optional(), to: z.coerce.date().optional(), limit: z.coerce.number().int().min(1).max(500).default(100) }).parse(request.query);
    return { events: await prisma.auditEvent.findMany({
      where: { tenantId: request.auth.tenantId, resourceType: q.resourceType, actorUserId: q.actorUserId, createdAt: { gte: q.from, lte: q.to } },
      orderBy: { createdAt: 'desc' }, take: q.limit
    }) };
  });
}
