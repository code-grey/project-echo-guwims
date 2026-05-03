package http

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// ContextKey is used for typed context keys
type ContextKey string

const UserIDKey ContextKey = "user_id"
const RoleKey ContextKey = "role"

func AuthMiddleware(secret string) func(http.HandlerFunc) http.HandlerFunc {
	return func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				jsonError(w, http.StatusUnauthorized, "Missing authorization header")
				return
			}

			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || parts[0] != "Bearer" {
				jsonError(w, http.StatusUnauthorized, "Invalid authorization header format")
				return
			}

			tokenString := parts[1]
			token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
				return []byte(secret), nil
			})

			if err != nil || !token.Valid {
				jsonError(w, http.StatusUnauthorized, "Invalid or expired token")
				return
			}

			claims, ok := token.Claims.(jwt.MapClaims)
			if !ok {
				jsonError(w, http.StatusUnauthorized, "Invalid token claims")
				return
			}

			userIDStr, ok := claims["sub"].(string)
			if !ok {
				jsonError(w, http.StatusUnauthorized, "Invalid user ID in token")
				return
			}

			uid, err := uuid.Parse(userIDStr)
			if err != nil {
				jsonError(w, http.StatusUnauthorized, "Malformed user ID in token")
				return
			}

			ctx := context.WithValue(r.Context(), UserIDKey, uid)
			if roleStr, ok := claims["role"].(string); ok {
				ctx = context.WithValue(ctx, RoleKey, roleStr)
			}
			next.ServeHTTP(w, r.WithContext(ctx))
		}
	}
}
