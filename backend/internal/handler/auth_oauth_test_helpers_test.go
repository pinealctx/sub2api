package handler

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/require"
)

func findCookie(cookies []*http.Cookie, name string) *http.Cookie {
	for _, cookie := range cookies {
		if cookie.Name == name {
			return cookie
		}
	}
	return nil
}

func decodeCookieValueForTest(t *testing.T, value string) string {
	t.Helper()
	decoded, err := decodeCookieValue(value)
	require.NoError(t, err)
	return decoded
}
