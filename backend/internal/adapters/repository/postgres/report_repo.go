package postgres

import (
	"context"

	"github.com/code-grey/project-echo-guwims/backend/internal/core/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ReportRepo struct {
	q *Queries
}

func NewReportRepo(pool *pgxpool.Pool) *ReportRepo {
	return &ReportRepo{
		q: New(pool),
	}
}

func (r *ReportRepo) Create(ctx context.Context, t *domain.Report) error {
	var pgReporterID pgtype.UUID
	copy(pgReporterID.Bytes[:], t.ReporterID[:])
	pgReporterID.Valid = true

	row, err := r.q.CreateReport(ctx, CreateReportParams{
		ReporterID:    pgReporterID,
		StMakepoint:   t.Longitude,
		StMakepoint_2: t.Latitude,
		ImageUrl:      pgtype.Text{String: t.ImageURL, Valid: t.ImageURL != ""},
		Metadata:      t.Metadata,
	})
	if err != nil {
		return err
	}

	resID, _ := uuid.FromBytes(row.ID.Bytes[:])
	resReporterID, _ := uuid.FromBytes(row.ReporterID.Bytes[:])

	t.ID = resID
	t.ReporterID = resReporterID
	t.Status = domain.ReportStatus(row.Status)
	t.CreatedAt = row.CreatedAt.Time
	
	if lon, ok := row.Longitude.(float64); ok {
		t.Longitude = lon
	}
	if lat, ok := row.Latitude.(float64); ok {
		t.Latitude = lat
	}

	return nil
}

func (r *ReportRepo) GetWithinRadius(ctx context.Context, lat, lon, radius float64) ([]*domain.Report, error) {
	rows, err := r.q.GetReportsWithinRadius(ctx, GetReportsWithinRadiusParams{
		StMakepoint:   lon,
		StMakepoint_2: lat,
		StDwithin:     radius,
	})
	if err != nil {
		return nil, err
	}

	var res []*domain.Report
	for _, row := range rows {
		var lat, lon float64
		if lo, ok := row.Longitude.(float64); ok {
			lon = lo
		}
		if la, ok := row.Latitude.(float64); ok {
			lat = la
		}

		resID, _ := uuid.FromBytes(row.ID.Bytes[:])
		resReporterID, _ := uuid.FromBytes(row.ReporterID.Bytes[:])

		res = append(res, &domain.Report{
			ID:                   resID,
			ReporterID:           resReporterID,
			ReporterUniversityID: row.ReporterUniversityID,
			Status:               domain.ReportStatus(row.Status),
			ImageURL:             row.ImageUrl.String,
			Metadata:             row.Metadata,
			CreatedAt:            row.CreatedAt.Time,
			Longitude:            lon,
			Latitude:             lat,
		})
	}
	return res, nil
}

func (r *ReportRepo) GetByID(ctx context.Context, id uuid.UUID) (*domain.Report, error) {
	var pgID pgtype.UUID
	copy(pgID.Bytes[:], id[:])
	pgID.Valid = true

	row, err := r.q.GetReportByID(ctx, pgID)
	if err != nil {
		return nil, err
	}

	var lat, lon float64
	if lo, ok := row.Longitude.(float64); ok {
		lon = lo
	}
	if la, ok := row.Latitude.(float64); ok {
		lat = la
	}

	resID, _ := uuid.FromBytes(row.ID.Bytes[:])
	resReporterID, _ := uuid.FromBytes(row.ReporterID.Bytes[:])

	return &domain.Report{
		ID:         resID,
		ReporterID: resReporterID,
		Status:     domain.ReportStatus(row.Status),
		ImageURL:   row.ImageUrl.String,
		Metadata:   row.Metadata,
		CreatedAt:  row.CreatedAt.Time,
		Longitude:  lon,
		Latitude:   lat,
	}, nil
}

func (r *ReportRepo) UpdateStatus(ctx context.Context, id uuid.UUID, status domain.ReportStatus) error {
	var pgID pgtype.UUID
	copy(pgID.Bytes[:], id[:])
	pgID.Valid = true

	return r.q.UpdateReportStatus(ctx, UpdateReportStatusParams{
		ID:     pgID,
		Status: ReportStatus(status),
	})
}

func (r *ReportRepo) UpdateMetadata(ctx context.Context, id uuid.UUID, metadata []byte) error {
	var pgID pgtype.UUID
	copy(pgID.Bytes[:], id[:])
	pgID.Valid = true

	return r.q.UpdateReportMetadata(ctx, UpdateReportMetadataParams{
		ID:       pgID,
		Metadata: metadata,
	})
}

func (r *ReportRepo) Delete(ctx context.Context, id uuid.UUID) error {
	var pgID pgtype.UUID
	copy(pgID.Bytes[:], id[:])
	pgID.Valid = true

	return r.q.DeleteReport(ctx, pgID)
}
