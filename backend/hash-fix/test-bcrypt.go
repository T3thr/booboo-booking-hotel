package main

import (
	"fmt"
	"log"

	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Load .env from backend directory
	if err := godotenv.Load("../.env"); err != nil {
		log.Println("Warning: .env file not found")
	}

	password := "password123"
	
	// Hash ที่เราใส่ใน database
	dbHash := "$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK"
	
	// Hash เก่าที่มีใน seed data
	oldHash := "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"
	
	fmt.Println("Testing password:", password)
	fmt.Println()
	
	// Test new hash
	err := bcrypt.CompareHashAndPassword([]byte(dbHash), []byte(password))
	if err == nil {
		fmt.Println("✓ New hash WORKS!")
	} else {
		fmt.Println("✗ New hash FAILED:", err)
	}
	
	// Test old hash
	err = bcrypt.CompareHashAndPassword([]byte(oldHash), []byte(password))
	if err == nil {
		fmt.Println("✓ Old hash WORKS!")
	} else {
		fmt.Println("✗ Old hash FAILED:", err)
	}
}
