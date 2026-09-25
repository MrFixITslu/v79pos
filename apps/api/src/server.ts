import Fastify from 'fastify';
import helmet from '@fastify/helmet';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import { ZodError } from 'zod';
import { Prisma } from '@prisma/client';
import { config, corsOrigins } from './lib/config.js';
import { prisma } from './lib/prisma.js';
import { AppError } from './lib/errors.js';
import { registerAuth } from './modules/auth/plugin.js';
import { catalogueRoutes } from './modules/catalogue/routes.js';
import { inventoryRoutes } from './modules/inventory/routes.js';
import { transferRoutes } from './modules/inventory/transfers.js';
import { salesRoutes } from './modules/sales/routes.js';
import { procurementRoutes } from './modules/procurement/routes.js';
import { replenishmentRoutes } from './modules/replenishment/routes.js';
import { customerRoutes } from './modules/customers/routes.js';
import { teamRoutes } from './modules/team/routes.js';
import { workforceRoutes } from './modules/team/workforce.js';
import { logisticsRoutes } from './modules/logistics/routes.js';
import { registerRoutes } from './modules/registers/routes.js';
import { stockCountRoutes } from './modules/inventory/counts.js';
import { pricingRoutes } from './modules/pricing/routes.js';
import { valueRoutes } from './modules/value/routes.js';
import { paymentRoutes } from './modules/payments/routes.js';
import { syncRoutes } from './modules/sync/routes.js';
import { integrationRoutes } from './modules/integrations/routes.js';
import { reportRoutes } from './modules/reports/routes.js';
import { auditRoutes } from './modules/audit/routes.js';
import { orderRoutes } from './modules/orders/routes.js';
import { fulfillmentRoutes } from './modules/fulfillment/routes.js';

const trustProxy = config.TRUST_PROXY === 'true' ? true : config.TRUST_PROXY === 'false' ? false : config.TRUST_PROXY;
const app = Fastify({ logger: { level: config.LOG_LEVEL, redact: ['req.headers.authorization','req.headers.cookie','body.cardNumber','body.cvv','body.accountCode'] }, trustProxy, bodyLimit: 1024 * 1024 });
await app.register(helmet);
await app.register(cors, {
  origin: corsOrigins.length === 0 ? false : (origin, callback) => {
    if (!origin || corsOrigins.includes(origin)) callback(null, true);
    else callback(new Error('Origin not allowed'), false);
  },
  credentials: true
});
await app.register(rateLimit, { max: 300, timeWindow: '1 minute' });

app.get('/health', async () => ({ status: 'ok', service: 'v79-commerce-api', version: '1.0.0-rc.1' }));
app.get('/ready', async (_request, reply) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return { status: 'ready', database: 'ok' };
  } catch {
    return reply.code(503).send({ status: 'not-ready', database: 'unavailable' });
  }
});

await registerAuth(app);
await catalogueRoutes(app);
await customerRoutes(app);
await pricingRoutes(app);
await valueRoutes(app);
await paymentRoutes(app);
await syncRoutes(app);
await integrationRoutes(app);
await reportRoutes(app);
await auditRoutes(app);
await inventoryRoutes(app);
await stockCountRoutes(app);
await transferRoutes(app);
await registerRoutes(app);
await salesRoutes(app);
await orderRoutes(app);
await fulfillmentRoutes(app);
await procurementRoutes(app);
await logisticsRoutes(app);
await replenishmentRoutes(app);
await teamRoutes(app);
await workforceRoutes(app);

app.addHook('onSend', async (request, reply, payload) => { reply.header('x-request-id', request.id); return payload; });

app.setErrorHandler((error, request, reply) => {
  if (error instanceof ZodError) {
    return reply.code(400).send({ code: 'VALIDATION_ERROR', message: 'Request validation failed', issues: error.issues });
  }
  if (error instanceof AppError) {
    return reply.code(error.statusCode).send({ code: error.code, message: error.message, details: error.details });
  }
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') return reply.code(409).send({ code: 'UNIQUE_CONSTRAINT', message: 'A record with this value already exists' });
    if (error.code === 'P2025') return reply.code(404).send({ code: 'NOT_FOUND', message: 'Record not found' });
  }
  request.log.error({ err: error }, 'Unhandled request error');
  return reply.code(500).send({ code: 'INTERNAL_ERROR', message: 'Unexpected server error' });
});

const close = async () => {
  await app.close();
  await prisma.$disconnect();
};
process.on('SIGTERM', close);
process.on('SIGINT', close);

await app.listen({ port: config.PORT, host: '0.0.0.0' });
