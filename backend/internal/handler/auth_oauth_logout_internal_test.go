package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
)

func TestLogoutClearsInternalOAuthCookies(t *testing.T) {
	handler := &AuthHandler{}

	recorder := httptest.NewRecorder()
	ginCtx, _ := gin.CreateTestContext(recorder)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	req.AddCookie(&http.Cookie{Name: oauthPendingSessionCookieName, Value: encodeCookieValue("pending-session")})
	req.AddCookie(&http.Cookie{Name: oauthPendingBrowserCookieName, Value: encodeCookieValue("pending-browser")})
	req.AddCookie(&http.Cookie{Name: oauthBindAccessTokenCookieName, Value: "bind-access-token"})
	req.AddCookie(&http.Cookie{Name: oidcOAuthStateCookieName, Value: encodeCookieValue("oidc-state")})
	ginCtx.Request = req

	handler.Logout(ginCtx)

	require.Equal(t, http.StatusOK, recorder.Code)
	cookies := recorder.Result().Cookies()
	for _, name := range []string{
		oauthPendingSessionCookieName,
		oauthPendingBrowserCookieName,
		oauthBindAccessTokenCookieName,
		oidcOAuthStateCookieName,
	} {
		cookie := findCookie(cookies, name)
		require.NotNil(t, cookie, name)
		require.Equal(t, -1, cookie.MaxAge, name)
		require.True(t, cookie.HttpOnly, name)
	}
}
