# Nexus Relay

Internal-maintenance AI API gateway for self-hosted model routing, account pools, API keys, and usage observability.

It keeps the core gateway, account pool, groups, proxies, API keys, usage logs, channel monitoring, ops monitoring, and the member Dashboard / Keys / Usage / Profile pages. Public SaaS and commercial self-service flows are not exposed in this fork.

## Kept

- Claude, OpenAI-compatible, Gemini, Antigravity, and Codex/OpenAI-compatible gateway entrypoints.
- API Key authentication, account scheduling, sticky sessions, model listing, and usage recording.
- Admin tools for users, groups, accounts/channels, proxies, usage, channel monitoring, ops, settings, backups, and system operations.
- Email/password login and generic OIDC login for internal identity providers such as Microsoft Entra ID.

## Removed

- Public registration and non-target OAuth login providers.
- Payment, orders, plans, public subscription purchase, redeem codes, promo codes, invitation rebates, affiliate workflows, and public promotion pages.
- Runtime blocking based on balance, recharge state, subscription purchase state, or commercial quota state.
- Sponsor, ecosystem, public payment, and public SaaS documentation links.

Old commercial API paths are intentionally not registered and should return 404.

## Verification

```bash
cd backend
go test ./...
```

```bash
pnpm --dir frontend install
pnpm --dir frontend run typecheck
pnpm --dir frontend run test:run
```

Use a pnpm version compatible with lockfile v9 before installing frontend dependencies.
