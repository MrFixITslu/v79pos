#!/bin/sh
set -eu

if [ "${NODE_ENV:-}" = production ]; then
  : "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set for the POS database}"
fi

if [ -n "${POSTGRES_PASSWORD:-}" ]; then
  # Build the URL once for the API, worker and migration job. URL-encode
  # reserved characters in passwords; never print the resulting URL.
  export DATABASE_URL="$(node -e 'const p=process.env.POSTGRES_PASSWORD; process.stdout.write(`postgresql://v79commerce:${encodeURIComponent(p)}@postgres:5432/v79commerce?schema=public`)')"
fi

exec "$@"
