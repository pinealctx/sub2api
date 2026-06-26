//go:build unit

package service

import (
	"context"
	"time"

	"github.com/Wei-Shaw/sub2api/internal/config"
)

type settingRepoStub struct {
	values map[string]string
	err    error
}

func (s *settingRepoStub) Get(context.Context, string) (*Setting, error) {
	panic("unexpected Get call")
}

func (s *settingRepoStub) GetValue(_ context.Context, key string) (string, error) {
	if s.err != nil {
		return "", s.err
	}
	if value, ok := s.values[key]; ok {
		return value, nil
	}
	return "", ErrSettingNotFound
}

func (s *settingRepoStub) Set(context.Context, string, string) error {
	panic("unexpected Set call")
}

func (s *settingRepoStub) GetMultiple(_ context.Context, keys []string) (map[string]string, error) {
	if s.err != nil {
		return nil, s.err
	}
	out := make(map[string]string, len(keys))
	for _, key := range keys {
		if value, ok := s.values[key]; ok {
			out[key] = value
		}
	}
	return out, nil
}

func (s *settingRepoStub) SetMultiple(context.Context, map[string]string) error {
	panic("unexpected SetMultiple call")
}

func (s *settingRepoStub) GetAll(context.Context) (map[string]string, error) {
	panic("unexpected GetAll call")
}

func (s *settingRepoStub) Delete(context.Context, string) error {
	panic("unexpected Delete call")
}

type refreshTokenCacheStub struct{}

func (s *refreshTokenCacheStub) StoreRefreshToken(context.Context, string, *RefreshTokenData, time.Duration) error {
	return nil
}
func (s *refreshTokenCacheStub) GetRefreshToken(context.Context, string) (*RefreshTokenData, error) {
	return nil, ErrRefreshTokenNotFound
}
func (s *refreshTokenCacheStub) DeleteRefreshToken(context.Context, string) error {
	return nil
}
func (s *refreshTokenCacheStub) DeleteUserRefreshTokens(context.Context, int64) error {
	return nil
}
func (s *refreshTokenCacheStub) DeleteTokenFamily(context.Context, string) error {
	return nil
}
func (s *refreshTokenCacheStub) AddToUserTokenSet(context.Context, int64, string, time.Duration) error {
	return nil
}
func (s *refreshTokenCacheStub) AddToFamilyTokenSet(context.Context, string, string, time.Duration) error {
	return nil
}
func (s *refreshTokenCacheStub) GetUserTokenHashes(context.Context, int64) ([]string, error) {
	return nil, nil
}
func (s *refreshTokenCacheStub) GetFamilyTokenHashes(context.Context, string) ([]string, error) {
	return nil, nil
}
func (s *refreshTokenCacheStub) IsTokenInFamily(context.Context, string, string) (bool, error) {
	return false, nil
}

type userPlatformQuotaRepoStub struct {
	bulkInsertCalls [][]UserPlatformQuotaRecord
	bulkInsertErr   error
}

func (s *userPlatformQuotaRepoStub) BulkInsertInitial(_ context.Context, records []UserPlatformQuotaRecord) error {
	cloned := make([]UserPlatformQuotaRecord, len(records))
	copy(cloned, records)
	s.bulkInsertCalls = append(s.bulkInsertCalls, cloned)
	return s.bulkInsertErr
}

func (s *userPlatformQuotaRepoStub) GetByUserPlatform(context.Context, int64, string) (*UserPlatformQuotaRecord, error) {
	panic("unexpected GetByUserPlatform call")
}
func (s *userPlatformQuotaRepoStub) ListByUser(context.Context, int64) ([]UserPlatformQuotaRecord, error) {
	panic("unexpected ListByUser call")
}
func (s *userPlatformQuotaRepoStub) IncrementUsageWithReset(context.Context, int64, string, float64, time.Time) error {
	panic("unexpected IncrementUsageWithReset call")
}
func (s *userPlatformQuotaRepoStub) UpsertForUser(context.Context, int64, []UserPlatformQuotaRecord) error {
	panic("unexpected UpsertForUser call")
}
func (s *userPlatformQuotaRepoStub) ResetExpiredWindow(context.Context, int64, string, string, time.Time) error {
	panic("unexpected ResetExpiredWindow call")
}
func (s *userPlatformQuotaRepoStub) BatchSnapshotUsage(context.Context, []UserPlatformQuotaSnapshot, time.Time) error {
	return nil
}

func newAuthService(repo *userRepoStub, settings map[string]string, _ EmailCache, quotaRepo UserPlatformQuotaRepository) *AuthService {
	cfg := &config.Config{
		JWT: config.JWTConfig{
			Secret:                   "test-secret",
			ExpireHour:               1,
			AccessTokenExpireMinutes: 60,
			RefreshTokenExpireDays:   7,
		},
		Default: config.DefaultConfig{
			UserConcurrency: 2,
		},
	}
	settingService := NewSettingService(&settingRepoStub{values: settings}, cfg)
	return NewAuthService(nil, repo, &refreshTokenCacheStub{}, cfg, settingService, nil, nil, nil, quotaRepo)
}
