package http

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/code-grey/project-echo-guwims/backend/internal/core/domain"
	"github.com/code-grey/project-echo-guwims/backend/internal/core/ports"
	"github.com/code-grey/project-echo-guwims/backend/internal/core/worker"
	"github.com/google/uuid"
)

type ReportHandler struct {
	repo    ports.ReportRepository
	storage ports.StorageProvider
	vision  ports.VisionProvider
	worker  *worker.Pool
}

func NewReportHandler(repo ports.ReportRepository, storage ports.StorageProvider, vision ports.VisionProvider, wp *worker.Pool) *ReportHandler {
	return &ReportHandler{
		repo:    repo,
		storage: storage,
		vision:  vision,
		worker:  wp,
	}
}

func (h *ReportHandler) Create(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := r.Context().Value(UserIDKey).(uuid.UUID)
	if !ok {
		jsonError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Lat      float64 `json:"lat"`
		Lon      float64 `json:"lon"`
		Metadata string  `json:"metadata"`
		ImageURL string  `json:"image_url"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid payload")
		return
	}

	if req.ImageURL == "" {
		jsonError(w, http.StatusBadRequest, "Image URL is required")
		return
	}

	// Prepare Metadata
	metaMap := make(map[string]interface{})
	if req.Metadata != "" {
		json.Unmarshal([]byte(req.Metadata), &metaMap)
	}

	report := &domain.Report{
		ReporterID: userID,
		Latitude:   req.Lat,
		Longitude:  req.Lon,
		ImageURL:   req.ImageURL,
		Status:     domain.ReportStatusLogged,
		// We will marshal metadata after the background vision task completes,
		// but we need a placeholder to save the initial report state safely.
		Metadata:   []byte(`{"ai_description": "Processing..."}`),
	}

	// First, save the initial state to the DB so the user gets a 202 response immediately.
	if err := h.repo.Create(r.Context(), report); err != nil {
		log.Printf("Failed to save initial report: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to create report")
		return
	}

	// Use Worker Pool for background vision analysis and update
	h.worker.Submit(func(parentCtx context.Context) {
		ctx, cancel := context.WithTimeout(parentCtx, 60*time.Second)
		defer cancel()

		var imageFile []byte
		err := worker.Retry(ctx, 5, 2*time.Second, func() error {
			resp, err := http.Get(req.ImageURL)
			if err != nil {
				return err
			}
			defer resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				return fmt.Errorf("failed to fetch image, status: %d", resp.StatusCode)
			}
			imageFile, err = io.ReadAll(resp.Body)
			return err
		})

		var aiAnalysis *ports.VisionAnalysis
		if err == nil && len(imageFile) > 0 {
			// Analyze with AI Vision
			err = worker.Retry(ctx, 3, 2*time.Second, func() error {
				analysis, err := h.vision.AnalyzeImage(ctx, imageFile)
				if err != nil {
					return err
				}
				aiAnalysis = analysis
				return nil
			})
			if err != nil {
				log.Printf("Background: Vision analysis failed: %v\n", err)
			}
		} else {
			log.Printf("Background: Failed to fetch image for analysis: %v\n", err)
		}

		if aiAnalysis != nil {
			metaMap["ai_description"] = aiAnalysis.Description
			metaMap["department"] = aiAnalysis.Department
			metaMap["ai_tags"] = aiAnalysis.Tags
			metaMap["ai_confidence"] = aiAnalysis.Confidence
		} else {
			metaMap["ai_description"] = "AI Analysis failed or timed out."
			metaMap["department"] = "UNKNOWN"
		}
		
		finalMetadata, _ := json.Marshal(metaMap)

		// Update the report with the final AI metadata
		err = worker.Retry(ctx, 3, 500*time.Millisecond, func() error {
			return h.repo.UpdateMetadata(ctx, report.ID, finalMetadata)
		})
		if err != nil {
			log.Printf("Background: Failed to update report metadata after retries: %v\n", err)
		}
	})

	w.WriteHeader(http.StatusAccepted)
	jsonResponse(w, http.StatusAccepted, map[string]string{"message": "Report received and processing"})
}

func (h *ReportHandler) GetNearby(w http.ResponseWriter, r *http.Request) {
	lat, _ := strconv.ParseFloat(r.URL.Query().Get("lat"), 64)
	lon, _ := strconv.ParseFloat(r.URL.Query().Get("lon"), 64)
	radius, _ := strconv.ParseFloat(r.URL.Query().Get("radius"), 64)

	if radius == 0 {
		radius = 10.0 // Default 10 meters
	}

	userRole, _ := r.Context().Value(RoleKey).(string)
	userID, _ := r.Context().Value(UserIDKey).(uuid.UUID)

	var reports []*domain.Report
	var err error

	if userRole == string(domain.RoleStudent) {
		// Students only see their own reports (BOLA enforcement)
		reports, err = h.repo.GetByReporter(r.Context(), userID)
	} else {
		// Admins/Workers can see all nearby reports
		reports, err = h.repo.GetWithinRadius(r.Context(), lat, lon, radius)
	}

	if err != nil {
		log.Printf("Failed to fetch reports: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to fetch reports")
		return
	}

	jsonResponse(w, http.StatusOK, reports)
}

func (h *ReportHandler) GetAll(w http.ResponseWriter, r *http.Request) {
	// Role check is handled by middleware, but we double-verify here for safety
	userRole, _ := r.Context().Value(RoleKey).(string)
	if userRole != string(domain.RoleAdmin) {
		jsonError(w, http.StatusForbidden, "Forbidden: Admin access only")
		return
	}

	reports, err := h.repo.GetAll(r.Context())
	if err != nil {
		log.Printf("Failed to fetch all reports: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to fetch reports")
		return
	}

	jsonResponse(w, http.StatusOK, reports)
}

func (h *ReportHandler) GetQueue(w http.ResponseWriter, r *http.Request) {
	userRole, _ := r.Context().Value(RoleKey).(string)

	// Determine department based on role
	var department string
	switch userRole {
	case string(domain.RoleSanitationWorker):
		department = "ESTATE" // Or SANITATION if specifically mapped
	case string(domain.RoleElectrician):
		department = "ELECTRICAL"
	case string(domain.RoleSecurity):
		department = "SECURITY"
	default:
		// If an Admin hits this, they might want to see a specific department's queue
		department = r.URL.Query().Get("department")
		if department == "" && userRole != string(domain.RoleAdmin) {
			jsonError(w, http.StatusForbidden, "Forbidden: Invalid role for queue access")
			return
		}
	}

	reports, err := h.repo.GetByQueue(r.Context(), department, domain.ReportStatusDispatched)
	if err != nil {
		log.Printf("Failed to fetch queue: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to fetch queue")
		return
	}

	jsonResponse(w, http.StatusOK, reports)
}

func (h *ReportHandler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := r.Context().Value(UserIDKey).(uuid.UUID)
	if !ok {
		jsonError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userRole, _ := r.Context().Value(RoleKey).(string)

	var req struct {
		ReportID      uuid.UUID           `json:"report_id"`
		Status        domain.ReportStatus `json:"status"`
		WorkerLat     *float64            `json:"worker_lat,omitempty"`
		WorkerLng     *float64            `json:"worker_lng,omitempty"`
		AfterImageURL *string             `json:"after_image_url,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid payload")
		return
	}

	// BOLA Check
	report, err := h.repo.GetByID(r.Context(), req.ReportID)
	if err != nil {
		jsonError(w, http.StatusNotFound, "Report not found")
		return
	}

	if report.ReporterID != userID && userRole == string(domain.RoleStudent) {
		jsonError(w, http.StatusForbidden, "Forbidden: Students can only update their own reports")
		return
	}

	// Anti-Fraud "Proof of Work" Validation
	if req.Status == domain.ReportStatusResolved {
		if req.WorkerLat == nil || req.WorkerLng == nil || req.AfterImageURL == nil || *req.AfterImageURL == "" {
			if userRole != string(domain.RoleAdmin) {
				jsonError(w, http.StatusBadRequest, "Missing Proof of Work: worker_lat, worker_lng, and after_image_url are required to resolve a task")
				return
			}
		} else {
			distance, err := h.repo.CheckDistance(r.Context(), req.ReportID, *req.WorkerLat, *req.WorkerLng)
			if err != nil {
				log.Printf("Failed to calculate distance: %v\n", err)
				jsonError(w, http.StatusInternalServerError, "Failed to validate location")
				return
			}

			if distance > 50 {
				jsonError(w, http.StatusForbidden, "Proof of Work Failed: Worker must be within 50 meters of the incident location to resolve it")
				return
			}

			// Update Metadata with the AfterImageURL
			var meta map[string]interface{}
			if err := json.Unmarshal(report.Metadata, &meta); err != nil {
				meta = make(map[string]interface{})
			}
			meta["after_image_url"] = *req.AfterImageURL
			meta["resolution_distance_meters"] = distance
			if uniID, ok := r.Context().Value(UniversityIDKey).(string); ok {
				meta["resolved_by_university_id"] = uniID
			}
			
			updatedMetaBytes, _ := json.Marshal(meta)
			if err := h.repo.UpdateMetadata(r.Context(), req.ReportID, updatedMetaBytes); err != nil {
				log.Printf("Failed to update report metadata: %v\n", err)
				jsonError(w, http.StatusInternalServerError, "Failed to save Proof of Work evidence")
				return
			}
		}
	}

	if err := h.repo.UpdateStatus(r.Context(), req.ReportID, req.Status); err != nil {
		log.Printf("Failed to update report status: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to update report status")
		return
	}

	jsonResponse(w, http.StatusOK, map[string]string{"message": "Report status updated"})
}

