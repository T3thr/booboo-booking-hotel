package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Load .env
	godotenv.Load()

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL not set")
	}

	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer pool.Close()

	fmt.Println("Checking staff password hashes...")
	fmt.Println("===========================================\n")

	// Query staff accounts
	rows, err := pool.Query(context.Background(), `
		SELECT s.email, sa.hashed_password
		FROM staff s
		JOIN staff_accounts sa ON s.staff_id = sa.staff_id
		WHERE s.email = 'housekeeper1@hotel.com'
		LIMIT 1
	`)
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var email, hash string
		if err := rows.Scan(&email, &hash); err != nil {
			continue
		}

		fmt.Printf("Email: %s\n", email)
		fmt.Printf("Hash in DB: %s\n\n", hash)

		// Test password
		testPassword := "staff123"
		err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(testPassword))
		if err == nil {
			fmt.Printf("✓ Password '%s' MATCHES!\n", testPassword)
		} else {
			fmt.Printf("✗ Password '%s' DOES NOT MATCH\n", testPassword)
			fmt.Printf("Error: %v\n\n", err)

			// Try generating a new hash
			newHash, _ := bcrypt.GenerateFromPassword([]byte(testPassword), bcrypt.DefaultCost)
			fmt.Printf("Expected hash for '%s':\n%s\n", testPassword, string(newHash))
		}
	}
}
