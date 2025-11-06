package utils

import (
	"testing"
	"time"
)

func TestGenerateToken(t *testing.T) {
	userID := 1
	email := "test@example.com"
	role := "guest"
	secret := "test-secret-key"

	token, err := GenerateToken(userID, email, role, secret)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	if token == "" {
		t.Error("Token should not be empty")
	}
}

func TestValidateToken(t *testing.T) {
	userID := 1
	email := "test@example.com"
	role := "guest"
	secret := "test-secret-key"

	// Generate token
	token, err := GenerateToken(userID, email, role, secret)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	// Validate token
	claims, err := ValidateToken(token, secret)
	if err != nil {
		t.Fatalf("Failed to validate token: %v", err)
	}

	if claims.UserID != userID {
		t.Errorf("Expected UserID %d, got %d", userID, claims.UserID)
	}

	if claims.Email != email {
		t.Errorf("Expected Email %s, got %s", email, claims.Email)
	}

	if claims.Role != role {
		t.Errorf("Expected Role %s, got %s", role, claims.Role)
	}

	// Check expiration
	if claims.ExpiresAt.Time.Before(time.Now()) {
		t.Error("Token should not be expired")
	}
}

func TestValidateTokenWithWrongSecret(t *testing.T) {
	userID := 1
	email := "test@example.com"
	role := "guest"
	secret := "test-secret-key"
	wrongSecret := "wrong-secret-key"

	// Generate token with correct secret
	token, err := GenerateToken(userID, email, role, secret)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	// Try to validate with wrong secret
	_, err = ValidateToken(token, wrongSecret)
	if err == nil {
		t.Error("Validation should fail with wrong secret")
	}
}

func TestValidateInvalidToken(t *testing.T) {
	secret := "test-secret-key"
	invalidToken := "invalid.token.string"

	_, err := ValidateToken(invalidToken, secret)
	if err == nil {
		t.Error("Validation should fail for invalid token")
	}
}
