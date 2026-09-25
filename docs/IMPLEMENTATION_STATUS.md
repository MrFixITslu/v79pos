# Implementation status — V79 Commerce 1.0.0-rc.1

## Complete in backend release candidate

### Platform and security
Multi-tenant tenant/membership/role/location model; location-scoped authorization; Hub JWT/JWKS auth foundation; audit log; security headers/rate limiting; production secret checks; backup/restore tooling; retention cleanup.

### POS and payments
Transactional sale checkout; server-side price/tax calculation; split tenders; cash/change; register sessions/reconciliation; returns/refunds; internal-value refunds; payment-provider abstraction/intents/signed webhooks; no raw card fields.

### Catalogue, pricing and customers
Products/variants/SKU/barcodes; customer records; customer price lists; promotions/codes; services and stock-tracked types; serialized/lot/expiry products.

### Inventory
Immutable inventory ledger; balances/states; FIFO cost layers; stock counts; reservations; branch transfers; serial/lot movement; expiry alerts; inventory exceptions; offline replay support.

### Procurement/logistics
Suppliers; supplier-product price/MOQ/case-pack; purchase orders/approval; partial receipt; landed cost; inbound shipment tracking; ETA/status history; supplier lead-time history/performance.

### Smart replenishment
Weighted 7/30/90-day demand velocity; optional service-level/variance safety stock; conservative observed lead time; dated inbound simulation; projected stockout; safety-stock breach; order-by date; recommended order quantity; alerts; draft PO creation.

### Orders and fulfilment
Quotes/orders/invoices/layaway; deposits/partial payments; inventory reservation; order-to-sale completion; pickup/delivery/shipment fulfilment; picking/dispatch/delivery/proof metadata.

### Team
Team profiles; location-aware cashier PIN verification; shifts; commissions and proportional refund reversals.

### Integrations and insight
Transactional outbox; per-destination retries/signatures/subscriptions; owner KPI dashboard; slow stock; supplier metrics; delayed logistics; deterministic intelligence briefing.

## Deliberately external/deferred

- Figma and production frontend/device UI, pending Figma tool access.
- Provider-specific WiPay/Stripe/terminal adapter code pending chosen provider sandbox credentials/specifications.
- Live Hub/FFPRO2/V79Marketing endpoints/secrets.
- Prisma baseline migration generation/validation, blocked only by unavailable dependencies in this execution environment and enforced as a CI/release gate.
