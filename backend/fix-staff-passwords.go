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
	fmt.Println("Fixing Staff Password Hashes")
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

	// Generate correct hash for "staff123"
	password := "staff123"
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to generate hash: %v", err)
	}

	fmt.Printf("Password: %s\n", password)
	fmt.Printf("New Hash: %s\n\n", string(hash))

	// Verify the hash works
	err = bcrypt.CompareHashAndPassword(hash, []byte(password))
	if err != nil {
		log.Fatal("Hash verification failed!")
	}
	fmt.Println("✓ Hash verification: SUCCESS\n")

	// Update all staff accounts
	fmt.Println("Updating staff_accounts table...")
	result, err := pool.Exec(context.Background(), `
		UPDATE staff_accounts 
		SET hashed_password = $1
		WHERE staff_id IN (SELECT staff_id FROM staff WHERE email LIKE '%@hotel.com')
	`, string(hash))
	
	if err != nil {
		log.Fatalf("Failed to update: %v", err)
	}

	rowsAffected := result.RowsAffected()
	fmt.Printf("✓ Updated %d staff accounts\n\n", rowsAffected)

	// Verify updates
	fmt.Println("Verifying updates...")
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

	fmt.Println("\nStaff Accounts:")
	fmt.Println("-----------------------------------------------------------")
	for rows.Next() {
		var email, firstName, lastName, roleCode string
		if err := rows.Scan(&email, &firstName, &lastName, &roleCode); err != nil {
			log.Printf("Error scanning: %v", err)
			continue
		}
		fmt.Printf("%-30s | %s %s | %s\n", email, firstName, lastName, roleCode)
	}

	fmt.Println("\n============================================")
	fmt.Println("Password Fix Complete!")
	fmt.Println("============================================\n")
	fmt.Println("All staff can now login with:")
	fmt.Println("  Password: staff123\n")
	fmt.Println("Test accounts:")
	fmt.Println("  manager@hotel.com")
	fmt.Println("  receptionist1@hotel.com")
	fmt.Println("  housekeeper1@hotel.com\n")
}
