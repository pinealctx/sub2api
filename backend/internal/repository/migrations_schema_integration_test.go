//go:build integration

package repository

import (
	"context"
	"database/sql"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestMigrationsRunner_InternalCoreBaselineSchema(t *testing.T) {
	tx := testTx(t)

	require.NoError(t, ApplyMigrations(context.Background(), integrationDB))

	for _, table := range []string{
		"users",
		"api_keys",
		"groups",
		"accounts",
		"account_groups",
		"proxies",
		"usage_logs",
		"settings",
		"auth_identities",
		"pending_auth_sessions",
		"user_allowed_groups",
		"user_attribute_definitions",
		"user_attribute_values",
		"user_platform_quotas",
		"channel_monitors",
		"channel_monitor_histories",
		"channel_monitor_request_templates",
		"ops_error_logs",
		"ops_system_logs",
		"scheduler_outbox",
	} {
		requireTable(t, tx, table)
	}

	for _, table := range []string{
		"payment_orders",
		"payment_audit_logs",
		"payment_provider_instances",
		"redeem_codes",
		"promo_codes",
		"promo_code_usages",
		"affiliate_accounts",
		"affiliate_ledgers",
		"user_subscriptions",
		"subscription_plans",
		"announcements",
		"announcement_reads",
		"auth_identity_channels",
	} {
		requireTableAbsent(t, tx, table)
	}

	requireColumn(t, tx, "users", "signup_source", "character varying", 20, false)
	requireConstraintDefinitionContains(t, tx, "users", "users_signup_source_check", "'email'", "'oidc'")
	requireColumn(t, tx, "api_keys", "key", "character varying", 128, false)
	requireColumn(t, tx, "usage_logs", "request_type", "smallint", 0, false)
	requireColumn(t, tx, "usage_logs", "openai_ws_mode", "boolean", 0, false)
	requireColumn(t, tx, "usage_logs", "account_stats_cost", "numeric", 0, true)
	requireColumn(t, tx, "scheduler_outbox", "dedup_key", "text", 0, true)
	requireIndex(t, tx, "scheduler_outbox", "idx_scheduler_outbox_pending_dedup_key")
}

func requireTable(t *testing.T, tx *sql.Tx, table string) {
	t.Helper()

	var regclass sql.NullString
	require.NoError(t, tx.QueryRowContext(context.Background(), "SELECT to_regclass($1)", "public."+table).Scan(&regclass))
	require.True(t, regclass.Valid, "expected table %s to exist", table)
}

func requireTableAbsent(t *testing.T, tx *sql.Tx, table string) {
	t.Helper()

	var regclass sql.NullString
	require.NoError(t, tx.QueryRowContext(context.Background(), "SELECT to_regclass($1)", "public."+table).Scan(&regclass))
	require.False(t, regclass.Valid, "expected table %s to be absent", table)
}

func requireIndex(t *testing.T, tx *sql.Tx, table, index string) {
	t.Helper()

	var exists bool
	err := tx.QueryRowContext(context.Background(), `
SELECT EXISTS (
	SELECT 1
	FROM pg_indexes
	WHERE schemaname = 'public'
	  AND tablename = $1
	  AND indexname = $2
)
`, table, index).Scan(&exists)
	require.NoError(t, err, "query pg_indexes for %s.%s", table, index)
	require.True(t, exists, "expected index %s on %s", index, table)
}

func requireConstraintDefinitionContains(t *testing.T, tx *sql.Tx, table, constraint string, fragments ...string) {
	t.Helper()

	var def string
	err := tx.QueryRowContext(context.Background(), `
SELECT pg_get_constraintdef(c.oid)
FROM pg_constraint c
JOIN pg_class tbl ON tbl.oid = c.conrelid
JOIN pg_namespace ns ON ns.oid = tbl.relnamespace
WHERE ns.nspname = 'public'
  AND tbl.relname = $1
  AND c.conname = $2
`, table, constraint).Scan(&def)
	require.NoError(t, err, "query constraint definition for %s.%s", table, constraint)

	for _, fragment := range fragments {
		require.Contains(t, def, fragment, "expected constraint definition for %s.%s to contain %q", table, constraint, fragment)
	}
}

func requireColumn(t *testing.T, tx *sql.Tx, table, column, dataType string, maxLen int, nullable bool) {
	t.Helper()

	var row struct {
		DataType string
		MaxLen   sql.NullInt64
		Nullable string
	}

	err := tx.QueryRowContext(context.Background(), `
SELECT
  data_type,
  character_maximum_length,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = $1
  AND column_name = $2
`, table, column).Scan(&row.DataType, &row.MaxLen, &row.Nullable)
	require.NoError(t, err, "query information_schema.columns for %s.%s", table, column)
	require.Equal(t, dataType, row.DataType, "data_type mismatch for %s.%s", table, column)

	if maxLen > 0 {
		require.True(t, row.MaxLen.Valid, "expected maxLen for %s.%s", table, column)
		require.Equal(t, int64(maxLen), row.MaxLen.Int64, "maxLen mismatch for %s.%s", table, column)
	}

	if nullable {
		require.Equal(t, "YES", row.Nullable, "nullable mismatch for %s.%s", table, column)
	} else {
		require.Equal(t, "NO", row.Nullable, "nullable mismatch for %s.%s", table, column)
	}
}
