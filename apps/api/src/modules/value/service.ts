import { createHmac, randomBytes } from 'node:crypto';
import { GiftCardStatus, Prisma, ValueTransactionType } from '@prisma/client';
import { config } from '../../lib/config.js';
import { conflict, notFound } from '../../lib/errors.js';

const D = (v: Prisma.Decimal.Value) => new Prisma.Decimal(v);
export const hashGiftCardCode = (code: string) => createHmac('sha256', config.GIFT_CARD_PEPPER).update(code.trim().toUpperCase()).digest('hex');
export const generateGiftCardCode = () => randomBytes(10).toString('hex').toUpperCase();

export async function debitInternalTender(tx: Prisma.TransactionClient, args: {
  tenantId: string; customerId?: string; method: 'STORE_CREDIT'|'GIFT_CARD'|'LOYALTY_POINTS'; amount: number; accountCode?: string; referenceType?: string; referenceId: string; userId: string;
}) {
  const amount = D(args.amount);
  if (args.method === 'STORE_CREDIT') {
    if (!args.customerId) throw conflict('Store credit requires a customer');
    const account = await tx.storeCreditAccount.findUnique({ where: { tenantId_customerId: { tenantId: args.tenantId, customerId: args.customerId } } });
    if (!account || account.balance.lt(amount)) throw conflict('Insufficient store credit');
    await tx.storeCreditAccount.update({ where: { id: account.id }, data: { balance: { decrement: amount } } });
    await tx.storeCreditTransaction.create({ data: { accountId: account.id, type: ValueTransactionType.DEBIT, amount, referenceType: args.referenceType ?? 'SALE', referenceId: args.referenceId, createdBy: args.userId } });
    return account.id;
  }
  if (args.method === 'GIFT_CARD') {
    if (!args.accountCode) throw conflict('Gift card code is required');
    const card = await tx.giftCard.findUnique({ where: { tenantId_codeHash: { tenantId: args.tenantId, codeHash: hashGiftCardCode(args.accountCode) } } });
    if (!card || card.status !== GiftCardStatus.ACTIVE) throw notFound('Active gift card not found');
    if (card.expiresAt && card.expiresAt < new Date()) throw conflict('Gift card has expired');
    if (card.balance.lt(amount)) throw conflict('Insufficient gift card balance');
    const remaining = card.balance.minus(amount);
    await tx.giftCard.update({ where: { id: card.id }, data: { balance: remaining, status: remaining.eq(0) ? GiftCardStatus.DEPLETED : GiftCardStatus.ACTIVE } });
    await tx.giftCardTransaction.create({ data: { giftCardId: card.id, type: ValueTransactionType.DEBIT, amount, referenceType: args.referenceType ?? 'SALE', referenceId: args.referenceId, createdBy: args.userId } });
    return card.id;
  }
  if (!args.customerId) throw conflict('Loyalty redemption requires a customer');
  const [program, account] = await Promise.all([
    tx.loyaltyProgram.findUnique({ where: { tenantId: args.tenantId } }),
    tx.loyaltyAccount.findUnique({ where: { tenantId_customerId: { tenantId: args.tenantId, customerId: args.customerId } } })
  ]);
  if (!program?.active || !account) throw conflict('Loyalty programme is not available');
  const points = Math.ceil(amount.toNumber() / program.redemptionValue.toNumber());
  if (points < program.minimumRedeemPoints || account.points < points) throw conflict('Insufficient loyalty points');
  await tx.loyaltyAccount.update({ where: { id: account.id }, data: { points: { decrement: points } } });
  await tx.loyaltyTransaction.create({ data: { accountId: account.id, delta: -points, referenceType: args.referenceType ?? 'SALE', referenceId: args.referenceId, notes: `Redeemed for ${amount.toFixed(2)}` } });
  return account.id;
}

export async function creditInternalTender(tx: Prisma.TransactionClient, args: {
  tenantId: string; customerId?: string; method: 'STORE_CREDIT'|'GIFT_CARD'|'LOYALTY_POINTS'; amount: number; accountId?: string; referenceType?: string; referenceId: string; userId: string;
}) {
  const amount = D(args.amount);
  if (args.method === 'STORE_CREDIT') {
    if (!args.customerId) throw conflict('Store credit refund requires a customer');
    const account = await tx.storeCreditAccount.upsert({
      where: { tenantId_customerId: { tenantId: args.tenantId, customerId: args.customerId } },
      create: { tenantId: args.tenantId, customerId: args.customerId, balance: amount },
      update: { balance: { increment: amount } }
    });
    await tx.storeCreditTransaction.create({ data: { accountId: account.id, type: ValueTransactionType.CREDIT, amount, referenceType: args.referenceType ?? 'SALE_RETURN', referenceId: args.referenceId, createdBy: args.userId } });
    return account.id;
  }
  if (args.method === 'GIFT_CARD') {
    if (!args.accountId) throw conflict('Gift card refund requires the original gift card reference');
    const card = await tx.giftCard.findFirst({ where: { id: args.accountId, tenantId: args.tenantId } });
    if (!card) throw notFound('Gift card not found');
    if (card.status === GiftCardStatus.BLOCKED) throw conflict('Blocked gift cards cannot receive refunds');
    await tx.giftCard.update({ where: { id: card.id }, data: { balance: { increment: amount }, status: GiftCardStatus.ACTIVE } });
    await tx.giftCardTransaction.create({ data: { giftCardId: card.id, type: ValueTransactionType.CREDIT, amount, referenceType: args.referenceType ?? 'SALE_RETURN', referenceId: args.referenceId, createdBy: args.userId } });
    return card.id;
  }
  if (!args.customerId) throw conflict('Loyalty refund requires a customer');
  const program = await tx.loyaltyProgram.findUnique({ where: { tenantId: args.tenantId } });
  if (!program?.active) throw conflict('Loyalty programme is not available');
  const points = Math.ceil(amount.toNumber() / program.redemptionValue.toNumber());
  const account = await tx.loyaltyAccount.upsert({
    where: { tenantId_customerId: { tenantId: args.tenantId, customerId: args.customerId } },
    create: { tenantId: args.tenantId, customerId: args.customerId, points, lifetimeEarned: 0 },
    update: { points: { increment: points } }
  });
  await tx.loyaltyTransaction.create({ data: { accountId: account.id, delta: points, referenceType: args.referenceType ?? 'SALE_RETURN', referenceId: args.referenceId, notes: `Refunded value ${amount.toFixed(2)}` } });
  return account.id;
}

export async function earnLoyalty(tx: Prisma.TransactionClient, args: { tenantId: string; customerId?: string; saleId: string; eligibleAmount: number }) {
  if (!args.customerId || args.eligibleAmount <= 0) return 0;
  const program = await tx.loyaltyProgram.findUnique({ where: { tenantId: args.tenantId } });
  if (!program?.active) return 0;
  const points = Math.floor(args.eligibleAmount * program.earnPointsPerCurrency.toNumber());
  if (points <= 0) return 0;
  const account = await tx.loyaltyAccount.upsert({
    where: { tenantId_customerId: { tenantId: args.tenantId, customerId: args.customerId } },
    create: { tenantId: args.tenantId, customerId: args.customerId, points, lifetimeEarned: points },
    update: { points: { increment: points }, lifetimeEarned: { increment: points } }
  });
  await tx.loyaltyTransaction.create({ data: { accountId: account.id, delta: points, referenceType: 'SALE', referenceId: args.saleId, notes: 'Points earned from sale' } });
  return points;
}
