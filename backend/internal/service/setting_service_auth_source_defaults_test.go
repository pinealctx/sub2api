//go:build unit

package service

import (
	"context"
	"testing"

	"github.com/Wei-Shaw/sub2api/internal/config"
	"github.com/stretchr/testify/require"
)

type authSourceDefaultsRepoStub struct {
	values  map[string]string
	updates map[string]string
}

func (s *authSourceDefaultsRepoStub) Get(ctx context.Context, key string) (*Setting, error) {
	panic("unexpected Get call")
}

func (s *authSourceDefaultsRepoStub) GetValue(ctx context.Context, key string) (string, error) {
	panic("unexpected GetValue call")
}

func (s *authSourceDefaultsRepoStub) Set(ctx context.Context, key, value string) error {
	panic("unexpected Set call")
}

func (s *authSourceDefaultsRepoStub) GetMultiple(ctx context.Context, keys []string) (map[string]string, error) {
	out := make(map[string]string, len(keys))
	for _, key := range keys {
		if value, ok := s.values[key]; ok {
			out[key] = value
		}
	}
	return out, nil
}

func (s *authSourceDefaultsRepoStub) SetMultiple(ctx context.Context, settings map[string]string) error {
	s.updates = make(map[string]string, len(settings))
	for key, value := range settings {
		s.updates[key] = value
		if s.values == nil {
			s.values = map[string]string{}
		}
		s.values[key] = value
	}
	return nil
}

func (s *authSourceDefaultsRepoStub) GetAll(ctx context.Context) (map[string]string, error) {
	panic("unexpected GetAll call")
}

func (s *authSourceDefaultsRepoStub) Delete(ctx context.Context, key string) error {
	panic("unexpected Delete call")
}

func TestSettingService_GetAuthSourceDefaultSettings_ParsesInternalProviders(t *testing.T) {
	repo := &authSourceDefaultsRepoStub{
		values: map[string]string{
			SettingKeyAuthSourceDefaultEmailConcurrency:      "7",
			SettingKeyAuthSourceDefaultEmailGrantOnSignup:    "false",
			SettingKeyAuthSourceDefaultEmailGrantOnFirstBind: "true",
			SettingKeyAuthSourceDefaultOIDCConcurrency:       "9",
			SettingKeyAuthSourceDefaultOIDCGrantOnSignup:     "true",
			SettingKeyAuthSourceDefaultOIDCGrantOnFirstBind:  "false",
			SettingKeyAuthSourcePlatformQuotas("oidc"):       `{"anthropic":{"daily":12.5}}`,
			SettingKeyForceEmailOnOIDCAccountCreation:        "true",
		},
	}
	svc := NewSettingService(repo, &config.Config{})

	got, err := svc.GetAuthSourceDefaultSettings(context.Background())
	require.NoError(t, err)
	require.Equal(t, 7, got.Email.Concurrency)
	require.False(t, got.Email.GrantOnSignup)
	require.True(t, got.Email.GrantOnFirstBind)
	require.Equal(t, 9, got.OIDC.Concurrency)
	require.True(t, got.OIDC.GrantOnSignup)
	require.False(t, got.OIDC.GrantOnFirstBind)
	require.True(t, got.ForceEmailOnOIDCAccountCreation)
	require.NotNil(t, got.OIDC.PlatformQuotas["anthropic"])
	require.NotNil(t, got.OIDC.PlatformQuotas["anthropic"].DailyLimitUSD)
	require.InDelta(t, 12.5, *got.OIDC.PlatformQuotas["anthropic"].DailyLimitUSD, 0.000001)
}

func TestSettingService_UpdateAuthSourceDefaultSettings_PersistsInternalProviders(t *testing.T) {
	daily := 3.5
	repo := &authSourceDefaultsRepoStub{}
	svc := NewSettingService(repo, &config.Config{})

	err := svc.UpdateAuthSourceDefaultSettings(context.Background(), &AuthSourceDefaultSettings{
		Email: ProviderDefaultGrantSettings{
			Concurrency:      3,
			GrantOnSignup:    false,
			GrantOnFirstBind: true,
		},
		OIDC: ProviderDefaultGrantSettings{
			Concurrency:      5,
			GrantOnSignup:    true,
			GrantOnFirstBind: false,
			PlatformQuotas: map[string]*DefaultPlatformQuotaSetting{
				"anthropic": {DailyLimitUSD: &daily},
			},
		},
	})

	require.NoError(t, err)
	require.Equal(t, "3", repo.updates[SettingKeyAuthSourceDefaultEmailConcurrency])
	require.Equal(t, "false", repo.updates[SettingKeyAuthSourceDefaultEmailGrantOnSignup])
	require.Equal(t, "true", repo.updates[SettingKeyAuthSourceDefaultEmailGrantOnFirstBind])
	require.Equal(t, "5", repo.updates[SettingKeyAuthSourceDefaultOIDCConcurrency])
	require.Equal(t, "true", repo.updates[SettingKeyAuthSourceDefaultOIDCGrantOnSignup])
	require.Equal(t, "false", repo.updates[SettingKeyAuthSourceDefaultOIDCGrantOnFirstBind])
	require.JSONEq(t, `{"anthropic":{"daily":3.5,"weekly":null,"monthly":null}}`, repo.updates[SettingKeyAuthSourcePlatformQuotas("oidc")])
}
