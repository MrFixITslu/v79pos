import { prisma } from '../lib/prisma.js';
import { builtInPermissions, builtInRoleKeys } from '../modules/auth/context.js';

const name = process.env.BOOTSTRAP_TENANT_NAME ?? 'Vision79 Demo';
const slug = process.env.BOOTSTRAP_TENANT_SLUG ?? 'vision79-demo';
const ownerUserId = process.env.BOOTSTRAP_OWNER_USER_ID ?? 'dev-owner';

const tenant = await prisma.tenant.upsert({ where: { slug }, create: { name, slug, currency: 'XCD', timezone: 'America/St_Lucia' }, update: { name, active: true } });
for (const key of builtInRoleKeys()) {
  const permissions = builtInPermissions(key);
  const role = await prisma.tenantRole.upsert({ where: { tenantId_key: { tenantId: tenant.id, key } }, create: { tenantId: tenant.id, key, name: key[0] + key.slice(1).toLowerCase(), builtIn: true }, update: { builtIn: true } });
  await prisma.rolePermission.deleteMany({ where: { roleId: role.id } });
  if (!permissions.includes('*')) await prisma.rolePermission.createMany({ data: permissions.map(permission => ({ roleId: role.id, permission })) });
}
await prisma.membership.upsert({ where: { tenantId_userId: { tenantId: tenant.id, userId: ownerUserId } }, create: { tenantId: tenant.id, userId: ownerUserId, roleKey: 'OWNER' }, update: { roleKey: 'OWNER', active: true } });
const location = await prisma.location.upsert({ where: { tenantId_code: { tenantId: tenant.id, code: 'MAIN' } }, create: { tenantId: tenant.id, name: 'Main Store', code: 'MAIN', type: 'STORE' }, update: { active: true } });
await prisma.register.upsert({ where: { tenantId_code: { tenantId: tenant.id, code: 'REG-01' } }, create: { tenantId: tenant.id, locationId: location.id, name: 'Register 1', code: 'REG-01' }, update: { locationId: location.id, active: true } });
console.log(JSON.stringify({ tenantId: tenant.id, tenantSlug: tenant.slug, ownerUserId, locationId: location.id }, null, 2));
await prisma.$disconnect();
