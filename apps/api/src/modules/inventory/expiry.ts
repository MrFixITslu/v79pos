import { NotificationSeverity, Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';

const D = (v: Prisma.Decimal.Value) => new Prisma.Decimal(v);

export async function refreshExpiryAlerts(tenantId: string, warningDays = 30, criticalDays = 7) {
  const now = new Date();
  const warningCutoff = new Date(now.getTime() + warningDays * 86_400_000);
  const lots = await prisma.inventoryLot.findMany({
    where: { tenantId, quantityOnHand: { gt: 0 }, expiryDate: { not: null, lte: warningCutoff } },
    include: { productVariant: { include: { product: true } }, location: true },
    orderBy: { expiryDate: 'asc' }
  });

  const activeKeys: string[] = [];
  for (const lot of lots) {
    if (!lot.expiryDate) continue;
    const days = Math.floor((lot.expiryDate.getTime() - now.getTime()) / 86_400_000);
    const expired = days < 0;
    const severity = expired || days <= criticalDays ? NotificationSeverity.CRITICAL : NotificationSeverity.WARNING;
    const dedupeKey = `expiry:${lot.id}`;
    activeKeys.push(dedupeKey);
    const title = expired ? 'Expired inventory requires action' : days <= criticalDays ? 'Inventory expires soon' : 'Inventory expiry warning';
    const message = expired
      ? `${lot.productVariant.product.name} / ${lot.productVariant.name}, lot ${lot.lotNumber}, has expired with ${D(lot.quantityOnHand).toString()} units at ${lot.location.name}.`
      : `${lot.productVariant.product.name} / ${lot.productVariant.name}, lot ${lot.lotNumber}, expires in ${days} day${days === 1 ? '' : 's'} with ${D(lot.quantityOnHand).toString()} units at ${lot.location.name}.`;
    await prisma.notification.upsert({
      where: { tenantId_dedupeKey: { tenantId, dedupeKey } },
      create: { tenantId, type: 'INVENTORY_EXPIRY', severity, title, message, actionUrl: '/inventory/lots', dedupeKey },
      update: { severity, title, message, readAt: null }
    });
  }

  await prisma.notification.updateMany({
    where: { tenantId, type: 'INVENTORY_EXPIRY', readAt: null, ...(activeKeys.length ? { dedupeKey: { notIn: activeKeys } } : {}) },
    data: { readAt: now }
  });
  return lots.length;
}
