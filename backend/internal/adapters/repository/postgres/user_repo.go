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

func (r *UserRepo) GetAll(ctx context.Context) ([]*domain.User, error) {
	users, err := r.q.GetAllUsers(ctx)
	if err != nil {
		return nil, err
	}

	var res []*domain.User
	for _, u := range users {
		resID, _ := uuid.FromBytes(u.ID.Bytes[:])
		var pinHash *string
		if u.PinHash.Valid {
			pinHash = &u.PinHash.String
		}
		var providerID *string
		if u.ProviderID.Valid {
			providerID = &u.ProviderID.String
		}

		res = append(res, &domain.User{
			ID:           resID,
			UniversityID: u.UniversityID,
			PinHash:      pinHash,
			AuthProvider: u.AuthProvider,
			ProviderID:   providerID,
			Role:         domain.Role(u.Role),
			CreatedAt:    u.CreatedAt.Time,
		})
	}
	return res, nil
}

func (r *UserRepo) Create(ctx context.Context, user *domain.User) error {
	var pinHash pgtype.Text
	if user.PinHash != nil {
		pinHash = pgtype.Text{String: *user.PinHash, Valid: true}
	}

	u, err := r.q.CreateUser(ctx, CreateUserParams{
		UniversityID: user.UniversityID,
		PinHash:      pinHash,
		Role:         UserRole(user.Role),
		AuthProvider: user.AuthProvider,
	})
	if err != nil {
		return err
	}

	resID, _ := uuid.FromBytes(u.ID.Bytes[:])
	user.ID = resID
	user.CreatedAt = u.CreatedAt.Time
	return nil
}

func (r *UserRepo) Delete(ctx context.Context, id uuid.UUID) error {
	var pgID pgtype.UUID
	copy(pgID.Bytes[:], id[:])
	pgID.Valid = true
	return r.q.DeleteUser(ctx, pgID)
}
