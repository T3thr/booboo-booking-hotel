package main

import (
	"fmt"
	"log"

	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "staff123"
	
	// Generate hash
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatal(err)
	}

	// Verify it works
	err = bcrypt.CompareHashAndPassword(hash, []byte(password))
	if err != nil {
		log.Fatal("Hash verification failed!")
	}

	fmt.Println("-- Fix Staff Passwords SQL")
	fmt.Println("-- Password: staff123")
	fmt.Println()
	fmt.Println("UPDATE staff_accounts")
	fmt.Printf("SET hashed_password = '%s'\n", string(hash))
	fmt.Println("WHERE staff_id IN (SELECT staff_id FROM staff WHERE email LIKE '%@hotel.com');")
	fmt.Println()
	fmt.Println("-- Verify:")
	fmt.Println("SELECT s.email, r.role_code FROM staff s")
	fmt.Println("JOIN staff_accounts sa ON s.staff_id = sa.staff_id")
	fmt.Println("JOIN roles r ON s.role_id = r.role_id")
	fmt.Println("WHERE s.email LIKE '%@hotel.com';")
}
