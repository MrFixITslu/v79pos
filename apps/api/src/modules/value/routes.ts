import type { FastifyInstance } from 'fastify';
import { GiftCardStatus, ValueTransactionType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../lib/prisma.js';
import { requirePermission } from '../auth/context.js';
import { conflict, notFound } from '../../lib/errors.js';
import { generateGiftCardCode, hashGiftCardCode } from './service.js';

export async function valueRoutes(app: FastifyInstance) {
  app.put('/v1/loyalty/program', { preHandler: requirePermission('loyalty.manage') }, async request => {
    const body = z.object({ active: z.boolean(), earnPointsPerCurrency: z.coerce.number().nonnegative(), redemptionValue: z.coerce.number().positive(), minimumRedeemPoints: z.coerce.number().int().min(1) }).parse(request.body);
    return prisma.loyaltyProgram.upsert({ where: { tenantId: request.auth.tenantId }, create: { tenantId: request.auth.tenantId, ...body }, update: body });
  });

  app.get('/v1/customers/:id/value', { preHandler: requirePermission('customers.read') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    const customer = await prisma.customer.findFirst({ where: { id, tenantId: request.auth.tenantId } });
    if (!customer) throw notFound('Customer not found');
    const [credit, loyalty] = await Promise.all([
      prisma.storeCreditAccount.findUnique({ where: { tenantId_customerId: { tenantId: request.auth.tenantId, customerId: id } }, include: { transactions: { orderBy: { createdAt: 'desc' }, take: 20 } } }),
      prisma.loyaltyAccount.findUnique({ where: { tenantId_customerId: { tenantId: request.auth.tenantId, customerId: id } }, include: { transactions: { orderBy: { createdAt: 'desc' }, take: 20 } } })
    ]);
    return { storeCredit: credit, loyalty };
  });

  app.post('/v1/customers/:id/store-credit', { preHandler: requirePermission('store_credit.adjust') }, async request => {
    const { id } = z.object({ id: z.string() }).parse(request.params);
    const body = z.object({ amount: z.coerce.number(), notes: z.string().min(3).max(500) }).parse(request.body);
    if (body.amount === 0) throw conflict('Adjustment cannot be zero');
    return prisma.$transaction(async tx => {
      const customer = await tx.customer.findFirst({ where: { id, tenantId: request.auth.tenantId } });
      if (!customer) throw notFound('Customer not found');
      let account = await tx.storeCreditAccount.findUnique({ where: { tenantId_customerId: { tenantId: request.auth.tenantId, customerId: id } } });
      if (!account) {
        if (body.amount < 0) throw conflict('Store credit balance cannot be negative');
        account = await tx.storeCreditAccount.create({ data: { tenantId: request.auth.tenantId, customerId: id, balance: body.amount } });
      } else {
        if (account.balance.plus(body.amount).lt(0)) throw conflict('Store credit balance cannot be negative');
        account = await tx.storeCreditAccount.update({ where: { id: account.id }, data: { balance: { increment: body.amount } } });
      }
      await tx.storeCreditTransaction.create({ data: { accountId: account.id, type: ValueTransactionType.ADJUSTMENT, amount: Math.abs(body.amount), referenceType: 'MANUAL_ADJUSTMENT', referenceId: account.id, notes: body.notes, createdBy: request.auth.userId } });
      return account;
    });
  });

  app.post('/v1/gift-cards', { preHandler: requirePermission('gift_card.issue') }, async request => {
    const body = z.object({ value: z.coerce.number().positive(), expiresAt: z.coerce.date().optional() }).parse(request.body);
    const code = generateGiftCardCode();
    const card = await prisma.giftCard.create({ data: { tenantId: request.auth.tenantId, codeHash: hashGiftCardCode(code), last4: code.slice(-4), balance: body.value, initialValue: body.value, expiresAt: body.expiresAt, createdBy: request.auth.userId } });
    await prisma.giftCardTransaction.create({ data: { giftCardId: card.id, type: ValueTransactionType.CREDIT, amount: body.value, referenceType: 'ISSUANCE', referenceId: card.id, createdBy: request.auth.userId } });
    return { id: card.id, code, last4: card.last4, balance: card.balance, expiresAt: card.expiresAt };
  });

  app.post('/v1/gift-cards/balance', { preHandler: requirePermission('gift_card.read') }, async request => {
    const body = z.object({ code: z.string().min(8) }).parse(request.body);
    const card = await prisma.giftCard.findUnique({ where: { tenantId_codeHash: { tenantId: request.auth.tenantId, codeHash: hashGiftCardCode(body.code) } } });
    if (!card || card.status === GiftCardStatus.BLOCKED) throw notFound('Gift card not found');
    return { last4: card.last4, balance: card.balance, status: card.status, expiresAt: card.expiresAt };
  });
}
