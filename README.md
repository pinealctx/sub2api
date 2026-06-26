# Nexus Relay

Nexus Relay is an internal AI API gateway for team-owned routing, account pools, API keys, and usage observability.

It is maintained as a breaking internal fork. The runtime focuses on authentication, account scheduling, group isolation, proxy routing, rate controls, and usage records. Public self-service acquisition flows are outside this product line.

## Core Capabilities

- Claude, OpenAI-compatible, Gemini, Antigravity, and Codex/OpenAI-compatible gateway entrypoints.
- Upstream account pools with group assignment, sticky sessions, failover, proxy selection, and model listing.
- Member pages for Dashboard, API Keys, Usage, and Profile.
- Admin pages for users, groups, accounts/channels, proxies, usage, channel monitoring, ops, settings, backups, and system tools.
- Email/password login and generic OIDC login for internal identity providers such as Microsoft Entra ID.
- PostgreSQL and Redis backed usage logging, monitor history, and operational metrics.

## Runtime Semantics

Gateway requests are allowed or denied by API key status, user status, group membership, IP ACLs, rate limits, concurrency limits, account availability, and platform-specific routing rules.

Usage cost is retained as an observability field. It is not a member-facing wallet or purchase condition.

## Local Development

Use the versions pinned by this repository:

```bash
nvm use
corepack enable
corepack prepare pnpm@9.15.9 --activate
```

Install and verify:

```bash
pnpm --dir frontend install
pnpm --dir frontend run typecheck
pnpm --dir frontend run test:run

cd backend
go test ./...
```

For a local all-in-one environment, use the development compose file:

```bash
cp deploy/.env.example deploy/.env
docker compose -f deploy/docker-compose.dev.yml --env-file deploy/.env up --build
```

## Deployment

Deployment assets live in `deploy/`. New installations should use a fresh database or an explicitly rebuilt database from the internal baseline schema. Automatic migration from the old public schema is not supported.

The default container image reference is `ghcr.io/pinealctx/sub2api:latest`. Override it with `NEXUS_RELAY_IMAGE` when using a different internal registry or a locally built image.

## Upstream Maintenance

Keep `upstream` pointed at the original project so gateway improvements can still be reviewed and merged selectively. Product, docs, public acquisition flows, and non-target identity-provider changes should remain internal-fork decisions.
