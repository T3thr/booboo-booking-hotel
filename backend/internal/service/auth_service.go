package service

import (
	"context"
	"errors"
	"fmt"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
	"github.com/hotel-booking-system/backend/pkg/utils"
)

// AuthService handles authentication business logic
type AuthService struct {
	authRepo  *repository.AuthRepository
	jwtSecret string
}

// NewAuthService creates a new auth service
func NewAuthService(authRepo *repository.AuthRepository, jwtSecret string) *AuthService {
	return &AuthService{
		authRepo:  authRepo,
		jwtSecret: jwtSecret,
	}
}

// Register registers a new guest
func (s *AuthService) Register(ctx context.Context, req *models.RegisterRequest) (*models.LoginResponse, error) {
	// Check if email already exists
	exists, err := s.authRepo.EmailExists(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("failed to check email: %w", err)
	}

	if exists {
		return nil, errors.New("อีเมลนี้ถูกลงทะเบียนแล้ว")
	}

	// Hash password
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create guest
	guest := &models.Guest{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Phone:     req.Phone,
	}

	if err := s.authRepo.CreateGuest(ctx, guest); err != nil {
		return nil, fmt.Errorf("failed to create guest: %w", err)
	}

	// Create guest account
	if err := s.authRepo.CreateGuestAccount(ctx, guest.GuestID, hashedPassword); err != nil {
		return nil, fmt.Errorf("failed to create guest account: %w", err)
	}

	// Generate token with GUEST role code
	token, err := utils.GenerateToken(guest.GuestID, guest.Email, "GUEST", s.jwtSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %w", err)
	}

	return &models.LoginResponse{
		ID:          guest.GuestID,
		Email:       guest.Email,
		FirstName:   guest.FirstName,
		LastName:    guest.LastName,
		Phone:       guest.Phone,
		Role:        "guest",
		RoleCode:    "GUEST",
		UserType:    "guest",
		AccessToken: token,
	}, nil
}

// Login authenticates a user (guest or staff)
func (s *AuthService) Login(ctx context.Context, req *models.LoginRequest) (*models.LoginResponse, error) {
	fmt.Printf("[LOGIN] Attempting login for email: %s\n", req.Email)
	
	// Get user by email from unified view
	user, err := s.authRepo.GetUserByEmail(ctx, req.Email)
	if err != nil {
		fmt.Printf("[LOGIN] Error getting user: %v\n", err)
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	if user == nil {
		fmt.Printf("[LOGIN] User not found for email: %s\n", req.Email)
		return nil, errors.New("อีเมลหรือรหัสผ่านไม่ถูกต้อง")
	}
	
	fmt.Printf("[LOGIN] Found user ID: %d, Type: %s, Role: %s\n", user.UserID, user.UserType, user.RoleCode)

	// Check password
	if !utils.CheckPassword(req.Password, user.HashedPassword) {
		fmt.Printf("[LOGIN] Password check FAILED\n")
		return nil, errors.New("อีเมลหรือรหัสผ่านไม่ถูกต้อง")
	}
	
	fmt.Printf("[LOGIN] Password check SUCCESS\n")

	// Update last login based on user type
	if user.IsGuest() {
		// Get guest account to update last login
		account, err := s.authRepo.GetGuestAccountByGuestID(ctx, user.UserID)
		if err == nil && account != nil {
			if err := s.authRepo.UpdateLastLogin(ctx, account.GuestAccountID); err != nil {
				fmt.Printf("Failed to update guest last login: %v\n", err)
			}
		}
	} else if user.IsStaff() {
		// Update staff last login
		if err := s.authRepo.UpdateStaffLastLogin(ctx, user.UserID); err != nil {
			fmt.Printf("Failed to update staff last login: %v\n", err)
		}
	}

	// Generate token with role code (GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
	token, err := utils.GenerateToken(user.UserID, user.Email, user.RoleCode, s.jwtSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to generate token: %w", err)
	}

	// Dereference phone pointer, use empty string if nil
	phone := ""
	if user.Phone != nil {
		phone = *user.Phone
	}

	return &models.LoginResponse{
		ID:          user.UserID,
		Email:       user.Email,
		FirstName:   user.FirstName,
		LastName:    user.LastName,
		Phone:       phone,
		Role:        user.UserType,
		RoleCode:    user.RoleCode,
		UserType:    user.UserType,
		AccessToken: token,
	}, nil
}

// GetProfile retrieves guest profile
func (s *AuthService) GetProfile(ctx context.Context, guestID int) (*models.Guest, error) {
	guest, err := s.authRepo.GetGuestByID(ctx, guestID)
	if err != nil {
		return nil, fmt.Errorf("failed to get guest: %w", err)
	}

	if guest == nil {
		return nil, errors.New("guest not found")
	}

	return guest, nil
}

// UpdateProfile updates guest profile
func (s *AuthService) UpdateProfile(ctx context.Context, guestID int, req *models.UpdateProfileRequest) (*models.Guest, error) {
	// Get existing guest
	guest, err := s.authRepo.GetGuestByID(ctx, guestID)
	if err != nil {
		return nil, fmt.Errorf("failed to get guest: %w", err)
	}

	if guest == nil {
		return nil, errors.New("guest not found")
	}

	// Update fields
	guest.FirstName = req.FirstName
	guest.LastName = req.LastName
	guest.Phone = req.Phone

	// Save to database
	if err := s.authRepo.UpdateGuest(ctx, guest); err != nil {
		return nil, fmt.Errorf("failed to update guest: %w", err)
	}

	return guest, nil
}
