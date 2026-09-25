#!/bin/sh
set -eu
if [ ! -d node_modules ]; then
  echo "Dependencies are not installed. Run: pnpm install" >&2
  exit 1
fi
if find prisma/migrations -mindepth 1 -maxdepth 1 -type d | grep -q .; then
  echo "A migration directory already exists; refusing to create a second baseline." >&2
  exit 1
fi
pnpm db:generate
pnpm db:validate
pnpm prisma migrate dev --name baseline
pnpm build
pnpm test
printf '\nBaseline migration created. Review the SQL, then test `prisma migrate deploy` against an empty database before production.\n'
