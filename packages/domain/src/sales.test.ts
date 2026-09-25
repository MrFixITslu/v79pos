import { describe, expect, it } from 'vitest';
import { calculateSale } from './sales.js';

describe('calculateSale', () => {
  it('calculates discounts and tax deterministically', () => {
    const sale = calculateSale([
      { quantity: 2, unitPrice: 10, discount: 2, taxRate: 0.125 },
      { quantity: 1, unitPrice: 5, taxRate: 0 }
    ]);
    expect(sale.subtotal).toBe(25);
    expect(sale.discount).toBe(2);
    expect(sale.tax).toBe(2.25);
    expect(sale.total).toBe(25.25);
  });
});
