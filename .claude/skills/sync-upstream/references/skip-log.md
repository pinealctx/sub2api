# Upstream Skip Log

Commits from `github.com/Wei-Shaw/sub2api` that have been reviewed and intentionally excluded
from this internal fork. Maintained by the `/sync-upstream` skill.

Classification categories are defined in [divergence-rules.md](divergence-rules.md).

## Skipped — commercial / branding (will not merge)

| SHA | Date | Message | Reason |
|-----|------|---------|--------|
| b0dbc22f | 2026-06-27 | fix/subscription-confirm-show-converted-amount | payment flow (SKIP: commercial) |
| 3b18d1fa | 2026-06-27 | fix/subscription-direct-pay-price | payment flow (SKIP: commercial) |
| 88ca0c1d | 2026-06-27 | fix(payment): 显示订阅 CNY 换算实付金额 | payment flow (SKIP: commercial) |
| b1403e8b | 2026-06-27 | fix(payment): keep subscription price as direct pay amount | payment flow (SKIP: commercial) |
| 9a0fbcc8 | 2026-06-27 | chore: update sponsors | sponsor assets (SKIP: branding) |
| a822972d | 2026-06-27 | docs/source-compile-admin-setup | public install docs (SKIP: branding) |
| 65ad7df4 | 2026-06-30 | fix(payment): 空 supported_types 支付提供商卡片消失 | payment flow (SKIP: commercial) |
| 55242ffa | 2026-06-30 | fix(admin): 订单金额币种符号读取 currency 字段 | payment/order (SKIP: commercial) |
| 147c1879 | 2026-06-30 | fix(payment): support plural subscription validity units | subscription (SKIP: commercial) |
| c6f375d3 | 2026-06-30 | fix(payment): 订阅订单应用充值汇率换算 | subscription/recharge (SKIP: commercial) |
| 9f5b57fc | 2026-06-30 | fix(billing): 防止余额计费持续透支 | billing wallet (SKIP: not a member wallet) |
| c2754222 | 2026-06-30 | chore: sync VERSION to 0.1.139 | KEEP_INTERNAL: VERSION managed internally |
| 98feeccb | 2026-06-30 | docs: note admin account wizard requirement in source-compile install | public install docs (SKIP: branding) |

## Deferred — wanted, but needs a dedicated focused merge

These are gateway/feature commits we DO want, but they cannot be cleanly cherry-picked onto the
current tree because they are entangled with the Grok platform refactor and/or our internal
baseline schema.

**2026-06-30 decision — Grok deferred (architectural blocker).** A dedicated Grok merge was
attempted and aborted. Root cause: upstream Grok (`feat: add grok subscription support`) is wired
into the **member-subscription commercial system that this fork removed**. Grok threads
`subscription` through the billing path (`GetSubscriptionFromContext`, `CheckBillingEligibility(...,
subscription, ...)`), adds `SubscriptionType: standard|subscription` to groups, and branches account
scheduling on subscription type. None of `GetSubscriptionFromContext`, the subscription billing
param, or subscription services exist in our tree. Taking Grok as-is would either reintroduce the
commercial subscription surface (violates the fork's core boundary) or require substantial
decoupling surgery. Owner chose to keep Grok deferred. Revisit only via the "decouple Grok from
member-subscriptions" path, or if the subscription system is deliberately reintroduced.

| SHA(s) | Message | Why deferred |
|--------|---------|--------------|
| 39be1ec9 + 11 follow-ups | feat: add grok subscription support (xAI provider) | 92-file squashed feature; introduces `PlatformGrok` + `isOpenAIGatewayPlatform`/`isOpenAIResponsesCompatibleGatewayPlatform` helpers; conflicts with our removed UI (EmailVerifyView, subscription tabs) and diverged SettingsView/DashboardView |
| 7a38c662 | Bridge OpenAI count_tokens to responses input_tokens | depends on Grok platform helpers + `PlatformGrok`; will not compile without Grok |
| 819fda34 | feat(codex-detect): codex_cli_only 检测加固 + 引擎指纹 + 账号级 app-server | 41-file feature; setting_service conflict bundles removed payment settings; 6 conflicts in diverged SettingsView |
| bad87ff5 | feat(ops): add api key filter to system logs | carries schema migration (ops_system_logs.api_key_id, migrations 154/155) that must be reconciled with the internal baseline schema |

## Merge History

| Date | PR | Upstream range | Commits taken | Skipped / Deferred |
|------|----|---------------|---------------|--------------------|
| 2026-06-26 | #1 `codex/merge-upstream-core-fixes` | initial baseline | multiple gateway fixes | commercial features, branding |
| 2026-06-30 | `merge/upstream-20260630` | `ce6af413`..`upstream/main` (39 non-merge) | 12 gateway/observability/keys/scheduler fixes | 10 commercial skipped; 15 deferred (Grok cluster + 3 dependents); 2 already applied |
