<template>
  <AppLayout>
    <div class="mx-auto flex max-w-6xl flex-col gap-6">
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 class="text-2xl font-semibold text-gray-900 dark:text-white">
            {{ t("admin.settings.title") }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Internal gateway configuration
          </p>
        </div>
        <button class="btn btn-primary" :disabled="saving || loading" @click="saveSettings">
          <Icon name="check" size="md" class="mr-2" />
          {{ saving ? t("common.saving") : t("common.save") }}
        </button>
      </div>

      <div class="flex flex-wrap gap-2">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          type="button"
          :class="['btn btn-sm', activeTab === tab.key ? 'btn-primary' : 'btn-secondary']"
          @click="activeTab = tab.key"
        >
          <Icon :name="tab.icon" size="sm" class="mr-1.5" />
          {{ tab.label }}
        </button>
      </div>

      <div v-if="loading" class="card flex items-center justify-center py-16">
        <Icon name="refresh" size="lg" class="animate-spin text-gray-400" />
      </div>

      <div v-else class="space-y-6">
        <section v-show="activeTab === 'site'" class="settings-section">
          <SectionHeader title="Site" description="Internal branding and public metadata." />
          <div class="settings-grid">
            <Field label="Site name">
              <input v-model.trim="form.site_name" class="input" />
            </Field>
            <Field label="Site subtitle">
              <input v-model.trim="form.site_subtitle" class="input" />
            </Field>
            <Field label="Logo URL">
              <input v-model.trim="form.site_logo" class="input" />
            </Field>
            <Field label="API base URL">
              <input v-model.trim="form.api_base_url" class="input" />
            </Field>
            <Field label="Frontend URL">
              <input v-model.trim="form.frontend_url" class="input" />
            </Field>
            <Field label="Documentation URL">
              <input v-model.trim="form.doc_url" class="input" />
            </Field>
          </div>
          <Field label="Contact info">
            <textarea v-model.trim="form.contact_info" class="input min-h-24" />
          </Field>
          <ToggleRow v-model="form.hide_ccs_import_button" label="Hide CCS import button" />
          <ToggleRow v-model="form.available_channels_enabled" label="Show available channels to members" />
          <ToggleRow v-model="form.allow_user_view_error_requests" label="Allow members to inspect failed requests" />
        </section>

        <section v-show="activeTab === 'auth'" class="settings-section">
          <SectionHeader title="Authentication" description="Email password login, OIDC, TOTP, and verification controls." />
          <div class="settings-grid">
            <ToggleRow v-model="form.email_verify_enabled" label="Require email verification where applicable" />
            <ToggleRow v-model="form.invitation_code_enabled" label="Require invitation code for OIDC-created users" />
            <ToggleRow v-model="form.force_email_on_oidc_account_creation" label="Require email during OIDC account creation" />
            <ToggleRow v-model="form.totp_enabled" label="Enable TOTP two-factor authentication" />
            <ToggleRow v-model="form.turnstile_enabled" label="Enable Cloudflare Turnstile" />
            <Field label="Turnstile site key">
              <input v-model.trim="form.turnstile_site_key" class="input" />
            </Field>
            <Field label="Turnstile secret key">
              <input v-model.trim="form.turnstile_secret_key" class="input" type="password" autocomplete="new-password" />
            </Field>
          </div>

          <div class="mt-6 border-t border-gray-100 pt-6 dark:border-dark-700">
            <div class="settings-grid">
              <ToggleRow v-model="form.oidc_connect_enabled" label="Enable OIDC login" />
              <Field label="Provider name">
                <input v-model.trim="form.oidc_connect_provider_name" class="input" />
              </Field>
              <Field label="Client ID">
                <input v-model.trim="form.oidc_connect_client_id" class="input" />
              </Field>
              <Field label="Client secret">
                <input v-model.trim="form.oidc_connect_client_secret" class="input" type="password" autocomplete="new-password" />
              </Field>
              <Field label="Issuer URL">
                <input v-model.trim="form.oidc_connect_issuer_url" class="input" />
              </Field>
              <Field label="Discovery URL">
                <input v-model.trim="form.oidc_connect_discovery_url" class="input" />
              </Field>
              <Field label="Authorize URL">
                <input v-model.trim="form.oidc_connect_authorize_url" class="input" />
              </Field>
              <Field label="Token URL">
                <input v-model.trim="form.oidc_connect_token_url" class="input" />
              </Field>
              <Field label="Userinfo URL">
                <input v-model.trim="form.oidc_connect_userinfo_url" class="input" />
              </Field>
              <Field label="JWKS URL">
                <input v-model.trim="form.oidc_connect_jwks_url" class="input" />
              </Field>
              <Field label="Scopes">
                <input v-model.trim="form.oidc_connect_scopes" class="input" />
              </Field>
              <Field label="Backend redirect URL">
                <input v-model.trim="form.oidc_connect_redirect_url" class="input" />
              </Field>
              <Field label="Frontend callback">
                <input v-model.trim="form.oidc_connect_frontend_redirect_url" class="input" />
              </Field>
              <Field label="Token auth method">
                <input v-model.trim="form.oidc_connect_token_auth_method" class="input" />
              </Field>
              <Field label="Allowed signing algs">
                <input v-model.trim="form.oidc_connect_allowed_signing_algs" class="input" />
              </Field>
              <Field label="Clock skew seconds">
                <input v-model.number="form.oidc_connect_clock_skew_seconds" class="input" type="number" min="0" />
              </Field>
              <ToggleRow v-model="form.oidc_connect_use_pkce" label="Use PKCE" />
              <ToggleRow v-model="form.oidc_connect_validate_id_token" label="Validate ID token" />
              <ToggleRow v-model="form.oidc_connect_require_email_verified" label="Require verified OIDC email" />
            </div>
          </div>
        </section>

        <section v-show="activeTab === 'gateway'" class="settings-section">
          <SectionHeader title="Gateway" description="Internal scheduling, fallback, and protocol behavior." />
          <div class="settings-grid">
            <Field label="Default concurrency">
              <input v-model.number="form.default_concurrency" class="input" type="number" min="0" />
            </Field>
            <Field label="Default user RPM limit">
              <input v-model.number="form.default_user_rpm_limit" class="input" type="number" min="0" />
            </Field>
            <ToggleRow v-model="form.allow_ungrouped_key_scheduling" label="Allow ungrouped API key scheduling" />
            <ToggleRow v-model="form.openai_advanced_scheduler_enabled" label="Enable OpenAI advanced scheduler" />
            <ToggleRow v-model="form.enable_model_fallback" label="Enable model fallback" />
            <ToggleRow v-model="form.enable_identity_patch" label="Enable identity patch" />
            <ToggleRow v-model="form.enable_fingerprint_unification" label="Enable fingerprint unification" />
            <ToggleRow v-model="form.enable_metadata_passthrough" label="Pass through metadata" />
            <ToggleRow v-model="form.enable_cch_signing" label="Enable CCH signing" />
            <ToggleRow v-model="form.enable_claude_oauth_system_prompt_injection" label="Inject Claude OAuth system prompt" />
            <ToggleRow v-model="form.enable_anthropic_cache_ttl_1h_injection" label="Inject Anthropic 1h cache TTL" />
            <ToggleRow v-model="form.rewrite_message_cache_control" label="Rewrite message cache control" />
            <ToggleRow v-model="form.openai_allow_claude_code_codex_plugin" label="Allow Claude Code Codex plugin" />
            <Field label="Anthropic fallback model">
              <input v-model.trim="form.fallback_model_anthropic" class="input" />
            </Field>
            <Field label="OpenAI fallback model">
              <input v-model.trim="form.fallback_model_openai" class="input" />
            </Field>
            <Field label="Gemini fallback model">
              <input v-model.trim="form.fallback_model_gemini" class="input" />
            </Field>
            <Field label="Antigravity fallback model">
              <input v-model.trim="form.fallback_model_antigravity" class="input" />
            </Field>
            <Field label="Minimum Claude Code version">
              <input v-model.trim="form.min_claude_code_version" class="input" />
            </Field>
            <Field label="Maximum Claude Code version">
              <input v-model.trim="form.max_claude_code_version" class="input" />
            </Field>
            <Field label="Antigravity User-Agent version">
              <input v-model.trim="form.antigravity_user_agent_version" class="input" />
            </Field>
            <Field label="OpenAI Codex User-Agent">
              <input v-model.trim="form.openai_codex_user_agent" class="input" />
            </Field>
          </div>
          <Field label="Identity patch prompt">
            <textarea v-model="form.identity_patch_prompt" class="input min-h-28 font-mono text-xs" />
          </Field>
          <Field label="Claude OAuth system prompt">
            <textarea v-model="form.claude_oauth_system_prompt" class="input min-h-32 font-mono text-xs" />
          </Field>
        </section>

        <section v-show="activeTab === 'ops'" class="settings-section">
          <SectionHeader title="Ops" description="Monitoring, risk controls, and system email." />
          <div class="settings-grid">
            <ToggleRow v-model="form.ops_monitoring_enabled" label="Enable Ops monitoring" />
            <ToggleRow v-model="form.ops_realtime_monitoring_enabled" label="Enable realtime Ops monitoring" />
            <Field label="Ops metrics interval seconds">
              <input v-model.number="form.ops_metrics_interval_seconds" class="input" type="number" min="5" />
            </Field>
            <Field label="Ops query mode">
              <select v-model="form.ops_query_mode_default" class="input">
                <option value="auto">auto</option>
                <option value="raw">raw</option>
                <option value="preagg">preagg</option>
              </select>
            </Field>
            <ToggleRow v-model="form.channel_monitor_enabled" label="Enable channel monitor" />
            <Field label="Channel monitor interval seconds">
              <input v-model.number="form.channel_monitor_default_interval_seconds" class="input" type="number" min="10" />
            </Field>
            <ToggleRow v-model="form.risk_control_enabled" label="Enable risk control" />
            <ToggleRow v-model="form.cyber_session_block_enabled" label="Enable Cyber session block" />
            <Field label="Cyber session block TTL seconds">
              <input v-model.number="form.cyber_session_block_ttl_seconds" class="input" type="number" min="0" />
            </Field>
            <ToggleRow v-model="form.account_quota_notify_enabled" label="Enable account quota notifications" />
          </div>
          <Field label="Account quota notification emails">
            <textarea v-model="accountQuotaEmailsText" class="input min-h-24" placeholder="one email per line" />
          </Field>
        </section>

        <section v-show="activeTab === 'mail'" class="settings-section">
          <SectionHeader title="Mail" description="SMTP delivery and internal email templates." />
          <div class="settings-grid">
            <Field label="SMTP host">
              <input v-model.trim="form.smtp_host" class="input" />
            </Field>
            <Field label="SMTP port">
              <input v-model.number="form.smtp_port" class="input" type="number" min="1" />
            </Field>
            <Field label="SMTP username">
              <input v-model.trim="form.smtp_username" class="input" />
            </Field>
            <Field label="SMTP password">
              <input v-model.trim="form.smtp_password" class="input" type="password" autocomplete="new-password" />
            </Field>
            <Field label="From email">
              <input v-model.trim="form.smtp_from_email" class="input" />
            </Field>
            <Field label="From name">
              <input v-model.trim="form.smtp_from_name" class="input" />
            </Field>
            <ToggleRow v-model="form.smtp_use_tls" label="Use TLS" />
            <Field label="Test recipient">
              <input v-model.trim="testEmail" class="input" type="email" />
            </Field>
          </div>
          <div class="flex flex-wrap gap-3">
            <button class="btn btn-secondary" :disabled="testingSmtp" @click="testSmtp">
              <Icon name="beaker" size="md" class="mr-2" />
              Test SMTP
            </button>
            <button class="btn btn-secondary" :disabled="sendingTestEmail || !testEmail" @click="sendTestEmail">
              <Icon name="mail" size="md" class="mr-2" />
              Send test email
            </button>
          </div>
          <div class="mt-6 border-t border-gray-100 pt-6 dark:border-dark-700">
            <EmailTemplateEditor />
          </div>
        </section>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, reactive, ref } from "vue";
