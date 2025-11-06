package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/database"
)

type PricingRepository struct {
	db *database.DB
}

func NewPricingRepository(db *database.DB) *PricingRepository {
	return &PricingRepository{db: db}
}

// ============================================================================
// Rate Tier Methods
// ============================================================================

// GetAllRateTiers retrieves all rate tiers
func (r *PricingRepository) GetAllRateTiers(ctx context.Context) ([]models.RateTier, error) {
	query := `
		SELECT rate_tier_id, name, description, display_order, color_code, 
		       is_active, created_at, updated_at
		FROM rate_tiers
		ORDER BY display_order, name
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query rate tiers: %w", err)
	}
	defer rows.Close()

	var tiers []models.RateTier
	for rows.Next() {
		var tier models.RateTier
		err := rows.Scan(
			&tier.RateTierID,
			&tier.Name,
			&tier.Description,
			&tier.DisplayOrder,
			&tier.ColorCode,
			&tier.IsActive,
			&tier.CreatedAt,
			&tier.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan rate tier: %w", err)
		}
		tiers = append(tiers, tier)
	}

	return tiers, nil
}

// GetRateTierByID retrieves a rate tier by ID
func (r *PricingRepository) GetRateTierByID(ctx context.Context, id int) (*models.RateTier, error) {
	query := `
		SELECT rate_tier_id, name, description, display_order, color_code, 
		       is_active, created_at, updated_at
		FROM rate_tiers
		WHERE rate_tier_id = $1
	`

	var tier models.RateTier
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&tier.RateTierID,
		&tier.Name,
		&tier.Description,
		&tier.DisplayOrder,
		&tier.ColorCode,
		&tier.IsActive,
		&tier.CreatedAt,
		&tier.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get rate tier: %w", err)
	}

	return &tier, nil
}

// CreateRateTier creates a new rate tier
func (r *PricingRepository) CreateRateTier(ctx context.Context, req *models.CreateRateTierRequest) (*models.RateTier, error) {
	query := `
		INSERT INTO rate_tiers (name, description, display_order, color_code)
		VALUES ($1, $2, $3, $4)
		RETURNING rate_tier_id, name, description, display_order, color_code, 
		          is_active, created_at, updated_at
	`

	var tier models.RateTier
	err := r.db.Pool.QueryRow(ctx, query,
		req.Name,
		req.Description,
		req.DisplayOrder,
		req.ColorCode,
	).Scan(
		&tier.RateTierID,
		&tier.Name,
		&tier.Description,
		&tier.DisplayOrder,
		&tier.ColorCode,
		&tier.IsActive,
		&tier.CreatedAt,
		&tier.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create rate tier: %w", err)
	}

	return &tier, nil
}

// UpdateRateTier updates a rate tier
func (r *PricingRepository) UpdateRateTier(ctx context.Context, id int, req *models.UpdateRateTierRequest) (*models.RateTier, error) {
	// Build dynamic update query
	query := `UPDATE rate_tiers SET updated_at = CURRENT_TIMESTAMP`
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
	if req.DisplayOrder != nil {
		query += fmt.Sprintf(", display_order = $%d", argCount)
		args = append(args, *req.DisplayOrder)
		argCount++
	}
	if req.ColorCode != nil {
		query += fmt.Sprintf(", color_code = $%d", argCount)
		args = append(args, *req.ColorCode)
		argCount++
	}
	if req.IsActive != nil {
		query += fmt.Sprintf(", is_active = $%d", argCount)
		args = append(args, *req.IsActive)
		argCount++
	}

	query += fmt.Sprintf(" WHERE rate_tier_id = $%d", argCount)
	args = append(args, id)
	query += ` RETURNING rate_tier_id, name, description, display_order, color_code, 
	           is_active, created_at, updated_at`

	var tier models.RateTier
	err := r.db.Pool.QueryRow(ctx, query, args...).Scan(
		&tier.RateTierID,
		&tier.Name,
		&tier.Description,
		&tier.DisplayOrder,
		&tier.ColorCode,
		&tier.IsActive,
		&tier.CreatedAt,
		&tier.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update rate tier: %w", err)
	}

	return &tier, nil
}

// ============================================================================
// Pricing Calendar Methods
// ============================================================================

// GetPricingCalendar retrieves pricing calendar for a date range
func (r *PricingRepository) GetPricingCalendar(ctx context.Context, startDate, endDate time.Time) ([]models.PricingCalendar, error) {
	query := `
		SELECT pc.date, pc.rate_tier_id, pc.notes, pc.created_at, pc.updated_at,
		       rt.name, rt.description, rt.display_order, rt.color_code, rt.is_active,
		       rt.created_at, rt.updated_at
		FROM pricing_calendar pc
		JOIN rate_tiers rt ON pc.rate_tier_id = rt.rate_tier_id
		WHERE pc.date >= $1 AND pc.date <= $2
		ORDER BY pc.date
	`

	rows, err := r.db.Pool.Query(ctx, query, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query pricing calendar: %w", err)
	}
	defer rows.Close()

	var calendars []models.PricingCalendar
	for rows.Next() {
		var cal models.PricingCalendar
		var tier models.RateTier

		err := rows.Scan(
			&cal.Date,
			&cal.RateTierID,
			&cal.Notes,
			&cal.CreatedAt,
			&cal.UpdatedAt,
			&tier.Name,
			&tier.Description,
			&tier.DisplayOrder,
			&tier.ColorCode,
			&tier.IsActive,
			&tier.CreatedAt,
			&tier.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan pricing calendar: %w", err)
		}

		tier.RateTierID = cal.RateTierID
		cal.RateTier = &tier
		calendars = append(calendars, cal)
	}

	return calendars, nil
}

// UpdatePricingCalendar updates pricing calendar for a date range
func (r *PricingRepository) UpdatePricingCalendar(ctx context.Context, req *models.UpdatePricingCalendarRequest) error {
	query := `
		INSERT INTO pricing_calendar (date, rate_tier_id, notes)
		SELECT date_series.date, $3, $4
		FROM generate_series($1::date, $2::date, '1 day'::interval) as date_series(date)
		ON CONFLICT (date) 
		DO UPDATE SET 
			rate_tier_id = EXCLUDED.rate_tier_id,
			notes = EXCLUDED.notes,
			updated_at = CURRENT_TIMESTAMP
	`

	_, err := r.db.Pool.Exec(ctx, query, req.StartDate, req.EndDate, req.RateTierID, req.Notes)
	if err != nil {
		return fmt.Errorf("failed to update pricing calendar: %w", err)
	}

	return nil
}

// ============================================================================
// Rate Pricing Methods
// ============================================================================

// GetAllRatePricing retrieves all rate pricing with details
func (r *PricingRepository) GetAllRatePricing(ctx context.Context) ([]models.RatePricingWithDetails, error) {
	query := `
		SELECT 
			rp.rate_plan_id, rpl.name as rate_plan_name,
			rp.room_type_id, rt.name as room_type_name,
			rp.rate_tier_id, tier.name as rate_tier_name,
			rp.price, rp.created_at, rp.updated_at
		FROM rate_pricing rp
		JOIN rate_plans rpl ON rp.rate_plan_id = rpl.rate_plan_id
		JOIN room_types rt ON rp.room_type_id = rt.room_type_id
		JOIN rate_tiers tier ON rp.rate_tier_id = tier.rate_tier_id
		ORDER BY rpl.name, rt.name, tier.display_order
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query rate pricing: %w", err)
	}
	defer rows.Close()

	var pricings []models.RatePricingWithDetails
	for rows.Next() {
		var pricing models.RatePricingWithDetails
		err := rows.Scan(
			&pricing.RatePlanID,
			&pricing.RatePlanName,
			&pricing.RoomTypeID,
			&pricing.RoomTypeName,
			&pricing.RateTierID,
			&pricing.RateTierName,
			&pricing.Price,
			&pricing.CreatedAt,
			&pricing.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan rate pricing: %w", err)
		}
		pricings = append(pricings, pricing)
	}

	return pricings, nil
}

