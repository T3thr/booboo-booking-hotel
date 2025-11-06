package repository

import (
	"context"
	"errors"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/database"
	"github.com/jackc/pgx/v5"
)

// AuthRepository handles authentication database operations
type AuthRepository struct {
	db *database.DB
}

// NewAuthRepository creates a new auth repository
func NewAuthRepository(db *database.DB) *AuthRepository {
	return &AuthRepository{db: db}
}

// CreateGuest creates a new guest
func (r *AuthRepository) CreateGuest(ctx context.Context, guest *models.Guest) error {
	query := `
		INSERT INTO guests (first_name, last_name, email, phone)
		VALUES ($1, $2, $3, $4)
		RETURNING guest_id, created_at, updated_at
	`

	return r.db.Pool.QueryRow(ctx, query,
		guest.FirstName,
		guest.LastName,
		guest.Email,
		guest.Phone,
	).Scan(&guest.GuestID, &guest.CreatedAt, &guest.UpdatedAt)
}

// CreateGuestAccount creates a guest account with hashed password
func (r *AuthRepository) CreateGuestAccount(ctx context.Context, guestID int, hashedPassword string) error {
	query := `
		INSERT INTO guest_accounts (guest_id, hashed_password)
		VALUES ($1, $2)
	`

	_, err := r.db.Pool.Exec(ctx, query, guestID, hashedPassword)
	return err
}

// GetUserByEmail retrieves any user (guest or staff) by email from unified view
func (r *AuthRepository) GetUserByEmail(ctx context.Context, email string) (*models.UnifiedUser, error) {
	query := `
		SELECT 
			user_type,
			user_id, 
			first_name, 
			last_name, 
			email, 
			phone, 
			role_code,
			role_name,
			hashed_password,
			last_login,
			created_at
		FROM v_all_users
		WHERE email = $1
	`

	var user models.UnifiedUser
	err := r.db.Pool.QueryRow(ctx, query, email).Scan(
		&user.UserType,
		&user.UserID,
		&user.FirstName,
		&user.LastName,
		&user.Email,
		&user.Phone,
		&user.RoleCode,
		&user.RoleName,
		&user.HashedPassword,
		&user.LastLogin,
		&user.CreatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return &user, nil
}

// GetGuestByEmail retrieves a guest by email with role information
func (r *AuthRepository) GetGuestByEmail(ctx context.Context, email string) (*models.Guest, error) {
	query := `
		SELECT 
			user_id as guest_id, 
			first_name, 
			last_name, 
			email, 
			phone, 
			role_code,
			role_name,
			hashed_password,
			created_at
		FROM v_all_users
		WHERE email = $1 AND user_type = 'guest'
	`

	var guest models.Guest
	var hashedPassword string
	err := r.db.Pool.QueryRow(ctx, query, email).Scan(
		&guest.GuestID,
		&guest.FirstName,
		&guest.LastName,
		&guest.Email,
		&guest.Phone,
		&guest.RoleCode,
		&guest.RoleName,
		&hashedPassword,
		&guest.CreatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	// Set updated_at to created_at if not available
	guest.UpdatedAt = guest.CreatedAt

	return &guest, nil
}

// GetGuestAccountByGuestID retrieves guest account by guest ID
func (r *AuthRepository) GetGuestAccountByGuestID(ctx context.Context, guestID int) (*models.GuestAccount, error) {
	query := `
		SELECT guest_account_id, guest_id, hashed_password, last_login
		FROM guest_accounts
		WHERE guest_id = $1
	`

	var account models.GuestAccount
	err := r.db.Pool.QueryRow(ctx, query, guestID).Scan(
		&account.GuestAccountID,
		&account.GuestID,
		&account.HashedPassword,
		&account.LastLogin,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return &account, nil
}

// UpdateLastLogin updates the last login timestamp for guest
func (r *AuthRepository) UpdateLastLogin(ctx context.Context, guestAccountID int) error {
	query := `
		UPDATE guest_accounts
		SET last_login = $1
		WHERE guest_account_id = $2
	`

	_, err := r.db.Pool.Exec(ctx, query, time.Now(), guestAccountID)
	return err
}

// UpdateStaffLastLogin updates the last login timestamp for staff
func (r *AuthRepository) UpdateStaffLastLogin(ctx context.Context, staffID int) error {
	query := `
		UPDATE staff_accounts
		SET last_login = $1
		WHERE staff_id = $2
	`

	_, err := r.db.Pool.Exec(ctx, query, time.Now(), staffID)
	return err
}

// GetGuestByID retrieves a guest by ID
func (r *AuthRepository) GetGuestByID(ctx context.Context, guestID int) (*models.Guest, error) {
	query := `
		SELECT guest_id, first_name, last_name, email, phone, created_at, updated_at
		FROM guests
		WHERE guest_id = $1
	`

	var guest models.Guest
	err := r.db.Pool.QueryRow(ctx, query, guestID).Scan(
		&guest.GuestID,
		&guest.FirstName,
		&guest.LastName,
		&guest.Email,
		&guest.Phone,
		&guest.CreatedAt,
		&guest.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	return &guest, nil
}

// UpdateGuest updates guest information
func (r *AuthRepository) UpdateGuest(ctx context.Context, guest *models.Guest) error {
	query := `
		UPDATE guests
		SET first_name = $1, last_name = $2, phone = $3, updated_at = $4
		WHERE guest_id = $5
	`

	_, err := r.db.Pool.Exec(ctx, query,
		guest.FirstName,
		guest.LastName,
		guest.Phone,
		time.Now(),
		guest.GuestID,
	)

	return err
}

// EmailExists checks if an email already exists
func (r *AuthRepository) EmailExists(ctx context.Context, email string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM guests WHERE email = $1)`

	var exists bool
	err := r.db.Pool.QueryRow(ctx, query, email).Scan(&exists)
	return exists, err
}
