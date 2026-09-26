import type { FastifyInstance, FastifyRequest } from 'fastify';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { prisma } from '../../lib/prisma.js';
import { config } from '../../lib/config.js';
import { unauthorized } from '../../lib/errors.js';
import { builtInPermissions, type AuthContext } from './context.js';

const jwks = createRemoteJWKSet(new URL(config.HUB_JWKS_URL));

function bearer(request: FastifyRequest) {
  const header = request.headers.authorization;
  if (!header?.startsWith('Bearer ')) throw unauthorized('Bearer token required');
  return header.slice(7);
}

async function userFromRequest(request: FastifyRequest): Promise<{ userId: string; tokenTenantId?: string }> {
  if (config.AUTH_MODE === 'dev') {
    if (config.NODE_ENV === 'production') throw unauthorized('Development authentication is disabled in production');
    const userId = String(request.headers['x-dev-user-id'] ?? '').trim();
    if (!userId) throw unauthorized('x-dev-user-id is required in development auth mode');
    return { userId };
  }

  const verified = await jwtVerify(bearer(request), jwks, {
    issuer: config.JWT_ISSUER,
    audience: config.JWT_AUDIENCE
  });
  if (!verified.payload.sub) throw unauthorized('Token subject is missing');
  const tenantClaim = typeof verified.payload.tenant_id === 'string' ? verified.payload.tenant_id : undefined;
  return { userId: verified.payload.sub, tokenTenantId: tenantClaim };
}

export async function registerAuth(app: FastifyInstance) {
  app.decorateRequest('auth', undefined as unknown as AuthContext);

  app.addHook('onRequest', async request => {
    if (request.url === '/' || request.url === '/favicon.svg' || request.url === '/app.js' || request.url === '/app.css' || request.url === '/health' || request.url === '/ready' || request.url.startsWith('/v1/payments/webhooks/') || request.url.startsWith('/api/platform/')) return;

    const identity = await userFromRequest(request);
    const requestedTenant = String(request.headers['x-v79-tenant-id'] ?? '').trim();
    if (identity.tokenTenantId && requestedTenant && identity.tokenTenantId !== requestedTenant) {
      throw unauthorized('Tenant selection does not match the authenticated token');
    }
    const tenantId = identity.tokenTenantId ?? requestedTenant;
    if (!tenantId) throw unauthorized('Tenant context is required');

    const membership = await prisma.membership.findUnique({
      where: { tenantId_userId: { tenantId, userId: identity.userId } },
      include: {
        tenant: { select: { active: true } },
        role: { include: { permissions: true } },
        locationAccess: { select: { locationId: true } }
      }
    });

    if (!membership?.active || !membership.tenant.active) throw unauthorized('No active membership for this tenant');

    const permissions = new Set([
      ...builtInPermissions(membership.roleKey),
      ...membership.role.permissions.map(p => p.permission)
    ]);
    const allLocations = membership.roleKey === 'OWNER' || membership.roleKey === 'ADMIN';
    const auth: AuthContext = {
      userId: identity.userId,
      tenantId,
      membershipId: membership.id,
      roleKey: membership.roleKey,
      permissions,
      locationIds: new Set(membership.locationAccess.map(item => item.locationId)),
      allLocations
    };
    request.auth = auth;
  });
}
