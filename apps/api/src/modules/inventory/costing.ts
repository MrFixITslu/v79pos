import { Prisma } from '@prisma/client';

const D = (v: Prisma.Decimal.Value) => new Prisma.Decimal(v);

export async function consumeFifoCost(
  tx: Prisma.TransactionClient,
  input: {
    tenantId: string;
    locationId: string;
    productVariantId: string;
    quantity: Prisma.Decimal.Value;
    fallbackUnitCost: Prisma.Decimal.Value;
  }
) {
  let remaining = D(input.quantity);
  let totalCost = D(0);
  const layers = await tx.inventoryCostLayer.findMany({
    where: {
      tenantId: input.tenantId,
      locationId: input.locationId,
      productVariantId: input.productVariantId,
      quantityRemaining: { gt: 0 }
    },
    orderBy: [{ receivedAt: 'asc' }, { id: 'asc' }]
  });

  for (const layer of layers) {
    if (remaining.lte(0)) break;
    const take = Prisma.Decimal.min(remaining, layer.quantityRemaining);
    totalCost = totalCost.plus(take.mul(layer.unitCost));
    remaining = remaining.minus(take);
    await tx.inventoryCostLayer.update({
      where: { id: layer.id },
      data: { quantityRemaining: { decrement: take } }
    });
  }

  if (remaining.gt(0)) totalCost = totalCost.plus(remaining.mul(D(input.fallbackUnitCost)));
  const quantity = D(input.quantity);
  return quantity.gt(0) ? totalCost.div(quantity) : D(0);
}
