import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { conflict, notFound } from '../../lib/errors.js';
import { requirePermission } from '../auth/context.js';

const membershipSchema = z.object({
  userId: z.string().min(1),
  roleKey: z.string().min(1).max(50),
  locationIds: z.array(z.string()).default([])
});

export async function teamRoutes(app: FastifyInstance) {
  app.get('/v1/me', async request => ({
    userId: request.auth.userId,
    tenantId: request.auth.tenantId,
    roleKey: request.auth.roleKey,
    permissions: [...request.auth.permissions],
    locationIds: [...request.auth.locationIds],
    allLocations: request.auth.allLocations
  }));

  app.get('/v1/team', { preHandler: requirePermission('team.read') }, async request => {
    return { members: await prisma.membership.findMany({ where: { tenantId: request.auth.tenantId, active: true }, include: { role: true, locationAccess: { include: { location: true } } }, orderBy: { createdAt: 'asc' } }) };
  });

  app.post('/v1/team', { preHandler: requirePermission('team.write') }, async request => {
    const body = membershipSchema.parse(request.body);
    const role = await prisma.tenantRole.findUnique({ where: { tenantId_key: { tenantId: request.auth.tenantId, key: body.roleKey } } });
    if (!role) throw notFound('Role not found');
    if (['OWNER', 'ADMIN'].includes(body.roleKey) && request.auth.roleKey !== 'OWNER') throw conflict('Only an owner can assign owner or admin roles');
    const locations = await prisma.location.findMany({ where: { tenantId: request.auth.tenantId, id: { in: body.locationIds }, active: true }, select: { id: true } });
    if (locations.length !== new Set(body.locationIds).size) throw notFound('One or more locations were not found');

    return prisma.$transaction(async tx => {
      const membership = await tx.membership.upsert({
        where: { tenantId_userId: { tenantId: request.auth.tenantId, userId: body.userId } },
        create: { tenantId: request.auth.tenantId, userId: body.userId, roleKey: body.roleKey },
        update: { roleKey: body.roleKey, active: true }
      });
      await tx.userLocationAccess.deleteMany({ where: { membershipId: membership.id } });
      if (body.locationIds.length) await tx.userLocationAccess.createMany({ data: body.locationIds.map(locationId => ({ membershipId: membership.id, locationId })) });
      return tx.membership.findUnique({ where: { id: membership.id }, include: { role: true, locationAccess: true } });
    });
  });
}
