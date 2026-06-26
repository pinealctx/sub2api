/**
 * Internal admin settings API.
 */

import { apiClient } from "../client";
import type {
  CustomEndpoint,
  CustomMenuItem,
  LoginAgreementDocument,
  NotifyEmailEntry,
} from "@/types";

export type PlatformType = "anthropic" | "openai" | "gemini" | "antigravity";
export type QuotaWindowType = "daily" | "weekly" | "monthly";

export interface PlatformQuotaLimits {
  daily: number | null;
  weekly: number | null;
  monthly: number | null;
}

export type DefaultPlatformQuotasMap = Partial<
  Record<PlatformType, PlatformQuotaLimits>
>;

const PLATFORMS: PlatformType[] = [
  "anthropic",
  "openai",
  "gemini",
  "antigravity",
];

export function normalizePlatformQuotasMap(
  input?: DefaultPlatformQuotasMap | null,
): DefaultPlatformQuotasMap {
  const result: DefaultPlatformQuotasMap = {};
  for (const platform of PLATFORMS) {
    const source = input?.[platform];
    result[platform] = {
      daily: typeof source?.daily === "number" ? source.daily : null,
      weekly: typeof source?.weekly === "number" ? source.weekly : null,
      monthly: typeof source?.monthly === "number" ? source.monthly : null,
    };
  }
  return result;
}

export function sanitizePlatformQuotasMap(
  input?: DefaultPlatformQuotasMap | null,
): DefaultPlatformQuotasMap {
  const clean = (value: unknown): number | null =>
    typeof value === "number" && Number.isFinite(value) && value >= 0
      ? value
      : null;
  const result: DefaultPlatformQuotasMap = {};
  for (const platform of PLATFORMS) {
    const source = input?.[platform];
    result[platform] = {
      daily: clean(source?.daily),
      weekly: clean(source?.weekly),
      monthly: clean(source?.monthly),
    };
  }
  return result;
}

export interface OpenAIFastPolicyRule {
  service_tier: "all" | "priority" | "flex";
  action: "pass" | "filter" | "block";
  scope: "all" | "oauth" | "apikey" | "bedrock";
  error_message?: string;
  model_whitelist?: string[];
  fallback_action?: "pass" | "filter" | "block";
  fallback_error_message?: string;
}

export interface OpenAIFastPolicySettings {
  rules: OpenAIFastPolicyRule[];
}

export interface SystemSettings {
  email_verify_enabled?: boolean;
  invitation_code_enabled?: boolean;
  password_reset_enabled?: boolean;
  force_email_on_oidc_account_creation?: boolean;
  account_creation_email_suffix_whitelist?: string[];
  login_agreement_enabled?: boolean;
  login_agreement_mode?: "modal" | "checkbox" | string;
  login_agreement_updated_at?: string;
  login_agreement_documents?: LoginAgreementDocument[];

  default_concurrency?: number;
  default_user_rpm_limit?: number;
  default_platform_quotas?: DefaultPlatformQuotasMap;

  site_name?: string;
  site_logo?: string;
  site_subtitle?: string;
  api_base_url?: string;
  frontend_url?: string;
  contact_info?: string;
  doc_url?: string;
  home_content?: string;
  backend_mode_enabled?: boolean;
  hide_ccs_import_button?: boolean;
  table_default_page_size?: number;
  table_page_size_options?: number[];
  custom_menu_items?: CustomMenuItem[];
  custom_endpoints?: CustomEndpoint[];

  smtp_host?: string;
  smtp_port?: number;
  smtp_username?: string;
  smtp_password?: string;
  smtp_password_configured?: boolean;
  smtp_from_email?: string;
  smtp_from_name?: string;
  smtp_use_tls?: boolean;

  turnstile_enabled?: boolean;
  turnstile_site_key?: string;
  turnstile_secret_key?: string;
  turnstile_secret_key_configured?: boolean;
  totp_enabled?: boolean;
  totp_encryption_key_configured?: boolean;
  api_key_acl_trust_forwarded_ip?: boolean;

