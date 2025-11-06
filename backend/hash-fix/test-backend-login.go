package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
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

	email := "anan.test@example.com"
	password := "password123"

	fmt.Println("Testing login flow for:", email)
	fmt.Println()

	// Step 1: Get guest by email
	var guestID int
	var firstName, lastName, guestEmail, phone string
	err = conn.QueryRow(context.Background(),
		`SELECT guest_id, first_name, last_name, email, phone 
		 FROM guests WHERE email = $1`, email).Scan(
		&guestID, &firstName, &lastName, &guestEmail, &phone)

	if err != nil {
		log.Fatal("Guest not found:", err)
	}

	fmt.Printf("✓ Found guest: %s %s (ID: %d)\n", firstName, lastName, guestID)

	// Step 2: Get guest account
	var accountID int
	var hashedPassword string
	err = conn.QueryRow(context.Background(),
		`SELECT guest_account_id, hashed_password 
		 FROM guest_accounts WHERE guest_id = $1`, guestID).Scan(
		&accountID, &hashedPassword)

	if err != nil {
		log.Fatal("Account not found:", err)
	}

	fmt.Printf("✓ Found account (ID: %d)\n", accountID)
	fmt.Printf("  Hash: %s\n", hashedPassword)

	// Step 3: Verify password
	err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
	if err == nil {
		fmt.Println("✓ Password verification SUCCESS!")
		fmt.Println()
		fmt.Println("Login should work!")
	} else {
		fmt.Println("✗ Password verification FAILED:", err)
		fmt.Println()
		fmt.Println("This is why login fails!")
	}
}
