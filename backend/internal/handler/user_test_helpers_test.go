//go:build unit

package handler

import (
	"context"
	"time"

	"github.com/Wei-Shaw/sub2api/internal/pkg/pagination"
	"github.com/Wei-Shaw/sub2api/internal/service"
)

type userHandlerRepoStub struct {
	user       *service.User
	identities []service.UserAuthIdentityRecord
	unbound    []string
}

func (s *userHandlerRepoStub) Create(context.Context, *service.User) error { return nil }

func (s *userHandlerRepoStub) GetByID(context.Context, int64) (*service.User, error) {
	if s.user == nil {
		return nil, service.ErrUserNotFound
	}
	cloned := *s.user
	return &cloned, nil
}

func (s *userHandlerRepoStub) GetByIDIncludeDeleted(ctx context.Context, id int64) (*service.User, error) {
	return s.GetByID(ctx, id)
}

func (s *userHandlerRepoStub) GetByEmail(context.Context, string) (*service.User, error) {
	if s.user == nil {
		return nil, service.ErrUserNotFound
	}
	cloned := *s.user
	return &cloned, nil
}

func (s *userHandlerRepoStub) GetFirstAdmin(context.Context) (*service.User, error) {
	if s.user == nil {
		return nil, service.ErrUserNotFound
	}
	cloned := *s.user
	return &cloned, nil
}

func (s *userHandlerRepoStub) Update(_ context.Context, user *service.User) error {
	cloned := *user
	s.user = &cloned
	return nil
}

func (s *userHandlerRepoStub) Delete(context.Context, int64) error { return nil }

func (s *userHandlerRepoStub) GetUserAvatar(context.Context, int64) (*service.UserAvatar, error) {
	if s.user == nil || s.user.AvatarURL == "" {
		return nil, nil
	}
	return &service.UserAvatar{
		URL:             s.user.AvatarURL,
		StorageProvider: s.user.AvatarSource,
		ContentType:     s.user.AvatarMIME,
		ByteSize:        s.user.AvatarByteSize,
		SHA256:          s.user.AvatarSHA256,
	}, nil
}

func (s *userHandlerRepoStub) UpsertUserAvatar(_ context.Context, _ int64, input service.UpsertUserAvatarInput) (*service.UserAvatar, error) {
	if s.user == nil {
		s.user = &service.User{}
	}
	s.user.AvatarURL = input.URL
	s.user.AvatarSource = input.StorageProvider
	s.user.AvatarMIME = input.ContentType
	s.user.AvatarByteSize = input.ByteSize
	s.user.AvatarSHA256 = input.SHA256
	return &service.UserAvatar{
		URL:             input.URL,
		StorageProvider: input.StorageProvider,
		ContentType:     input.ContentType,
		ByteSize:        input.ByteSize,
		SHA256:          input.SHA256,
	}, nil
}

func (s *userHandlerRepoStub) DeleteUserAvatar(context.Context, int64) error {
	if s.user != nil {
		s.user.AvatarURL = ""
		s.user.AvatarSource = ""
		s.user.AvatarMIME = ""
		s.user.AvatarByteSize = 0
		s.user.AvatarSHA256 = ""
	}
	return nil
}

func (s *userHandlerRepoStub) List(context.Context, pagination.PaginationParams) ([]service.User, *pagination.PaginationResult, error) {
	return nil, nil, nil
}

func (s *userHandlerRepoStub) ListWithFilters(context.Context, pagination.PaginationParams, service.UserListFilters) ([]service.User, *pagination.PaginationResult, error) {
	return nil, nil, nil
}

func (s *userHandlerRepoStub) GetLatestUsedAtByUserIDs(context.Context, []int64) (map[int64]*time.Time, error) {
	return map[int64]*time.Time{}, nil
}

func (s *userHandlerRepoStub) GetLatestUsedAtByUserID(context.Context, int64) (*time.Time, error) {
	return nil, nil
}

func (s *userHandlerRepoStub) UpdateUserLastActiveAt(_ context.Context, _ int64, activeAt time.Time) error {
	if s.user != nil {
		s.user.LastActiveAt = &activeAt
	}
	return nil
}

func (s *userHandlerRepoStub) UpdateConcurrency(context.Context, int64, int) error { return nil }
func (s *userHandlerRepoStub) BatchSetConcurrency(context.Context, []int64, int) (int, error) {
	return 0, nil
}
func (s *userHandlerRepoStub) BatchAddConcurrency(context.Context, []int64, int) (int, error) {
	return 0, nil
}
func (s *userHandlerRepoStub) ExistsByEmail(context.Context, string) (bool, error) { return false, nil }
func (s *userHandlerRepoStub) RemoveGroupFromAllowedGroups(context.Context, int64) (int64, error) {
	return 0, nil
}
func (s *userHandlerRepoStub) AddGroupToAllowedGroups(context.Context, int64, int64) error {
	return nil
}
func (s *userHandlerRepoStub) RemoveGroupFromUserAllowedGroups(context.Context, int64, int64) error {
	return nil
}
func (s *userHandlerRepoStub) ListUserAuthIdentities(context.Context, int64) ([]service.UserAuthIdentityRecord, error) {
	out := make([]service.UserAuthIdentityRecord, len(s.identities))
	copy(out, s.identities)
	return out, nil
}
func (s *userHandlerRepoStub) UnbindUserAuthProvider(_ context.Context, _ int64, provider string) error {
	s.unbound = append(s.unbound, provider)
	filtered := s.identities[:0]
	for _, identity := range s.identities {
		if identity.ProviderType != provider {
			filtered = append(filtered, identity)
		}
	}
	s.identities = filtered
	return nil
}

func (s *userHandlerRepoStub) UpdateTotpSecret(context.Context, int64, *string) error { return nil }
func (s *userHandlerRepoStub) EnableTotp(context.Context, int64) error                { return nil }
func (s *userHandlerRepoStub) DisableTotp(context.Context, int64) error               { return nil }

type userHandlerRefreshTokenCacheStub struct {
	revokedUserIDs []int64
}

func (s *userHandlerRefreshTokenCacheStub) StoreRefreshToken(context.Context, string, *service.RefreshTokenData, time.Duration) error {
	return nil
}
func (s *userHandlerRefreshTokenCacheStub) GetRefreshToken(context.Context, string) (*service.RefreshTokenData, error) {
	return nil, service.ErrRefreshTokenNotFound
}
func (s *userHandlerRefreshTokenCacheStub) DeleteRefreshToken(context.Context, string) error {
	return nil
}
func (s *userHandlerRefreshTokenCacheStub) DeleteUserRefreshTokens(_ context.Context, userID int64) error {
	s.revokedUserIDs = append(s.revokedUserIDs, userID)
	return nil
}
func (s *userHandlerRefreshTokenCacheStub) DeleteTokenFamily(context.Context, string) error {
	return nil
}
func (s *userHandlerRefreshTokenCacheStub) AddToUserTokenSet(context.Context, int64, string, time.Duration) error {
	return nil
}
func (s *userHandlerRefreshTokenCacheStub) AddToFamilyTokenSet(context.Context, string, string, time.Duration) error {
	return nil
}
func (s *userHandlerRefreshTokenCacheStub) GetUserTokenHashes(context.Context, int64) ([]string, error) {
	return nil, nil
}
func (s *userHandlerRefreshTokenCacheStub) GetFamilyTokenHashes(context.Context, string) ([]string, error) {
	return nil, nil
}
func (s *userHandlerRefreshTokenCacheStub) IsTokenInFamily(context.Context, string, string) (bool, error) {
	return false, nil
}
