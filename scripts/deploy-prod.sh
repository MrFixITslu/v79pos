#!/bin/sh
set -eu

ENV_FILE="${ENV_FILE:-.env}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Copy .env.production.example to .env and replace every placeholder." >&2
  exit 1
fi

if grep -Eiq '=(REPLACE_|change[_-]?me|replace-with)' "$ENV_FILE"; then
  echo "Deployment blocked: placeholder secrets remain in $ENV_FILE." >&2
  exit 1
fi

proxy_network="${PROXY_NETWORK:-$(sed -n 's/^PROXY_NETWORK=//p' "$ENV_FILE" | tail -1)}"
proxy_network="${proxy_network:-proxy_network}"

if ! docker network inspect "$proxy_network" >/dev/null 2>&1; then
  echo "Required Docker network '$proxy_network' does not exist." >&2
  echo "Create it first with: docker network create $proxy_network" >&2
  exit 1
fi

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config >/dev/null
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" build --pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo
echo "V79 POS services:"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
echo
echo "Nginx Proxy Manager: pos.v79sl.com -> http://v79-pos:8080 on $proxy_network"
