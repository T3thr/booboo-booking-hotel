package models

import "time"

// RateTier represents a pricing tier (e.g., Low Season, High Season)
type RateTier struct {
	RateTierID   int       `json:"rate_tier_id" db:"rate_tier_id"`
	Name         string    `json:"name" db:"name"`
	Description  *string   `json:"description" db:"description"`
	DisplayOrder int       `json:"display_order" db:"display_order"`
	ColorCode    *string   `json:"color_code" db:"color_code"`
	IsActive     bool      `json:"is_active" db:"is_active"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// CreateRateTierRequest represents the request to create a rate tier
type CreateRateTierRequest struct {
	Name         string  `json:"name" binding:"required"`
	Description  *string `json:"description"`
	DisplayOrder int     `json:"display_order"`
	ColorCode    *string `json:"color_code"`
}

// UpdateRateTierRequest represents the request to update a rate tier
type UpdateRateTierRequest struct {
	Name         *string `json:"name"`
	Description  *string `json:"description"`
	DisplayOrder *int    `json:"display_order"`
	ColorCode    *string `json:"color_code"`
	IsActive     *bool   `json:"is_active"`
}

// PricingCalendar represents the pricing calendar for a specific date
type PricingCalendar struct {
	Date        time.Time `json:"date" db:"date"`
	RateTierID  int       `json:"rate_tier_id" db:"rate_tier_id"`
	RateTier    *RateTier `json:"rate_tier,omitempty"`
	Notes       *string   `json:"notes" db:"notes"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// UpdatePricingCalendarRequest represents the request to update pricing calendar
type UpdatePricingCalendarRequest struct {
	StartDate  string `json:"start_date" binding:"required"`
	EndDate    string `json:"end_date" binding:"required"`
	RateTierID int    `json:"rate_tier_id" binding:"required"`
	Notes      string `json:"notes"`
}

// RatePricing represents the pricing matrix (rate plan x room type x rate tier)
type RatePricing struct {
	RatePlanID int       `json:"rate_plan_id" db:"rate_plan_id"`
	RoomTypeID int       `json:"room_type_id" db:"room_type_id"`
	RateTierID int       `json:"rate_tier_id" db:"rate_tier_id"`
	Price      float64   `json:"price" db:"price"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
}

// RatePricingWithDetails includes related entity names
type RatePricingWithDetails struct {
	RatePlanID   int       `json:"rate_plan_id" db:"rate_plan_id"`
	RatePlanName string    `json:"rate_plan_name" db:"rate_plan_name"`
	RoomTypeID   int       `json:"room_type_id" db:"room_type_id"`
	RoomTypeName string    `json:"room_type_name" db:"room_type_name"`
	RateTierID   int       `json:"rate_tier_id" db:"rate_tier_id"`
	RateTierName string    `json:"rate_tier_name" db:"rate_tier_name"`
	Price        float64   `json:"price" db:"price"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// UpdateRatePricingRequest represents the request to update rate pricing
type UpdateRatePricingRequest struct {
	RatePlanID int     `json:"rate_plan_id" binding:"required"`
	RoomTypeID int     `json:"room_type_id" binding:"required"`
	RateTierID int     `json:"rate_tier_id" binding:"required"`
	Price      float64 `json:"price" binding:"required,min=0"`
}

// BulkUpdateRatePricingRequest represents bulk update request
type BulkUpdateRatePricingRequest struct {
	RatePlanID       int     `json:"rate_plan_id" binding:"required"`
	AdjustmentType   string  `json:"adjustment_type" binding:"required,oneof=percentage fixed"`
	AdjustmentValue  float64 `json:"adjustment_value" binding:"required"`
	RoomTypeIDs      []int   `json:"room_type_ids"`
	RateTierIDs      []int   `json:"rate_tier_ids"`
}


