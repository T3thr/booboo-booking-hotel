package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file
	if err := godotenv.Load("../.env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// Get database URL
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL not set")
	}

	// Connect to database
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer conn.Close(ctx)

	fmt.Println("========================================")
	fmt.Println("Fix Hold Ambiguous Error")
	fmt.Println("========================================")
	fmt.Println()

	// Read SQL file
	sqlContent, err := os.ReadFile("../../database/migrations/005_create_booking_hold_function.sql")
	if err != nil {
		log.Fatalf("Failed to read SQL file: %v", err)
	}

	// Execute SQL
	fmt.Println("Recreating booking hold function...")
	_, err = conn.Exec(ctx, string(sqlContent))
	if err != nil {
		log.Fatalf("Failed to execute SQL: %v", err)
	}

	fmt.Println("✅ Function recreated successfully!")
	fmt.Println()
	fmt.Println("========================================")
	fmt.Println("Next steps:")
	fmt.Println("1. Rebuild backend: cd backend && go build -o bin/server.exe cmd/server/main.go")
	fmt.Println("2. Restart backend server")
	fmt.Println("3. Test booking hold on frontend")
	fmt.Println("========================================")
}