  oidc_connect_enabled?: boolean;
  oidc_connect_provider_name?: string;
  oidc_connect_client_id?: string;
  oidc_connect_client_secret?: string;
  oidc_connect_client_secret_configured?: boolean;
  oidc_connect_issuer_url?: string;
  oidc_connect_discovery_url?: string;
  oidc_connect_authorize_url?: string;
  oidc_connect_token_url?: string;
  oidc_connect_userinfo_url?: string;
  oidc_connect_jwks_url?: string;
  oidc_connect_scopes?: string;
  oidc_connect_redirect_url?: string;
  oidc_connect_frontend_redirect_url?: string;
  oidc_connect_token_auth_method?: string;
  oidc_connect_use_pkce?: boolean;
  oidc_connect_validate_id_token?: boolean;
  oidc_connect_allowed_signing_algs?: string;
  oidc_connect_clock_skew_seconds?: number;
  oidc_connect_require_email_verified?: boolean;
  oidc_connect_userinfo_email_path?: string;
  oidc_connect_userinfo_id_path?: string;
  oidc_connect_userinfo_username_path?: string;

  enable_model_fallback?: boolean;
  fallback_model_anthropic?: string;
  fallback_model_openai?: string;
  fallback_model_gemini?: string;
  fallback_model_antigravity?: string;
  enable_identity_patch?: boolean;
  identity_patch_prompt?: string;

  ops_monitoring_enabled?: boolean;
  ops_realtime_monitoring_enabled?: boolean;
  ops_query_mode_default?: "auto" | "raw" | "preagg" | string;
  ops_metrics_interval_seconds?: number;
  min_claude_code_version?: string;
  max_claude_code_version?: string;

  allow_ungrouped_key_scheduling?: boolean;
  openai_advanced_scheduler_enabled?: boolean;
  enable_fingerprint_unification?: boolean;
  enable_metadata_passthrough?: boolean;
  enable_cch_signing?: boolean;
  enable_claude_oauth_system_prompt_injection?: boolean;
  claude_oauth_system_prompt?: string;
  claude_oauth_system_prompt_blocks?: string;
  enable_anthropic_cache_ttl_1h_injection?: boolean;
  rewrite_message_cache_control?: boolean;
  antigravity_user_agent_version?: string;
  openai_codex_user_agent?: string;
  openai_allow_claude_code_codex_plugin?: boolean;

  risk_control_enabled?: boolean;
  cyber_session_block_enabled?: boolean;
  cyber_session_block_ttl_seconds?: number;
  account_quota_notify_enabled?: boolean;
  account_quota_notify_emails?: NotifyEmailEntry[];
  channel_monitor_enabled?: boolean;
  channel_monitor_default_interval_seconds?: number;
  available_channels_enabled?: boolean;
  service_quota_enabled?: boolean;
  openai_fast_policy_settings?: OpenAIFastPolicySettings;
  allow_user_view_error_requests?: boolean;
}

export type UpdateSettingsRequest = Partial<SystemSettings>;

export async function getSettings(): Promise<SystemSettings> {
  const { data } = await apiClient.get<SystemSettings>("/admin/settings");
  return data;
}

export async function updateSettings(
  settings: UpdateSettingsRequest,
): Promise<SystemSettings> {
  const { data } = await apiClient.put<SystemSettings>(
    "/admin/settings",
    settings,
  );
  return data;
}

export interface TestSmtpRequest {
  smtp_host: string;
  smtp_port: number;
  smtp_username: string;
  smtp_password: string;
  smtp_use_tls: boolean;
}

export async function testSmtpConnection(
  config: TestSmtpRequest,
): Promise<{ message: string }> {
  const { data } = await apiClient.post<{ message: string }>(
    "/admin/settings/test-smtp",
    config,
  );
  return data;
}

export interface SendTestEmailRequest extends TestSmtpRequest {
  to_email: string;
  smtp_from_email?: string;
  smtp_from_name?: string;
}

export async function sendTestEmail(
  config: SendTestEmailRequest,
): Promise<{ message: string }> {
  const { data } = await apiClient.post<{ message: string }>(
    "/admin/settings/send-test-email",
    config,
  );
  return data;
}

export interface EmailTemplateOption {
  event: string;
  label?: string;
  description?: string;
  category?: string;
  optional?: boolean;
}

export type EmailTemplateEventOption = string | EmailTemplateOption;

export interface EmailTemplateSummary {
  event: string;
  locale: string;
  subject: string;
  is_custom?: boolean;
  updated_at?: string;
}

export interface EmailTemplateListResponse {
  events: EmailTemplateEventOption[];
  locales: string[];
  templates?: EmailTemplateSummary[];
  placeholders?: string[];
}

