import { prisma } from './prisma.js';

export async function runRetentionCleanup() {
  const now = new Date();
  const oldCatalog = new Date(now.getTime() - 14 * 86400_000);
  const oldWebhook = new Date(now.getTime() - 90 * 86400_000);
  const oldNotifications = new Date(now.getTime() - 180 * 86400_000);
  const [catalog, webhooks, notifications] = await prisma.$transaction([
    prisma.catalogRevision.deleteMany({ where: { expiresAt: { lt: oldCatalog } } }),
    prisma.paymentWebhookEvent.deleteMany({ where: { processedAt: { lt: oldWebhook } } }),
    prisma.notification.deleteMany({ where: { readAt: { not: null, lt: oldNotifications } } })
  ]);
  return { catalogRevisions: catalog.count, paymentWebhookEvents: webhooks.count, notifications: notifications.count };
}
