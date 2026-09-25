import { Prisma } from '@prisma/client';
import { prisma } from './prisma.js';

export async function serializable<T>(fn: (tx: Prisma.TransactionClient) => Promise<T>, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt += 1) {
    try {
      return await prisma.$transaction(fn, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
    } catch (error) {
      const retryable = error instanceof Prisma.PrismaClientKnownRequestError && (error as Prisma.PrismaClientKnownRequestError).code === 'P2034';
      if (!retryable || attempt === maxRetries) throw error;
    }
  }
  throw new Error('Serializable transaction retry exhausted');
}
