package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/jackc/pgx/v5/stdlib"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Connect to database
	db, err := sql.Open("pgx", "postgresql://postgres:postgres123@db:5432/hotel_booking?sslmode=disable")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Generate hash for password123
	hash, err := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Generated hash: %s\n", string(hash))

	// Update all guest accounts
	result, err := db.Exec(`
		UPDATE guest_accounts 
		SET hashed_password = $1
		WHERE guest_id IN (
			SELECT guest_id FROM guests 
			WHERE email IN ('somchai@example.com', 'somying@example.com', 'prayut@example.com', 'yingluck@example.com', 'abhisit@example.com')
		)
	`, string(hash))
	
	if err != nil {
		log.Fatal(err)
	}

	rows, _ := result.RowsAffected()
	fmt.Printf("Updated %d accounts\n", rows)

	// Create anan.test@example.com
	var guestID int
	err = db.QueryRow(`
		INSERT INTO guests (first_name, last_name, email, phone) 
		VALUES ('Anan', 'Testsawat', 'anan.test@example.com', '0812345001')
		ON CONFLICT (email) DO UPDATE SET first_name = EXCLUDED.first_name
		RETURNING guest_id
	`).Scan(&guestID)
	
	if err != nil {
		log.Printf("Guest insert error: %v\n", err)
	} else {
		fmt.Printf("Guest ID: %d\n", guestID)
		
		// Add account
		_, err = db.Exec(`
			INSERT INTO guest_accounts (guest_id, hashed_password)
			VALUES ($1, $2)
			ON CONFLICT (guest_id) DO UPDATE SET hashed_password = EXCLUDED.hashed_password
		`, guestID, string(hash))
		
		if err != nil {
			log.Printf("Account insert error: %v\n", err)
		} else {
			fmt.Println("Account created/updated for anan.test@example.com")
		}
	}

	fmt.Println("\nAll passwords set to: password123")
}
