//go:build unit

package service

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestNormalizeAccountCreationEmailSuffixWhitelist(t *testing.T) {
	got, err := NormalizeAccountCreationEmailSuffixWhitelist([]string{"example.com", "@EXAMPLE.COM", " @foo.bar ", "*.EDU.CN"})
	require.NoError(t, err)
	require.Equal(t, []string{"@example.com", "@foo.bar", "*.edu.cn"}, got)
}

func TestNormalizeAccountCreationEmailSuffixWhitelist_Invalid(t *testing.T) {
	for _, item := range []string{"@invalid_domain", "*.", "*", "*.@", "*.foo"} {
		t.Run(item, func(t *testing.T) {
			_, err := NormalizeAccountCreationEmailSuffixWhitelist([]string{item})
			require.Error(t, err)
		})
	}
}

func TestParseAccountCreationEmailSuffixWhitelist(t *testing.T) {
	got := ParseAccountCreationEmailSuffixWhitelist(`["example.com","@foo.bar","*.EDU.CN","@invalid_domain","*.foo"]`)
	require.Equal(t, []string{"@example.com", "@foo.bar", "*.edu.cn"}, got)
}

func TestIsAccountCreationEmailSuffixAllowed(t *testing.T) {
	require.True(t, IsAccountCreationEmailSuffixAllowed("user@example.com", []string{"@example.com"}))
	require.False(t, IsAccountCreationEmailSuffixAllowed("user@sub.example.com", []string{"@example.com"}))
	require.True(t, IsAccountCreationEmailSuffixAllowed("user@qq.com", []string{"@qq.com"}))
	require.False(t, IsAccountCreationEmailSuffixAllowed("user@sub.qq.com", []string{"@qq.com"}))
	require.True(t, IsAccountCreationEmailSuffixAllowed("student@cs.edu.cn", []string{"*.edu.cn"}))
	require.True(t, IsAccountCreationEmailSuffixAllowed("student@edu.cn", []string{"*.edu.cn"}))
	require.False(t, IsAccountCreationEmailSuffixAllowed("student@foo.cn", []string{"*.edu.cn"}))
	require.True(t, IsAccountCreationEmailSuffixAllowed("user@a.com", []string{"@a.com", "*.b.cn"}))
	require.True(t, IsAccountCreationEmailSuffixAllowed("user@school.b.cn", []string{"@a.com", "*.b.cn"}))
	require.True(t, IsAccountCreationEmailSuffixAllowed("user@b.cn", []string{"@a.com", "*.b.cn"}))
	require.False(t, IsAccountCreationEmailSuffixAllowed("user@c.cn", []string{"@a.com", "*.b.cn"}))
	require.True(t, IsAccountCreationEmailSuffixAllowed("user@any.com", []string{}))
}
