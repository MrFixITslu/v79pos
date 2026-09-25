import { Prisma, PurchaseOrderStatus, ShipmentStatus } from '@prisma/client';
import { calculateReplenishment, choosePlanningLeadTime } from '@v79/commerce-domain';
import { prisma } from '../../lib/prisma.js';

const MS_DAY = 86_400_000;
const toDays = (future: Date, now: Date) => Math.max(0, Math.ceil((future.getTime() - now.getTime()) / MS_DAY));
const datePlusDays = (date: Date, days: number | null) => days == null ? null : new Date(date.getTime() + days * MS_DAY);

async function salesRate(tenantId: string, locationId: string, productVariantId: string, manual?: Prisma.Decimal | null) {
  if (manual != null) return manual.toNumber();
  const now = new Date();
  const quantitySince = async (days: number) => {
    const from = new Date(now.getTime() - days * MS_DAY);
    const result = await prisma.saleLine.aggregate({
      where: { productVariantId, sale: { tenantId, locationId, status: 'COMPLETED', completedAt: { gte: from } } },
      _sum: { quantity: true }
    });
    return (result._sum.quantity?.toNumber() ?? 0) / days;
  };
  const [d7, d30, d90] = await Promise.all([quantitySince(7), quantitySince(30), quantitySince(90)]);
  return d7 * 0.5 + d30 * 0.3 + d90 * 0.2;
}

async function dailyDemandStdDev(tenantId: string, locationId: string, productVariantId: string, days = 30) {
  const now = new Date();
  const from = new Date(now.getTime() - days * MS_DAY);
  const lines = await prisma.saleLine.findMany({
    where: { productVariantId, sale: { tenantId, locationId, status: 'COMPLETED', completedAt: { gte: from } } },
    select: { quantity: true, sale: { select: { completedAt: true } } }
  });
  const daily = Array.from({ length: days }, () => 0);
  for (const line of lines) {
    if (!line.sale.completedAt) continue;
    const offset = Math.floor((now.getTime() - line.sale.completedAt.getTime()) / MS_DAY);
    if (offset >= 0 && offset < days) daily[days - 1 - offset] += line.quantity.toNumber();
  }
  const mean = daily.reduce((a, b) => a + b, 0) / days;
  return Math.sqrt(daily.reduce((sum, v) => sum + (v - mean) ** 2, 0) / days);
}

function serviceFactor(level?: Prisma.Decimal | null) {
  const v = level?.toNumber() ?? 0;
  if (v >= 0.995) return 2.576;
  if (v >= 0.99) return 2.326;
  if (v >= 0.98) return 2.054;
  if (v >= 0.95) return 1.645;
  if (v >= 0.9) return 1.282;
  return 0;
}

async function inboundReceipts(tenantId: string, locationId: string, productVariantId: string, now: Date) {
  const poLines = await prisma.purchaseOrderLine.findMany({
    where: {
      productVariantId,
      purchaseOrder: {
        tenantId,
        shipToLocationId: locationId,
        status: { in: [PurchaseOrderStatus.APPROVED, PurchaseOrderStatus.SUBMITTED, PurchaseOrderStatus.CONFIRMED, PurchaseOrderStatus.PARTIALLY_RECEIVED] }
      }
    },
    include: {
      purchaseOrder: { select: { expectedAt: true } },
      shipmentLines: { include: { shipment: { select: { status: true, eta: true } } } }
    }
  });
  const receipts: { quantity: number; arrivesInDays: number }[] = [];
  for (const line of poLines) {
    let outstanding = line.orderedQty.minus(line.receivedQty).toNumber();
    if (outstanding <= 0) continue;
    for (const sl of line.shipmentLines) {
      if ([ShipmentStatus.RECEIVED, ShipmentStatus.CANCELLED].includes(sl.shipment.status)) continue;
      const qty = Math.min(outstanding, sl.quantity.toNumber());
      if (qty <= 0) continue;
      receipts.push({ quantity: qty, arrivesInDays: sl.shipment.eta ? toDays(sl.shipment.eta, now) : 0 });
      outstanding -= qty;
    }
    if (outstanding > 0) receipts.push({ quantity: outstanding, arrivesInDays: line.purchaseOrder.expectedAt ? toDays(line.purchaseOrder.expectedAt, now) : 0 });
  }
  return receipts;
}

async function observedLeadTimes(tenantId: string, supplierId: string, productVariantId: string) {
  const lines = await prisma.goodsReceiptLine.findMany({
    where: {
      productVariantId,
      receipt: { tenantId, purchaseOrder: { supplierId } }
    },
    include: { receipt: { include: { purchaseOrder: { select: { orderDate: true, createdAt: true } } } } },
    orderBy: { receipt: { receivedAt: 'desc' } },
    take: 20
  });
  return lines.map(line => {
    const start = line.receipt.purchaseOrder.orderDate ?? line.receipt.purchaseOrder.createdAt;
    return Math.max(0, Math.ceil((line.receipt.receivedAt.getTime() - start.getTime()) / MS_DAY));
  });
}

