package http

import (
	"encoding/csv"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/code-grey/project-echo-guwims/backend/internal/core/domain"
	"github.com/code-grey/project-echo-guwims/backend/internal/core/ports"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AdminHandler struct {
	userRepo ports.UserRepository
}

func NewAdminHandler(userRepo ports.UserRepository) *AdminHandler {
	return &AdminHandler{
		userRepo: userRepo,
	}
}

func (h *AdminHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userRole, _ := r.Context().Value(RoleKey).(string)
	if userRole != string(domain.RoleAdmin) {
		jsonError(w, http.StatusForbidden, "Forbidden: Admin only")
		return
	}

	users, err := h.userRepo.GetAll(r.Context())
	if err != nil {
		jsonError(w, http.StatusInternalServerError, "Failed to fetch users")
		return
	}

	jsonResponse(w, http.StatusOK, users)
}

func (h *AdminHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userRole, _ := r.Context().Value(RoleKey).(string)
	if userRole != string(domain.RoleAdmin) {
		jsonError(w, http.StatusForbidden, "Forbidden: Admin only")
		return
	}

	var req struct {
		UniversityID string      `json:"university_id"`
		Pin          string      `json:"pin"`
		Role         domain.Role `json:"role"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid payload")
		return
	}

	hashedPin, err := bcrypt.GenerateFromPassword([]byte(req.Pin), bcrypt.DefaultCost)
	if err != nil {
		jsonError(w, http.StatusInternalServerError, "Failed to hash PIN")
		return
	}

	pinStr := string(hashedPin)
	user := &domain.User{
		UniversityID: req.UniversityID,
		PinHash:      &pinStr,
		Role:         req.Role,
		AuthProvider: "LOCAL",
	}

	if err := h.userRepo.Create(r.Context(), user); err != nil {
		jsonError(w, http.StatusInternalServerError, "Failed to create user")
		return
	}

	jsonResponse(w, http.StatusCreated, user)
}

func (h *AdminHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userRole, _ := r.Context().Value(RoleKey).(string)
	if userRole != string(domain.RoleAdmin) {
		jsonError(w, http.StatusForbidden, "Forbidden: Admin only")
		return
	}

	idStr := r.URL.Query().Get("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	if err := h.userRepo.Delete(r.Context(), id); err != nil {
		jsonError(w, http.StatusInternalServerError, "Failed to delete user")
		return
	}

	jsonResponse(w, http.StatusOK, map[string]string{"message": "User deleted"})
}

func (h *AdminHandler) ImportUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userRole, _ := r.Context().Value(RoleKey).(string)
	if userRole != string(domain.RoleAdmin) {
		jsonError(w, http.StatusForbidden, "Forbidden: Admin only")
		return
	}

	file, _, err := r.FormFile("csv")
	if err != nil {
		jsonError(w, http.StatusBadRequest, "CSV file is required")
		return
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		jsonError(w, http.StatusBadRequest, "Failed to parse CSV")
		return
	}

	// Expecting CSV format: university_id, pin, role
	successCount := 0
	for i, record := range records {
		if i == 0 {
			continue // Skip header
		}
		if len(record) < 3 {
			continue
		}

		uID := strings.TrimSpace(record[0])
		pin := strings.TrimSpace(record[1])
		roleStr := strings.TrimSpace(record[2])

		hashedPin, _ := bcrypt.GenerateFromPassword([]byte(pin), bcrypt.DefaultCost)
		pinStr := string(hashedPin)

		user := &domain.User{
			UniversityID: uID,
			PinHash:      &pinStr,
			Role:         domain.Role(roleStr),
			AuthProvider: "LOCAL",
		}

		if err := h.userRepo.Create(r.Context(), user); err == nil {
			successCount++
		}
	}

	jsonResponse(w, http.StatusOK, map[string]interface{}{
		"message": "Import complete",
		"count":   successCount,
	})
}