import { useI18n } from "vue-i18n";
import { adminAPI } from "@/api/admin";
import AppLayout from "@/components/layout/AppLayout.vue";
import Icon from "@/components/icons/Icon.vue";
import EmailTemplateEditor from "@/views/admin/settings/EmailTemplateEditor.vue";
import { useAppStore } from "@/stores/app";
import { extractApiErrorMessage } from "@/utils/apiError";
import {
  normalizePlatformQuotasMap,
  sanitizePlatformQuotasMap,
  type SystemSettings,
  type UpdateSettingsRequest,
} from "@/api/admin/settings";
import type { NotifyEmailEntry } from "@/types";

const { t } = useI18n();
const appStore = useAppStore();
type IconName = InstanceType<typeof Icon>["$props"]["name"];

type TabKey = "site" | "auth" | "gateway" | "ops" | "mail";

const tabs: Array<{ key: TabKey; label: string; icon: IconName }> = [
  { key: "site", label: "Site", icon: "cog" },
  { key: "auth", label: "Auth", icon: "shield" },
  { key: "gateway", label: "Gateway", icon: "server" },
  { key: "ops", label: "Ops", icon: "chart" },
  { key: "mail", label: "Mail", icon: "mail" },
];

const activeTab = ref<TabKey>("site");
const loading = ref(true);
const saving = ref(false);
const testingSmtp = ref(false);
const sendingTestEmail = ref(false);
const testEmail = ref("");
const accountQuotaEmailsText = ref("");

