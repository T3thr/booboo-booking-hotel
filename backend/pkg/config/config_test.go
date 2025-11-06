package config

import (
	"os"
	"testing"
)

func TestLoad(t *testing.T) {
	// Set test environment variables
	os.Setenv("DB_PASSWORD", "testpass")
	os.Setenv("JWT_SECRET", "testsecret")
	
	cfg, err := Load()
	if err != nil {
		t.Fatalf("Failed to load config: %v", err)
	}
	
	if cfg.Database.Password != "testpass" {
		t.Errorf("Expected DB password 'testpass', got '%s'", cfg.Database.Password)
	}
	
	if cfg.JWT.Secret != "testsecret" {
		t.Errorf("Expected JWT secret 'testsecret', got '%s'", cfg.JWT.Secret)
	}
}

func TestGetDSN(t *testing.T) {
	cfg := DatabaseConfig{
		Host:     "localhost",
		Port:     "5432",
		User:     "postgres",
		Password: "password",
		DBName:   "testdb",
		SSLMode:  "disable",
	}
	
	expected := "host=localhost port=5432 user=postgres password=password dbname=testdb sslmode=disable"
	dsn := cfg.GetDSN()
	
	if dsn != expected {
		t.Errorf("Expected DSN '%s', got '%s'", expected, dsn)
	}
}
