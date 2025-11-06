package models

import "time"

// Guest represents a guest in the system
type Guest struct {
	GuestID   int       `json:"guest_id" db:"guest_id"`
	FirstName string    `json:"first_name" db:"first_name"`
	LastName  string    `json:"last_name" db:"last_name"`
	Email     string    `json:"email" db:"email"`
	Phone     string    `json:"phone" db:"phone"`
	RoleCode  string    `json:"role_code,omitempty" db:"role_code"`
	RoleName  string    `json:"role_name,omitempty" db:"role_name"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// GuestAccount represents authentication credentials
type GuestAccount struct {
	GuestAccountID int        `json:"guest_account_id" db:"guest_account_id"`
	GuestID        int        `json:"guest_id" db:"guest_id"`
	HashedPassword string     `json:"-" db:"hashed_password"` // Never expose in JSON
	LastLogin      *time.Time `json:"last_login,omitempty" db:"last_login"`
}

// GuestWithAccount combines guest and account information
type GuestWithAccount struct {
	Guest
	GuestAccountID int        `json:"guest_account_id"`
	LastLogin      *time.Time `json:"last_login,omitempty"`
}

// RegisterRequest represents registration input
type RegisterRequest struct {
	FirstName string `json:"first_name" binding:"required,min=2,max=100"`
	LastName  string `json:"last_name" binding:"required,min=2,max=100"`
	Email     string `json:"email" binding:"required,email"`
	Phone     string `json:"phone" binding:"required,min=10,max=20"`
	Password  string `json:"password" binding:"required,min=8"`
}

// LoginRequest represents login input
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse represents login output
type LoginResponse struct {
	ID          int    `json:"id"`
	Email       string `json:"email"`
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	Role        string `json:"role"`
	RoleCode    string `json:"role_code"`
	UserType    string `json:"user_type"`
	AccessToken string `json:"accessToken"`
}

// UpdateProfileRequest represents profile update input
type UpdateProfileRequest struct {
	FirstName string `json:"first_name" binding:"required,min=2,max=100"`
	LastName  string `json:"last_name" binding:"required,min=2,max=100"`
	Phone     string `json:"phone" binding:"required,min=10,max=20"`
}