// GetRatePricingByPlan retrieves rate pricing for a specific rate plan
func (r *PricingRepository) GetRatePricingByPlan(ctx context.Context, ratePlanID int) ([]models.RatePricingWithDetails, error) {
	query := `
		SELECT 
			rp.rate_plan_id, rpl.name as rate_plan_name,
			rp.room_type_id, rt.name as room_type_name,
			rp.rate_tier_id, tier.name as rate_tier_name,
			rp.price, rp.created_at, rp.updated_at
		FROM rate_pricing rp
		JOIN rate_plans rpl ON rp.rate_plan_id = rpl.rate_plan_id
		JOIN room_types rt ON rp.room_type_id = rt.room_type_id
		JOIN rate_tiers tier ON rp.rate_tier_id = tier.rate_tier_id
		WHERE rp.rate_plan_id = $1
		ORDER BY rt.name, tier.display_order
	`

	rows, err := r.db.Pool.Query(ctx, query, ratePlanID)
	if err != nil {
		return nil, fmt.Errorf("failed to query rate pricing: %w", err)
	}
	defer rows.Close()

	var pricings []models.RatePricingWithDetails
	for rows.Next() {
		var pricing models.RatePricingWithDetails
		err := rows.Scan(
			&pricing.RatePlanID,
			&pricing.RatePlanName,
			&pricing.RoomTypeID,
			&pricing.RoomTypeName,
			&pricing.RateTierID,
			&pricing.RateTierName,
			&pricing.Price,
			&pricing.CreatedAt,
			&pricing.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan rate pricing: %w", err)
		}
		pricings = append(pricings, pricing)
	}

	return pricings, nil
}

