import type { Prisma } from '@prisma/client';

export async function resolveUnitPrices(tx: Prisma.TransactionClient, args: {
  tenantId: string;
  customerId?: string;
  variantIds: string[];
  effectiveAt?: Date;
}) {
  const now = args.effectiveAt ?? new Date();
  let priceListId: string | null = null;
  if (args.customerId) {
    const customer = await tx.customer.findFirst({ where: { id: args.customerId, tenantId: args.tenantId }, select: { priceListId: true } });
    priceListId = customer?.priceListId ?? null;
  }
  if (!priceListId) return new Map<string, number>();
  const list = await tx.priceList.findFirst({
    where: { id: priceListId, tenantId: args.tenantId, active: true, AND: [
      { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
      { OR: [{ endsAt: null }, { endsAt: { gte: now } }] }
    ] },
    include: { items: { where: { productVariantId: { in: args.variantIds } } } }
  });
  return new Map((list?.items ?? []).map(item => [item.productVariantId, item.price.toNumber()]));
}

export async function resolvePromotions(tx: Prisma.TransactionClient, args: {
  tenantId: string;
  variantIds: string[];
  promotionCode?: string;
  effectiveAt?: Date;
}) {
  const now = args.effectiveAt ?? new Date();
  const promotions = await tx.promotion.findMany({
    where: {
      tenantId: args.tenantId,
      active: true,
      ...(args.promotionCode ? { code: { equals: args.promotionCode, mode: 'insensitive' } } : { code: null }),
      AND: [
        { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
        { OR: [{ endsAt: null }, { endsAt: { gte: now } }] }
      ]
    },
    include: { products: { where: { productVariantId: { in: args.variantIds } } } }
  });
  return promotions;
}

export function promotionDiscount(args: {
  promotion: { type: 'PERCENTAGE' | 'FIXED_AMOUNT'; value: { toNumber(): number }; maximumDiscount: { toNumber(): number } | null; appliesToAll: boolean; products: { productVariantId: string }[] };
  variantId: string;
  quantity: number;
  unitPrice: number;
}) {
  const eligible = args.promotion.appliesToAll || args.promotion.products.some(p => p.productVariantId === args.variantId);
  if (!eligible) return 0;
  const gross = args.quantity * args.unitPrice;
  let discount = args.promotion.type === 'PERCENTAGE'
    ? gross * Math.min(1, Math.max(0, args.promotion.value.toNumber() / 100))
    : args.promotion.value.toNumber() * args.quantity;
  if (args.promotion.maximumDiscount) discount = Math.min(discount, args.promotion.maximumDiscount.toNumber());
  return Math.min(gross, Math.max(0, discount));
}
