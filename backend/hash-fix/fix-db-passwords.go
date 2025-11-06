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

	// Connect to database
	conn, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		log.Fatal("Unable to connect to database:", err)
	}
	defer conn.Close(context.Background())

	fmt.Println("Connected to database successfully!")

	// The correct bcrypt hash for "password123"
	correctHash := "$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK"

	// Update passwords for demo users
	query := `
		UPDATE guest_accounts
		SET hashed_password = $1
		WHERE guest_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	`

	result, err := conn.Exec(context.Background(), query, correctHash)
	if err != nil {
		log.Fatal("Failed to update passwords:", err)
	}

	rowsAffected := result.RowsAffected()
	fmt.Printf("✓ Updated %d user passwords successfully!\n", rowsAffected)
	fmt.Println()
	fmt.Println("You can now login with:")
	fmt.Println("  Email: anan.test@example.com")
	fmt.Println("  Password: password123")
	fmt.Println()
}
