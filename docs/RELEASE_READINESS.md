# V79 Commerce release readiness

Status: **Backend release candidate 1.0.0-rc.1**

## Code-complete backend scope

The release candidate contains the commerce domain required for a modern multi-location POS: sales/refunds, register sessions, inventory ledger and costing, stock counts, price lists/promotions, internal value, commercial orders/deposits, suppliers/POs/receiving, logistics, replenishment, fulfilment, workforce, offline sync foundations, reports, audit and ecosystem delivery.

## Release gates that must pass before production

1. Install the locked project dependencies in CI/development.
2. Run `pnpm db:generate` and `pnpm db:validate`.
3. Generate the Prisma baseline migration with `./scripts/prepare-baseline-migration.sh`.
4. Review generated migration SQL and deploy it to a fresh PostgreSQL database with `prisma migrate deploy`.
5. Run `pnpm build`, `pnpm test` and `pnpm lint`.
6. Run integration tests against PostgreSQL/Redis, including concurrent inventory sale/transfer scenarios.
7. Configure Hub production authentication and verify tenant isolation with cross-tenant negative tests.
8. Configure and test actual payment adapters/terminal webhooks with provider sandboxes. V79 Commerce must never receive/store raw PAN/CVV.
9. Configure and test FFPRO2, V79Marketing and Hub webhook consumers with idempotency/retry tests.
10. Complete UI/offline-device beta testing, accessibility, load/performance and restore drills before merchant launch.

## Known external blockers in this build environment

The current execution environment has neither installed npm dependencies nor package-registry access. Therefore Prisma Client generation, Prisma schema validation, the baseline migration, the TypeScript dependency-aware build and Vitest suite cannot be executed here. CI is configured as the authoritative gate for those checks.

The connected Figma Starter account also reached its MCP tool-call allowance; engineering continued while UI design was intentionally deferred until access resets.

## Safety/financial invariants implemented

- Stock quantities are derived from immutable movements; adjustments append compensating entries.
- FIFO cost layers are separate from quantity movements and feed COGS/gross-margin reporting.
- Sales, stock movements, payments, internal-value debits/refunds and outbox records are transactional.
- Internal-value refunds credit their corresponding ledgers rather than only writing a refund row.
- Cash reconciliation includes cash POS payments and cash deposits on commercial orders linked to the register session.
- Expired lots are blocked from sale and from sellable-stock restocking.
- Offline sale replay is idempotent; oversells become explicit inventory exceptions.
- Machine webhooks are authenticated by signatures and do not depend on interactive Hub login.
- Production configuration rejects development auth/default cryptographic secrets.
