package domain

import (
	"time"

	"github.com/google/uuid"
)

type Role string

const (
	RoleStudent          Role = "STUDENT"
	RoleSanitationWorker Role = "SANITATION_WORKER"
	RoleElectrician      Role = "ELECTRICIAN"
	RoleSecurity         Role = "SECURITY"
	RoleAdmin            Role = "ADMIN"
)

type User struct {
	ID           uuid.UUID `json:"id"`
	UniversityID string    `json:"university_id"`
	PinHash      *string   `json:"-"`
	AuthProvider string    `json:"auth_provider"`
	ProviderID   *string   `json:"provider_id"`
	Role         Role      `json:"role"`
	CreatedAt    time.Time `json:"created_at"`
}