const form = reactive<Required<Pick<
  SystemSettings,
  | "email_verify_enabled"
  | "invitation_code_enabled"
  | "password_reset_enabled"
  | "force_email_on_oidc_account_creation"
  | "account_creation_email_suffix_whitelist"
  | "default_concurrency"
  | "default_user_rpm_limit"
  | "site_name"
  | "site_logo"
  | "site_subtitle"
  | "api_base_url"
  | "frontend_url"
  | "contact_info"
  | "doc_url"
  | "home_content"
  | "backend_mode_enabled"
  | "hide_ccs_import_button"
  | "smtp_host"
  | "smtp_port"
  | "smtp_username"
  | "smtp_password"
  | "smtp_from_email"
  | "smtp_from_name"
  | "smtp_use_tls"
  | "turnstile_enabled"
  | "turnstile_site_key"
  | "turnstile_secret_key"
  | "api_key_acl_trust_forwarded_ip"
  | "totp_enabled"
  | "oidc_connect_enabled"
  | "oidc_connect_provider_name"
  | "oidc_connect_client_id"
  | "oidc_connect_client_secret"
  | "oidc_connect_issuer_url"
  | "oidc_connect_discovery_url"
  | "oidc_connect_authorize_url"
  | "oidc_connect_token_url"
  | "oidc_connect_userinfo_url"
  | "oidc_connect_jwks_url"
  | "oidc_connect_scopes"
  | "oidc_connect_redirect_url"
  | "oidc_connect_frontend_redirect_url"
  | "oidc_connect_token_auth_method"
  | "oidc_connect_use_pkce"
  | "oidc_connect_validate_id_token"
  | "oidc_connect_allowed_signing_algs"
  | "oidc_connect_clock_skew_seconds"
  | "oidc_connect_require_email_verified"
  | "enable_model_fallback"
  | "fallback_model_anthropic"
  | "fallback_model_openai"
  | "fallback_model_gemini"
  | "fallback_model_antigravity"
  | "enable_identity_patch"
  | "identity_patch_prompt"
  | "ops_monitoring_enabled"
  | "ops_realtime_monitoring_enabled"
  | "ops_query_mode_default"
  | "ops_metrics_interval_seconds"
  | "min_claude_code_version"
  | "max_claude_code_version"
  | "allow_ungrouped_key_scheduling"
  | "openai_advanced_scheduler_enabled"
  | "enable_fingerprint_unification"
  | "enable_metadata_passthrough"
  | "enable_cch_signing"
  | "enable_claude_oauth_system_prompt_injection"
  | "claude_oauth_system_prompt"
  | "claude_oauth_system_prompt_blocks"
  | "enable_anthropic_cache_ttl_1h_injection"
  | "rewrite_message_cache_control"
  | "antigravity_user_agent_version"
  | "openai_codex_user_agent"
  | "openai_allow_claude_code_codex_plugin"
  | "risk_control_enabled"
  | "cyber_session_block_enabled"
  | "cyber_session_block_ttl_seconds"
  | "account_quota_notify_enabled"
  | "channel_monitor_enabled"
  | "channel_monitor_default_interval_seconds"
  | "available_channels_enabled"
  | "service_quota_enabled"
  | "allow_user_view_error_requests"
