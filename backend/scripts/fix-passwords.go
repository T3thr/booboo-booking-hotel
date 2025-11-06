package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5"
)

func main() {
	fmt.Println("=== Fixing Password Hashes ===")

	// Build connection string
	dbURL := "host=ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech port=5432 user=neondb_owner password=npg_8kHamXSLKg1x dbname=neondb sslmode=require"

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

	// Correct bcrypt hash for "password123"
	correctHash := "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"

	// Update all demo account passwords
	query := `UPDATE guest_accounts 
	          SET hashed_password = $1 
	          WHERE guest_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)`

	result, err := conn.Exec(ctx, query, correctHash)
	if err != nil {
		log.Fatalf("Failed to update passwords: %v", err)
	}

	rowsAffected := result.RowsAffected()
	fmt.Printf("✓ Updated %d password hashes\n", rowsAffected)

	// Verify the update
	var count int
	err = conn.QueryRow(ctx, `
		SELECT COUNT(*) 
		FROM guest_accounts 
		WHERE guest_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) 
		  AND hashed_password = $1
	`, correctHash).Scan(&count)
	
	if err != nil {
		log.Fatalf("Failed to verify update: %v", err)
	}

	fmt.Printf("✓ Verified: %d accounts now have correct password hash\n", count)
	fmt.Println("\n=== Password Fix Completed Successfully ===")
	fmt.Println("\nYou can now login with:")
	fmt.Println("  Email: anan.test@example.com")
	fmt.Println("  Password: password123")
}
