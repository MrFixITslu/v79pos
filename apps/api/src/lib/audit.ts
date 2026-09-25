import type { Prisma } from '@prisma/client';

export async function writeAudit(
  tx: Prisma.TransactionClient,
  input: {
    tenantId: string;
    actorUserId?: string;
    action: string;
    resourceType: string;
    resourceId?: string;
    before?: Prisma.InputJsonValue;
    after?: Prisma.InputJsonValue;
    ipAddress?: string;
    deviceId?: string;
  }
) {
  return tx.auditEvent.create({ data: input });
}
