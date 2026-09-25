import { describe, expect, it } from 'vitest';
import { calculateExpectedCash } from './cash.js';

describe('calculateExpectedCash', () => {
  it('includes sale cash, order deposits, change, refunds and drawer movements', () => {
    expect(calculateExpectedCash({
      openingFloat: 200,
      cashPayments: 650,
      changeGiven: 25,
      cashRefunds: 50,
      movements: [
        { type: 'PAID_IN', amount: 20 },
        { type: 'CASH_DROP', amount: 300 },
        { type: 'PAID_OUT', amount: 10 }
      ]
    })).toBe(485);
  });
});
