# Nexus Relay Development Guide

This guide is the internal maintenance baseline for Nexus Relay. It intentionally avoids personal machine notes and public project operations.

## Repository Model

- `origin`: internal private repository, currently `pinealctx/sub2api`.
- `upstream`: original project remote, kept only for selective gateway feature merges.
- Go module path remains `github.com/Wei-Shaw/sub2api` for merge friendliness unless a full module rename is scheduled.
- Product-facing text, browser titles, deployment docs, and internal docs should use `Nexus Relay`.

## Toolchain

- Go: use the version declared in `backend/go.mod`.
- Node: use `.nvmrc`.
- pnpm: use `9.15.9`, matching CI and the lockfile format.
- Docker: use Compose v2 for local integration environments.

Recommended setup:

```bash
nvm use
corepack enable
corepack prepare pnpm@9.15.9 --activate
pnpm --dir frontend install
```

## Local Services

Use the repository compose file for a reproducible local stack:

```bash
cp deploy/.env.example deploy/.env
docker compose -f deploy/docker-compose.dev.yml --env-file deploy/.env up --build
```

Default local URL:

```text
http://127.0.0.1:8080
```

The dev compose file builds from local source and runs PostgreSQL, Redis, and the backend container.

## Verification

Backend:

```bash
cd backend
go test ./...
```

Frontend:

```bash
pnpm --dir frontend run typecheck
pnpm --dir frontend run test:run
```

Build:

```bash
make build-backend
make build-frontend
```

## Code Generation

When Ent schema changes:

```bash
make -C backend generate
```

Commit generated Ent files together with schema changes.

## Internal Fork Rules

- Keep the runtime focused on gateway access, scheduling, accounting records, and operations.
- Do not reintroduce public acquisition flows, external promotional assets, or non-target login providers.
- Keep usage cost as an observability field, not a purchase or wallet boundary.
- Keep new database work on the internal baseline. Old public-schema automatic upgrades are out of scope.
- Prefer small, reviewable upstream merges. Keep gateway capabilities; drop product/commercial surface area.

## Release Notes

GitHub Actions builds and tests the backend and frontend on push and pull request. Tagged releases publish internal artifacts and GHCR images for this fork.
