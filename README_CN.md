# Nexus Relay

Nexus Relay 是团队内部维护的 AI API 网关，用于自管模型路由、账号池、API Key 和用量观测。

这是一个允许破坏性变更的内部 fork。运行时聚焦鉴权、账号调度、分组隔离、代理路由、速率控制和用量记录。公开自助获客链路不属于这个产品方向。

## 核心能力

- Claude、OpenAI 兼容、Gemini、Antigravity、Codex/OpenAI 兼容网关入口。
- 上游账号池、分组绑定、粘性会话、故障切换、代理选择和模型列表。
- 成员侧 Dashboard、API Keys、Usage、Profile。
- 管理侧用户、分组、账号/渠道、代理、用量、渠道监控、Ops、设置、备份和系统工具。
- 邮箱密码登录和通用 OIDC 登录，可接入 Microsoft Entra ID 等内部身份源。
- 基于 PostgreSQL 和 Redis 的用量日志、监控历史与运维指标。

## 运行语义

网关请求只由 API Key 状态、用户状态、分组归属、IP ACL、速率限制、并发限制、账号可用性和平台路由规则决定是否放行。

用量费用字段只作为观测和统计口径保留，不作为成员钱包或购买条件。

## 本地开发

使用仓库锁定的版本：

```bash
nvm use
corepack enable
corepack prepare pnpm@9.15.9 --activate
```

安装与验证：

```bash
pnpm --dir frontend install
pnpm --dir frontend run typecheck
pnpm --dir frontend run test:run

cd backend
go test ./...
```

本地一体化环境可以使用开发 compose：

```bash
cp deploy/.env.example deploy/.env
docker compose -f deploy/docker-compose.dev.yml --env-file deploy/.env up --build
```

## 部署

部署文件位于 `deploy/`。新环境应使用全新数据库，或基于内部版 baseline schema 手动重建数据库。不支持从旧公开版 schema 自动迁移。

默认容器镜像为 `ghcr.io/pinealctx/sub2api:latest`。如使用其他内部镜像仓库或本地构建镜像，可通过 `NEXUS_RELAY_IMAGE` 覆盖。

## 上游维护

保留 `upstream` 指向原项目，便于后续选择性合并网关能力。产品、文档、公开获客链路和非目标身份源变更继续按内部 fork 的方向维护。
