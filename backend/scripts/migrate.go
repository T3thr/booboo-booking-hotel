package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/jackc/pgx/v5"
)

func main() {
	// Get DATABASE_URL from environment
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("ERROR: DATABASE_URL environment variable is not set")
	}

	fmt.Println("=== Starting Database Migrations ===")
	fmt.Printf("Database URL: %s...\n", dbURL[:30])

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

	// List of migrations in order
	migrations := []string{
		"001_create_guests_tables.sql",
		"002_create_room_management_tables.sql",
		"003_create_pricing_inventory_tables.sql",
		"004_create_bookings_tables.sql",
		"005_create_booking_hold_function.sql",
		"006_create_confirm_booking_function.sql",
		"007_create_cancel_booking_function.sql",
		"008_create_release_expired_holds_function.sql",
		"009_create_check_in_function.sql",
		"010_create_check_out_function.sql",
		"011_create_move_room_function.sql",
		"012_performance_optimization.sql",
	}

	// Run each migration
	for _, migration := range migrations {
		fmt.Printf("\nRunning migration: %s\n", migration)
		
		// Read migration file
		migrationPath := filepath.Join("..", "database", "migrations", migration)
		content, err := os.ReadFile(migrationPath)
		if err != nil {
			log.Printf("⚠ Warning: Migration file not found: %s", migration)
			continue
		}

		// Execute using the simple protocol which doesn't parse parameters
		// This allows dollar-quoted strings to work properly
		_, err = conn.PgConn().Exec(ctx, string(content)).ReadAll()
		if err != nil {
			log.Fatalf("✗ %s failed: %v", migration, err)
		}
		
		fmt.Printf("✓ %s completed successfully\n", migration)
	}

	fmt.Println("\n=== All Migrations Completed Successfully ===")
}
