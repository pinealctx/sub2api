# Nexus Relay Container Image

Nexus Relay is an internal AI API gateway for account pools, group-based access, API keys, and usage observability.

## Image

Default internal image:

```text
ghcr.io/pinealctx/sub2api:latest
```

Use `NEXUS_RELAY_IMAGE` in compose deployments to point at another internal registry.

## Quick Start

```bash
docker run -d \
  --name sub2api \
  -p 8080:8080 \
  -e AUTO_SETUP=true \
  -e RUN_MODE=simple \
  -e DATABASE_HOST=postgres.example.internal \
  -e DATABASE_USER=sub2api \
  -e DATABASE_PASSWORD=change_this_secure_password \
  -e DATABASE_DBNAME=sub2api \
  -e REDIS_HOST=redis.example.internal \
  -e JWT_SECRET=change_this_64_hex_secret \
  -e TOTP_ENCRYPTION_KEY=change_this_64_hex_secret \
  ghcr.io/pinealctx/sub2api:latest
```

For normal deployments, prefer `docker-compose.local.yml` from this directory.

## Runtime Requirements

- PostgreSQL
- Redis
- Fixed `JWT_SECRET`
- Fixed `TOTP_ENCRYPTION_KEY`
- Fresh internal schema database for new deployments

## Supported Architectures

- `linux/amd64`
- `linux/arm64`
