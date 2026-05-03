package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type ReportStatus string

const (
	ReportStatusLogged         ReportStatus = "LOGGED"
	ReportStatusActionRequired ReportStatus = "ACTION_REQUIRED"
	ReportStatusDispatched     ReportStatus = "DISPATCHED"
	ReportStatusResolved       ReportStatus = "RESOLVED"
)

type Report struct {
	ID                   uuid.UUID       `json:"id"`
	ReporterID           uuid.UUID       `json:"reporter_id"`
	ReporterUniversityID string          `json:"reporter_university_id,omitempty"`
	Status               ReportStatus    `json:"status"`
	ImageURL             string          `json:"image_url"`
	Metadata             json.RawMessage `json:"metadata"` // JSONB
	CreatedAt            time.Time       `json:"created_at"`
	ResolvedAt           *time.Time      `json:"resolved_at,omitempty"`
	Longitude            float64         `json:"longitude"`
	Latitude             float64         `json:"latitude"`
}