>> & { default_platform_quotas: ReturnType<typeof normalizePlatformQuotasMap> }>({
  email_verify_enabled: false,
  invitation_code_enabled: false,
  password_reset_enabled: false,
  force_email_on_oidc_account_creation: false,
  account_creation_email_suffix_whitelist: [],
  default_concurrency: 1,
  default_user_rpm_limit: 0,
  default_platform_quotas: normalizePlatformQuotasMap(),
  site_name: "Internal API Gateway",
  site_logo: "",
  site_subtitle: "",
  api_base_url: "",
  frontend_url: "",
  contact_info: "",
  doc_url: "",
  home_content: "",
  backend_mode_enabled: false,
  hide_ccs_import_button: false,
  smtp_host: "",
  smtp_port: 587,
  smtp_username: "",
  smtp_password: "",
  smtp_from_email: "",
  smtp_from_name: "",
  smtp_use_tls: true,
  turnstile_enabled: false,
  turnstile_site_key: "",
  turnstile_secret_key: "",
  api_key_acl_trust_forwarded_ip: false,
  totp_enabled: false,
  oidc_connect_enabled: false,
  oidc_connect_provider_name: "OIDC",
  oidc_connect_client_id: "",
  oidc_connect_client_secret: "",
  oidc_connect_issuer_url: "",
  oidc_connect_discovery_url: "",
  oidc_connect_authorize_url: "",
  oidc_connect_token_url: "",
  oidc_connect_userinfo_url: "",
  oidc_connect_jwks_url: "",
  oidc_connect_scopes: "openid email profile",
  oidc_connect_redirect_url: "",
  oidc_connect_frontend_redirect_url: "/auth/oidc/callback",
  oidc_connect_token_auth_method: "client_secret_post",
  oidc_connect_use_pkce: false,
  oidc_connect_validate_id_token: false,
  oidc_connect_allowed_signing_algs: "RS256,ES256,PS256",
  oidc_connect_clock_skew_seconds: 120,
  oidc_connect_require_email_verified: false,
  enable_model_fallback: false,
  fallback_model_anthropic: "",
  fallback_model_openai: "",
  fallback_model_gemini: "",
  fallback_model_antigravity: "",
  enable_identity_patch: true,
  identity_patch_prompt: "",
  ops_monitoring_enabled: true,
  ops_realtime_monitoring_enabled: true,
  ops_query_mode_default: "auto",
  ops_metrics_interval_seconds: 60,
  min_claude_code_version: "",
  max_claude_code_version: "",
  allow_ungrouped_key_scheduling: false,
  openai_advanced_scheduler_enabled: false,
  enable_fingerprint_unification: true,
  enable_metadata_passthrough: false,
  enable_cch_signing: false,
  enable_claude_oauth_system_prompt_injection: true,
  claude_oauth_system_prompt: "",
  claude_oauth_system_prompt_blocks: "",
  enable_anthropic_cache_ttl_1h_injection: false,
  rewrite_message_cache_control: false,
  antigravity_user_agent_version: "",
  openai_codex_user_agent: "",
  openai_allow_claude_code_codex_plugin: false,
  risk_control_enabled: false,
  cyber_session_block_enabled: false,
  cyber_session_block_ttl_seconds: 3600,
  account_quota_notify_enabled: false,
  channel_monitor_enabled: true,
  channel_monitor_default_interval_seconds: 60,
  available_channels_enabled: false,
  service_quota_enabled: false,
  allow_user_view_error_requests: false,
});

