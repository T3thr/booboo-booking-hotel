package main

import (
	"context"
	"fmt"
	"os"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	godotenv.Load()
	dbURL := os.Getenv("DATABASE_URL")
	pool, _ := pgxpool.New(context.Background(), dbURL)
	defer pool.Close()

	// Generate hash
	hash, _ := bcrypt.GenerateFromPassword([]byte("staff123"), 10)
	
	// Update
	pool.Exec(context.Background(), 
		"UPDATE staff_accounts SET hashed_password = $1 WHERE staff_id IN (SELECT staff_id FROM staff WHERE email LIKE '%@hotel.com')", 
		string(hash))
	
	fmt.Println("✓ Staff passwords fixed!")
	fmt.Println("Password: staff123")
	fmt.Println("\nTest with:")
	fmt.Println("  manager@hotel.com")
	fmt.Println("  receptionist1@hotel.com")
	fmt.Println("  housekeeper1@hotel.com")
}
