# V79 POS production deployment

V79 POS follows the same Docker/Nginx Proxy Manager pattern as the other V79 applications.

## Docker identity

- Compose project: `v79pos`
- API container: `v79-pos`
- Worker: `v79-pos-worker`
- PostgreSQL: `v79-pos-db`
- Redis: `v79-pos-redis`
- API port inside Docker: `8080`
- Only Docker network: `proxy_network`
- Public URL: `https://pos.v79sl.com`

The API is **not** published directly to a host port. Nginx Proxy Manager reaches it over `proxy_network`.

For backward compatibility with the Hub, the API also keeps the Docker DNS alias `v79-commerce-api`.

## First deployment

```bash
git clone https://github.com/MrFixITslu/v79pos.git
cd v79pos
cp .env.production.example .env
nano .env
```

Replace every `REPLACE_...` value with a strong unique value. Then:

```bash
docker network inspect proxy_network >/dev/null 2>&1 || docker network create proxy_network
chmod +x scripts/deploy-prod.sh
./scripts/deploy-prod.sh
```

The stack starts PostgreSQL and Redis, applies committed Prisma migrations, starts the POS API, waits for its health check, then starts the worker.

## Existing database: Prisma P1000 or API readiness 503

PostgreSQL reads `POSTGRES_PASSWORD` only when it initializes an empty data volume. Editing `.env` later does not change the password inside the existing `v79pos_postgres_data` volume. A successful `pg_isready` check does not test that password. The migration and API then fail authentication and `/ready` returns 503.

From the POS repository directory on the Docker host, set a strong `POSTGRES_PASSWORD` in `.env`, then run:

```bash
./scripts/repair-server.sh
docker compose ps
docker compose logs --tail=40 migrate api worker
```

The repair preserves the volume and updates the existing `v79commerce` role to the password in `.env` before applying migrations. It also sets missing application secrets; configure the Hub secret and JWT values for your Hub before user sign-in. Do not run `docker compose down -v`, which deletes POS database and Redis volumes. For a new volume, use `./scripts/deploy-prod.sh`.

The API, worker and migration job construct their database URL at startup from `POSTGRES_PASSWORD`. This handles passwords containing reserved URL characters such as `@`, `:`, `/` and `#`. Keep `.env` private and use the same file for both `docker compose` and the repair script.

## Nginx Proxy Manager

Create or update the proxy host:

- Domain: `pos.v79sl.com`
- Scheme: `http`
- Forward Hostname / IP: `v79-pos`
- Forward Port: `8080`
- Websockets: enabled if available
- Block Common Exploits: enabled
- SSL certificate: Let's Encrypt for `pos.v79sl.com`
- Force SSL: enabled
- HTTP/2: enabled

All V79 POS services—including API, worker, PostgreSQL, Redis and migration—use `proxy_network` only. Nginx Proxy Manager must also be connected to `proxy_network`. PostgreSQL and Redis do not publish host ports.

## Verify

```bash
docker compose ps
docker inspect v79-pos --format '{{json .NetworkSettings.Networks}}'
docker exec v79-pos wget -qO- http://127.0.0.1:8080/health
docker exec v79-pos wget -qO- http://127.0.0.1:8080/ready
```

Expected Nginx route:

```text
https://pos.v79sl.com
        ↓
Nginx Proxy Manager
        ↓ proxy_network
v79-pos:8080
```

## Development

The previous development-oriented stack is retained as `docker-compose.dev.yml`:

```bash
docker compose -f docker-compose.dev.yml up -d --build
```

Production should use the default `docker-compose.yml`.