const SectionHeader = defineComponent({
  props: {
    title: { type: String, required: true },
    description: { type: String, default: "" },
  },
  setup(props) {
    return () =>
      h("div", { class: "mb-5" }, [
        h("h2", { class: "text-lg font-semibold text-gray-900 dark:text-white" }, props.title),
        props.description
          ? h("p", { class: "mt-1 text-sm text-gray-500 dark:text-gray-400" }, props.description)
          : null,
      ]);
  },
});

const Field = defineComponent({
  props: {
    label: { type: String, required: true },
  },
  setup(props, { slots }) {
    return () =>
      h("label", { class: "block space-y-1.5" }, [
        h("span", { class: "input-label" }, props.label),
        slots.default?.(),
      ]);
  },
});

const ToggleRow = defineComponent({
  props: {
    modelValue: { type: Boolean, required: true },
    label: { type: String, required: true },
  },
  emits: ["update:modelValue"],
  setup(props, { emit }) {
    return () =>
      h("label", { class: "flex items-center justify-between gap-4 rounded-xl border border-gray-100 bg-gray-50 px-4 py-3 text-sm dark:border-dark-700 dark:bg-dark-900/40" }, [
        h("span", { class: "font-medium text-gray-700 dark:text-gray-200" }, props.label),
        h("input", {
          type: "checkbox",
          class: "h-4 w-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500",
          checked: props.modelValue,
          onChange: (event: Event) => emit("update:modelValue", (event.target as HTMLInputElement).checked),
        }),
      ]);
  },
});

