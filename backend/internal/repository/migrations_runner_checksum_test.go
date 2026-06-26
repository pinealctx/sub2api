package repository

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestIsMigrationChecksumCompatible_InternalBaselineHasNoLegacyExceptions(t *testing.T) {
	require.Empty(t, migrationChecksumCompatibilityRules)
	require.False(t, isMigrationChecksumCompatible(
		"001_internal_core_baseline.sql",
		"db-checksum",
		"file-checksum",
	))
}
