export type InboundReceipt = {
  quantity: number;
  arrivesInDays: number;
};

export type ReplenishmentInput = {
  onHand: number;
  reserved: number;
  committed: number;
  quarantined?: number;
  damaged?: number;
  expired?: number;
  confirmedIncoming?: number;
  inboundReceipts?: InboundReceipt[];
  forecastDailyDemand: number;
  planningLeadTimeDays: number;
  safetyStock: number;
  reviewPeriodDays?: number;
  casePack?: number;
  minimumOrderQty?: number;
  horizonDays?: number;
};

export type ReplenishmentStatus =
  | 'HEALTHY'
  | 'PLAN'
  | 'ORDER_SOON'
  | 'ORDER_NOW'
  | 'STOCKOUT_RISK'
  | 'STOCKED_OUT';

export type ReplenishmentRecommendation = {
  available: number;
  inventoryPosition: number;
  reorderPoint: number;
  daysOfCover: number | null;
  projectedStockoutDays: number | null;
  safetyStockBreachDays: number | null;
  orderByDays: number | null;
  status: ReplenishmentStatus;
  recommendedOrderQty: number;
  targetStock: number;
};

const roundUpToPack = (qty: number, pack: number) => Math.ceil(qty / pack) * pack;

export function percentile(values: number[], p: number): number | null {
  const clean = values.filter(Number.isFinite).sort((a, b) => a - b);
  if (clean.length === 0) return null;
  const clamped = Math.min(1, Math.max(0, p));
  const index = Math.ceil(clamped * clean.length) - 1;
  return clean[Math.max(0, index)];
}

export function choosePlanningLeadTime(args: {
  manualLeadDays?: number | null;
  quotedLeadDays?: number | null;
  observedLeadDays?: number[];
  variabilityBufferDays?: number;
}): number {
  if (args.manualLeadDays != null && args.manualLeadDays >= 0) {
    return Math.ceil(args.manualLeadDays);
  }

  const observedP80 = percentile(args.observedLeadDays ?? [], 0.8);
  const quoted = args.quotedLeadDays ?? 0;
  const base = observedP80 == null ? quoted : Math.max(quoted, observedP80);
  return Math.max(0, Math.ceil(base + (args.variabilityBufferDays ?? 0)));
}

function simulateInventory(input: ReplenishmentInput, startingAvailable: number) {
  const horizon = Math.max(
    30,
    input.horizonDays ?? input.planningLeadTimeDays + (input.reviewPeriodDays ?? 14) + 60
  );
  const arrivals = new Map<number, number>();
  for (const receipt of input.inboundReceipts ?? []) {
    if (receipt.quantity <= 0) continue;
    const day = Math.max(0, Math.ceil(receipt.arrivesInDays));
    arrivals.set(day, (arrivals.get(day) ?? 0) + receipt.quantity);
  }

  let projected = startingAvailable;
  let stockout: number | null = projected <= 0 ? 0 : null;
  let safetyBreach: number | null = projected <= input.safetyStock ? 0 : null;

  for (let day = 1; day <= horizon; day += 1) {
    projected += arrivals.get(day) ?? 0;
    projected -= Math.max(0, input.forecastDailyDemand);

    if (safetyBreach == null && projected <= input.safetyStock) safetyBreach = day;
    if (stockout == null && projected <= 0) {
      stockout = day;
      break;
    }
  }

  return { projectedStockoutDays: stockout, safetyStockBreachDays: safetyBreach };
}

export function calculateReplenishment(input: ReplenishmentInput): ReplenishmentRecommendation {
  const unavailable =
    Math.max(0, input.reserved) +
    Math.max(0, input.committed) +
    Math.max(0, input.quarantined ?? 0) +
    Math.max(0, input.damaged ?? 0) +
    Math.max(0, input.expired ?? 0);
  const available = Math.max(0, input.onHand - unavailable);
  const scheduledIncoming = (input.inboundReceipts ?? []).reduce(
    (sum, receipt) => sum + Math.max(0, receipt.quantity),
    0
  );
  const confirmedIncoming =
    input.inboundReceipts && input.inboundReceipts.length > 0
      ? scheduledIncoming
      : Math.max(0, input.confirmedIncoming ?? 0);
  const inventoryPosition = available + confirmedIncoming;
  const reorderPoint = Math.max(
    0,
    input.forecastDailyDemand * input.planningLeadTimeDays + input.safetyStock
  );
  const daysOfCover = input.forecastDailyDemand > 0 ? available / input.forecastDailyDemand : null;

  const reviewPeriod = Math.max(1, input.reviewPeriodDays ?? 14);
  const targetStock =
    input.forecastDailyDemand * (input.planningLeadTimeDays + reviewPeriod) + input.safetyStock;
  let orderQty = Math.max(0, targetStock - inventoryPosition);
  const pack = Math.max(1, input.casePack ?? 1);
  orderQty = roundUpToPack(orderQty, pack);
  if (orderQty > 0) orderQty = Math.max(orderQty, input.minimumOrderQty ?? 0);
  if (orderQty > 0) orderQty = roundUpToPack(orderQty, pack);

  const simulation = simulateInventory(input, available);
  const orderByDays =
    simulation.safetyStockBreachDays == null
      ? null
      : simulation.safetyStockBreachDays - input.planningLeadTimeDays;

  let status: ReplenishmentStatus = 'HEALTHY';
  if (available <= 0 && input.forecastDailyDemand > 0) {
    status = 'STOCKED_OUT';
  } else if (input.forecastDailyDemand > 0) {
    if (simulation.projectedStockoutDays != null && simulation.projectedStockoutDays < input.planningLeadTimeDays) {
      status = 'STOCKOUT_RISK';
    } else if (orderByDays != null && orderByDays <= 0) {
      status = 'ORDER_NOW';
    } else if (orderByDays != null && orderByDays <= 5) {
      status = 'ORDER_SOON';
    } else if (orderByDays != null && orderByDays <= 14) {
      status = 'PLAN';
    } else if (inventoryPosition <= reorderPoint) {
      status = 'ORDER_NOW';
    }
  }

  return {
    available,
    inventoryPosition,
    reorderPoint,
    daysOfCover,
    projectedStockoutDays: simulation.projectedStockoutDays,
    safetyStockBreachDays: simulation.safetyStockBreachDays,
    orderByDays,
    status,
    recommendedOrderQty: orderQty,
    targetStock
  };
}
