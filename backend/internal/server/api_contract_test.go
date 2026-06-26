//go:build unit

package server_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Wei-Shaw/sub2api/internal/config"
	"github.com/Wei-Shaw/sub2api/internal/handler"
	servermiddleware "github.com/Wei-Shaw/sub2api/internal/server/middleware"
	"github.com/Wei-Shaw/sub2api/internal/server/routes"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
)

func TestInternalAPIRouteContracts(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := buildInternalContractRouter()

	for _, path := range []string{
		"/api/v1/payment/orders",
		"/api/v1/payments/orders",
		"/api/v1/redeem-codes",
		"/api/v1/redeem",
		"/api/v1/subscriptions",
		"/api/v1/subscription-plans",
		"/api/v1/promo-codes",
		"/api/v1/affiliate",
		"/api/v1/announcements",
		"/api/v1/auth/register",
		"/api/v1/auth/oauth/linuxdo/start",
		"/api/v1/auth/oauth/wechat/start",
		"/api/v1/auth/oauth/github/start",
		"/api/v1/auth/oauth/google/start",
		"/api/v1/auth/oauth/dingtalk/start",
	} {
		t.Run("removed "+path, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, path, nil)
			rec := httptest.NewRecorder()

			router.ServeHTTP(rec, req)

			require.Equal(t, http.StatusNotFound, rec.Code)
		})
	}

	registered := registeredRoutes(router)

	for _, route := range []string{
		"POST /api/v1/auth/login",
		"POST /api/v1/auth/refresh",
		"POST /api/v1/auth/logout",
		"GET /api/v1/auth/oauth/oidc/start",
		"GET /api/v1/auth/oauth/oidc/callback",
		"GET /api/v1/auth/me",
		"GET /api/v1/user/profile",
		"GET /api/v1/keys",
		"GET /api/v1/usage",
		"GET /api/v1/admin/dashboard/stats",
		"GET /api/v1/admin/ops/concurrency",
		"GET /api/v1/admin/users",
		"GET /api/v1/admin/groups",
		"GET /api/v1/admin/accounts",
		"GET /api/v1/admin/proxies",
		"POST /v1/messages",
		"GET /v1/models",
		"POST /v1/chat/completions",
		"GET /v1beta/models",
		"POST /backend-api/codex/responses",
	} {
		require.True(t, registered[route], "expected route %s to be registered", route)
	}

	for _, route := range []string{
		"POST /api/v1/auth/register",
		"GET /api/v1/auth/oauth/linuxdo/start",
		"GET /api/v1/auth/oauth/wechat/start",
		"GET /api/v1/auth/oauth/github/start",
		"GET /api/v1/auth/oauth/google/start",
		"GET /api/v1/auth/oauth/dingtalk/start",
		"POST /api/v1/payment/orders",
		"GET /api/v1/redeem-codes",
		"GET /api/v1/subscriptions",
		"GET /api/v1/promo-codes",
		"GET /api/v1/affiliate",
		"GET /api/v1/announcements",
	} {
		require.False(t, registered[route], "removed route %s must not be registered", route)
	}
}

func buildInternalContractRouter() *gin.Engine {
	router := gin.New()
	v1 := router.Group("/api/v1")
	handlers := &handler.Handlers{Admin: &handler.AdminHandlers{}}
	pass := func(c *gin.Context) { c.Next() }

	routes.RegisterAuthRoutes(v1, handlers, servermiddleware.JWTAuthMiddleware(pass), nil, nil)
	routes.RegisterUserRoutes(v1, handlers, servermiddleware.JWTAuthMiddleware(pass), nil)
	routes.RegisterAdminRoutes(v1, handlers, servermiddleware.AdminAuthMiddleware(pass), nil)
	routes.RegisterGatewayRoutes(
		router,
		handlers,
		servermiddleware.APIKeyAuthMiddleware(pass),
		nil,
		nil,
		nil,
		&config.Config{},
	)

	return router
}

func registeredRoutes(router *gin.Engine) map[string]bool {
	out := make(map[string]bool)
	for _, route := range router.Routes() {
		out[route.Method+" "+route.Path] = true
	}
	return out
}
