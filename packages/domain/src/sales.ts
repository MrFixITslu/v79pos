export type SaleLineInput = {
  quantity: number;
  unitPrice: number;
  discount?: number;
  taxRate?: number;
};

export type SaleLineTotal = {
  quantity: number;
  unitPrice: number;
  gross: number;
  discount: number;
  taxable: number;
  tax: number;
  total: number;
};

const money = (n: number) => Math.round((n + Number.EPSILON) * 100) / 100;

export function calculateSaleLine(input: SaleLineInput): SaleLineTotal {
  if (input.quantity <= 0) throw new Error('quantity must be greater than zero');
  if (input.unitPrice < 0) throw new Error('unitPrice cannot be negative');
  const gross = input.quantity * input.unitPrice;
  const discount = Math.min(gross, Math.max(0, input.discount ?? 0));
  const taxable = Math.max(0, gross - discount);
  const tax = taxable * Math.max(0, input.taxRate ?? 0);
  return {
    quantity: input.quantity,
    unitPrice: money(input.unitPrice),
    gross: money(gross),
    discount: money(discount),
    taxable: money(taxable),
    tax: money(tax),
    total: money(taxable + tax)
  };
}

export function calculateSale(lines: SaleLineInput[]) {
  const calculated = lines.map(calculateSaleLine);
  return {
    lines: calculated,
    subtotal: money(calculated.reduce((sum, line) => sum + line.gross, 0)),
    discount: money(calculated.reduce((sum, line) => sum + line.discount, 0)),
    tax: money(calculated.reduce((sum, line) => sum + line.tax, 0)),
    total: money(calculated.reduce((sum, line) => sum + line.total, 0))
  };
}