export async function recalculateTenant(tenantId: string) {
  const now = new Date();
  const policies = await prisma.replenishmentPolicy.findMany({
    where: { tenantId, enabled: true },
    include: { productVariant: { include: { product: true, supplierMap: { where: { active: true }, include: { supplier: true }, orderBy: [{ preferred: 'desc' }, { unitCost: 'asc' }] } } } }
  });
  const results = [];

  for (const policy of policies) {
    const [balance, demand, demandStd] = await Promise.all([
      prisma.inventoryBalance.findUnique({ where: { tenantId_locationId_productVariantId: { tenantId, locationId: policy.locationId, productVariantId: policy.productVariantId } } }),
      salesRate(tenantId, policy.locationId, policy.productVariantId, policy.manualDailyDemand),
      dailyDemandStdDev(tenantId, policy.locationId, policy.productVariantId)
    ]);
    const supplierMap = policy.productVariant.supplierMap.find(m => m.supplierId === policy.preferredSupplierId) ?? policy.productVariant.supplierMap[0];
    const observed = supplierMap ? await observedLeadTimes(tenantId, supplierMap.supplierId, policy.productVariantId) : [];
    const leadDays = choosePlanningLeadTime({ manualLeadDays: policy.manualLeadDays, quotedLeadDays: supplierMap?.supplier.quotedLeadDays, observedLeadDays: observed });
    const arrivals = await inboundReceipts(tenantId, policy.locationId, policy.productVariantId, now);
    const baseSafety = Math.max(policy.safetyStockQty.toNumber(), demand * (policy.safetyDays ?? 0));
    const statisticalSafety = serviceFactor(policy.serviceLevel) * demandStd * Math.sqrt(Math.max(1, leadDays));
    const safetyStock = Math.ceil(Math.max(baseSafety, statisticalSafety));
    const recommendation = calculateReplenishment({
      onHand: balance?.onHand.toNumber() ?? 0,
      reserved: balance?.reserved.toNumber() ?? 0,
      committed: balance?.committed.toNumber() ?? 0,
      quarantined: balance?.quarantined.toNumber() ?? 0,
      damaged: balance?.damaged.toNumber() ?? 0,
      expired: balance?.expired.toNumber() ?? 0,
      inboundReceipts: arrivals,
      forecastDailyDemand: demand,
      planningLeadTimeDays: leadDays,
      safetyStock,
      reviewPeriodDays: policy.reviewPeriodDays,
      casePack: supplierMap?.casePack.toNumber() ?? 1,
      minimumOrderQty: supplierMap?.minimumOrderQty.toNumber() ?? 0
    });
    const row = await prisma.reorderRecommendation.create({
      data: {
        tenantId,
        locationId: policy.locationId,
        productVariantId: policy.productVariantId,
        supplierId: supplierMap?.supplierId,
        status: recommendation.status,
        inventoryPosition: recommendation.inventoryPosition,
        forecastDailyDemand: demand,
        planningLeadDays: leadDays,
        safetyStockQty: safetyStock,
        reorderPoint: recommendation.reorderPoint,
        recommendedQty: recommendation.recommendedOrderQty,
        projectedStockoutAt: datePlusDays(now, recommendation.projectedStockoutDays),
        safetyStockBreachAt: datePlusDays(now, recommendation.safetyStockBreachDays),
        orderByAt: datePlusDays(now, recommendation.orderByDays),
        explanation: {
          available: recommendation.available,
          onHand: balance?.onHand.toString() ?? '0',
          reserved: balance?.reserved.toString() ?? '0',
          committed: balance?.committed.toString() ?? '0',
          inboundReceipts: arrivals,
          forecastDailyDemand: demand,
          demandStdDev: demandStd,
          observedLeadDays: observed,
          quotedLeadDays: supplierMap?.supplier.quotedLeadDays ?? null,
          planningLeadDays: leadDays,
          safetyStock,
          reviewPeriodDays: policy.reviewPeriodDays,
          casePack: supplierMap?.casePack.toString() ?? '1',
          minimumOrderQty: supplierMap?.minimumOrderQty.toString() ?? '0'
        }
      }
    });

    const dedupeKey = `replenishment:${policy.locationId}:${policy.productVariantId}`;
    if (['ORDER_NOW', 'STOCKOUT_RISK', 'STOCKED_OUT'].includes(recommendation.status)) {
      await prisma.notification.upsert({
        where: { tenantId_dedupeKey: { tenantId, dedupeKey } },
        create: {
          tenantId, type: 'REPLENISHMENT', severity: recommendation.status === 'ORDER_NOW' ? 'WARNING' : 'CRITICAL',
          title: recommendation.status === 'STOCKED_OUT' ? 'Product stocked out' : recommendation.status === 'STOCKOUT_RISK' ? 'Stock-out risk' : 'Reorder required',
          message: `${policy.productVariant.product.name} / ${policy.productVariant.name}: order ${recommendation.recommendedOrderQty} units.`,
          actionUrl: '/replenishment', dedupeKey
        },
        update: {
          severity: recommendation.status === 'ORDER_NOW' ? 'WARNING' : 'CRITICAL',
          title: recommendation.status === 'STOCKED_OUT' ? 'Product stocked out' : recommendation.status === 'STOCKOUT_RISK' ? 'Stock-out risk' : 'Reorder required',
          message: `${policy.productVariant.product.name} / ${policy.productVariant.name}: order ${recommendation.recommendedOrderQty} units.`,
          readAt: null
        }
      });
    } else {
      await prisma.notification.updateMany({ where: { tenantId, dedupeKey, readAt: null }, data: { readAt: now } });
    }
    results.push(row);
  }
  return results;
}
