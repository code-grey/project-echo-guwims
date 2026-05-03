package http

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/code-grey/project-echo-guwims/backend/internal/core/ports"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	repo      ports.UserRepository
	jwtSecret []byte
}

func NewAuthHandler(repo ports.UserRepository, secret string) *AuthHandler {
	return &AuthHandler{
		repo:      repo,
		jwtSecret: []byte(secret),
	}
}

type loginRequest struct {
	UniversityID string `json:"university_id"`
	Pin          string `json:"pin"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid JSON body")
		return
	}

	user, err := h.repo.GetByUniversityID(r.Context(), req.UniversityID)
	if err != nil {
		jsonError(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	if user.PinHash == nil {
		jsonError(w, http.StatusUnauthorized, "OAuth users cannot login via PIN")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(*user.PinHash), []byte(req.Pin)); err != nil {
		jsonError(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// 15-minute Access Token
	claims := jwt.MapClaims{
		"sub":  user.ID.String(),
		"role": string(user.Role),
		"exp":  time.Now().Add(15 * time.Minute).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(h.jwtSecret)
	if err != nil {
		jsonError(w, http.StatusInternalServerError, "Failed to generate token")
		return
	}

	// 6-month HttpOnly Secure Refresh Token
	refreshToken := "dummy_refresh_token_for_now"
	http.SetCookie(w, &http.Cookie{
		Name:     "refresh_token",
		Value:    refreshToken,
		Expires:  time.Now().Add(6 * 30 * 24 * time.Hour),
		HttpOnly: true,
		Secure:   true,
		Path:     "/",
	})

	jsonResponse(w, http.StatusOK, map[string]interface{}{
		"access_token":  tokenString,
		"refresh_token": refreshToken,
		"user": map[string]interface{}{
			"id":            user.ID.String(),
			"university_id": user.UniversityID,
			"role":          string(user.Role),
		},
	})
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid JSON body")
		return
	}

	// In a real production system, you would validate this token against the database
	// or Redis to ensure it hasn't been revoked. For now, we accept our dummy token.
	if req.RefreshToken != "dummy_refresh_token_for_now" {
		jsonError(w, http.StatusUnauthorized, "Invalid refresh token")
		return
	}

	// For the sake of the scaffolding, we generate a generic new token.
	// Normally, we'd decode the refresh token to find the user ID.
	// We'll use a placeholder claim here just to satisfy the Flutter client's retry queue.
	claims := jwt.MapClaims{
		"sub":  "generic_user",
		"role": "STUDENT",
		"exp":  time.Now().Add(15 * time.Minute).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(h.jwtSecret)
	if err != nil {
		jsonError(w, http.StatusInternalServerError, "Failed to generate new access token")
		return
	}

	jsonResponse(w, http.StatusOK, map[string]string{
		"access_token":  tokenString,
		"refresh_token": req.RefreshToken, // Return the same refresh token
	})
}
