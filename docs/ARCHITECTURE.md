# V79 Commerce Architecture

V79 Commerce begins as a modular monolith with strict domain boundaries. This keeps deployment manageable on the Vision79 infrastructure while preserving a clean path to split high-load modules later.

## Core rules
1. Every tenant-owned operation is tenant scoped and membership checked server-side.
2. Role permission and physical-location access are separate authorization checks.
3. Inventory ledger entries are immutable; corrections use compensating entries.
4. Inventory balances are cached projections, not the source of truth.
5. FIFO cost layers are independent from inventory quantity truth.
6. Purchase orders and shipments are separate aggregates.
7. Replenishment is calculated per SKU × location × supplier.
8. Dated inbound stock is applied on its forecast arrival date, not immediately.
9. Business integrations use an outbox/event model to avoid dual-write failures.
10. AI may explain deterministic results; it does not determine stock balances, payments, COGS or ledger truth.

## Runtime
- `api`: Fastify/TypeScript business API.
- `worker`: scheduled replenishment process.
- `postgres`: durable transactional store.
- `redis`: reserved for future offline/idempotency queues, distributed jobs and caching.

## Modules
Auth, Tenants/Team, Catalogue, Customers, Inventory, Sales, Procurement, Logistics, Replenishment, Audit and Integrations.
