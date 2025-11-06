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

	// Query the hash from database
	var hashedPassword string
	err = conn.QueryRow(context.Background(),
		"SELECT hashed_password FROM guest_accounts WHERE guest_id = 1").Scan(&hashedPassword)
	if err != nil {
		log.Fatal("Query failed:", err)
	}

	fmt.Println("Hash from database:")
	fmt.Println(hashedPassword)
	fmt.Println()

	// Test if it works with password123
	password := "password123"
	err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
	if err == nil {
		fmt.Println("✓ Database hash is CORRECT! Password verification works!")
	} else {
		fmt.Println("✗ Database hash is WRONG! Password verification failed:", err)
	}
}
