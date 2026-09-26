#!/bin/sh
set -eu

if [ -n "${POSTGRES_PASSWORD:-}" ]; then
  ENCODED_PASSWORD="$(node -e 'process.stdout.write(encodeURIComponent(process.env.POSTGRES_PASSWORD))')"
  export DATABASE_URL="postgresql://v79commerce:${ENCODED_PASSWORD}@postgres:5432/v79commerce?schema=public"
fi

exec "$@"
