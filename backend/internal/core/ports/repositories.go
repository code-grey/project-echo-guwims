package ports

import (
	"context"

	"github.com/code-grey/project-echo-guwims/backend/internal/core/domain"
	"github.com/google/uuid"
)

type UserRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
	GetByUniversityID(ctx context.Context, universityID string) (*domain.User, error)
}

type ReportRepository interface {
	Create(ctx context.Context, report *domain.Report) error
	GetWithinRadius(ctx context.Context, lat, lon, radius float64) ([]*domain.Report, error)
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Report, error)
	UpdateStatus(ctx context.Context, id uuid.UUID, status domain.ReportStatus) error
	UpdateMetadata(ctx context.Context, id uuid.UUID, metadata []byte) error
	Delete(ctx context.Context, id uuid.UUID) error
}
