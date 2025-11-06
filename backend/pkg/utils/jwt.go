package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims represents JWT token claims with enhanced role support
type Claims struct {
	UserID   int    `json:"user_id"`
	Email    string `json:"email"`
	Role     string `json:"role"`      // Role code (GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
	UserType string `json:"user_type"` // User type (guest, staff)
	jwt.RegisteredClaims
}

// GenerateToken creates a JWT token with user information and role
func GenerateToken(userID int, email, roleCode, secret string) (string, error) {
	// Determine user type based on role
	userType := "guest"
	if roleCode != "GUEST" {
		userType = "staff"
	}
	
	claims := Claims{
		UserID:   userID,
		Email:    email,
		Role:     roleCode,
		UserType: userType,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "booking-hotel-api",
			Subject:   email,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ValidateToken validates and parses a JWT token
func ValidateToken(tokenString, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		// Additional validation
		if claims.UserID <= 0 {
			return nil, errors.New("invalid user ID in token")
		}
		if claims.Email == "" {
			return nil, errors.New("invalid email in token")
		}
		if claims.Role == "" {
			return nil, errors.New("invalid role in token")
		}
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// RefreshToken creates a new token with extended expiration
func RefreshToken(claims *Claims, secret string) (string, error) {
	// Create new claims with extended expiration
	newClaims := Claims{
		UserID:   claims.UserID,
		Email:    claims.Email,
		Role:     claims.Role,
		UserType: claims.UserType,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "booking-hotel-api",
			Subject:   claims.Email,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, newClaims)
	return token.SignedString([]byte(secret))
}

// IsTokenExpired checks if token is expired
func IsTokenExpired(claims *Claims) bool {
	return claims.ExpiresAt.Time.Before(time.Now())
}

// GetTokenTimeLeft returns remaining time before token expires
func GetTokenTimeLeft(claims *Claims) time.Duration {
	return time.Until(claims.ExpiresAt.Time)
}

// IsGuest checks if the token belongs to a guest
func (c *Claims) IsGuest() bool {
	return c.Role == "GUEST"
}

// IsStaff checks if the token belongs to staff
func (c *Claims) IsStaff() bool {
	return c.Role == "RECEPTIONIST" || c.Role == "HOUSEKEEPER" || c.Role == "MANAGER"
}

// IsManager checks if the token belongs to a manager
func (c *Claims) IsManager() bool {
	return c.Role == "MANAGER"
}

// HasRole checks if the token has a specific role
func (c *Claims) HasRole(role string) bool {
	return c.Role == role
}

// HasAnyRole checks if the token has any of the specified roles
func (c *Claims) HasAnyRole(roles ...string) bool {
	for _, role := range roles {
		if c.Role == role {
			return true
		}
	}
	return false
}

// CanAccess checks if the user can access a resource based on required roles
func (c *Claims) CanAccess(requiredRoles []string) bool {
	return c.HasAnyRole(requiredRoles...)
}
