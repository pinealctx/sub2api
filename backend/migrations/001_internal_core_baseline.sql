-- Internal core schema baseline.
-- Breaking fork policy: deploy on a new database or rebuild the database manually.
-- Commercial/public SaaS tables and legacy OAuth compatibility tables are intentionally absent.

DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_trgm extension not created: %', SQLERRM;
  END;
END $$;

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    concurrency INT NOT NULL DEFAULT 5,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    username VARCHAR(100) NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    totp_secret_encrypted TEXT,
    totp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    totp_enabled_at TIMESTAMPTZ,
    signup_source VARCHAR(20) NOT NULL DEFAULT 'email' CHECK (signup_source IN ('email', 'oidc')),
    last_login_at TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ,
    rpm_limit INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS users_email ON users (email) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS users_status ON users (status);
CREATE INDEX IF NOT EXISTS users_deleted_at ON users (deleted_at);

CREATE TABLE IF NOT EXISTS groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    rate_multiplier NUMERIC(10,4) NOT NULL DEFAULT 1,
    is_exclusive BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    platform VARCHAR(50) NOT NULL DEFAULT 'anthropic',
    daily_limit_usd NUMERIC(20,8),
    weekly_limit_usd NUMERIC(20,8),
    monthly_limit_usd NUMERIC(20,8),
    allow_image_generation BOOLEAN NOT NULL DEFAULT FALSE,
    image_rate_independent BOOLEAN NOT NULL DEFAULT FALSE,
    image_rate_multiplier NUMERIC(10,4) NOT NULL DEFAULT 1,
    image_price_1k NUMERIC(20,8),
    image_price_2k NUMERIC(20,8),
    image_price_4k NUMERIC(20,8),
    claude_code_only BOOLEAN NOT NULL DEFAULT FALSE,
    fallback_group_id BIGINT,
    fallback_group_id_on_invalid_request BIGINT,
    model_routing JSONB DEFAULT '{}'::jsonb,
    model_routing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    mcp_xml_inject BOOLEAN NOT NULL DEFAULT TRUE,
    supported_model_scopes JSONB NOT NULL DEFAULT '["claude","gemini_text","gemini_image"]'::jsonb,
    sort_order INT NOT NULL DEFAULT 0,
    allow_messages_dispatch BOOLEAN NOT NULL DEFAULT FALSE,
    require_oauth_only BOOLEAN NOT NULL DEFAULT FALSE,
    require_privacy_set BOOLEAN NOT NULL DEFAULT FALSE,
    default_mapped_model VARCHAR(100) NOT NULL DEFAULT '',
    messages_dispatch_model_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    models_list_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    rpm_limit INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS groups_name ON groups (name) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS groups_status ON groups (status);
CREATE INDEX IF NOT EXISTS groups_platform ON groups (platform);
CREATE INDEX IF NOT EXISTS groups_is_exclusive ON groups (is_exclusive);
CREATE INDEX IF NOT EXISTS groups_sort_order ON groups (sort_order);
CREATE INDEX IF NOT EXISTS groups_deleted_at ON groups (deleted_at);
INSERT INTO groups (name, description, platform, rate_multiplier, is_exclusive, status)
SELECT 'anthropic-default', 'Auto-created default group', 'anthropic', 1, FALSE, 'active'
WHERE NOT EXISTS (SELECT 1 FROM groups WHERE name = 'anthropic-default' AND deleted_at IS NULL);
INSERT INTO groups (name, description, platform, rate_multiplier, is_exclusive, status)
SELECT 'openai-default', 'Auto-created default group', 'openai', 1, FALSE, 'active'
WHERE NOT EXISTS (SELECT 1 FROM groups WHERE name = 'openai-default' AND deleted_at IS NULL);
INSERT INTO groups (name, description, platform, rate_multiplier, is_exclusive, status)
SELECT 'gemini-default', 'Auto-created default group', 'gemini', 1, FALSE, 'active'
WHERE NOT EXISTS (SELECT 1 FROM groups WHERE name = 'gemini-default' AND deleted_at IS NULL);
INSERT INTO groups (name, description, platform, rate_multiplier, is_exclusive, status)
SELECT 'antigravity-default-1', 'Auto-created default group', 'antigravity', 1, FALSE, 'active'
WHERE NOT EXISTS (SELECT 1 FROM groups WHERE name = 'antigravity-default-1' AND deleted_at IS NULL);
INSERT INTO groups (name, description, platform, rate_multiplier, is_exclusive, status)
SELECT 'antigravity-default-2', 'Auto-created default group', 'antigravity', 1, FALSE, 'active'
WHERE NOT EXISTS (SELECT 1 FROM groups WHERE name = 'antigravity-default-2' AND deleted_at IS NULL);

