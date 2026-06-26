package repository

import (
	"context"
	"sync"
	"testing"
	"time"

	dbent "github.com/Wei-Shaw/sub2api/ent"
	"github.com/Wei-Shaw/sub2api/ent/authidentity"
	"github.com/Wei-Shaw/sub2api/ent/identityadoptiondecision"
	"github.com/Wei-Shaw/sub2api/internal/service"
	"github.com/stretchr/testify/require"
)

func TestUserRepositoryBindAuthIdentityToUserIsIdempotentForOIDC(t *testing.T) {
	repo, client := newUserEntRepo(t)
	ctx := context.Background()

	user := &service.User{
		Email:        "oidc-bind@example.com",
		Username:     "oidc-bind",
		PasswordHash: "hash",
		Role:         service.RoleUser,
		Status:       service.StatusActive,
	}
	require.NoError(t, repo.Create(ctx, user))

	first, err := repo.BindAuthIdentityToUser(ctx, BindAuthIdentityInput{
		UserID: user.ID,
		Canonical: AuthIdentityKey{
			ProviderType:    "oidc",
			ProviderKey:     "https://issuer.example",
			ProviderSubject: "subject-123",
		},
		Metadata: map[string]any{"display_name": "first"},
	})
	require.NoError(t, err)
	require.NotNil(t, first)
	require.NotNil(t, first.Identity)

	second, err := repo.BindAuthIdentityToUser(ctx, BindAuthIdentityInput{
		UserID: user.ID,
		Canonical: AuthIdentityKey{
			ProviderType:    "oidc",
			ProviderKey:     "https://issuer.example",
			ProviderSubject: "subject-123",
		},
		Metadata: map[string]any{"display_name": "second"},
	})
	require.NoError(t, err)
	require.NotNil(t, second)
	require.Equal(t, first.Identity.ID, second.Identity.ID)
	require.Equal(t, "second", second.Identity.Metadata["display_name"])

	identityCount, err := client.AuthIdentity.Query().
		Where(
			authidentity.UserIDEQ(user.ID),
			authidentity.ProviderTypeEQ("oidc"),
			authidentity.ProviderSubjectEQ("subject-123"),
		).
		Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 1, identityCount)
}

func TestUserRepositoryUpsertIdentityAdoptionDecisionIsIdempotentUnderConcurrency(t *testing.T) {
	repo, client := newUserEntRepo(t)
	ctx := context.Background()

	user := &service.User{
		Email:        "repo-adoption@example.com",
		Username:     "repo-adoption",
		PasswordHash: "hash",
		Role:         service.RoleUser,
		Status:       service.StatusActive,
	}
	require.NoError(t, repo.Create(ctx, user))

	identity, err := client.AuthIdentity.Create().
		SetUserID(user.ID).
		SetProviderType("oidc").
		SetProviderKey("https://issuer.example").
		SetProviderSubject("subject-repo-adoption").
		SetMetadata(map[string]any{}).
		Save(ctx)
	require.NoError(t, err)

	session, err := client.PendingAuthSession.Create().
		SetSessionToken("pending-repo-adoption").
		SetIntent("bind_current_user").
		SetProviderType("oidc").
		SetProviderKey("https://issuer.example").
		SetProviderSubject("subject-repo-adoption").
		SetExpiresAt(time.Now().UTC().Add(15 * time.Minute)).
		SetUpstreamIdentityClaims(map[string]any{"provider_subject": "subject-repo-adoption"}).
		SetLocalFlowState(map[string]any{"step": "pending"}).
		Save(ctx)
	require.NoError(t, err)

	firstCreateStarted := make(chan struct{})
	releaseFirstCreate := make(chan struct{})
	var firstCreate sync.Once
	client.IdentityAdoptionDecision.Use(func(next dbent.Mutator) dbent.Mutator {
		return dbent.MutateFunc(func(ctx context.Context, m dbent.Mutation) (dbent.Value, error) {
			blocked := false
			if m.Op().Is(dbent.OpCreate) {
				firstCreate.Do(func() {
					blocked = true
					close(firstCreateStarted)
				})
			}
			if blocked {
				<-releaseFirstCreate
			}
			return next.Mutate(ctx, m)
		})
	})

	type adoptionResult struct {
		decision *dbent.IdentityAdoptionDecision
		err      error
	}

	input := IdentityAdoptionDecisionInput{
		PendingAuthSessionID: session.ID,
		IdentityID:           &identity.ID,
		AdoptDisplayName:     true,
		AdoptAvatar:          true,
	}

	results := make(chan adoptionResult, 2)
	go func() {
		decision, err := repo.UpsertIdentityAdoptionDecision(ctx, input)
		results <- adoptionResult{decision: decision, err: err}
	}()

	<-firstCreateStarted

	go func() {
		decision, err := repo.UpsertIdentityAdoptionDecision(ctx, input)
		results <- adoptionResult{decision: decision, err: err}
	}()

	time.Sleep(100 * time.Millisecond)
	close(releaseFirstCreate)

	first := <-results
	second := <-results

	require.NoError(t, first.err)
	require.NoError(t, second.err)
	require.NotNil(t, first.decision)
	require.NotNil(t, second.decision)
	require.Equal(t, first.decision.ID, second.decision.ID)

	count, err := client.IdentityAdoptionDecision.Query().
		Where(identityadoptiondecision.PendingAuthSessionIDEQ(session.ID)).
		Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 1, count)

	loaded, err := client.IdentityAdoptionDecision.Query().
		Where(identityadoptiondecision.PendingAuthSessionIDEQ(session.ID)).
		Only(ctx)
	require.NoError(t, err)
	require.NotNil(t, loaded.IdentityID)
	require.Equal(t, identity.ID, *loaded.IdentityID)
	require.True(t, loaded.AdoptDisplayName)
	require.True(t, loaded.AdoptAvatar)
}
