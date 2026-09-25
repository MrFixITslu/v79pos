export type CashMovementInput = { type: 'PAID_IN'|'PAID_OUT'|'CASH_DROP'|'CASH_PICKUP'; amount: number };

export function calculateExpectedCash(args: {
  openingFloat: number;
  cashPayments: number;
  changeGiven?: number;
  cashRefunds?: number;
  movements?: CashMovementInput[];
}) {
  let expected = args.openingFloat + args.cashPayments - (args.changeGiven ?? 0) - (args.cashRefunds ?? 0);
  for (const movement of args.movements ?? []) {
    expected += movement.type === 'PAID_IN' ? movement.amount : -movement.amount;
  }
  return Math.round((expected + Number.EPSILON) * 100) / 100;
}
