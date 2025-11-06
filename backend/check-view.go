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
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// Get database URL
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL not set")
	}

	// Connect to database
	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer pool.Close()

	fmt.Println("✓ Connected to database")
	fmt.Println()

	// Check if v_all_users view exists
	var exists bool
	err = pool.QueryRow(context.Background(), `
		SELECT EXISTS (
			SELECT 1 FROM information_schema.views 
			WHERE table_name = 'v_all_users'
		)
	`).Scan(&exists)

	if err != nil {
		log.Fatalf("Error checking view: %v", err)
	}

	if exists {
		fmt.Println("✓ v_all_users view EXISTS")
		fmt.Println()

		// Test query on the view
		var count int
		err = pool.QueryRow(context.Background(), `SELECT COUNT(*) FROM v_all_users`).Scan(&count)
		if err != nil {
			log.Fatalf("Error querying view: %v", err)
		}
		fmt.Printf("✓ View has %d users\n", count)
		fmt.Println()

		// Show sample data
		rows, err := pool.Query(context.Background(), `
			SELECT user_type, user_id, email, role_code 
			FROM v_all_users 
			LIMIT 5
		`)
		if err != nil {
			log.Fatalf("Error querying sample data: %v", err)
		}
		defer rows.Close()

		fmt.Println("Sample users:")
		fmt.Println("----------------------------------------")
		for rows.Next() {
			var userType, email, roleCode string
			var userID int
			if err := rows.Scan(&userType, &userID, &email, &roleCode); err != nil {
				log.Printf("Error scanning row: %v", err)
				continue
			}
			fmt.Printf("Type: %-6s | ID: %-3d | Email: %-30s | Role: %s\n", 
				userType, userID, email, roleCode)
		}
	} else {
		fmt.Println("✗ v_all_users view DOES NOT EXIST")
		fmt.Println()
		fmt.Println("You need to run migration 014:")
		fmt.Println("  cd database/migrations")
		fmt.Println("  Run: 014_create_role_system_clean.sql")
	}

	// Check if staff table exists
	err = pool.QueryRow(context.Background(), `
		SELECT EXISTS (
			SELECT 1 FROM information_schema.tables 
			WHERE table_name = 'staff'
		)
	`).Scan(&exists)

	if err != nil {
		log.Fatalf("Error checking staff table: %v", err)
	}

	fmt.Println()
	if exists {
		fmt.Println("✓ staff table EXISTS")
		
		var staffCount int
		err = pool.QueryRow(context.Background(), `SELECT COUNT(*) FROM staff`).Scan(&staffCount)
		if err == nil {
			fmt.Printf("✓ Staff table has %d records\n", staffCount)
		}
	} else {
		fmt.Println("✗ staff table DOES NOT EXIST")
	}

	// Check if roles table exists
	err = pool.QueryRow(context.Background(), `
		SELECT EXISTS (
			SELECT 1 FROM information_schema.tables 
			WHERE table_name = 'roles'
		)
	`).Scan(&exists)

	if err != nil {
		log.Fatalf("Error checking roles table: %v", err)
	}

	fmt.Println()
	if exists {
		fmt.Println("✓ roles table EXISTS")
		
		var roleCount int
		err = pool.QueryRow(context.Background(), `SELECT COUNT(*) FROM roles`).Scan(&roleCount)
		if err == nil {
			fmt.Printf("✓ Roles table has %d records\n", roleCount)
		}
	} else {
		fmt.Println("✗ roles table DOES NOT EXIST")
	}
}
