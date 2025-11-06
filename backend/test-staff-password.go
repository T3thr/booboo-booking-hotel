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
	fmt.Println("============================================")
	fmt.Println("Testing Staff Password Hashes")
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

	// Test password: "staff123"
	testPassword := "staff123"
	
	// Get staff accounts
	rows, err := pool.Query(context.Background(), `
		SELECT s.email, sa.hashed_password 
		FROM staff s
		JOIN staff_accounts sa ON s.staff_id = sa.staff_id
		WHERE s.email LIKE '%@hotel.com'
		LIMIT 5
	`)
	if err != nil {
		log.Fatalf("Failed to query: %v", err)
	}
	defer rows.Close()

	fmt.Println("Testing password 'staff123' against database hashes:\n")
	fmt.Println("Email                          | Hash Match")
	fmt.Println("-----------------------------------------------------------")

	for rows.Next() {
		var email, hash string
		if err := rows.Scan(&email, &hash); err != nil {
			log.Printf("Error scanning: %v", err)
			continue
		}

		// Test password
		err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(testPassword))
		match := "✗ FAIL"
		if err == nil {
			match = "✓ PASS"
		}

		fmt.Printf("%-30s | %s\n", email, match)
	}

	fmt.Println("\n============================================")
	fmt.Println("Generating correct hash for 'staff123':")
	fmt.Println("============================================\n")

	// Generate correct hash
	correctHash, err := bcrypt.GenerateFromPassword([]byte(testPassword), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to generate hash: %v", err)
	}

	fmt.Printf("Password: %s\n", testPassword)
	fmt.Printf("Hash: %s\n\n", string(correctHash))

	// Verify it works
	err = bcrypt.CompareHashAndPassword(correctHash, []byte(testPassword))
	if err == nil {
		fmt.Println("✓ New hash verification: SUCCESS")
	} else {
		fmt.Println("✗ New hash verification: FAILED")
	}
}
