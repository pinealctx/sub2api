# Nexus Relay

团队内部维护版 AI API 网关，用于自管模型路由、账号池、API Key 和用量统计。

本 fork 保留核心网关、账号池、分组、代理、API Key、用量记录、渠道监控、运维监控，以及成员侧 Dashboard / Keys / Usage / Profile。公开 SaaS 和商业自助链路不再作为运行时能力暴露。

## 保留能力

- Claude、OpenAI 兼容、Gemini、Antigravity、Codex/OpenAI 兼容网关入口。
- API Key 鉴权、账号调度、粘性会话、用量记录、模型列表。
- 管理后台用户、分组、上游账号/渠道、代理、用量、渠道监控、Ops、设置、备份和系统工具。
- 成员自助 Dashboard、API Key、Usage、Profile。
- 邮箱密码登录和通用 OIDC 登录，可用于 Microsoft Entra ID 等内部身份源。

## 移除能力

- 公开注册和非目标 OAuth 登录。
- 支付、订单、套餐、公开订阅购买、兑换码、优惠码、邀请返利、Affiliate、公开推广页。
- 因余额、充值状态、订阅购买状态、商业配额购买状态拦截网关调用。
- 赞助商、生态推广、公开支付和公开 SaaS 文档入口。

旧商业 API 路径不会注册，预期返回 404。

## 运行语义

网关只做鉴权、分组校验、IP ACL、调度和用量记录。用户余额为 0、没有有效订阅、购买配额耗尽，都不会阻止模型调用。

停用的 API Key、停用用户、不可用分组和 IP ACL 命中仍会被拦截。

## 部署注意

继续使用本仓库的后端、前端、PostgreSQL、Redis 部署流程。旧生产库迁移到内部 fork 前必须先做完整数据库备份。此 fork 允许 breaking changes，适合作为长期维护的内部主线。

## 验证

后端：

```bash
cd backend
go test ./...
```

前端：

```bash
pnpm --dir frontend install
pnpm --dir frontend run typecheck
pnpm --dir frontend run test:run
```

如果本机 pnpm 版本低于 lockfile v9 兼容版本，请先切换 pnpm 版本，避免误重写锁文件。
