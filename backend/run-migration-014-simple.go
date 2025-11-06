package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	fmt.Println("============================================")
	fmt.Println("Running Migration 014: Role System")
	fmt.Println("============================================\n")

	// Load .env
	godotenv.Load()

	// Get database URL
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL not set")
	}

	// Connect
	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer pool.Close()

	fmt.Println("✓ Connected to database\n")

	// Read and execute migration
	sqlContent, err := os.ReadFile("../database/migrations/014_create_role_system_clean.sql")
	if err != nil {
		log.Fatalf("Failed to read SQL file: %v", err)
	}

	fmt.Println("Executing migration...")
	_, err = pool.Exec(context.Background(), string(sqlContent))
	if err != nil {
		log.Fatalf("Failed to execute migration: %v", err)
	}

	fmt.Println("✓ Migration executed successfully\n")

	// Verify
	var count int
	pool.QueryRow(context.Background(), "SELECT COUNT(*) FROM v_all_users").Scan(&count)
	fmt.Printf("✓ v_all_users view created with %d users\n\n", count)

	fmt.Println("============================================")
	fmt.Println("Migration 014 Completed!")
	fmt.Println("============================================\n")
	fmt.Println("Staff Login Credentials:")
	fmt.Println("  Manager: manager@hotel.com / staff123")
	fmt.Println("  Receptionist: receptionist1@hotel.com / staff123")
	fmt.Println("  Housekeeper: housekeeper1@hotel.com / staff123\n")
}
