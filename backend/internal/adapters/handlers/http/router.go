package http

import (
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux, authHandler *AuthHandler, reportHandler *ReportHandler, jwtSecret string) {
	// Health Check
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	authMiddleware := AuthMiddleware(jwtSecret)

	// Auth
	mux.HandleFunc("/api/auth/login", authHandler.Login)     // POST
	mux.HandleFunc("/api/auth/refresh", authHandler.Refresh) // POST

	// Reports
	mux.HandleFunc("/api/reports", authMiddleware(reportHandler.Create))           // POST
	mux.HandleFunc("/api/reports/nearby", authMiddleware(reportHandler.GetNearby)) // GET
	mux.HandleFunc("/api/reports/update-status", authMiddleware(reportHandler.UpdateStatus)) // PUT
	mux.HandleFunc("/api/reports/update", authMiddleware(reportHandler.Update)) // PUT
	mux.HandleFunc("/api/reports/delete", authMiddleware(reportHandler.Delete)) // DELETE
}
