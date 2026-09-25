import type { Prisma } from '@prisma/client';

export async function emitEvent(
  tx: Prisma.TransactionClient,
  input: {
    tenantId: string;
    eventType: string;
    aggregateType: string;
    aggregateId: string;
    payload: Prisma.InputJsonValue;
  }
) {
  return tx.outboxEvent.create({ data: input });
}