func (h *ReportHandler) Update(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := r.Context().Value(UserIDKey).(uuid.UUID)
	if !ok {
		jsonError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userRole, _ := r.Context().Value(RoleKey).(string)

	var req struct {
		ReportID    uuid.UUID `json:"report_id"`
		Description *string   `json:"description,omitempty"`
		Department  *string   `json:"department,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid payload")
		return
	}

	// BOLA Check
	report, err := h.repo.GetByID(r.Context(), req.ReportID)
	if err != nil {
		jsonError(w, http.StatusNotFound, "Report not found")
		return
	}

	if report.ReporterID != userID && userRole != string(domain.RoleAdmin) {
		jsonError(w, http.StatusForbidden, "Forbidden: Only admins or the reporter can edit this report")
		return
	}

	// Unmarshal existing metadata
	var metaMap map[string]interface{}
	if len(report.Metadata) > 0 {
		if err := json.Unmarshal(report.Metadata, &metaMap); err != nil {
			log.Printf("Warning: Failed to parse existing metadata: %v\n", err)
			metaMap = make(map[string]interface{})
		}
	} else {
		metaMap = make(map[string]interface{})
	}

	// Apply updates
	if req.Description != nil {
		metaMap["ai_description"] = *req.Description // Override the AI description
	}
	if req.Department != nil && userRole == string(domain.RoleAdmin) {
		// Only admins can manually override the department routing
		metaMap["department"] = *req.Department
	}

	updatedMetadataBytes, _ := json.Marshal(metaMap)

	if err := h.repo.UpdateMetadata(r.Context(), req.ReportID, updatedMetadataBytes); err != nil {
		log.Printf("Failed to update report metadata: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to update report")
		return
	}

	jsonResponse(w, http.StatusOK, map[string]string{"message": "Report updated successfully"})
}

func (h *ReportHandler) Delete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	userID, ok := r.Context().Value(UserIDKey).(uuid.UUID)
	if !ok {
		jsonError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	userRole, _ := r.Context().Value(RoleKey).(string)

	reportIDStr := r.URL.Query().Get("id")
	if reportIDStr == "" {
		jsonError(w, http.StatusBadRequest, "Missing report id")
		return
	}

	reportID, err := uuid.Parse(reportIDStr)
	if err != nil {
		jsonError(w, http.StatusBadRequest, "Invalid report id")
		return
	}

	// BOLA Check
	report, err := h.repo.GetByID(r.Context(), reportID)
	if err != nil {
		jsonError(w, http.StatusNotFound, "Report not found")
		return
	}

	if report.ReporterID != userID && userRole != string(domain.RoleAdmin) {
		jsonError(w, http.StatusForbidden, "Forbidden: Only admins or the reporter can delete this report")
		return
	}

	// Delete from storage
	if report.ImageURL != "" {
		if err := h.storage.DeleteImage(r.Context(), report.ImageURL); err != nil {
			log.Printf("Warning: Failed to delete image from storage: %v\n", err)
		}
	}

	if err := h.repo.Delete(r.Context(), reportID); err != nil {
		log.Printf("Failed to delete report: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to delete report")
		return
	}

	jsonResponse(w, http.StatusOK, map[string]string{"message": "Report deleted successfully"})
}

func (h *ReportHandler) GetStorageSignature(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		jsonError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	sig, err := h.storage.GenerateSignature()
	if err != nil {
		log.Printf("Failed to generate storage signature: %v\n", err)
		jsonError(w, http.StatusInternalServerError, "Failed to generate storage signature")
		return
	}

	jsonResponse(w, http.StatusOK, sig)
}
