#!/bin/sh
set -eu

ENV_FILE="${ENV_FILE:-.env}"
HUB_ENV="${HUB_ENV:-$HOME/v79hub/.env}"

if [ ! -f "$ENV_FILE" ]; then
  cp .env.production.example "$ENV_FILE"
fi

python3 - "$ENV_FILE" "$HUB_ENV" <<'PY'
from pathlib import Path
import sys

env_path = Path(sys.argv[1])
hub_path = Path(sys.argv[2])

def read_env(path):
    data = {}
    if not path.exists():
        return data
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]
        data[key.strip()] = value
    return data

def write_env(path, updates):
    lines = path.read_text().splitlines()
    seen = set()
    out = []
    for raw in lines:
        if "=" in raw and not raw.lstrip().startswith("#"):
            key = raw.split("=", 1)[0].strip()
            if key in updates:
                out.append(f"{key}={updates[key]}")
                seen.add(key)
                continue
        out.append(raw)
    for key, value in updates.items():
        if key not in seen:
            out.append(f"{key}={value}")
    path.write_text("\n".join(out) + "\n")

env = read_env(env_path)
hub = read_env(hub_path)

def placeholder(value):
    if not value:
        return True
    lower = value.lower()
    return "replace_" in lower or "replace-with" in lower or "change_me" in lower or "change-me" in lower

updates = {
    "NODE_ENV": "production",
    "AUTH_MODE": "hub",
    "CORS_ORIGINS": "https://pos.v79sl.com",
    "TRUST_PROXY": "true",
    "PROXY_NETWORK": "proxy_network",
}

if not env.get("V79_PLATFORM_SHARED_SECRET"):
    secret = hub.get("V79_PLATFORM_SHARED_SECRET")
    if secret:
        updates["V79_PLATFORM_SHARED_SECRET"] = secret

import secrets
if placeholder(env.get("GIFT_CARD_PEPPER")):
    updates["GIFT_CARD_PEPPER"] = secrets.token_urlsafe(48)
if placeholder(env.get("ENCRYPTION_KEY")):
    updates["ENCRYPTION_KEY"] = secrets.token_urlsafe(48)

write_env(env_path, updates)
print("POS environment repaired.")
PY

POSTGRES_PASSWORD="$(python3 - "$ENV_FILE" <<'PY'
from pathlib import Path
import sys

for raw in Path(sys.argv[1]).read_text().splitlines():
    if raw.startswith("POSTGRES_PASSWORD="):
        value = raw.split("=", 1)[1].strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]
        print(value, end="")
        break
PY
)"

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "POSTGRES_PASSWORD is missing from $ENV_FILE" >&2
  exit 1
fi

if printf '%s' "$POSTGRES_PASSWORD" | grep -Eiq 'REPLACE_|change[_-]?me|replace-with'; then
  echo "POSTGRES_PASSWORD is still a placeholder in $ENV_FILE" >&2
  exit 1
fi

if ! docker network inspect proxy_network >/dev/null 2>&1; then
  docker network create proxy_network >/dev/null
fi

docker compose --env-file "$ENV_FILE" up -d postgres redis

echo "Synchronizing PostgreSQL role password..."
python3 - "$POSTGRES_PASSWORD" <<'PY' | docker exec -i -u postgres v79-pos-db psql -U v79commerce -d v79commerce -v ON_ERROR_STOP=1
import sys
password = sys.argv[1].replace("'", "''")
print(f"ALTER ROLE v79commerce WITH PASSWORD '{password}';")
PY

echo "Running Prisma migrations..."
docker compose --env-file "$ENV_FILE" run --rm migrate ./node_modules/.bin/prisma migrate deploy

echo "Starting V79 POS..."
docker compose --env-file "$ENV_FILE" up -d --build

echo
docker compose --env-file "$ENV_FILE" ps
echo
echo "Checking readiness..."
docker exec v79-pos wget -qO- http://127.0.0.1:8080/ready
echo
echo "V79 POS repair complete."