const parsedQuotaEmails = computed<NotifyEmailEntry[]>(() =>
  accountQuotaEmailsText.value
    .split(/\r?\n|,/)
    .map((email) => email.trim())
    .filter(Boolean)
    .map((email) => ({ email, disabled: false, verified: true })),
);

function applySettings(settings: SystemSettings): void {
  for (const key of Object.keys(form) as Array<keyof typeof form>) {
    if (key === "default_platform_quotas") continue;
    const value = settings[key as keyof SystemSettings];
    if (value !== undefined) {
      (form[key] as unknown) = value as never;
    }
  }
  form.default_platform_quotas = normalizePlatformQuotasMap(settings.default_platform_quotas);
  form.smtp_password = "";
  form.turnstile_secret_key = "";
  form.oidc_connect_client_secret = "";
  accountQuotaEmailsText.value = (settings.account_quota_notify_emails || [])
    .map((item) => item.email)
    .filter(Boolean)
    .join("\n");
}

async function loadSettings(): Promise<void> {
  loading.value = true;
  try {
    applySettings(await adminAPI.settings.getSettings());
  } catch (error) {
    appStore.showError(extractApiErrorMessage(error, t("admin.settings.failedToLoad")));
  } finally {
    loading.value = false;
  }
}

function buildPayload(): UpdateSettingsRequest {
  const payload: UpdateSettingsRequest = {
    ...form,
    default_platform_quotas: sanitizePlatformQuotasMap(form.default_platform_quotas),
    account_quota_notify_emails: parsedQuotaEmails.value,
  };

  if (!form.smtp_password.trim()) {
    delete payload.smtp_password;
  }
  if (!form.turnstile_secret_key.trim()) {
    delete payload.turnstile_secret_key;
  }
  if (!form.oidc_connect_client_secret.trim()) {
    delete payload.oidc_connect_client_secret;
  }

  return payload;
}

async function saveSettings(): Promise<void> {
  saving.value = true;
  try {
    const updated = await adminAPI.settings.updateSettings(buildPayload());
    applySettings(updated);
    appStore.showSuccess(t("admin.settings.saved"));
  } catch (error) {
    appStore.showError(extractApiErrorMessage(error, t("admin.settings.failedToSave")));
  } finally {
    saving.value = false;
  }
}

function smtpPayload() {
  return {
    smtp_host: form.smtp_host,
    smtp_port: Number(form.smtp_port || 587),
    smtp_username: form.smtp_username,
    smtp_password: form.smtp_password,
    smtp_use_tls: form.smtp_use_tls,
  };
}

async function testSmtp(): Promise<void> {
  testingSmtp.value = true;
  try {
    await adminAPI.settings.testSmtpConnection(smtpPayload());
    appStore.showSuccess("SMTP connection succeeded");
  } catch (error) {
    appStore.showError(extractApiErrorMessage(error, "SMTP test failed"));
  } finally {
    testingSmtp.value = false;
  }
}

async function sendTestEmail(): Promise<void> {
  sendingTestEmail.value = true;
  try {
    await adminAPI.settings.sendTestEmail({
      ...smtpPayload(),
      to_email: testEmail.value,
      smtp_from_email: form.smtp_from_email,
      smtp_from_name: form.smtp_from_name,
    });
    appStore.showSuccess("Test email sent");
  } catch (error) {
    appStore.showError(extractApiErrorMessage(error, "Failed to send test email"));
  } finally {
    sendingTestEmail.value = false;
  }
}

onMounted(() => {
  void loadSettings();
});
</script>

<style scoped>
.settings-section {
  @apply card space-y-5 border border-gray-100 bg-white p-6 dark:border-dark-700 dark:bg-dark-900/60;
}

.settings-grid {
  @apply grid gap-4 md:grid-cols-2;
}
</style>
