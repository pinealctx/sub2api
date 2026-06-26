//go:build unit

package service

import "context"

type authCacheInvalidatorStub struct {
	keys     []string
	userIDs  []int64
	groupIDs []int64
}

func (s *authCacheInvalidatorStub) InvalidateAuthCacheByKey(_ context.Context, key string) {
	s.keys = append(s.keys, key)
}

func (s *authCacheInvalidatorStub) InvalidateAuthCacheByUserID(_ context.Context, userID int64) {
	s.userIDs = append(s.userIDs, userID)
}

func (s *authCacheInvalidatorStub) InvalidateAuthCacheByGroupID(_ context.Context, groupID int64) {
	s.groupIDs = append(s.groupIDs, groupID)
}
