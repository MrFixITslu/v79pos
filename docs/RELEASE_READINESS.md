# V79 Commerce release readiness

Status: **Backend release candidate 1.0.0-rc.1**

## Code-complete backend scope

The release candidate contains the commerce domain required for a modern multi-location POS: sales/refunds, register sessions, inventory ledger and costing, stock counts, price lists/promotions, internal value, commercial orders/deposits, suppliers/POs/receiving, logistics, replenishment, fulfilment, workforce, offline sync foundations, reports, audit and ecosystem delivery.

## Release gates

Completed in GitHub CI / verified baseline workflow:

1. ✅ Locked project dependencies install successfully and `pnpm-lock.yaml` is committed.
2. ✅ `pnpm db:generate` and `pnpm db:validate` pass.
3. ✅ A Prisma baseline migration is committed.
4. ✅ The baseline migration deploys successfully to a fresh PostgreSQL 17 database.
5. ✅ `pnpm build`, `pnpm test` and `pnpm lint` pass.

Remaining before merchant production launch:

6. Run broader integration/concurrency tests against PostgreSQL, including simultaneous inventory sale/transfer scenarios.
7. Configure Hub production authentication and verify tenant isolation with cross-tenant negative tests.
8. Configure and test actual payment adapters/terminal webhooks with provider sandboxes. V79 Commerce must never receive/store raw PAN/CVV.
9. Configure and test FFPRO2, V79Marketing and Hub webhook consumers with idempotency/retry tests.
10. Complete UI/offline-device beta testing, accessibility, load/performance and restore drills before merchant launch.

## Current external blockers

The backend dependency, Prisma validation and baseline-migration blockers have been removed using GitHub-hosted validation. The generated baseline was deployed successfully against a fresh PostgreSQL 17 service before it was committed.

The connected Figma Starter account reached its MCP tool-call allowance; UI design remains intentionally deferred until access resets. Live payment and ecosystem-provider validation also require their sandbox/production credentials and endpoints.

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
