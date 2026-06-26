//go:build integration

package repository

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	dbent "github.com/Wei-Shaw/sub2api/ent"
	"github.com/Wei-Shaw/sub2api/internal/service"
	"github.com/stretchr/testify/suite"
)

type UserProfileIdentityRepoSuite struct {
	suite.Suite
	ctx    context.Context
	client *dbent.Client
	repo   *userRepository
}

func TestUserProfileIdentityRepoSuite(t *testing.T) {
	suite.Run(t, new(UserProfileIdentityRepoSuite))
}

func (s *UserProfileIdentityRepoSuite) SetupTest() {
	s.ctx = context.Background()
	s.client = testEntClient(s.T())
	s.repo = newUserRepositoryWithSQL(s.client, integrationDB)

	_, err := integrationDB.ExecContext(s.ctx, `
TRUNCATE TABLE
	identity_adoption_decisions,
	auth_identities,
	pending_auth_sessions,
	user_provider_default_grants,
	user_avatars
RESTART IDENTITY`)
	s.Require().NoError(err)
}

func (s *UserProfileIdentityRepoSuite) mustCreateUser(label string) *dbent.User {
	s.T().Helper()

	user, err := s.client.User.Create().
		SetEmail(fmt.Sprintf("%s-%d@example.com", label, time.Now().UnixNano())).
		SetPasswordHash("test-password-hash").
		SetRole("user").
		SetStatus("active").
		Save(s.ctx)
	s.Require().NoError(err)
	return user
}

func (s *UserProfileIdentityRepoSuite) mustCreatePendingAuthSession(key AuthIdentityKey) *dbent.PendingAuthSession {
	s.T().Helper()

	session, err := s.client.PendingAuthSession.Create().
		SetSessionToken(fmt.Sprintf("pending-%d", time.Now().UnixNano())).
		SetIntent("bind_current_user").
		SetProviderType(key.ProviderType).
		SetProviderKey(key.ProviderKey).
		SetProviderSubject(key.ProviderSubject).
		SetExpiresAt(time.Now().UTC().Add(15 * time.Minute)).
		SetUpstreamIdentityClaims(map[string]any{"provider_subject": key.ProviderSubject}).
		SetLocalFlowState(map[string]any{"step": "pending"}).
		Save(s.ctx)
	s.Require().NoError(err)
	return session
}

func (s *UserProfileIdentityRepoSuite) TestCreateLookupAndBindCanonicalIdentity() {
	user := s.mustCreateUser("oidc-identity")
	verifiedAt := time.Now().UTC().Truncate(time.Second)

	created, err := s.repo.CreateAuthIdentity(s.ctx, CreateAuthIdentityInput{
		UserID: user.ID,
		Canonical: AuthIdentityKey{
			ProviderType:    "oidc",
			ProviderKey:     "https://issuer.example",
			ProviderSubject: "subject-123",
		},
		Issuer:     stringPtr("https://issuer.example"),
		VerifiedAt: &verifiedAt,
		Metadata:   map[string]any{"display_name": "first"},
	})
	s.Require().NoError(err)
	s.Require().NotNil(created.Identity)

	loaded, err := s.repo.GetUserByCanonicalIdentity(s.ctx, created.IdentityRef())
	s.Require().NoError(err)
	s.Require().Equal(user.ID, loaded.User.ID)
	s.Require().Equal(created.Identity.ID, loaded.Identity.ID)
	s.Require().Equal("subject-123", loaded.Identity.ProviderSubject)

	bound, err := s.repo.BindAuthIdentityToUser(s.ctx, BindAuthIdentityInput{
		UserID:    user.ID,
		Canonical: created.IdentityRef(),
		Metadata:  map[string]any{"display_name": "second"},
	})
	s.Require().NoError(err)
	s.Require().Equal(created.Identity.ID, bound.Identity.ID)
	s.Require().Equal("second", bound.Identity.Metadata["display_name"])
}

