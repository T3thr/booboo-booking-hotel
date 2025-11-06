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
	fmt.Println("Fixing Staff Passwords")
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

	// Read SQL file
	sqlContent, err := os.ReadFile("../database/migrations/fix_staff_passwords_now.sql")
	if err != nil {
		log.Fatalf("Failed to read SQL file: %v", err)
	}

	// Execute
	fmt.Println("Updating staff passwords...")
	_, err = pool.Exec(context.Background(), string(sqlContent))
	if err != nil {
		log.Fatalf("Failed to execute: %v", err)
	}

	fmt.Println("✓ Passwords updated successfully\n")

	// Verify
	rows, err := pool.Query(context.Background(), `
		SELECT s.email, s.first_name, s.last_name, r.role_code
		FROM staff s
		JOIN staff_accounts sa ON s.staff_id = sa.staff_id
		JOIN roles r ON s.role_id = r.role_id
		WHERE s.email LIKE '%@hotel.com'
		ORDER BY s.staff_id
	`)
	if err != nil {
		log.Fatalf("Failed to query: %v", err)
	}
	defer rows.Close()

	fmt.Println("Staff Accounts:")
	fmt.Println("-----------------------------------------------------------")
	for rows.Next() {
		var email, firstName, lastName, roleCode string
		if err := rows.Scan(&email, &firstName, &lastName, &roleCode); err != nil {
			continue
		}
		fmt.Printf("%-30s | %s %s | %s\n", email, firstName, lastName, roleCode)
	}

	fmt.Println("\n============================================")
	fmt.Println("Fix Complete!")
	fmt.Println("============================================\n")
	fmt.Println("All staff can now login with:")
	fmt.Println("  Password: staff123\n")
	fmt.Println("Test accounts:")
	fmt.Println("  manager@hotel.com / staff123")
	fmt.Println("  receptionist1@hotel.com / staff123")
	fmt.Println("  housekeeper1@hotel.com / staff123\n")
}
