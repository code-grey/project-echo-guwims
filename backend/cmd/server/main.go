package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	httpapi "github.com/code-grey/project-echo-guwims/backend/internal/adapters/handlers/http"
	"github.com/code-grey/project-echo-guwims/backend/internal/adapters/repository/postgres"
	"github.com/code-grey/project-echo-guwims/backend/internal/adapters/storage/cloudinary"
	"github.com/code-grey/project-echo-guwims/backend/internal/adapters/vision/google"
	"github.com/code-grey/project-echo-guwims/backend/internal/core/worker"
	"github.com/code-grey/project-echo-guwims/backend/internal/core/ports"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on system environment variables.")
	}

	// 10-minute interval self-pinging background goroutine for Render
	go func() {
		ticker := time.NewTicker(10 * time.Minute)
		client := &http.Client{Timeout: 5 * time.Second}
		for range ticker.C {
			liveURL := os.Getenv("LIVE_URL")
			if liveURL != "" {
				// Ping the actual endpoint
				resp, err := client.Get(liveURL + "/healthz")
				if err != nil {
					log.Printf("Self-ping failed: %v\n", err)
				} else {
					log.Printf("Self-ping successful: %d\n", resp.StatusCode)
					resp.Body.Close()
				}
			} else {
				log.Println("Keep-alive ping (Local mode, LIVE_URL not set)...")
			}
		}
	}()

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("FATAL: DATABASE_URL is required")
	}

	// Configure DB Connection Pool (Prevention of Connection Exhaustion)
	config, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		log.Fatalf("Unable to parse DB config: %v\n", err)
	}
	config.MaxConns = 20
	config.MinConns = 5
	config.MaxConnIdleTime = 30 * time.Minute

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer pool.Close()

	userRepo := postgres.NewUserRepo(pool)
	reportRepo := postgres.NewReportRepo(pool)

	// Initialize Worker Pool (Prevention of Goroutine Sprawl)
	// 5 concurrent workers, 100 task buffer
	wp := worker.NewPool(5, 100)

	// Initialize Vision AI
	geminiKey := os.Getenv("GEMINI_API_KEY")
	geminiModel := os.Getenv("GEMINI_MODEL")
	vision := google.NewGeminiVisionProvider(geminiKey, geminiModel)

	var storage ports.StorageProvider
	cloudinaryURL := os.Getenv("CLOUDINARY_URL")
	if cloudinaryURL != "" {
		cld, err := cloudinary.NewProvider(cloudinaryURL)
		if err != nil {
			log.Fatalf("Failed to initialize Cloudinary: %v", err)
		}
		storage = cld
		log.Println("Cloudinary initialized.")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		log.Fatal("FATAL: JWT_SECRET environment variable is required")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize Handlers
	authHandler := httpapi.NewAuthHandler(userRepo, jwtSecret)
	reportHandler := httpapi.NewReportHandler(reportRepo, storage, vision, wp)
	adminHandler := httpapi.NewAdminHandler(userRepo)

	// Setup Router
	mux := http.NewServeMux()
	httpapi.RegisterRoutes(mux, authHandler, reportHandler, adminHandler, jwtSecret)

	log.Printf("Starting server on :%s\n", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}
