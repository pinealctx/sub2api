# Nexus Relay Deployment

This directory contains internal deployment assets for Nexus Relay.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.dev.yml` | Local development stack; builds the image from this checkout |
| `docker-compose.local.yml` | Production-style stack with local data directories |
| `docker-compose.yml` | Production-style stack with named Docker volumes |
| `docker-compose.standalone.yml` | App container only; PostgreSQL and Redis are external |
| `.env.example` | Environment template |
| `config.example.yaml` | Full configuration reference |
| `docker-deploy.sh` | Prepares a deploy directory from the checked-out repository |
| `install.sh` | Linux binary installer for internal releases |
| `sub2api.service` | systemd unit for binary deployments |
| `DATAMANAGEMENTD_CN.md` | Optional host-side data-management daemon guide |

Service and directory names still use `sub2api` where changing them would affect existing compose networks, volumes, logs, or upstream mergeability. Product-facing text should use Nexus Relay.

## Local Development

```bash
cp deploy/.env.example deploy/.env
docker compose -f deploy/docker-compose.dev.yml --env-file deploy/.env up --build
```

Open:

```text
http://127.0.0.1:8080
```

## Docker Deployment

Prepare configuration:

```bash
cd deploy
cp .env.example .env
openssl rand -hex 32
```

Set at least:

```env
POSTGRES_PASSWORD=change_this_secure_password
JWT_SECRET=change_this_64_hex_secret
TOTP_ENCRYPTION_KEY=change_this_64_hex_secret
```

Start with local directories:

```bash
docker compose -f docker-compose.local.yml --env-file .env up -d
```

Check logs:

```bash
docker compose -f docker-compose.local.yml --env-file .env logs -f sub2api
```

The default image is:

```text
ghcr.io/pinealctx/sub2api:latest
```

Override it when needed:

```env
NEXUS_RELAY_IMAGE=registry.example.com/internal/nexus-relay:latest
```

## Data Model

Nexus Relay uses the internal core schema baseline. New deployments should use an empty database. Automatic upgrade from an older public schema is intentionally unsupported.

Before replacing or rebuilding an existing internal deployment, back up:

```text
data/
postgres_data/
redis_data/
.env
```

## Optional Data Management Daemon

The admin data-management tools can talk to a host-side daemon over:

```text
/tmp/sub2api-datamanagement.sock
```

See `DATAMANAGEMENTD_CN.md` when enabling that feature.
