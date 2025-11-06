package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/database"
)

type PolicyRepository struct {
	db *database.DB
}

func NewPolicyRepository(db *database.DB) *PolicyRepository {
	return &PolicyRepository{db: db}
}

// ============================================================================
// Cancellation Policy Methods
// ============================================================================

// GetAllCancellationPolicies retrieves all cancellation policies
func (r *PolicyRepository) GetAllCancellationPolicies(ctx context.Context) ([]models.CancellationPolicy, error) {
	query := `
		SELECT policy_id, name, description, days_before_check_in, 
		       refund_percentage, is_active, created_at, updated_at
		FROM cancellation_policies
		ORDER BY name
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query cancellation policies: %w", err)
	}
	defer rows.Close()

	var policies []models.CancellationPolicy
	for rows.Next() {
		var policy models.CancellationPolicy
		err := rows.Scan(
			&policy.PolicyID,
			&policy.Name,
			&policy.Description,
			&policy.DaysBeforeCheckIn,
			&policy.RefundPercentage,
			&policy.IsActive,
			&policy.CreatedAt,
			&policy.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan cancellation policy: %w", err)
		}
		policies = append(policies, policy)
	}

	return policies, nil
}

// GetCancellationPolicyByID retrieves a cancellation policy by ID
func (r *PolicyRepository) GetCancellationPolicyByID(ctx context.Context, id int) (*models.CancellationPolicy, error) {
	query := `
		SELECT policy_id, name, description, days_before_check_in, 
		       refund_percentage, is_active, created_at, updated_at
		FROM cancellation_policies
		WHERE policy_id = $1
	`

	var policy models.CancellationPolicy
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&policy.PolicyID,
		&policy.Name,
		&policy.Description,
		&policy.DaysBeforeCheckIn,
		&policy.RefundPercentage,
		&policy.IsActive,
		&policy.CreatedAt,
		&policy.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get cancellation policy: %w", err)
	}

	return &policy, nil
}

// CreateCancellationPolicy creates a new cancellation policy
func (r *PolicyRepository) CreateCancellationPolicy(ctx context.Context, req *models.CreateCancellationPolicyRequest) (*models.CancellationPolicy, error) {
	query := `
		INSERT INTO cancellation_policies (name, description, days_before_check_in, refund_percentage)
		VALUES ($1, $2, $3, $4)
		RETURNING policy_id, name, description, days_before_check_in, 
		          refund_percentage, is_active, created_at, updated_at
	`

	var policy models.CancellationPolicy
	err := r.db.Pool.QueryRow(ctx, query,
		req.Name,
		req.Description,
		req.DaysBeforeCheckIn,
		req.RefundPercentage,
	).Scan(
		&policy.PolicyID,
		&policy.Name,
		&policy.Description,
		&policy.DaysBeforeCheckIn,
		&policy.RefundPercentage,
		&policy.IsActive,
		&policy.CreatedAt,
		&policy.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create cancellation policy: %w", err)
	}

	return &policy, nil
}

// UpdateCancellationPolicy updates a cancellation policy
func (r *PolicyRepository) UpdateCancellationPolicy(ctx context.Context, id int, req *models.UpdateCancellationPolicyRequest) (*models.CancellationPolicy, error) {
	// Build dynamic update query
	query := `UPDATE cancellation_policies SET updated_at = CURRENT_TIMESTAMP`
	args := []interface{}{}
	argCount := 1

	if req.Name != nil {
		query += fmt.Sprintf(", name = $%d", argCount)
		args = append(args, *req.Name)
		argCount++
	}
	if req.Description != nil {
		query += fmt.Sprintf(", description = $%d", argCount)
		args = append(args, *req.Description)
		argCount++
	}
	if req.DaysBeforeCheckIn != nil {
		query += fmt.Sprintf(", days_before_check_in = $%d", argCount)
		args = append(args, *req.DaysBeforeCheckIn)
		argCount++
	}
	if req.RefundPercentage != nil {
		query += fmt.Sprintf(", refund_percentage = $%d", argCount)
		args = append(args, *req.RefundPercentage)
		argCount++
	}
	if req.IsActive != nil {
		query += fmt.Sprintf(", is_active = $%d", argCount)
		args = append(args, *req.IsActive)
		argCount++
	}

	query += fmt.Sprintf(" WHERE policy_id = $%d", argCount)
	args = append(args, id)
	query += ` RETURNING policy_id, name, description, days_before_check_in, 
	           refund_percentage, is_active, created_at, updated_at`

	var policy models.CancellationPolicy
	err := r.db.Pool.QueryRow(ctx, query, args...).Scan(
		&policy.PolicyID,
		&policy.Name,
		&policy.Description,
		&policy.DaysBeforeCheckIn,
		&policy.RefundPercentage,
		&policy.IsActive,
		&policy.CreatedAt,
		&policy.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update cancellation policy: %w", err)
	}

	return &policy, nil
}

// DeleteCancellationPolicy deletes a cancellation policy
func (r *PolicyRepository) DeleteCancellationPolicy(ctx context.Context, id int) error {
	query := `DELETE FROM cancellation_policies WHERE policy_id = $1`

	result, err := r.db.Pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete cancellation policy: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("cancellation policy not found")
	}

	return nil
}

// CheckPolicyInUse checks if a policy is being used by any rate plans
func (r *PolicyRepository) CheckPolicyInUse(ctx context.Context, id int) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM rate_plans WHERE policy_id = $1)`

	var inUse bool
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(&inUse)
	if err != nil {
		return false, fmt.Errorf("failed to check policy usage: %w", err)
	}

	return inUse, nil
}

