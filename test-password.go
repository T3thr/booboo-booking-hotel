package main

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "password123"
	
	// Hash from database
	hashFromDB := "$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K"
	
	// Test if password matches
	err := bcrypt.CompareHashAndPassword([]byte(hashFromDB), []byte(password))
	if err == nil {
		fmt.Println("✓ Password matches!")
	} else {
		fmt.Printf("✗ Password does NOT match: %v\n", err)
	}
	
	// Generate new hash for comparison
	newHash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	fmt.Printf("\nNew hash for 'password123':\n%s\n", string(newHash))
}
