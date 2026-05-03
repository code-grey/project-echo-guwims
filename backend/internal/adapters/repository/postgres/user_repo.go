package postgres

import (
	"context"

	"github.com/code-grey/project-echo-guwims/backend/internal/core/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserRepo struct {
	q *Queries
}

func NewUserRepo(pool *pgxpool.Pool) *UserRepo {
	return &UserRepo{
		q: New(pool),
	}
}

func (r *UserRepo) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	var pgID pgtype.UUID
	copy(pgID.Bytes[:], id[:])
	pgID.Valid = true

	u, err := r.q.GetUserByID(ctx, pgID)
	if err != nil {
		return nil, err
	}

	resID, _ := uuid.FromBytes(u.ID.Bytes[:])

	var pinHash *string
	if u.PinHash.Valid {
		pinHash = &u.PinHash.String
	}
	var providerID *string
	if u.ProviderID.Valid {
		providerID = &u.ProviderID.String
	}

	return &domain.User{
		ID:           resID,
		UniversityID: u.UniversityID,
		PinHash:      pinHash,
		AuthProvider: u.AuthProvider,
		ProviderID:   providerID,
		Role:         domain.Role(u.Role),
		CreatedAt:    u.CreatedAt.Time,
	}, nil
}

func (r *UserRepo) GetByUniversityID(ctx context.Context, universityID string) (*domain.User, error) {
	u, err := r.q.GetUserByUniversityID(ctx, universityID)
	if err != nil {
		return nil, err
	}

	resID, _ := uuid.FromBytes(u.ID.Bytes[:])

	var pinHash *string
	if u.PinHash.Valid {
		pinHash = &u.PinHash.String
	}
	var providerID *string
	if u.ProviderID.Valid {
		providerID = &u.ProviderID.String
	}

	return &domain.User{
		ID:           resID,
		UniversityID: u.UniversityID,
		PinHash:      pinHash,
		AuthProvider: u.AuthProvider,
		ProviderID:   providerID,
		Role:         domain.Role(u.Role),
		CreatedAt:    u.CreatedAt.Time,
	}, nil
}
