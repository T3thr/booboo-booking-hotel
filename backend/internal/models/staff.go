package models

import (
	"time"
)

// Staff represents a hotel staff member
type Staff struct {
	StaffID   int       `json:"staff_id" db:"staff_id"`
	FirstName string    `json:"first_name" db:"first_name"`
	LastName  string    `json:"last_name" db:"last_name"`
	Email     string    `json:"email" db:"email"`
	Phone     *string   `json:"phone" db:"phone"`
	RoleID    int       `json:"role_id" db:"role_id"`
	IsActive  bool      `json:"is_active" db:"is_active"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`

	// Joined fields
	RoleCode string `json:"role_code" db:"role_code"`
	RoleName string `json:"role_name" db:"role_name"`
}

// StaffAccount represents staff authentication data
type StaffAccount struct {
	StaffAccountID int        `json:"staff_account_id" db:"staff_account_id"`
	StaffID        int        `json:"staff_id" db:"staff_id"`
	HashedPassword string     `json:"-" db:"hashed_password"`
	LastLogin      *time.Time `json:"last_login" db:"last_login"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
}

// Role represents user roles
type Role struct {
	RoleID      int       `json:"role_id" db:"role_id"`
	RoleName    string    `json:"role_name" db:"role_name"`
	RoleCode    string    `json:"role_code" db:"role_code"`
	Description *string   `json:"description" db:"description"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// UnifiedUser represents a user from the v_all_users view
type UnifiedUser struct {
	UserType       string     `json:"user_type" db:"user_type"`
	UserID         int        `json:"user_id" db:"user_id"`
	FirstName      string     `json:"first_name" db:"first_name"`
	LastName       string     `json:"last_name" db:"last_name"`
	Email          string     `json:"email" db:"email"`
	Phone          *string    `json:"phone" db:"phone"`
	RoleCode       string     `json:"role_code" db:"role_code"`
	RoleName       string     `json:"role_name" db:"role_name"`
	HashedPassword string     `json:"-" db:"hashed_password"`
	LastLogin      *time.Time `json:"last_login" db:"last_login"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
}

// GetFullName returns the full name of the staff member
func (s *Staff) GetFullName() string {
	return s.FirstName + " " + s.LastName
}

// GetFullName returns the full name from unified user
func (u *UnifiedUser) GetFullName() string {
	return u.FirstName + " " + u.LastName
}

// IsGuest checks if the user is a guest
func (u *UnifiedUser) IsGuest() bool {
	return u.UserType == "guest"
}

// IsStaff checks if the user is staff
func (u *UnifiedUser) IsStaff() bool {
	return u.UserType == "staff"
}

// HasRole checks if the user has a specific role
func (u *UnifiedUser) HasRole(roleCode string) bool {
	return u.RoleCode == roleCode
}

// CanAccess checks if the user can access a specific resource
func (u *UnifiedUser) CanAccess(requiredRoles []string) bool {
	for _, role := range requiredRoles {
		if u.RoleCode == role {
			return true
		}
	}
	return false
}
