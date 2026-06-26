# Nexus Relay

Internal-maintenance AI API gateway for team-owned model routing, account pools, API keys, and usage observability.

This fork keeps the gateway, account pool, groups, proxies, API keys, usage records, channel monitoring, ops monitoring, and the member Dashboard / Keys / Usage / Profile pages. It removes public SaaS and commercial self-service flows from the exposed runtime surface.

## What This Fork Keeps

- Claude, OpenAI-compatible, Gemini, Antigravity, Codex/OpenAI-compatible gateway entrypoints.
- API Key authentication, account scheduling, sticky sessions, usage logging, and model listing.
- Admin management for users, groups, upstream accounts/channels, proxies, usage, channel monitor, ops, settings, backup, and system tools.
- Member self-service for Dashboard, API Keys, Usage, and Profile.
- Email/password login and generic OIDC login for internal identity providers such as Microsoft Entra ID.

## What This Fork Removes

- Public registration and non-target OAuth login providers.
- Payment, orders, plans, public subscription purchase, redeem codes, promo codes, invitation rebates, affiliate workflows, and public promotion pages.
- Runtime blocking based on user balance, recharge state, subscription purchase state, or commercial quota purchase state.
- Sponsor, ecosystem, public payment, and public SaaS documentation from this internal README.

Old commercial API paths are intentionally not registered and should return 404.

## Runtime Model

The gateway performs authentication, group validation, IP ACL checks, scheduling, and usage recording. It does not reject model calls because a user has zero balance, no active subscription, or an exhausted purchased quota.

Disabled API Keys, inactive users, unavailable groups, and IP ACL violations still block requests.

## Deployment Notes

Use the normal backend, frontend, PostgreSQL, and Redis deployment flow for this repository. Before moving an existing production database to this internal fork, take a full database backup. This fork is allowed to make breaking changes and should be maintained as a long-lived internal branch.

## Verification

Backend:

```bash
cd backend
go test ./...
```

Frontend:

```bash
pnpm --dir frontend install
pnpm --dir frontend run typecheck
pnpm --dir frontend run test:run
```

If your local `pnpm` is older than the lockfile format, use a pnpm version compatible with lockfile v9 rather than rewriting the lockfile accidentally.
