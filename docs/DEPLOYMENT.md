# Production deployment

V79 Commerce is designed to run behind Nginx Proxy Manager on the shared Docker proxy network.

## First deployment

1. Copy the production environment template:

   ```bash
   cp .env.production.example .env
   ```

2. Replace every `REPLACE_...` value with a strong unique secret. Production startup rejects placeholder cryptographic secrets.

3. Confirm the shared proxy network exists:

   ```bash
   docker network inspect proxy_network >/dev/null || docker network create proxy_network
   ```

4. Deploy:

   ```bash
   ./scripts/deploy-prod.sh
   ```

The Compose stack starts PostgreSQL and Redis, runs `prisma migrate deploy`, then starts the API and worker only after their dependencies are healthy.

## Nginx Proxy Manager

Create a proxy host for `commerce.v79sl.com`:

- Scheme: `http`
- Forward hostname: `v79-commerce-api`
- Forward port: `8080`
- Enable SSL and Force SSL.
- Attach Nginx Proxy Manager to the same `proxy_network`.

The API is intentionally not published on a host port in the production Compose file.

## Verification

After deployment:

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml exec -T api wget -qO- http://127.0.0.1:8080/health
docker compose -f docker-compose.prod.yml exec -T api wget -qO- http://127.0.0.1:8080/ready
```

Do not expose PostgreSQL or Redis outside the Compose network.

## Updates

Before an update, take a database backup. Then pull the approved commit and rerun:

```bash
./scripts/deploy-prod.sh
```

The migration service applies committed Prisma migrations before the new API starts.
