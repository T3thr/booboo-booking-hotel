package models

import "time"

// CancellationPolicy represents a cancellation policy
type CancellationPolicy struct {
	PolicyID          int       `json:"policy_id" db:"policy_id"`
	Name              string    `json:"name" db:"name"`
	Description       string    `json:"description" db:"description"`
	DaysBeforeCheckIn int       `json:"days_before_check_in" db:"days_before_check_in"`
	RefundPercentage  float64   `json:"refund_percentage" db:"refund_percentage"`
	IsActive          bool      `json:"is_active" db:"is_active"`
	CreatedAt         time.Time `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time `json:"updated_at" db:"updated_at"`
}

// CreateCancellationPolicyRequest represents the request to create a cancellation policy
type CreateCancellationPolicyRequest struct {
	Name              string  `json:"name" binding:"required"`
	Description       string  `json:"description" binding:"required"`
	DaysBeforeCheckIn int     `json:"days_before_check_in" binding:"required,min=0"`
	RefundPercentage  float64 `json:"refund_percentage" binding:"required,min=0,max=100"`
}

// UpdateCancellationPolicyRequest represents the request to update a cancellation policy
type UpdateCancellationPolicyRequest struct {
	Name              *string  `json:"name"`
	Description       *string  `json:"description"`
	DaysBeforeCheckIn *int     `json:"days_before_check_in"`
	RefundPercentage  *float64 `json:"refund_percentage"`
	IsActive          *bool    `json:"is_active"`
}

// Voucher represents a discount voucher
type Voucher struct {
	VoucherID     int       `json:"voucher_id" db:"voucher_id"`
	Code          string    `json:"code" db:"code"`
	DiscountType  string    `json:"discount_type" db:"discount_type"`
	DiscountValue float64   `json:"discount_value" db:"discount_value"`
	ExpiryDate    time.Time `json:"expiry_date" db:"expiry_date"`
	MaxUses       int       `json:"max_uses" db:"max_uses"`
	CurrentUses   int       `json:"current_uses" db:"current_uses"`
	IsActive      bool      `json:"is_active" db:"is_active"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

// CreateVoucherRequest represents the request to create a voucher
type CreateVoucherRequest struct {
	Code          string  `json:"code" binding:"required"`
	DiscountType  string  `json:"discount_type" binding:"required,oneof=Percentage FixedAmount"`
	DiscountValue float64 `json:"discount_value" binding:"required,min=0"`
	ExpiryDate    string  `json:"expiry_date" binding:"required"`
	MaxUses       int     `json:"max_uses" binding:"required,min=1"`
}

// UpdateVoucherRequest represents the request to update a voucher
type UpdateVoucherRequest struct {
	Code          *string  `json:"code"`
	DiscountType  *string  `json:"discount_type"`
	DiscountValue *float64 `json:"discount_value"`
	ExpiryDate    *string  `json:"expiry_date"`
	MaxUses       *int     `json:"max_uses"`
	IsActive      *bool    `json:"is_active"`
}

// ValidateVoucherRequest represents the request to validate a voucher
type ValidateVoucherRequest struct {
	Code        string  `json:"code" binding:"required"`
	TotalAmount float64 `json:"total_amount" binding:"required,min=0"`
}

// ValidateVoucherResponse represents the response for voucher validation
type ValidateVoucherResponse struct {
	Valid           bool    `json:"valid"`
	Message         string  `json:"message"`
	VoucherID       int     `json:"voucher_id,omitempty"`
	DiscountType    string  `json:"discount_type,omitempty"`
	DiscountValue   float64 `json:"discount_value,omitempty"`
	DiscountAmount  float64 `json:"discount_amount,omitempty"`
	FinalAmount     float64 `json:"final_amount,omitempty"`
}
// RatePlan represents a rate plan
type RatePlan struct {
	RatePlanID  int       `json:"rate_plan_id" db:"rate_plan_id"`
	Name        string    `json:"name" db:"name"`
	Description *string   `json:"description" db:"description"`
	PolicyID    int       `json:"policy_id" db:"policy_id"`
	IsActive    bool      `json:"is_active" db:"is_active"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}