export interface EmailTemplateDetail {
  event: string;
  locale: string;
  subject: string;
  html: string;
  is_custom?: boolean;
  updated_at?: string;
  placeholders?: string[];
}

export interface UpdateEmailTemplateRequest {
  subject: string;
  html: string;
}

export interface PreviewEmailTemplateRequest extends UpdateEmailTemplateRequest {
  event: string;
  locale: string;
}

export interface EmailTemplatePreviewResponse {
  subject: string;
  html: string;
}

export async function getEmailTemplates(): Promise<EmailTemplateListResponse> {
  const { data } = await apiClient.get<EmailTemplateListResponse>(
    "/admin/settings/email-templates",
  );
  return data;
}

export async function getEmailTemplate(
  event: string,
  locale: string,
): Promise<EmailTemplateDetail> {
  const { data } = await apiClient.get<EmailTemplateDetail>(
    `/admin/settings/email-templates/${encodeURIComponent(event)}/${encodeURIComponent(locale)}`,
  );
  return data;
}

export async function updateEmailTemplate(
  event: string,
  locale: string,
  request: UpdateEmailTemplateRequest,
): Promise<EmailTemplateDetail> {
  const { data } = await apiClient.put<EmailTemplateDetail>(
    `/admin/settings/email-templates/${encodeURIComponent(event)}/${encodeURIComponent(locale)}`,
    request,
  );
  return data;
}

export async function restoreOfficialEmailTemplate(
  event: string,
  locale: string,
): Promise<EmailTemplateDetail> {
  const { data } = await apiClient.post<EmailTemplateDetail>(
    `/admin/settings/email-templates/${encodeURIComponent(event)}/${encodeURIComponent(locale)}/restore-official`,
  );
  return data;
}

export async function previewEmailTemplate(
  request: PreviewEmailTemplateRequest,
): Promise<EmailTemplatePreviewResponse> {
  const { data } = await apiClient.post<EmailTemplatePreviewResponse>(
    "/admin/settings/email-template-preview",
    request,
  );
  return data;
}

export interface AdminApiKeyStatus {
  exists: boolean;
  masked_key: string;
}

export async function getAdminApiKey(): Promise<AdminApiKeyStatus> {
  const { data } = await apiClient.get<AdminApiKeyStatus>(
    "/admin/settings/admin-api-key",
  );
  return data;
}

export async function regenerateAdminApiKey(): Promise<{ key: string }> {
  const { data } = await apiClient.post<{ key: string }>(
    "/admin/settings/admin-api-key/regenerate",
  );
  return data;
}

export async function deleteAdminApiKey(): Promise<{ message: string }> {
  const { data } = await apiClient.delete<{ message: string }>(
    "/admin/settings/admin-api-key",
  );
  return data;
}

export interface OverloadCooldownSettings {
  enabled: boolean;
  cooldown_minutes: number;
}

export async function getOverloadCooldownSettings(): Promise<OverloadCooldownSettings> {
  const { data } = await apiClient.get<OverloadCooldownSettings>(
    "/admin/settings/overload-cooldown",
  );
  return data;
}

export async function updateOverloadCooldownSettings(
  settings: OverloadCooldownSettings,
): Promise<OverloadCooldownSettings> {
  const { data } = await apiClient.put<OverloadCooldownSettings>(
    "/admin/settings/overload-cooldown",
    settings,
  );
  return data;
}

export interface RateLimit429CooldownSettings {
  enabled: boolean;
  cooldown_seconds: number;
}

export async function getRateLimit429CooldownSettings(): Promise<RateLimit429CooldownSettings> {
  const { data } = await apiClient.get<RateLimit429CooldownSettings>(
    "/admin/settings/rate-limit-429-cooldown",
  );
  return data;
}

export async function updateRateLimit429CooldownSettings(
  settings: RateLimit429CooldownSettings,
): Promise<RateLimit429CooldownSettings> {
  const { data } = await apiClient.put<RateLimit429CooldownSettings>(
    "/admin/settings/rate-limit-429-cooldown",
    settings,
  );
  return data;
}

export interface StreamTimeoutSettings {
  enabled: boolean;
  action: "temp_unsched" | "error" | "none";
  temp_unsched_minutes: number;
  threshold_count: number;
  threshold_window_minutes: number;
}

export async function getStreamTimeoutSettings(): Promise<StreamTimeoutSettings> {
  const { data } = await apiClient.get<StreamTimeoutSettings>(
    "/admin/settings/stream-timeout",
  );
  return data;
}

