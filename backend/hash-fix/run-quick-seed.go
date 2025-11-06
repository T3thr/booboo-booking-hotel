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
	// Load .env from backend directory
	if err := godotenv.Load("../.env"); err != nil {
		log.Fatal("Error loading .env file:", err)
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL not set in .env file")
	}

	conn, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		log.Fatal("Unable to connect:", err)
	}
	defer conn.Close(context.Background())

	// Read SQL file
	sqlBytes, err := os.ReadFile("quick-seed.sql")
	if err != nil {
		log.Fatal("Failed to read SQL file:", err)
	}

	// Execute SQL
	_, err = conn.Exec(context.Background(), string(sqlBytes))
	if err != nil {
		log.Fatal("Failed to execute SQL:", err)
	}

	fmt.Println("✓ Demo users created successfully!")
	fmt.Println()
	fmt.Println("Login credentials:")
	fmt.Println("  Email: anan.test@example.com")
	fmt.Println("  Password: password123")
	fmt.Println()
}
