package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
)

func main() {
	fmt.Println("============================================")
	fmt.Println("Running Migration 014: Role System")
	fmt.Println("============================================")
	fmt.Println()

	// Build connection string from environment or use default
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "host=ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech port=5432 user=neondb_owner password=npg_8kHamXSLKg1x dbname=neondb sslmode=require"
	}

	// Connect to database
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer conn.Close(ctx)

	// Test connection
	if err := conn.Ping(ctx); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	fmt.Println("✓ Connected to database")
	fmt.Println()

	// Read SQL file (clean version without psql commands)
	sqlContent, err := os.ReadFile("../../database/migrations/014_create_role_system_clean.sql")
	if err != nil {
		log.Fatalf("Failed to read SQL file: %v", err)
	}

	// Execute migration
	fmt.Println("Executing migration...")
	_, err = conn.Exec(ctx, string(sqlContent))
	if err != nil {
		log.Fatalf("Failed to execute migration: %v", err)
	}

	fmt.Println()
	fmt.Println("============================================")
	fmt.Println("Migration 014 Completed Successfully!")
	fmt.Println("============================================")
	fmt.Println()
	fmt.Println("Demo Credentials:")
	fmt.Println("  Guest: anan.test@example.com / password123")
	fmt.Println("  Receptionist: receptionist1@hotel.com / staff123")
	fmt.Println("  Housekeeper: housekeeper1@hotel.com / staff123")
	fmt.Println("  Manager: manager@hotel.com / staff123")
	fmt.Println()
	fmt.Println("============================================")
}
