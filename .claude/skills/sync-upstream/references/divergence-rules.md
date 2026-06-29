# Upstream Divergence Rules

This document defines the intentional differences between **Nexus Relay** (this fork, `pinealctx/sub2api`)
and the upstream project (`github.com/Wei-Shaw/sub2api`). It is the authoritative reference used by
the `/sync-upstream` skill when classifying upstream commits.

## Remotes

| Remote | Repository | Purpose |
|--------|-----------|---------|
| `origin` | `pinealctx/sub2api` | Internal private repo |
| `upstream` | `github.com/Wei-Shaw/sub2api` | Original project, gateway features only |

The Go module path intentionally stays `github.com/Wei-Shaw/sub2api` to minimize merge conflicts.

---

## Classification Rules

### SKIP — Always discard

These areas contain features or content we have intentionally removed from the internal fork.
When an upstream commit touches **only** SKIP areas, mark it as SKIP without further review.

**Commercial / public acquisition flows:**
- Subscription, payment, billing wallet (the cost field in usage records is observability-only, not a purchase gate)
- Redeem codes and coupon system
- Affiliate / rebate programs
- Public pricing pages and purchase UI flows

**Branding and public-facing content:**
- Sponsor / partner assets and listings (`assets/partners/`)
- Sponsor update commits (`chore: update sponsors`, `chore: update partners`)
- `CLA.md` and `.github/workflows/cla.yml`
- Public install scripts (`install.sh`, Docker quickstart guides aimed at public users)
- `README_JA.md` and any new locale READMEs added upstream

**Identity providers we do not support:**
- Login provider integrations beyond email/password and generic OIDC (e.g. WeChat, GitHub OAuth for public users)

---

### TAKE — Accept proactively, low risk

Gateway and protocol improvements are the primary value from upstream. Cherry-pick these promptly.

**Core gateway paths:**
- `backend/internal/handler/gateway_*`
- `backend/internal/handler/openai_*`
- `backend/internal/handler/gemini_*`
- `backend/internal/handler/failover_*`
- Fixes to stream handling, backoff, idempotency, concurrency limiting

**AI platform adapters:**
- Claude / Anthropic passthrough fixes
- OpenAI, Codex, Gemini, Antigravity adapter fixes
- Model listing and routing logic

**Bug fixes in shared infrastructure:**
- Auth flows (OIDC, session, TOTP) — excluding new public login providers
- API key management and quota enforcement
- Usage logging, cost recording (observability fields only)
- Channel monitoring
- Proxy routing and selection
- Rate limiting / concurrency limiting
- Image generation pipeline

**Frontend fixes for pages we maintain:**
- Admin: Dashboard, Accounts, Groups, Proxies, Usage, Channel Monitor, Backup, Settings, Risk Control, Ops
- Member: Dashboard, API Keys, Usage, Profile

---

### REVIEW — Requires human judgment

These areas may contain a mix of wanted and unwanted changes, or carry higher integration risk.
Pause, show the diff to the user, and decide together.

**Database schema and migrations:**
- `backend/ent/schema/` and `backend/migrations/`
- Ask: does this column/table serve a commercial feature we've removed? If yes → SKIP.
- Ask: does it conflict with our internal baseline schema? If yes → adapt carefully before applying.

**New services or large refactors:**
- New `backend/internal/service/*.go` files
- Significant handler restructuring or new routes
- Evaluate: does this serve gateway/observability or a commercial purpose?

**Dependency changes:**
- `backend/go.mod` / `go.sum` bumps
- `frontend/package.json` / `pnpm-lock.yaml` changes
- Review for breaking API changes before accepting.

**CI / GitHub Actions:**
- `.github/workflows/` — we maintain our own pipeline
- Only take upstream CI changes if they fix a shared test or lint issue that applies to us.
- Never take CLA enforcement or public release workflow changes.

---

### KEEP_INTERNAL — Our version always wins

Files where we hold intentional content that must never be overwritten by an upstream merge.
During conflict resolution, always choose our version for these paths.

| Path | Reason |
|------|--------|
| `README.md`, `README_CN.md` | Internal product branding |
| `DEV_GUIDE.md` | Internal development guide |
| `.github/workflows/` | Internal CI configuration |
| `.goreleaser.yaml`, `.goreleaser.simple.yaml` | Internal release pipeline |
| `deploy/` | Internal deployment assets |
| `Dockerfile`, `Dockerfile.goreleaser` | Internal image definitions |
| `backend/cmd/server/VERSION` | Managed by internal release process |
| `skills/`, `.claude/` | Internal tooling (this skill and its references live here) |

---

## Known Intentional Removals

These were present in the upstream and have been deliberately removed in this fork.

| Feature | Upstream location | Removal commit |
|---------|-----------------|----------------|
| Redeem code admin commands | `skills/sub2api-admin/` | `122e15f0` |
| Public branding, partner logos, README | `assets/partners/`, `README*.md` | `95addbb7` |
| CLA workflow | `.github/workflows/cla.yml` | `95addbb7` |
| Public install/upgrade scripts | `install.sh`, deploy docs | `95addbb7` |
| Commercial wording in UI | frontend views | `4a619d0f`, `85409ecd` |

---

## Merge Process

See [../SKILL.md](../SKILL.md) for the step-by-step sync procedure.
Skipped commits are logged in [skip-log.md](skip-log.md).