export async function updateStreamTimeoutSettings(
  settings: StreamTimeoutSettings,
): Promise<StreamTimeoutSettings> {
  const { data } = await apiClient.put<StreamTimeoutSettings>(
    "/admin/settings/stream-timeout",
    settings,
  );
  return data;
}

export interface RectifierSettings {
  enabled: boolean;
  thinking_signature_enabled: boolean;
  thinking_budget_enabled: boolean;
  apikey_signature_enabled: boolean;
  apikey_signature_patterns: string[];
}

export async function getRectifierSettings(): Promise<RectifierSettings> {
  const { data } = await apiClient.get<RectifierSettings>(
    "/admin/settings/rectifier",
  );
  return data;
}

export async function updateRectifierSettings(
  settings: RectifierSettings,
): Promise<RectifierSettings> {
  const { data } = await apiClient.put<RectifierSettings>(
    "/admin/settings/rectifier",
    settings,
  );
  return data;
}

export interface BetaPolicyRule {
  beta_token: string;
  action: "pass" | "filter" | "block";
  scope: "all" | "oauth" | "apikey" | "bedrock";
  error_message?: string;
  model_whitelist?: string[];
  fallback_action?: "pass" | "filter" | "block";
  fallback_error_message?: string;
}

export interface BetaPolicySettings {
  rules: BetaPolicyRule[];
}

export async function getBetaPolicySettings(): Promise<BetaPolicySettings> {
  const { data } = await apiClient.get<BetaPolicySettings>(
    "/admin/settings/beta-policy",
  );
  return data;
}

export async function updateBetaPolicySettings(
  settings: BetaPolicySettings,
): Promise<BetaPolicySettings> {
  const { data } = await apiClient.put<BetaPolicySettings>(
    "/admin/settings/beta-policy",
    settings,
  );
  return data;
}

export interface WebSearchProviderConfig {
  type: "brave" | "tavily";
  api_key: string;
  api_key_configured: boolean;
  quota_limit: number | null;
  quota_reset_anchor_at: number | null;
  quota_used?: number;
  proxy_id: number | null;
  expires_at: number | null;
}

export interface WebSearchEmulationConfig {
  enabled: boolean;
  providers: WebSearchProviderConfig[];
}

export interface WebSearchTestResult {
  provider: string;
  results: { url: string; title: string; snippet: string; page_age?: string }[];
  query: string;
}

export async function getWebSearchEmulationConfig(): Promise<WebSearchEmulationConfig> {
  const { data } = await apiClient.get<WebSearchEmulationConfig>(
    "/admin/settings/web-search-emulation",
  );
  return data;
}

export async function updateWebSearchEmulationConfig(
  config: WebSearchEmulationConfig,
): Promise<WebSearchEmulationConfig> {
  const { data } = await apiClient.put<WebSearchEmulationConfig>(
    "/admin/settings/web-search-emulation",
    config,
  );
  return data;
}

export async function testWebSearchEmulation(
  query: string,
): Promise<WebSearchTestResult> {
  const { data } = await apiClient.post<WebSearchTestResult>(
    "/admin/settings/web-search-emulation/test",
    { query },
  );
  return data;
}

export async function resetWebSearchUsage(payload: {
  provider_type: string;
}): Promise<void> {
  await apiClient.post(
    "/admin/settings/web-search-emulation/reset-usage",
    payload,
  );
}

export const settingsAPI = {
  getSettings,
  updateSettings,
  testSmtpConnection,
  sendTestEmail,
  getEmailTemplates,
  getEmailTemplate,
  updateEmailTemplate,
  restoreOfficialEmailTemplate,
  previewEmailTemplate,
  getAdminApiKey,
  regenerateAdminApiKey,
  deleteAdminApiKey,
  getOverloadCooldownSettings,
  updateOverloadCooldownSettings,
  getRateLimit429CooldownSettings,
  updateRateLimit429CooldownSettings,
  getStreamTimeoutSettings,
  updateStreamTimeoutSettings,
  getRectifierSettings,
  updateRectifierSettings,
  getBetaPolicySettings,
  updateBetaPolicySettings,
  getWebSearchEmulationConfig,
  updateWebSearchEmulationConfig,
  testWebSearchEmulation,
  resetWebSearchUsage,
};

export default settingsAPI;
