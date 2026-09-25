# Validation notes — 1.0.0-rc.1

Validation performed in the current build environment:

- Prisma schema structural sanity: 77 models; no duplicate model/enum names; no obvious missing reverse relation in the custom static relation scan.
- TypeScript brace/static file sanity across source files.
- Domain modules `sales.ts`, `replenishment.ts` and `cash.ts` compiled directly with the globally available TypeScript compiler.
- Deterministic smoke checks passed:
  - sale total: 25.25 for the reference tax/discount case;
  - replenishment status: `STOCKOUT_RISK` with case-pack rounded recommended quantity 120;
  - planning lead time: 18 days using the historical P80 example;
  - cash reconciliation: 485 after float, cash payments/deposit, change, refund and drawer movements.

Not executable in this environment because project dependencies are unavailable and package-registry access is blocked:

- Prisma Client generation and `prisma validate`;
- full Fastify/Prisma TypeScript build;
- Vitest suite;
- Prisma baseline migration generation/deployment.

Those checks are mandatory in CI/release and are enforced by `scripts/release-check.sh` plus `.github/workflows/release-check.yml`.