// ============================================================================
// Voucher Methods
// ============================================================================

// GetAllVouchers retrieves all vouchers
func (r *PolicyRepository) GetAllVouchers(ctx context.Context) ([]models.Voucher, error) {
	query := `
		SELECT voucher_id, code, discount_type, discount_value, expiry_date,
		       max_uses, current_uses, is_active, created_at, updated_at
		FROM vouchers
		ORDER BY created_at DESC
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query vouchers: %w", err)
	}
	defer rows.Close()

	var vouchers []models.Voucher
	for rows.Next() {
		var voucher models.Voucher
		err := rows.Scan(
			&voucher.VoucherID,
			&voucher.Code,
			&voucher.DiscountType,
			&voucher.DiscountValue,
			&voucher.ExpiryDate,
			&voucher.MaxUses,
			&voucher.CurrentUses,
			&voucher.IsActive,
			&voucher.CreatedAt,
			&voucher.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan voucher: %w", err)
		}
		vouchers = append(vouchers, voucher)
	}

	return vouchers, nil
}

// GetVoucherByID retrieves a voucher by ID
func (r *PolicyRepository) GetVoucherByID(ctx context.Context, id int) (*models.Voucher, error) {
	query := `
		SELECT voucher_id, code, discount_type, discount_value, expiry_date,
		       max_uses, current_uses, is_active, created_at, updated_at
		FROM vouchers
		WHERE voucher_id = $1
	`

	var voucher models.Voucher
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&voucher.VoucherID,
		&voucher.Code,
		&voucher.DiscountType,
		&voucher.DiscountValue,
		&voucher.ExpiryDate,
		&voucher.MaxUses,
		&voucher.CurrentUses,
		&voucher.IsActive,
		&voucher.CreatedAt,
		&voucher.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get voucher: %w", err)
	}

	return &voucher, nil
}

// GetVoucherByCode retrieves a voucher by code
func (r *PolicyRepository) GetVoucherByCode(ctx context.Context, code string) (*models.Voucher, error) {
	query := `
		SELECT voucher_id, code, discount_type, discount_value, expiry_date,
		       max_uses, current_uses, is_active, created_at, updated_at
		FROM vouchers
		WHERE code = $1
	`

	var voucher models.Voucher
	err := r.db.Pool.QueryRow(ctx, query, code).Scan(
		&voucher.VoucherID,
		&voucher.Code,
		&voucher.DiscountType,
		&voucher.DiscountValue,
		&voucher.ExpiryDate,
		&voucher.MaxUses,
		&voucher.CurrentUses,
		&voucher.IsActive,
		&voucher.CreatedAt,
		&voucher.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get voucher by code: %w", err)
	}

	return &voucher, nil
}

// CreateVoucher creates a new voucher
func (r *PolicyRepository) CreateVoucher(ctx context.Context, req *models.CreateVoucherRequest, expiryDate time.Time) (*models.Voucher, error) {
	query := `
		INSERT INTO vouchers (code, discount_type, discount_value, expiry_date, max_uses)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING voucher_id, code, discount_type, discount_value, expiry_date,
		          max_uses, current_uses, is_active, created_at, updated_at
	`

	var voucher models.Voucher
	err := r.db.Pool.QueryRow(ctx, query,
		req.Code,
		req.DiscountType,
		req.DiscountValue,
		expiryDate,
		req.MaxUses,
	).Scan(
		&voucher.VoucherID,
		&voucher.Code,
		&voucher.DiscountType,
		&voucher.DiscountValue,
		&voucher.ExpiryDate,
		&voucher.MaxUses,
		&voucher.CurrentUses,
		&voucher.IsActive,
		&voucher.CreatedAt,
		&voucher.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create voucher: %w", err)
	}

	return &voucher, nil
}

// UpdateVoucher updates a voucher
func (r *PolicyRepository) UpdateVoucher(ctx context.Context, id int, req *models.UpdateVoucherRequest, expiryDate *time.Time) (*models.Voucher, error) {
	// Build dynamic update query
	query := `UPDATE vouchers SET updated_at = CURRENT_TIMESTAMP`
	args := []interface{}{}
	argCount := 1

	if req.Code != nil {
		query += fmt.Sprintf(", code = $%d", argCount)
		args = append(args, *req.Code)
		argCount++
	}
	if req.DiscountType != nil {
		query += fmt.Sprintf(", discount_type = $%d", argCount)
		args = append(args, *req.DiscountType)
		argCount++
	}
	if req.DiscountValue != nil {
		query += fmt.Sprintf(", discount_value = $%d", argCount)
		args = append(args, *req.DiscountValue)
		argCount++
	}
	if expiryDate != nil {
		query += fmt.Sprintf(", expiry_date = $%d", argCount)
		args = append(args, *expiryDate)
		argCount++
	}
	if req.MaxUses != nil {
		query += fmt.Sprintf(", max_uses = $%d", argCount)
		args = append(args, *req.MaxUses)
		argCount++
	}
	if req.IsActive != nil {
		query += fmt.Sprintf(", is_active = $%d", argCount)
		args = append(args, *req.IsActive)
		argCount++
	}

	query += fmt.Sprintf(" WHERE voucher_id = $%d", argCount)
	args = append(args, id)
	query += ` RETURNING voucher_id, code, discount_type, discount_value, expiry_date,
	           max_uses, current_uses, is_active, created_at, updated_at`

	var voucher models.Voucher
	err := r.db.Pool.QueryRow(ctx, query, args...).Scan(
		&voucher.VoucherID,
		&voucher.Code,
		&voucher.DiscountType,
		&voucher.DiscountValue,
		&voucher.ExpiryDate,
		&voucher.MaxUses,
		&voucher.CurrentUses,
		&voucher.IsActive,
		&voucher.CreatedAt,
		&voucher.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update voucher: %w", err)
	}

	return &voucher, nil
}

// DeleteVoucher deletes a voucher
func (r *PolicyRepository) DeleteVoucher(ctx context.Context, id int) error {
	query := `DELETE FROM vouchers WHERE voucher_id = $1`

	result, err := r.db.Pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete voucher: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("voucher not found")
	}

	return nil
}

// CheckVoucherInUse checks if a voucher is being used by any bookings
func (r *PolicyRepository) CheckVoucherInUse(ctx context.Context, id int) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM bookings WHERE voucher_id = $1)`

	var inUse bool
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(&inUse)
	if err != nil {
		return false, fmt.Errorf("failed to check voucher usage: %w", err)
	}

	return inUse, nil
}