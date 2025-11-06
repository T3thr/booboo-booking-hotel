package service

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
)

type PolicyService struct {
	policyRepo *repository.PolicyRepository
}

func NewPolicyService(policyRepo *repository.PolicyRepository) *PolicyService {
	return &PolicyService{
		policyRepo: policyRepo,
	}
}

// ============================================================================
// Cancellation Policy Methods
// ============================================================================

// GetAllCancellationPolicies retrieves all cancellation policies
func (s *PolicyService) GetAllCancellationPolicies(ctx context.Context) ([]models.CancellationPolicy, error) {
	return s.policyRepo.GetAllCancellationPolicies(ctx)
}

// GetCancellationPolicyByID retrieves a cancellation policy by ID
func (s *PolicyService) GetCancellationPolicyByID(ctx context.Context, id int) (*models.CancellationPolicy, error) {
	return s.policyRepo.GetCancellationPolicyByID(ctx, id)
}

// CreateCancellationPolicy creates a new cancellation policy
func (s *PolicyService) CreateCancellationPolicy(ctx context.Context, req *models.CreateCancellationPolicyRequest) (*models.CancellationPolicy, error) {
	// Validate refund percentage
	if req.RefundPercentage < 0 || req.RefundPercentage > 100 {
		return nil, fmt.Errorf("refund percentage must be between 0 and 100")
	}

	// Validate days before check-in
	if req.DaysBeforeCheckIn < 0 {
		return nil, fmt.Errorf("days before check-in cannot be negative")
	}

	return s.policyRepo.CreateCancellationPolicy(ctx, req)
}

// UpdateCancellationPolicy updates a cancellation policy
func (s *PolicyService) UpdateCancellationPolicy(ctx context.Context, id int, req *models.UpdateCancellationPolicyRequest) (*models.CancellationPolicy, error) {
	// Validate refund percentage if provided
	if req.RefundPercentage != nil {
		if *req.RefundPercentage < 0 || *req.RefundPercentage > 100 {
			return nil, fmt.Errorf("refund percentage must be between 0 and 100")
		}
	}

	// Validate days before check-in if provided
	if req.DaysBeforeCheckIn != nil {
		if *req.DaysBeforeCheckIn < 0 {
			return nil, fmt.Errorf("days before check-in cannot be negative")
		}
	}

	return s.policyRepo.UpdateCancellationPolicy(ctx, id, req)
}

// DeleteCancellationPolicy deletes a cancellation policy
func (s *PolicyService) DeleteCancellationPolicy(ctx context.Context, id int) error {
	// Check if policy is in use
	inUse, err := s.policyRepo.CheckPolicyInUse(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to check policy usage: %w", err)
	}

	if inUse {
		return fmt.Errorf("cannot delete policy: it is currently being used by rate plans")
	}

	return s.policyRepo.DeleteCancellationPolicy(ctx, id)
}

// ============================================================================
// Voucher Methods
// ============================================================================

// GetAllVouchers retrieves all vouchers
func (s *PolicyService) GetAllVouchers(ctx context.Context) ([]models.Voucher, error) {
	return s.policyRepo.GetAllVouchers(ctx)
}

// GetVoucherByID retrieves a voucher by ID
func (s *PolicyService) GetVoucherByID(ctx context.Context, id int) (*models.Voucher, error) {
	return s.policyRepo.GetVoucherByID(ctx, id)
}

// CreateVoucher creates a new voucher
func (s *PolicyService) CreateVoucher(ctx context.Context, req *models.CreateVoucherRequest) (*models.Voucher, error) {
	// Validate discount type
	if req.DiscountType != "Percentage" && req.DiscountType != "FixedAmount" {
		return nil, fmt.Errorf("discount type must be 'Percentage' or 'FixedAmount'")
	}

	// Validate discount value
	if req.DiscountValue <= 0 {
		return nil, fmt.Errorf("discount value must be greater than 0")
	}

	if req.DiscountType == "Percentage" && req.DiscountValue > 100 {
		return nil, fmt.Errorf("percentage discount cannot exceed 100")
	}

	// Validate and parse expiry date
	expiryDate, err := time.Parse("2006-01-02", req.ExpiryDate)
	if err != nil {
		return nil, fmt.Errorf("invalid expiry date format, use YYYY-MM-DD: %w", err)
	}

	// Check if expiry date is in the future
	if expiryDate.Before(time.Now()) {
		return nil, fmt.Errorf("expiry date must be in the future")
	}

	// Validate max uses
	if req.MaxUses < 1 {
		return nil, fmt.Errorf("max uses must be at least 1")
	}

	// Normalize code to uppercase
	req.Code = strings.ToUpper(strings.TrimSpace(req.Code))

	return s.policyRepo.CreateVoucher(ctx, req, expiryDate)
}