func (s *UserProfileIdentityRepoSuite) TestWithUserProfileIdentityTx_RollsBackIdentityAndGrantOnError() {
	user := s.mustCreateUser("tx-rollback")
	expectedErr := errors.New("rollback")

	err := s.repo.WithUserProfileIdentityTx(s.ctx, func(txCtx context.Context) error {
		_, err := s.repo.CreateAuthIdentity(txCtx, CreateAuthIdentityInput{
			UserID: user.ID,
			Canonical: AuthIdentityKey{
				ProviderType:    "oidc",
				ProviderKey:     "https://issuer.example",
				ProviderSubject: "subject-rollback",
			},
		})
		s.Require().NoError(err)

		inserted, err := s.repo.RecordProviderGrant(txCtx, ProviderGrantRecordInput{
			UserID:       user.ID,
			ProviderType: "oidc",
			GrantReason:  ProviderGrantReasonFirstBind,
		})
		s.Require().NoError(err)
		s.Require().True(inserted)
		return expectedErr
	})
	s.Require().ErrorIs(err, expectedErr)

	_, err = s.repo.GetUserByCanonicalIdentity(s.ctx, AuthIdentityKey{
		ProviderType:    "oidc",
		ProviderKey:     "https://issuer.example",
		ProviderSubject: "subject-rollback",
	})
	s.Require().True(dbent.IsNotFound(err))
}

func (s *UserProfileIdentityRepoSuite) TestRecordProviderGrant_IsIdempotentPerReason() {
	user := s.mustCreateUser("grant")

	inserted, err := s.repo.RecordProviderGrant(s.ctx, ProviderGrantRecordInput{
		UserID:       user.ID,
		ProviderType: "oidc",
		GrantReason:  ProviderGrantReasonFirstBind,
	})
	s.Require().NoError(err)
	s.Require().True(inserted)

	inserted, err = s.repo.RecordProviderGrant(s.ctx, ProviderGrantRecordInput{
		UserID:       user.ID,
		ProviderType: "oidc",
		GrantReason:  ProviderGrantReasonFirstBind,
	})
	s.Require().NoError(err)
	s.Require().False(inserted)

	inserted, err = s.repo.RecordProviderGrant(s.ctx, ProviderGrantRecordInput{
		UserID:       user.ID,
		ProviderType: "oidc",
		GrantReason:  ProviderGrantReasonSignup,
	})
	s.Require().NoError(err)
	s.Require().True(inserted)
}

func (s *UserProfileIdentityRepoSuite) TestUpsertIdentityAdoptionDecision_PersistsAndLinksIdentity() {
	user := s.mustCreateUser("adoption")
	identity, err := s.repo.CreateAuthIdentity(s.ctx, CreateAuthIdentityInput{
		UserID: user.ID,
		Canonical: AuthIdentityKey{
			ProviderType:    "oidc",
			ProviderKey:     "https://issuer.example",
			ProviderSubject: "subject-adoption",
		},
	})
	s.Require().NoError(err)

	session := s.mustCreatePendingAuthSession(identity.IdentityRef())

	first, err := s.repo.UpsertIdentityAdoptionDecision(s.ctx, IdentityAdoptionDecisionInput{
		PendingAuthSessionID: session.ID,
		AdoptDisplayName:     true,
		AdoptAvatar:          false,
	})
	s.Require().NoError(err)
	s.Require().True(first.AdoptDisplayName)
	s.Require().Nil(first.IdentityID)

	second, err := s.repo.UpsertIdentityAdoptionDecision(s.ctx, IdentityAdoptionDecisionInput{
		PendingAuthSessionID: session.ID,
		IdentityID:           &identity.Identity.ID,
		AdoptDisplayName:     true,
		AdoptAvatar:          true,
	})
	s.Require().NoError(err)
	s.Require().Equal(first.ID, second.ID)
	s.Require().NotNil(second.IdentityID)
	s.Require().Equal(identity.Identity.ID, *second.IdentityID)
	s.Require().True(second.AdoptAvatar)
}

func (s *UserProfileIdentityRepoSuite) TestUserAvatarCRUDAndUserLookup() {
	user := s.mustCreateUser("avatar")

	inlineAvatar, err := s.repo.UpsertUserAvatar(s.ctx, user.ID, service.UpsertUserAvatarInput{
		StorageProvider: "inline",
		URL:             "data:image/png;base64,QUJD",
		ContentType:     "image/png",
		ByteSize:        3,
		SHA256:          "902fbdd2b1df0c4f70b4a5d23525e932",
	})
	s.Require().NoError(err)
	s.Require().Equal("inline", inlineAvatar.StorageProvider)

	loadedAvatar, err := s.repo.GetUserAvatar(s.ctx, user.ID)
	s.Require().NoError(err)
	s.Require().NotNil(loadedAvatar)
	s.Require().Equal("image/png", loadedAvatar.ContentType)

	s.Require().NoError(s.repo.DeleteUserAvatar(s.ctx, user.ID))
	loadedAvatar, err = s.repo.GetUserAvatar(s.ctx, user.ID)
	s.Require().NoError(err)
	s.Require().Nil(loadedAvatar)
}

func stringPtr(v string) *string {
	return &v
}
