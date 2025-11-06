package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/hotel-booking-system/backend/internal/jobs"
	"github.com/hotel-booking-system/backend/internal/router"
	"github.com/hotel-booking-system/backend/pkg/cache"
	"github.com/hotel-booking-system/backend/pkg/config"
	"github.com/hotel-booking-system/backend/pkg/database"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	log.Println("Configuration loaded successfully")

	// Initialize database connection pool
	db, err := database.New(&cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	log.Println("Database connection established")

	// Initialize Redis cache (optional - system works without it)
	var redisCache *cache.RedisCache
	if cfg.Redis.URL != "" {
		redisCache, err = cache.NewRedisCache(cfg.Redis.URL)
		if err != nil {
			log.Printf("Warning: Failed to connect to Redis: %v (continuing without cache)", err)
			redisCache = nil
		} else {
			defer redisCache.Close()
			log.Println("Redis cache connection established")
		}
	} else {
		log.Println("Redis not configured, running without cache")
	}

	// Initialize and start night audit job
	nightAudit := jobs.NewNightAuditJob(db)
	if err := nightAudit.Start(); err != nil {
		log.Fatalf("Failed to start night audit job: %v", err)
	}
	defer nightAudit.Stop()

	log.Printf("Night audit job scheduled (next run: %s)", nightAudit.GetNextRunTime().Format("2006-01-02 15:04:05"))

	// Initialize and start hold cleanup job
	holdCleanup := jobs.NewHoldCleanupJob(db)
	if err := holdCleanup.Start(); err != nil {
		log.Fatalf("Failed to start hold cleanup job: %v", err)
	}
	defer holdCleanup.Stop()

	log.Printf("Hold cleanup job scheduled (next run: %s)", holdCleanup.GetNextRunTime().Format("2006-01-02 15:04:05"))

	// Setup router
	r := router.Setup(cfg, db, redisCache, nightAudit, holdCleanup)

	// Create HTTP server
	addr := fmt.Sprintf("0.0.0.0:%s", cfg.Server.Port)
	srv := &http.Server{
		Addr:           addr,
		Handler:        r,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20, // 1 MB
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Starting server on %s (mode: %s)", addr, cfg.Server.GinMode)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown with 5 second timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