// UpdateRatePricing updates or creates a rate pricing entry
func (r *PricingRepository) UpdateRatePricing(ctx context.Context, req *models.UpdateRatePricingRequest) error {
	query := `
		INSERT INTO rate_pricing (rate_plan_id, room_type_id, rate_tier_id, price)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (rate_plan_id, room_type_id, rate_tier_id)
		DO UPDATE SET 
			price = EXCLUDED.price,
			updated_at = CURRENT_TIMESTAMP
	`

	_, err := r.db.Pool.Exec(ctx, query, req.RatePlanID, req.RoomTypeID, req.RateTierID, req.Price)
	if err != nil {
		return fmt.Errorf("failed to update rate pricing: %w", err)
	}

	return nil
}

// BulkUpdateRatePricing updates multiple rate pricing entries
func (r *PricingRepository) BulkUpdateRatePricing(ctx context.Context, req *models.BulkUpdateRatePricingRequest) error {
	// Build WHERE clause for filtering
	whereClause := "WHERE rate_plan_id = $1"
	args := []interface{}{req.RatePlanID}
	argCount := 2

	if len(req.RoomTypeIDs) > 0 {
		whereClause += fmt.Sprintf(" AND room_type_id = ANY($%d)", argCount)
		args = append(args, req.RoomTypeIDs)
		argCount++
	}

	if len(req.RateTierIDs) > 0 {
		whereClause += fmt.Sprintf(" AND rate_tier_id = ANY($%d)", argCount)
		args = append(args, req.RateTierIDs)
		argCount++
	}

	// Build UPDATE clause based on adjustment type
	var updateClause string
	if req.AdjustmentType == "percentage" {
		updateClause = fmt.Sprintf("price = ROUND(price * (1 + $%d / 100.0), 2)", argCount)
	} else {
		updateClause = fmt.Sprintf("price = GREATEST(0, price + $%d)", argCount)
	}
	args = append(args, req.AdjustmentValue)

	query := fmt.Sprintf(`
		UPDATE rate_pricing
		SET %s, updated_at = CURRENT_TIMESTAMP
		%s
	`, updateClause, whereClause)

	_, err := r.db.Pool.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to bulk update rate pricing: %w", err)
	}

	return nil
}

// GetAllRatePlans retrieves all rate plans
func (r *PricingRepository) GetAllRatePlans(ctx context.Context) ([]models.RatePlan, error) {
	query := `
		SELECT rate_plan_id, name, description, policy_id, is_active, created_at, updated_at
		FROM rate_plans
		ORDER BY name
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query rate plans: %w", err)
	}
	defer rows.Close()

	var plans []models.RatePlan
	for rows.Next() {
		var plan models.RatePlan
		err := rows.Scan(
			&plan.RatePlanID,
			&plan.Name,
			&plan.Description,
			&plan.PolicyID,
			&plan.IsActive,
			&plan.CreatedAt,
			&plan.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan rate plan: %w", err)
		}
		plans = append(plans, plan)
	}

	return plans, nil
}