CREATE TABLE IF NOT EXISTS proxies (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    protocol VARCHAR(20) NOT NULL,
    host VARCHAR(255) NOT NULL,
    port INT NOT NULL,
    username VARCHAR(100),
    password VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    expires_at TIMESTAMPTZ,
    fallback_mode VARCHAR(20) NOT NULL DEFAULT 'none',
    backup_proxy_id BIGINT REFERENCES proxies(id) ON DELETE SET NULL,
    expiry_warn_days INT NOT NULL DEFAULT 7,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS proxies_status ON proxies (status);
CREATE INDEX IF NOT EXISTS proxies_expires_at ON proxies (expires_at);
CREATE INDEX IF NOT EXISTS proxies_backup_proxy_id ON proxies (backup_proxy_id);
CREATE INDEX IF NOT EXISTS proxies_deleted_at ON proxies (deleted_at);

CREATE TABLE IF NOT EXISTS accounts (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    notes TEXT,
    platform VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL,
    credentials JSONB NOT NULL DEFAULT '{}'::jsonb,
    extra JSONB NOT NULL DEFAULT '{}'::jsonb,
    proxy_id BIGINT REFERENCES proxies(id) ON DELETE SET NULL,
    proxy_fallback_origin_id BIGINT,
    concurrency INT NOT NULL DEFAULT 3,
    load_factor INT,
    priority INT NOT NULL DEFAULT 50,
    rate_multiplier NUMERIC(10,4) NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    error_message TEXT,
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    auto_pause_on_expired BOOLEAN NOT NULL DEFAULT TRUE,
    schedulable BOOLEAN NOT NULL DEFAULT TRUE,
    rate_limited_at TIMESTAMPTZ,
    rate_limit_reset_at TIMESTAMPTZ,
    overload_until TIMESTAMPTZ,
    temp_unschedulable_until TIMESTAMPTZ,
    temp_unschedulable_reason TEXT,
    session_window_start TIMESTAMPTZ,
    session_window_end TIMESTAMPTZ,
    session_window_status VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS accounts_platform ON accounts (platform);
CREATE INDEX IF NOT EXISTS accounts_type ON accounts (type);
CREATE INDEX IF NOT EXISTS accounts_status ON accounts (status);
CREATE INDEX IF NOT EXISTS accounts_proxy_id ON accounts (proxy_id);
CREATE INDEX IF NOT EXISTS accounts_priority ON accounts (priority);
CREATE INDEX IF NOT EXISTS accounts_last_used_at ON accounts (last_used_at);
CREATE INDEX IF NOT EXISTS accounts_schedulable ON accounts (schedulable);
CREATE INDEX IF NOT EXISTS accounts_rate_limited_at ON accounts (rate_limited_at);
CREATE INDEX IF NOT EXISTS accounts_rate_limit_reset_at ON accounts (rate_limit_reset_at);
CREATE INDEX IF NOT EXISTS accounts_overload_until ON accounts (overload_until);
CREATE INDEX IF NOT EXISTS accounts_platform_priority ON accounts (platform, priority);
CREATE INDEX IF NOT EXISTS accounts_priority_status ON accounts (priority, status);
CREATE INDEX IF NOT EXISTS accounts_deleted_at ON accounts (deleted_at);
CREATE INDEX IF NOT EXISTS accounts_active_scheduler_idx
    ON accounts (platform, status, schedulable, priority, id)
    WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS accounts_expiry_autopause_idx
    ON accounts (expires_at)
    WHERE deleted_at IS NULL AND auto_pause_on_expired = TRUE AND status = 'active';

CREATE TABLE IF NOT EXISTS account_groups (
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    priority INT NOT NULL DEFAULT 50,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (account_id, group_id)
);
CREATE INDEX IF NOT EXISTS account_groups_group_id ON account_groups (group_id);
CREATE INDEX IF NOT EXISTS account_groups_group_priority_account ON account_groups (group_id, priority, account_id);

CREATE TABLE IF NOT EXISTS api_keys (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key VARCHAR(128) NOT NULL,
    name VARCHAR(100) NOT NULL,
    group_id BIGINT REFERENCES groups(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    last_used_at TIMESTAMPTZ,
    ip_whitelist JSONB DEFAULT '[]'::jsonb,
    ip_blacklist JSONB DEFAULT '[]'::jsonb,
    quota NUMERIC(20,8) NOT NULL DEFAULT 0,
    quota_used NUMERIC(20,8) NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ,
    rate_limit_5h NUMERIC(20,8) NOT NULL DEFAULT 0,
    rate_limit_1d NUMERIC(20,8) NOT NULL DEFAULT 0,
    rate_limit_7d NUMERIC(20,8) NOT NULL DEFAULT 0,
    usage_5h NUMERIC(20,8) NOT NULL DEFAULT 0,
    usage_1d NUMERIC(20,8) NOT NULL DEFAULT 0,
    usage_7d NUMERIC(20,8) NOT NULL DEFAULT 0,
    window_5h_start TIMESTAMPTZ,
    window_1d_start TIMESTAMPTZ,
    window_7d_start TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS apikey_key ON api_keys (key) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS api_keys_user_id ON api_keys (user_id);
CREATE INDEX IF NOT EXISTS api_keys_group_id ON api_keys (group_id);
CREATE INDEX IF NOT EXISTS api_keys_status ON api_keys (status);
CREATE INDEX IF NOT EXISTS api_keys_last_used_at ON api_keys (last_used_at);
CREATE INDEX IF NOT EXISTS api_keys_expires_at ON api_keys (expires_at);
CREATE INDEX IF NOT EXISTS api_keys_quota_quota_used ON api_keys (quota, quota_used);
CREATE INDEX IF NOT EXISTS api_keys_deleted_at ON api_keys (deleted_at);

CREATE TABLE IF NOT EXISTS settings (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(255) NOT NULL UNIQUE,
    value TEXT NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS security_secrets (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(255) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth_identities (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_type VARCHAR(20) NOT NULL CHECK (provider_type IN ('email', 'oidc')),
    provider_key TEXT NOT NULL,
    provider_subject TEXT NOT NULL,
    verified_at TIMESTAMPTZ,
    issuer TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS authident_provider_type_provider_key_provider_subject
    ON auth_identities (provider_type, provider_key, provider_subject);
CREATE INDEX IF NOT EXISTS auth_identities_user_id ON auth_identities (user_id);
CREATE INDEX IF NOT EXISTS auth_identities_user_id_provider_type ON auth_identities (user_id, provider_type);

CREATE TABLE IF NOT EXISTS pending_auth_sessions (
    id BIGSERIAL PRIMARY KEY,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    intent VARCHAR(40) NOT NULL CHECK (intent IN ('login', 'bind_current_user', 'adopt_existing_user_by_email')),
    provider_type VARCHAR(20) NOT NULL CHECK (provider_type IN ('email', 'oidc')),
    provider_key TEXT NOT NULL,
    provider_subject TEXT NOT NULL,
    target_user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    redirect_to TEXT NOT NULL DEFAULT '',
    resolved_email TEXT NOT NULL DEFAULT '',
    account_creation_password_hash TEXT NOT NULL DEFAULT '',
    upstream_identity_claims JSONB NOT NULL DEFAULT '{}'::jsonb,
    local_flow_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    browser_session_key TEXT NOT NULL DEFAULT '',
    completion_code_hash TEXT NOT NULL DEFAULT '',
    completion_code_expires_at TIMESTAMPTZ,
    email_verified_at TIMESTAMPTZ,
    password_verified_at TIMESTAMPTZ,
    totp_verified_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS pending_auth_sessions_target_user_id ON pending_auth_sessions (target_user_id);
CREATE INDEX IF NOT EXISTS pending_auth_sessions_expires_at ON pending_auth_sessions (expires_at);
CREATE INDEX IF NOT EXISTS pending_auth_sessions_provider ON pending_auth_sessions (provider_type, provider_key, provider_subject);
CREATE INDEX IF NOT EXISTS pending_auth_sessions_completion_code_hash ON pending_auth_sessions (completion_code_hash);

CREATE TABLE IF NOT EXISTS identity_adoption_decisions (
    id BIGSERIAL PRIMARY KEY,
    pending_auth_session_id BIGINT NOT NULL UNIQUE REFERENCES pending_auth_sessions(id) ON DELETE CASCADE,
    identity_id BIGINT REFERENCES auth_identities(id) ON DELETE CASCADE,
    adopt_display_name BOOLEAN NOT NULL DEFAULT FALSE,
    adopt_avatar BOOLEAN NOT NULL DEFAULT FALSE,
    decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS identity_adoption_decisions_identity_id ON identity_adoption_decisions (identity_id);

CREATE TABLE IF NOT EXISTS user_provider_default_grants (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_type VARCHAR(20) NOT NULL CHECK (provider_type IN ('email', 'oidc')),
    grant_reason VARCHAR(20) NOT NULL DEFAULT 'first_bind' CHECK (grant_reason IN ('signup', 'first_bind')),
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS user_provider_default_grants_user_provider_reason_key
    ON user_provider_default_grants (user_id, provider_type, grant_reason);
CREATE INDEX IF NOT EXISTS user_provider_default_grants_user_id_idx ON user_provider_default_grants (user_id);

CREATE TABLE IF NOT EXISTS user_avatars (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    storage_provider VARCHAR(20) NOT NULL DEFAULT 'database',
    storage_key TEXT NOT NULL DEFAULT '',
    url TEXT NOT NULL DEFAULT '',
    content_type VARCHAR(100) NOT NULL DEFAULT '',
    byte_size INT NOT NULL DEFAULT 0,
    sha256 VARCHAR(64) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_allowed_groups (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, group_id)
);
CREATE INDEX IF NOT EXISTS user_allowed_groups_group_id ON user_allowed_groups (group_id);

CREATE TABLE IF NOT EXISTS user_attribute_definitions (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    value_type VARCHAR(20) NOT NULL DEFAULT 'string',
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    is_unique BOOLEAN NOT NULL DEFAULT FALSE,
    show_in_admin_list BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_attribute_values (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    definition_id BIGINT NOT NULL REFERENCES user_attribute_definitions(id) ON DELETE CASCADE,
    value TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, definition_id)
);
CREATE INDEX IF NOT EXISTS user_attribute_values_definition_id ON user_attribute_values (definition_id);
CREATE INDEX IF NOT EXISTS user_attribute_values_value ON user_attribute_values (value);

CREATE TABLE IF NOT EXISTS user_platform_quotas (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform VARCHAR(32) NOT NULL,
    daily_limit_usd NUMERIC(20,10),
    weekly_limit_usd NUMERIC(20,10),
    monthly_limit_usd NUMERIC(20,10),
    daily_usage_usd NUMERIC(20,10) NOT NULL DEFAULT 0,
    weekly_usage_usd NUMERIC(20,10) NOT NULL DEFAULT 0,
    monthly_usage_usd NUMERIC(20,10) NOT NULL DEFAULT 0,
    daily_window_start TIMESTAMPTZ,
    weekly_window_start TIMESTAMPTZ,
    monthly_window_start TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS user_platform_quotas_user_id_platform_active_key
    ON user_platform_quotas (user_id, platform) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS user_platform_quotas_user_id ON user_platform_quotas (user_id);
CREATE INDEX IF NOT EXISTS user_platform_quotas_platform ON user_platform_quotas (platform);

CREATE TABLE IF NOT EXISTS user_group_rate_multipliers (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    rate_multiplier NUMERIC(10,4),
    rpm_override INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, group_id)
);
CREATE INDEX IF NOT EXISTS idx_user_group_rate_multipliers_group_id ON user_group_rate_multipliers (group_id);

CREATE TABLE IF NOT EXISTS usage_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    api_key_id BIGINT NOT NULL REFERENCES api_keys(id) ON DELETE CASCADE,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    request_id VARCHAR(255),
    model VARCHAR(100) NOT NULL,
    requested_model VARCHAR(100),
    upstream_model VARCHAR(100),
    channel_id BIGINT,
    model_mapping_chain VARCHAR(500),
    billing_tier VARCHAR(50),
    billing_mode VARCHAR(20),
    group_id BIGINT REFERENCES groups(id) ON DELETE SET NULL,
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    cache_creation_tokens INT NOT NULL DEFAULT 0,
    cache_read_tokens INT NOT NULL DEFAULT 0,
    cache_creation_5m_tokens INT NOT NULL DEFAULT 0,
    cache_creation_1h_tokens INT NOT NULL DEFAULT 0,
    image_output_tokens INT NOT NULL DEFAULT 0,
    input_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    output_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    cache_creation_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    cache_read_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    image_output_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    total_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    actual_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    account_stats_cost NUMERIC(20,10),
    rate_multiplier NUMERIC(10,4) NOT NULL DEFAULT 1,
    account_rate_multiplier NUMERIC(10,4),
    request_type SMALLINT NOT NULL DEFAULT 0,
    stream BOOLEAN NOT NULL DEFAULT FALSE,
    openai_ws_mode BOOLEAN NOT NULL DEFAULT FALSE,
    duration_ms INT,
    first_token_ms INT,
    user_agent VARCHAR(512),
    ip_address VARCHAR(45),
    image_count INT NOT NULL DEFAULT 0,
    image_size VARCHAR(10),
    image_input_size VARCHAR(32),
    image_output_size VARCHAR(32),
    image_size_source VARCHAR(16),
    image_size_breakdown JSONB DEFAULT '{}'::jsonb,
    service_tier TEXT,
    reasoning_effort TEXT,
    inbound_endpoint TEXT,
    upstream_endpoint TEXT,
    cache_ttl_overridden BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS usage_logs_user_id ON usage_logs (user_id);
CREATE INDEX IF NOT EXISTS usage_logs_api_key_id ON usage_logs (api_key_id);
CREATE INDEX IF NOT EXISTS usage_logs_account_id ON usage_logs (account_id);
CREATE INDEX IF NOT EXISTS usage_logs_group_id ON usage_logs (group_id);
CREATE INDEX IF NOT EXISTS usage_logs_created_at ON usage_logs (created_at);
CREATE INDEX IF NOT EXISTS usage_logs_model ON usage_logs (model);
CREATE INDEX IF NOT EXISTS usage_logs_requested_model ON usage_logs (requested_model);
CREATE INDEX IF NOT EXISTS usage_logs_request_id ON usage_logs (request_id);
CREATE INDEX IF NOT EXISTS usage_logs_user_created_at ON usage_logs (user_id, created_at);
CREATE INDEX IF NOT EXISTS usage_logs_api_key_created_at ON usage_logs (api_key_id, created_at);
CREATE INDEX IF NOT EXISTS usage_logs_group_created_at ON usage_logs (group_id, created_at) WHERE group_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_usage_logs_request_api_key ON usage_logs (request_id, api_key_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_upstream_model ON usage_logs (upstream_model);
CREATE INDEX IF NOT EXISTS idx_usage_logs_requested_model ON usage_logs (requested_model);
CREATE INDEX IF NOT EXISTS idx_usage_logs_inbound_endpoint ON usage_logs (inbound_endpoint);
CREATE INDEX IF NOT EXISTS idx_usage_logs_upstream_endpoint ON usage_logs (upstream_endpoint);

CREATE TABLE IF NOT EXISTS usage_billing_dedup (
    id BIGSERIAL PRIMARY KEY,
    request_id VARCHAR(255) NOT NULL,
    api_key_id BIGINT NOT NULL,
    request_fingerprint VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_usage_billing_dedup_request_api_key ON usage_billing_dedup (request_id, api_key_id);
CREATE INDEX IF NOT EXISTS idx_usage_billing_dedup_created_at ON usage_billing_dedup (created_at);

CREATE TABLE IF NOT EXISTS usage_billing_dedup_archive (
    request_id VARCHAR(255) NOT NULL,
    api_key_id BIGINT NOT NULL,
    request_fingerprint VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (request_id, api_key_id)
);

CREATE TABLE IF NOT EXISTS scheduler_outbox (
    id BIGSERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    account_id BIGINT,
    group_id BIGINT,
    payload JSONB,
    dedup_key TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_scheduler_outbox_created_at ON scheduler_outbox (created_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_scheduler_outbox_pending_dedup_key
    ON scheduler_outbox (dedup_key)
    WHERE dedup_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS channels (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    model_mapping JSONB NOT NULL DEFAULT '{}'::jsonb,
    billing_model_source VARCHAR(20) NOT NULL DEFAULT 'requested',
    restrict_models BOOLEAN NOT NULL DEFAULT FALSE,
    features TEXT NOT NULL DEFAULT '',
    features_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    apply_pricing_to_account_stats BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_channels_status ON channels (status);

CREATE TABLE IF NOT EXISTS channel_groups (
    id BIGSERIAL PRIMARY KEY,
    channel_id BIGINT NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_channel_groups_group_id ON channel_groups (group_id);
CREATE INDEX IF NOT EXISTS idx_channel_groups_channel_id ON channel_groups (channel_id);

CREATE TABLE IF NOT EXISTS channel_model_pricing (
    id BIGSERIAL PRIMARY KEY,
    channel_id BIGINT NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL DEFAULT 'anthropic',
    models JSONB NOT NULL DEFAULT '[]'::jsonb,
    billing_mode VARCHAR(20) NOT NULL DEFAULT 'token',
    input_price NUMERIC(20,12),
    output_price NUMERIC(20,12),
    cache_write_price NUMERIC(20,12),
    cache_read_price NUMERIC(20,12),
    image_output_price NUMERIC(20,10),
    per_request_price NUMERIC(20,10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_channel_model_pricing_channel_id ON channel_model_pricing (channel_id);
CREATE INDEX IF NOT EXISTS idx_channel_model_pricing_platform ON channel_model_pricing (platform);

CREATE TABLE IF NOT EXISTS channel_pricing_intervals (
    id BIGSERIAL PRIMARY KEY,
    pricing_id BIGINT NOT NULL REFERENCES channel_model_pricing(id) ON DELETE CASCADE,
    min_tokens INT NOT NULL DEFAULT 0,
    max_tokens INT,
    tier_label VARCHAR(50),
    input_price NUMERIC(20,12),
    output_price NUMERIC(20,12),
    cache_write_price NUMERIC(20,12),
    cache_read_price NUMERIC(20,12),
    per_request_price NUMERIC(20,12),
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_channel_pricing_intervals_pricing_id ON channel_pricing_intervals (pricing_id);

CREATE TABLE IF NOT EXISTS channel_account_stats_pricing_rules (
    id BIGSERIAL PRIMARY KEY,
    channel_id BIGINT NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL DEFAULT '',
    group_ids BIGINT[] NOT NULL DEFAULT '{}',
    account_ids BIGINT[] NOT NULL DEFAULT '{}',
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cas_pricing_rules_channel_id ON channel_account_stats_pricing_rules (channel_id);

CREATE TABLE IF NOT EXISTS channel_account_stats_model_pricing (
    id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT NOT NULL REFERENCES channel_account_stats_pricing_rules(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL DEFAULT '',
    models JSONB NOT NULL DEFAULT '[]'::jsonb,
    billing_mode VARCHAR(20) NOT NULL DEFAULT 'token',
    input_price NUMERIC(20,10),
    output_price NUMERIC(20,10),
    cache_write_price NUMERIC(20,10),
    cache_read_price NUMERIC(20,10),
    image_output_price NUMERIC(20,10),
    per_request_price NUMERIC(20,10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cas_model_pricing_rule_id ON channel_account_stats_model_pricing (rule_id);

CREATE TABLE IF NOT EXISTS channel_account_stats_pricing_intervals (
    id BIGSERIAL PRIMARY KEY,
    pricing_id BIGINT NOT NULL REFERENCES channel_account_stats_model_pricing(id) ON DELETE CASCADE,
    min_tokens INT NOT NULL DEFAULT 0,
    max_tokens INT,
    tier_label VARCHAR(50),
    input_price NUMERIC(20,12),
    output_price NUMERIC(20,12),
    cache_write_price NUMERIC(20,12),
    cache_read_price NUMERIC(20,12),
    per_request_price NUMERIC(20,12),
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_account_stats_pricing_intervals_pricing_id
    ON channel_account_stats_pricing_intervals (pricing_id);

CREATE TABLE IF NOT EXISTS channel_monitor_request_templates (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    provider VARCHAR(20) NOT NULL CHECK (provider IN ('openai', 'anthropic', 'gemini')),
    api_mode VARCHAR(32) NOT NULL DEFAULT 'chat_completions',
    description VARCHAR(500) NOT NULL DEFAULT '',
    extra_headers JSONB NOT NULL DEFAULT '{}'::jsonb,
    body_override_mode VARCHAR(10) NOT NULL DEFAULT 'off',
    body_override JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS channel_monitor_templates_provider_name
    ON channel_monitor_request_templates (provider, name);
CREATE INDEX IF NOT EXISTS channel_monitor_templates_provider_api_mode
    ON channel_monitor_request_templates (provider, api_mode);

CREATE TABLE IF NOT EXISTS channel_monitors (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    provider VARCHAR(20) NOT NULL CHECK (provider IN ('openai', 'anthropic', 'gemini')),
    api_mode VARCHAR(32) NOT NULL DEFAULT 'chat_completions',
    endpoint VARCHAR(500) NOT NULL,
    api_key_encrypted TEXT NOT NULL,
    primary_model VARCHAR(200) NOT NULL,
    extra_models JSONB NOT NULL DEFAULT '[]'::jsonb,
    group_name VARCHAR(100) NOT NULL DEFAULT '',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    interval_seconds INT NOT NULL CHECK (interval_seconds BETWEEN 15 AND 3600),
    jitter_seconds INT NOT NULL DEFAULT 0 CHECK (jitter_seconds BETWEEN 0 AND 3600),
    last_checked_at TIMESTAMPTZ,
    created_by BIGINT NOT NULL,
    template_id BIGINT REFERENCES channel_monitor_request_templates(id) ON DELETE SET NULL,
    extra_headers JSONB NOT NULL DEFAULT '{}'::jsonb,
    body_override_mode VARCHAR(10) NOT NULL DEFAULT 'off',
    body_override JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS channel_monitors_enabled_last_checked ON channel_monitors (enabled, last_checked_at);
CREATE INDEX IF NOT EXISTS channel_monitors_provider ON channel_monitors (provider);
CREATE INDEX IF NOT EXISTS channel_monitors_provider_api_mode ON channel_monitors (provider, api_mode);
CREATE INDEX IF NOT EXISTS channel_monitors_group_name ON channel_monitors (group_name);
CREATE INDEX IF NOT EXISTS channel_monitors_template_id ON channel_monitors (template_id);

CREATE TABLE IF NOT EXISTS channel_monitor_histories (
    id BIGSERIAL PRIMARY KEY,
    monitor_id BIGINT NOT NULL REFERENCES channel_monitors(id) ON DELETE CASCADE,
    model VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('operational', 'degraded', 'failed', 'error')),
    latency_ms INT,
    ping_latency_ms INT,
    message VARCHAR(500) NOT NULL DEFAULT '',
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS channel_monitor_histories_monitor_model_checked
    ON channel_monitor_histories (monitor_id, model, checked_at DESC);
CREATE INDEX IF NOT EXISTS channel_monitor_histories_checked_at ON channel_monitor_histories (checked_at);

CREATE TABLE IF NOT EXISTS channel_monitor_daily_rollups (
    id BIGSERIAL PRIMARY KEY,
    monitor_id BIGINT NOT NULL REFERENCES channel_monitors(id) ON DELETE CASCADE,
    model VARCHAR(200) NOT NULL,
    bucket_date DATE NOT NULL,
    total_checks INT NOT NULL DEFAULT 0,
    ok_count INT NOT NULL DEFAULT 0,
    operational_count INT NOT NULL DEFAULT 0,
    degraded_count INT NOT NULL DEFAULT 0,
    failed_count INT NOT NULL DEFAULT 0,
    error_count INT NOT NULL DEFAULT 0,
    sum_latency_ms BIGINT NOT NULL DEFAULT 0,
    count_latency INT NOT NULL DEFAULT 0,
    sum_ping_latency_ms BIGINT NOT NULL DEFAULT 0,
    count_ping_latency INT NOT NULL DEFAULT 0,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS channel_monitor_daily_rollup_monitor_model_bucket
    ON channel_monitor_daily_rollups (monitor_id, model, bucket_date);
CREATE INDEX IF NOT EXISTS channel_monitor_daily_rollups_bucket_date ON channel_monitor_daily_rollups (bucket_date);

CREATE TABLE IF NOT EXISTS channel_monitor_aggregation_watermark (
    id INT PRIMARY KEY,
    last_aggregated_date DATE NOT NULL DEFAULT DATE '1970-01-01',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO channel_monitor_aggregation_watermark (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS usage_dashboard_hourly (
    bucket_start TIMESTAMPTZ PRIMARY KEY,
    total_requests BIGINT NOT NULL DEFAULT 0,
    input_tokens BIGINT NOT NULL DEFAULT 0,
    output_tokens BIGINT NOT NULL DEFAULT 0,
    cache_creation_tokens BIGINT NOT NULL DEFAULT 0,
    cache_read_tokens BIGINT NOT NULL DEFAULT 0,
    total_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    actual_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    account_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    total_duration_ms BIGINT NOT NULL DEFAULT 0,
    active_users BIGINT NOT NULL DEFAULT 0,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_usage_dashboard_hourly_bucket_start ON usage_dashboard_hourly (bucket_start DESC);

CREATE TABLE IF NOT EXISTS usage_dashboard_daily (
    bucket_date DATE PRIMARY KEY,
    total_requests BIGINT NOT NULL DEFAULT 0,
    input_tokens BIGINT NOT NULL DEFAULT 0,
    output_tokens BIGINT NOT NULL DEFAULT 0,
    cache_creation_tokens BIGINT NOT NULL DEFAULT 0,
    cache_read_tokens BIGINT NOT NULL DEFAULT 0,
    total_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    actual_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    account_cost NUMERIC(20,10) NOT NULL DEFAULT 0,
    total_duration_ms BIGINT NOT NULL DEFAULT 0,
    active_users BIGINT NOT NULL DEFAULT 0,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_usage_dashboard_daily_bucket_date ON usage_dashboard_daily (bucket_date DESC);

CREATE TABLE IF NOT EXISTS usage_dashboard_hourly_users (
    bucket_start TIMESTAMPTZ NOT NULL,
    user_id BIGINT NOT NULL,
    PRIMARY KEY (bucket_start, user_id)
);
CREATE INDEX IF NOT EXISTS idx_usage_dashboard_hourly_users_bucket_start ON usage_dashboard_hourly_users (bucket_start);

CREATE TABLE IF NOT EXISTS usage_dashboard_daily_users (
    bucket_date DATE NOT NULL,
    user_id BIGINT NOT NULL,
    PRIMARY KEY (bucket_date, user_id)
);
CREATE INDEX IF NOT EXISTS idx_usage_dashboard_daily_users_bucket_date ON usage_dashboard_daily_users (bucket_date);

CREATE TABLE IF NOT EXISTS usage_dashboard_aggregation_watermark (
    id INT PRIMARY KEY,
    last_aggregated_at TIMESTAMPTZ NOT NULL DEFAULT TIMESTAMPTZ '1970-01-01 00:00:00+00',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO usage_dashboard_aggregation_watermark (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ops_error_logs (
    id BIGSERIAL PRIMARY KEY,
    request_id VARCHAR(64),
    client_request_id VARCHAR(64),
    user_id BIGINT,
    api_key_id BIGINT,
    account_id BIGINT,
    group_id BIGINT,
    client_ip INET,
    platform VARCHAR(32),
    model VARCHAR(100),
    requested_model VARCHAR(100),
    upstream_model VARCHAR(100),
    request_path VARCHAR(256),
    inbound_endpoint TEXT,
    upstream_endpoint TEXT,
    request_type SMALLINT,
    stream BOOLEAN NOT NULL DEFAULT FALSE,
    openai_ws_mode BOOLEAN NOT NULL DEFAULT FALSE,
    user_agent TEXT,
    error_phase VARCHAR(32) NOT NULL,
    error_type VARCHAR(64) NOT NULL,
    severity VARCHAR(8) NOT NULL DEFAULT 'P2',
    status_code INT,
    is_business_limited BOOLEAN NOT NULL DEFAULT FALSE,
    is_count_tokens BOOLEAN NOT NULL DEFAULT FALSE,
    error_message TEXT,
    error_body TEXT,
    error_source VARCHAR(64),
    error_owner VARCHAR(32),
    account_status VARCHAR(50),
    upstream_status_code INT,
    upstream_error_message TEXT,
    upstream_error_detail TEXT,
    upstream_errors JSONB,
    provider_error_code VARCHAR(64),
    provider_error_type VARCHAR(64),
    network_error_type VARCHAR(50),
    retry_after_seconds INT,
    duration_ms INT,
    time_to_first_token_ms BIGINT,
    auth_latency_ms BIGINT,
    routing_latency_ms BIGINT,
    upstream_latency_ms BIGINT,
    response_latency_ms BIGINT,
    request_body JSONB,
    request_headers JSONB,
    request_body_truncated BOOLEAN NOT NULL DEFAULT FALSE,
    request_body_bytes INT,
    is_retryable BOOLEAN NOT NULL DEFAULT FALSE,
    retry_count INT NOT NULL DEFAULT 0,
    attempted_key_prefix VARCHAR(32),
    deleted_key_owner_user_id BIGINT,
    deleted_key_name VARCHAR(100),
    api_key_prefix VARCHAR(32),
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    resolved_by_user_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_created_at ON ops_error_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_platform_time ON ops_error_logs (platform, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_group_time ON ops_error_logs (group_id, created_at DESC) WHERE group_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_account_time ON ops_error_logs (account_id, created_at DESC) WHERE account_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_status_time ON ops_error_logs (status_code, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_phase_time ON ops_error_logs (error_phase, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_type_time ON ops_error_logs (error_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_request_id ON ops_error_logs (request_id);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_client_request_id ON ops_error_logs (client_request_id);
CREATE INDEX IF NOT EXISTS idx_ops_error_logs_resolved_time ON ops_error_logs (resolved, created_at DESC);

CREATE TABLE IF NOT EXISTS ops_system_metrics (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    window_minutes INT NOT NULL DEFAULT 1,
    platform VARCHAR(32),
    group_id BIGINT,
    success_count BIGINT NOT NULL DEFAULT 0,
    error_count_total BIGINT NOT NULL DEFAULT 0,
    business_limited_count BIGINT NOT NULL DEFAULT 0,
    error_count_sla BIGINT NOT NULL DEFAULT 0,
    upstream_error_count_excl_429_529 BIGINT NOT NULL DEFAULT 0,
    upstream_429_count BIGINT NOT NULL DEFAULT 0,
    upstream_529_count BIGINT NOT NULL DEFAULT 0,
    token_consumed BIGINT NOT NULL DEFAULT 0,
    qps DOUBLE PRECISION,
    tps DOUBLE PRECISION,
    duration_p50_ms INT,
    duration_p90_ms INT,
    duration_p95_ms INT,
    duration_p99_ms INT,
    duration_avg_ms DOUBLE PRECISION,
    duration_max_ms INT,
    ttft_p50_ms INT,
    ttft_p90_ms INT,
    ttft_p95_ms INT,
    ttft_p99_ms INT,
    ttft_avg_ms DOUBLE PRECISION,
    ttft_max_ms INT,
    cpu_usage_percent DOUBLE PRECISION,
    memory_used_mb BIGINT,
    memory_total_mb BIGINT,
    memory_usage_percent DOUBLE PRECISION,
    db_ok BOOLEAN,
    redis_ok BOOLEAN,
    db_conn_active INT,
    db_conn_idle INT,
    db_conn_waiting INT,
    redis_conn_total INT,
    redis_conn_idle INT,
    goroutine_count INT,
    concurrency_queue_depth INT,
    account_switch_count BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_ops_system_metrics_created_at ON ops_system_metrics (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_system_metrics_window_time ON ops_system_metrics (window_minutes, created_at DESC);

CREATE TABLE IF NOT EXISTS ops_job_heartbeats (
    job_name VARCHAR(64) PRIMARY KEY,
    last_run_at TIMESTAMPTZ,
    last_success_at TIMESTAMPTZ,
    last_error_at TIMESTAMPTZ,
    last_error TEXT,
    last_duration_ms BIGINT,
    last_result JSONB,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ops_alert_rules (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE,
    description TEXT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    severity VARCHAR(16) NOT NULL DEFAULT 'warning',
    metric_type VARCHAR(64) NOT NULL,
    operator VARCHAR(8) NOT NULL,
    threshold DOUBLE PRECISION NOT NULL,
    window_minutes INT NOT NULL DEFAULT 5,
    sustained_minutes INT NOT NULL DEFAULT 5,
    cooldown_minutes INT NOT NULL DEFAULT 10,
    filters JSONB,
    notify_email BOOLEAN NOT NULL DEFAULT TRUE,
    last_triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ops_alert_rules_enabled ON ops_alert_rules (enabled);

CREATE TABLE IF NOT EXISTS ops_alert_events (
    id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT REFERENCES ops_alert_rules(id) ON DELETE SET NULL,
    severity VARCHAR(16) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'firing',
    title VARCHAR(200),
    description TEXT,
    metric_value DOUBLE PRECISION,
    threshold_value DOUBLE PRECISION,
    dimensions JSONB,
    fired_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    email_sent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ops_alert_events_rule_status ON ops_alert_events (rule_id, status);
CREATE INDEX IF NOT EXISTS idx_ops_alert_events_fired_at ON ops_alert_events (fired_at DESC);

CREATE TABLE IF NOT EXISTS ops_alert_silences (
    id BIGSERIAL PRIMARY KEY,
    rule_id BIGINT REFERENCES ops_alert_rules(id) ON DELETE CASCADE,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    reason TEXT NOT NULL DEFAULT '',
    created_by_user_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ops_alert_silences_rule_time ON ops_alert_silences (rule_id, starts_at, ends_at);

CREATE TABLE IF NOT EXISTS ops_metrics_hourly (
    id BIGSERIAL PRIMARY KEY,
    bucket_start TIMESTAMPTZ NOT NULL,
    platform VARCHAR(32),
    group_id BIGINT,
    success_count BIGINT NOT NULL DEFAULT 0,
    error_count_total BIGINT NOT NULL DEFAULT 0,
    business_limited_count BIGINT NOT NULL DEFAULT 0,
    error_count_sla BIGINT NOT NULL DEFAULT 0,
    upstream_error_count_excl_429_529 BIGINT NOT NULL DEFAULT 0,
    upstream_429_count BIGINT NOT NULL DEFAULT 0,
    upstream_529_count BIGINT NOT NULL DEFAULT 0,
    token_consumed BIGINT NOT NULL DEFAULT 0,
    duration_p50_ms INT,
    duration_p90_ms INT,
    duration_p95_ms INT,
    duration_p99_ms INT,
    duration_avg_ms DOUBLE PRECISION,
    duration_max_ms INT,
    ttft_p50_ms INT,
    ttft_p90_ms INT,
    ttft_p95_ms INT,
    ttft_p99_ms INT,
    ttft_avg_ms DOUBLE PRECISION,
    ttft_max_ms INT,
    ttft_sample_count BIGINT NOT NULL DEFAULT 0,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_ops_metrics_hourly_unique_dim
    ON ops_metrics_hourly (bucket_start, COALESCE(platform, ''), COALESCE(group_id, 0));
CREATE INDEX IF NOT EXISTS idx_ops_metrics_hourly_bucket ON ops_metrics_hourly (bucket_start DESC);

CREATE TABLE IF NOT EXISTS ops_metrics_daily (
    id BIGSERIAL PRIMARY KEY,
    bucket_date DATE NOT NULL,
    platform VARCHAR(32),
    group_id BIGINT,
    success_count BIGINT NOT NULL DEFAULT 0,
    error_count_total BIGINT NOT NULL DEFAULT 0,
    business_limited_count BIGINT NOT NULL DEFAULT 0,
    error_count_sla BIGINT NOT NULL DEFAULT 0,
    upstream_error_count_excl_429_529 BIGINT NOT NULL DEFAULT 0,
    upstream_429_count BIGINT NOT NULL DEFAULT 0,
    upstream_529_count BIGINT NOT NULL DEFAULT 0,
    token_consumed BIGINT NOT NULL DEFAULT 0,
    duration_p50_ms INT,
    duration_p90_ms INT,
    duration_p95_ms INT,
    duration_p99_ms INT,
    duration_avg_ms DOUBLE PRECISION,
    duration_max_ms INT,
    ttft_p50_ms INT,
    ttft_p90_ms INT,
    ttft_p95_ms INT,
    ttft_p99_ms INT,
    ttft_avg_ms DOUBLE PRECISION,
    ttft_max_ms INT,
    ttft_sample_count BIGINT NOT NULL DEFAULT 0,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_ops_metrics_daily_unique_dim
    ON ops_metrics_daily (bucket_date, COALESCE(platform, ''), COALESCE(group_id, 0));
CREATE INDEX IF NOT EXISTS idx_ops_metrics_daily_bucket ON ops_metrics_daily (bucket_date DESC);

CREATE TABLE IF NOT EXISTS ops_system_logs (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    level VARCHAR(16) NOT NULL,
    component VARCHAR(128) NOT NULL DEFAULT '',
    message TEXT NOT NULL,
    request_id VARCHAR(128),
    client_request_id VARCHAR(128),
    user_id BIGINT,
    account_id BIGINT,
    platform VARCHAR(32),
    model VARCHAR(128),
    extra JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS idx_ops_system_logs_created_at_id ON ops_system_logs (created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_ops_system_logs_level_created_at ON ops_system_logs (level, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_system_logs_component_created_at ON ops_system_logs (component, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_system_logs_request_id ON ops_system_logs (request_id);
CREATE INDEX IF NOT EXISTS idx_ops_system_logs_client_request_id ON ops_system_logs (client_request_id);

CREATE TABLE IF NOT EXISTS ops_system_log_cleanup_audits (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    operator_id BIGINT NOT NULL,
    conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
    deleted_rows BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_ops_system_log_cleanup_audits_created_at
    ON ops_system_log_cleanup_audits (created_at DESC, id DESC);

CREATE TABLE IF NOT EXISTS deleted_api_key_audits (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(128) NOT NULL,
    api_key_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    key_name VARCHAR(100) NOT NULL DEFAULT '',
    deleted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS deletedapikeyaudit_key ON deleted_api_key_audits (key);
CREATE INDEX IF NOT EXISTS deletedapikeyaudit_user_id ON deleted_api_key_audits (user_id);

CREATE TABLE IF NOT EXISTS idempotency_records (
    id BIGSERIAL PRIMARY KEY,
    scope VARCHAR(128) NOT NULL,
    idempotency_key_hash VARCHAR(64) NOT NULL,
    request_fingerprint VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,
    response_status INT,
    response_body TEXT,
    error_reason VARCHAR(128),
    locked_until TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (scope, idempotency_key_hash)
);
CREATE INDEX IF NOT EXISTS idempotency_records_expires_at ON idempotency_records (expires_at);
CREATE INDEX IF NOT EXISTS idempotency_records_status_locked_until ON idempotency_records (status, locked_until);

CREATE TABLE IF NOT EXISTS error_passthrough_rules (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    priority INT NOT NULL DEFAULT 0,
    error_codes JSONB,
    keywords JSONB,
    match_mode VARCHAR(10) NOT NULL DEFAULT 'any',
    platforms JSONB,
    passthrough_code BOOLEAN NOT NULL DEFAULT TRUE,
    response_code INT,
    passthrough_body BOOLEAN NOT NULL DEFAULT TRUE,
    custom_message TEXT,
    skip_monitoring BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS errorpassthroughrule_enabled ON error_passthrough_rules (enabled);
CREATE INDEX IF NOT EXISTS errorpassthroughrule_priority ON error_passthrough_rules (priority);

CREATE TABLE IF NOT EXISTS tls_fingerprint_profiles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    enable_grease BOOLEAN NOT NULL DEFAULT FALSE,
    cipher_suites JSONB,
    curves JSONB,
    point_formats JSONB,
    signature_algorithms JSONB,
    alpn_protocols JSONB,
    supported_versions JSONB,
    key_share_groups JSONB,
    psk_modes JSONB,
    extensions JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS usage_cleanup_tasks (
    id BIGSERIAL PRIMARY KEY,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    filters JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_by BIGINT NOT NULL,
    deleted_rows BIGINT NOT NULL DEFAULT 0,
    error_message TEXT,
    canceled_by BIGINT,
    canceled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS usagecleanuptask_status_created_at ON usage_cleanup_tasks (status, created_at);
CREATE INDEX IF NOT EXISTS usagecleanuptask_created_at ON usage_cleanup_tasks (created_at);
CREATE INDEX IF NOT EXISTS usagecleanuptask_canceled_at ON usage_cleanup_tasks (canceled_at);

CREATE TABLE IF NOT EXISTS scheduled_test_plans (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    model_id VARCHAR(200) NOT NULL,
    cron_expression VARCHAR(100) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    max_results INT NOT NULL DEFAULT 50,
    auto_recover BOOLEAN NOT NULL DEFAULT FALSE,
    last_run_at TIMESTAMPTZ,
    next_run_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS scheduled_test_plans_account_id ON scheduled_test_plans (account_id);
CREATE INDEX IF NOT EXISTS scheduled_test_plans_due ON scheduled_test_plans (enabled, next_run_at);

CREATE TABLE IF NOT EXISTS scheduled_test_results (
    id BIGSERIAL PRIMARY KEY,
    plan_id BIGINT REFERENCES scheduled_test_plans(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    response_text TEXT NOT NULL DEFAULT '',
    error_message TEXT NOT NULL DEFAULT '',
    latency_ms BIGINT NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS scheduled_test_results_plan_created ON scheduled_test_results (plan_id, created_at DESC);

CREATE TABLE IF NOT EXISTS content_moderation_logs (
    id BIGSERIAL PRIMARY KEY,
    request_id VARCHAR(128) NOT NULL DEFAULT '',
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    user_email VARCHAR(255) NOT NULL DEFAULT '',
    api_key_id BIGINT REFERENCES api_keys(id) ON DELETE SET NULL,
    api_key_name VARCHAR(100) NOT NULL DEFAULT '',
    group_id BIGINT REFERENCES groups(id) ON DELETE SET NULL,
    group_name VARCHAR(255) NOT NULL DEFAULT '',
    endpoint VARCHAR(128) NOT NULL DEFAULT '',
    provider VARCHAR(64) NOT NULL DEFAULT '',
    model VARCHAR(255) NOT NULL DEFAULT '',
    mode VARCHAR(32) NOT NULL DEFAULT '',
    action VARCHAR(32) NOT NULL DEFAULT '',
    flagged BOOLEAN NOT NULL DEFAULT FALSE,
    highest_category VARCHAR(64) NOT NULL DEFAULT '',
    highest_score NUMERIC(8,6) NOT NULL DEFAULT 0,
    category_scores JSONB NOT NULL DEFAULT '{}'::jsonb,
    threshold_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
    input_excerpt TEXT NOT NULL DEFAULT '',
    upstream_latency_ms INT,
    error TEXT NOT NULL DEFAULT '',
    violation_count INT NOT NULL DEFAULT 0,
    auto_banned BOOLEAN NOT NULL DEFAULT FALSE,
    email_sent BOOLEAN NOT NULL DEFAULT FALSE,
    queue_delay_ms INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_created_at ON content_moderation_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_group_created_at ON content_moderation_logs (group_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_flagged_created_at ON content_moderation_logs (flagged, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_user_created_at ON content_moderation_logs (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_api_key_created_at ON content_moderation_logs (api_key_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_moderation_logs_endpoint_created_at ON content_moderation_logs (endpoint, created_at DESC);

INSERT INTO settings (key, value)
VALUES
    ('site_name', 'Nexus Relay'),
    ('site_description', 'Internal model gateway'),
    ('auth_source_default_email_concurrency', '5'),
    ('auth_source_default_email_grant_on_signup', 'false'),
    ('auth_source_default_email_grant_on_first_bind', 'false'),
    ('auth_source_default_oidc_concurrency', '5'),
    ('auth_source_default_oidc_grant_on_signup', 'false'),
    ('auth_source_default_oidc_grant_on_first_bind', 'false'),
    ('force_email_on_oidc_account_creation', 'false'),
    ('risk_control_enabled', 'false')
ON CONFLICT (key) DO NOTHING;
