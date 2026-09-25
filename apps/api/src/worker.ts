import { config } from './lib/config.js';
import { prisma } from './lib/prisma.js';
import { recalculateTenant } from './modules/replenishment/service.js';
import { processOutboxBatch } from './lib/outbox-delivery.js';
import { runRetentionCleanup } from './lib/retention.js';
import { refreshExpiryAlerts } from './modules/inventory/expiry.js';

let running = false;
let lastRetentionDay = '';
async function cycle() {
  if (running) return;
  running = true;
  try {
    const tenants = await prisma.tenant.findMany({ where: { active: true }, select: { id: true, slug: true } });
    const outbox = await processOutboxBatch();
    if (outbox.events) console.info(`[outbox] events=${outbox.events} delivered=${outbox.delivered} failed=${outbox.failed}`);
    const now = new Date();
    const retentionDay = now.toISOString().slice(0, 10);
    if (now.getUTCHours() === 3 && retentionDay !== lastRetentionDay) {
      const cleaned = await runRetentionCleanup();
      lastRetentionDay = retentionDay;
      console.info('[retention]', cleaned);
    }
    for (const tenant of tenants) {
      try {
        const rows = await recalculateTenant(tenant.id);
        const expiryAlerts = await refreshExpiryAlerts(tenant.id);
        console.info(`[replenishment] tenant=${tenant.slug} recommendations=${rows.length} expiryAlerts=${expiryAlerts}`);
      } catch (error) {
        console.error(`[replenishment] tenant=${tenant.slug} failed`, error);
      }
    }
  } finally {
    running = false;
  }
}

await cycle();
const interval = setInterval(cycle, config.REPLENISHMENT_INTERVAL_MINUTES * 60_000);

async function close() {
  clearInterval(interval);
  await prisma.$disconnect();
  process.exit(0);
}
process.on('SIGTERM', close);
process.on('SIGINT', close);
