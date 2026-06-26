# Database Migrations

This fork uses a breaking internal schema baseline.

## Policy

- `001_internal_core_baseline.sql` is the only supported starting point.
- Deploy on a new database, or manually rebuild the database before starting this fork.
- Automatic upgrades from the old public SaaS schema are not supported.
- Commercial/public SaaS tables are intentionally absent: payment, orders, plans, user subscriptions, redeem codes, promo codes, affiliate data, announcements, and legacy OAuth compatibility tables.
- Future schema changes should be added as forward-only migrations after the baseline.

## Runner

The custom runner in `internal/repository/migrations_runner.go` still records checksums in `schema_migrations`.

- Regular `*.sql` files run in a transaction.
- `*_notx.sql` files run statement-by-statement without a transaction and are reserved for concurrent index operations.

The baseline does not use `_notx.sql`; all indexes are regular indexes suitable for an empty/new database.