// UpdateVoucher updates a voucher
func (s *PolicyService) UpdateVoucher(ctx context.Context, id int, req *models.UpdateVoucherRequest) (*models.Voucher, error) {
	// Validate discount type if provided
	if req.DiscountType != nil {
		if *req.DiscountType != "Percentage" && *req.DiscountType != "FixedAmount" {
			return nil, fmt.Errorf("discount type must be 'Percentage' or 'FixedAmount'")
		}
	}

	// Validate discount value if provided
	if req.DiscountValue != nil {
		if *req.DiscountValue <= 0 {
			return nil, fmt.Errorf("discount value must be greater than 0")
		}

		// If discount type is being updated or we need to check existing
		if req.DiscountType != nil && *req.DiscountType == "Percentage" && *req.DiscountValue > 100 {
			return nil, fmt.Errorf("percentage discount cannot exceed 100")
		}
	}

	// Validate and parse expiry date if provided
	var expiryDate *time.Time
	if req.ExpiryDate != nil {
		parsed, err := time.Parse("2006-01-02", *req.ExpiryDate)
		if err != nil {
			return nil, fmt.Errorf("invalid expiry date format, use YYYY-MM-DD: %w", err)
		}
		expiryDate = &parsed
	}

	// Validate max uses if provided
	if req.MaxUses != nil {
		if *req.MaxUses < 1 {
			return nil, fmt.Errorf("max uses must be at least 1")
		}

		// Check if new max uses is less than current uses
		voucher, err := s.policyRepo.GetVoucherByID(ctx, id)
		if err != nil {
			return nil, fmt.Errorf("failed to get voucher: %w", err)
		}

		if *req.MaxUses < voucher.CurrentUses {
			return nil, fmt.Errorf("max uses cannot be less than current uses (%d)", voucher.CurrentUses)
		}
	}

	// Normalize code to uppercase if provided
	if req.Code != nil {
		normalized := strings.ToUpper(strings.TrimSpace(*req.Code))
		req.Code = &normalized
	}

	return s.policyRepo.UpdateVoucher(ctx, id, req, expiryDate)
}

// DeleteVoucher deletes a voucher
func (s *PolicyService) DeleteVoucher(ctx context.Context, id int) error {
	// Check if voucher is in use
	inUse, err := s.policyRepo.CheckVoucherInUse(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to check voucher usage: %w", err)
	}

	if inUse {
		return fmt.Errorf("cannot delete voucher: it is currently being used by bookings")
	}

	return s.policyRepo.DeleteVoucher(ctx, id)
}

// ValidateVoucher validates a voucher code and calculates discount
func (s *PolicyService) ValidateVoucher(ctx context.Context, req *models.ValidateVoucherRequest) (*models.ValidateVoucherResponse, error) {
	// Normalize code
	code := strings.ToUpper(strings.TrimSpace(req.Code))

	// Get voucher by code
	voucher, err := s.policyRepo.GetVoucherByCode(ctx, code)
	if err != nil {
		return &models.ValidateVoucherResponse{
			Valid:   false,
			Message: "Invalid voucher code",
		}, nil
	}

	// Check if voucher is active
	if !voucher.IsActive {
		return &models.ValidateVoucherResponse{
			Valid:   false,
			Message: "This voucher is no longer active",
		}, nil
	}

	// Check if voucher has expired
	if voucher.ExpiryDate.Before(time.Now()) {
		return &models.ValidateVoucherResponse{
			Valid:   false,
			Message: "This voucher has expired",
		}, nil
	}

	// Check if voucher has reached max uses
	if voucher.CurrentUses >= voucher.MaxUses {
		return &models.ValidateVoucherResponse{
			Valid:   false,
			Message: "This voucher has reached its usage limit",
		}, nil
	}

	// Calculate discount
	var discountAmount float64
	if voucher.DiscountType == "Percentage" {
		discountAmount = req.TotalAmount * (voucher.DiscountValue / 100.0)
	} else {
		discountAmount = voucher.DiscountValue
	}

	// Ensure discount doesn't exceed total amount
	if discountAmount > req.TotalAmount {
		discountAmount = req.TotalAmount
	}

	finalAmount := req.TotalAmount - discountAmount

	return &models.ValidateVoucherResponse{
		Valid:          true,
		Message:        "Voucher is valid",
		VoucherID:      voucher.VoucherID,
		DiscountType:   voucher.DiscountType,
		DiscountValue:  voucher.DiscountValue,
		DiscountAmount: discountAmount,
		FinalAmount:    finalAmount,
	}, nil
}
