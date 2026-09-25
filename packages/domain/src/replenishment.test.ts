import { describe, expect, it } from 'vitest';
import { calculateReplenishment, choosePlanningLeadTime, percentile } from './replenishment.js';

describe('calculateReplenishment', () => {
  it('flags stockout risk when physical cover is shorter than lead time', () => {
    const r = calculateReplenishment({
      onHand: 50,
      reserved: 0,
      committed: 0,
      confirmedIncoming: 0,
      forecastDailyDemand: 5,
      planningLeadTimeDays: 14,
      safetyStock: 20,
      casePack: 12
    });
    expect(r.status).toBe('STOCKOUT_RISK');
    expect(r.reorderPoint).toBe(90);
    expect(r.recommendedOrderQty % 12).toBe(0);
  });

  it('subtracts unavailable stock from sellable inventory', () => {
    const r = calculateReplenishment({
      onHand: 100,
      reserved: 10,
      committed: 15,
      quarantined: 5,
      damaged: 3,
      expired: 2,
      confirmedIncoming: 20,
      forecastDailyDemand: 2,
      planningLeadTimeDays: 10,
      safetyStock: 15
    });
    expect(r.available).toBe(65);
    expect(r.inventoryPosition).toBe(85);
  });

  it('includes dated inbound receipts in the stockout simulation', () => {
    const r = calculateReplenishment({
      onHand: 40,
      reserved: 0,
      committed: 0,
      inboundReceipts: [{ quantity: 100, arrivesInDays: 5 }],
      forecastDailyDemand: 5,
      planningLeadTimeDays: 10,
      safetyStock: 20
    });
    expect(r.projectedStockoutDays).toBeGreaterThan(20);
    expect(r.inventoryPosition).toBe(140);
  });

  it('rounds recommended quantity to MOQ and supplier pack size', () => {
    const r = calculateReplenishment({
      onHand: 20,
      reserved: 0,
      committed: 0,
      forecastDailyDemand: 3,
      planningLeadTimeDays: 10,
      safetyStock: 10,
      reviewPeriodDays: 14,
      minimumOrderQty: 50,
      casePack: 12
    });
    expect(r.recommendedOrderQty).toBeGreaterThanOrEqual(50);
    expect(r.recommendedOrderQty % 12).toBe(0);
  });
});

describe('planning lead time', () => {
  it('uses a conservative historical percentile when history is slower than quote', () => {
    expect(percentile([10, 12, 14, 18, 30], 0.8)).toBe(18);
    expect(
      choosePlanningLeadTime({ quotedLeadDays: 14, observedLeadDays: [10, 12, 14, 18, 30] })
    ).toBe(18);
  });

  it('allows a manual lead-time override', () => {
    expect(
      choosePlanningLeadTime({ manualLeadDays: 25, quotedLeadDays: 10, observedLeadDays: [12, 14] })
    ).toBe(25);
  });
});
