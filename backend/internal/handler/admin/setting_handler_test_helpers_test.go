//go:build unit

package admin

import (
	"context"

	"github.com/Wei-Shaw/sub2api/internal/service"
)

type settingHandlerRepoStub struct {
	values      map[string]string
	lastUpdates map[string]string
}

func (s *settingHandlerRepoStub) Get(context.Context, string) (*service.Setting, error) {
	panic("unexpected Get call")
}

func (s *settingHandlerRepoStub) GetValue(_ context.Context, key string) (string, error) {
	if s.values != nil {
		if value, ok := s.values[key]; ok {
			return value, nil
		}
	}
	return "", service.ErrSettingNotFound
}

func (s *settingHandlerRepoStub) Set(context.Context, string, string) error {
	panic("unexpected Set call")
}

func (s *settingHandlerRepoStub) GetMultiple(_ context.Context, keys []string) (map[string]string, error) {
	out := make(map[string]string, len(keys))
	for _, key := range keys {
		if s.values != nil {
			if value, ok := s.values[key]; ok {
				out[key] = value
			}
		}
	}
	return out, nil
}

func (s *settingHandlerRepoStub) SetMultiple(_ context.Context, settings map[string]string) error {
	s.lastUpdates = make(map[string]string, len(settings))
	if s.values == nil {
		s.values = make(map[string]string, len(settings))
	}
	for key, value := range settings {
		s.lastUpdates[key] = value
		s.values[key] = value
	}
	return nil
}

func (s *settingHandlerRepoStub) GetAll(context.Context) (map[string]string, error) {
	out := make(map[string]string, len(s.values))
	for key, value := range s.values {
		out[key] = value
	}
	return out, nil
}

func (s *settingHandlerRepoStub) Delete(context.Context, string) error {
	panic("unexpected Delete call")
}
