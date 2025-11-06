package service

import (
	"context"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
	"github.com/hotel-booking-system/backend/pkg/cache"
)

type PricingService struct {
	pricingRepo *repository.PricingRepository
	cache       *cache.RedisCache
}

func NewPricingService(pricingRepo *repository.PricingRepository, redisCache *cache.RedisCache) *PricingService {
	return &PricingService{
		pricingRepo: pricingRepo,
		cache:       redisCache,
	}
}

// ============================================================================
// Rate Tier Methods
// ============================================================================

// GetAllRateTiers retrieves all rate tiers
func (s *PricingService) GetAllRateTiers(ctx context.Context) ([]models.RateTier, error) {
	// Try to get from cache first
	if s.cache != nil {
		cacheKey := cache.RateTiersKey()
		var cachedTiers []models.RateTier
		if err := s.cache.Get(cacheKey, &cachedTiers); err == nil {
			return cachedTiers, nil
		}
	}

	// Cache miss - get from database
	tiers, err := s.pricingRepo.GetAllRateTiers(ctx)
	if err != nil {
		return nil, err
	}

	// Store in cache
	if s.cache != nil {
		cacheKey := cache.RateTiersKey()
		_ = s.cache.Set(cacheKey, tiers, cache.RateTiersExpiration)
	}

	return tiers, nil
}

// GetRateTierByID retrieves a rate tier by ID
func (s *PricingService) GetRateTierByID(ctx context.Context, id int) (*models.RateTier, error) {
	return s.pricingRepo.GetRateTierByID(ctx, id)
}

// CreateRateTier creates a new rate tier
func (s *PricingService) CreateRateTier(ctx context.Context, req *models.CreateRateTierRequest) (*models.RateTier, error) {
	// Validate color code format if provided
	if req.ColorCode != nil && *req.ColorCode != "" {
		if !isValidHexColor(*req.ColorCode) {
			return nil, fmt.Errorf("invalid color code format, must be hex format (e.g., #FF0000)")
		}
	}

	return s.pricingRepo.CreateRateTier(ctx, req)
}

// UpdateRateTier updates a rate tier
func (s *PricingService) UpdateRateTier(ctx context.Context, id int, req *models.UpdateRateTierRequest) (*models.RateTier, error) {
	// Validate color code format if provided
	if req.ColorCode != nil && *req.ColorCode != "" {
		if !isValidHexColor(*req.ColorCode) {
			return nil, fmt.Errorf("invalid color code format, must be hex format (e.g., #FF0000)")
		}
	}

	return s.pricingRepo.UpdateRateTier(ctx, id, req)
}

// ============================================================================
// Pricing Calendar Methods
// ============================================================================

// GetPricingCalendar retrieves pricing calendar for a date range
func (s *PricingService) GetPricingCalendar(ctx context.Context, startDate, endDate string) ([]models.PricingCalendar, error) {
	// Try to get from cache first
	if s.cache != nil {
		cacheKey := cache.PricingCalendarKey(startDate, endDate)
		var cachedCalendar []models.PricingCalendar
		if err := s.cache.Get(cacheKey, &cachedCalendar); err == nil {
			return cachedCalendar, nil
		}
	}

	// Parse dates
	start, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		return nil, fmt.Errorf("invalid start date format: %w", err)
	}

	end, err := time.Parse("2006-01-02", endDate)
	if err != nil {
		return nil, fmt.Errorf("invalid end date format: %w", err)
	}

	// Validate date range
	if end.Before(start) {
		return nil, fmt.Errorf("end date must be after start date")
	}

	// Limit to 1 year range
	if end.Sub(start).Hours() > 365*24 {
		return nil, fmt.Errorf("date range cannot exceed 1 year")
	}

	// Cache miss - get from database
	calendar, err := s.pricingRepo.GetPricingCalendar(ctx, start, end)
	if err != nil {
		return nil, err
	}

	// Store in cache
	if s.cache != nil {
		cacheKey := cache.PricingCalendarKey(startDate, endDate)
		_ = s.cache.Set(cacheKey, calendar, cache.PricingCalendarExpiration)
	}

	return calendar, nil
}

// UpdatePricingCalendar updates pricing calendar for a date range
func (s *PricingService) UpdatePricingCalendar(ctx context.Context, req *models.UpdatePricingCalendarRequest) error {
	// Parse dates
	start, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		return fmt.Errorf("invalid start date format: %w", err)
	}

	end, err := time.Parse("2006-01-02", req.EndDate)
	if err != nil {
		return fmt.Errorf("invalid end date format: %w", err)
	}

	// Validate date range
	if end.Before(start) {
		return fmt.Errorf("end date must be after start date")
	}

	// Verify rate tier exists
	_, err = s.pricingRepo.GetRateTierByID(ctx, req.RateTierID)
	if err != nil {
		return fmt.Errorf("invalid rate tier ID: %w", err)
	}

	return s.pricingRepo.UpdatePricingCalendar(ctx, req)
}

// ============================================================================
// Rate Pricing Methods
// ============================================================================

// GetAllRatePricing retrieves all rate pricing with details
func (s *PricingService) GetAllRatePricing(ctx context.Context) ([]models.RatePricingWithDetails, error) {
	return s.pricingRepo.GetAllRatePricing(ctx)
}

// GetRatePricingByPlan retrieves rate pricing for a specific rate plan
func (s *PricingService) GetRatePricingByPlan(ctx context.Context, ratePlanID int) ([]models.RatePricingWithDetails, error) {
	return s.pricingRepo.GetRatePricingByPlan(ctx, ratePlanID)
}

// UpdateRatePricing updates or creates a rate pricing entry
func (s *PricingService) UpdateRatePricing(ctx context.Context, req *models.UpdateRatePricingRequest) error {
	// Validate price
	if req.Price < 0 {
		return fmt.Errorf("price cannot be negative")
	}

	return s.pricingRepo.UpdateRatePricing(ctx, req)
}

// BulkUpdateRatePricing updates multiple rate pricing entries
func (s *PricingService) BulkUpdateRatePricing(ctx context.Context, req *models.BulkUpdateRatePricingRequest) error {
	// Validate adjustment type
	if req.AdjustmentType != "percentage" && req.AdjustmentType != "fixed" {
		return fmt.Errorf("adjustment type must be 'percentage' or 'fixed'")
	}

	// Validate adjustment value
	if req.AdjustmentType == "percentage" {
		if req.AdjustmentValue < -100 {
			return fmt.Errorf("percentage adjustment cannot be less than -100")
		}
	}

	return s.pricingRepo.BulkUpdateRatePricing(ctx, req)
}

// GetAllRatePlans retrieves all rate plans
func (s *PricingService) GetAllRatePlans(ctx context.Context) ([]models.RatePlan, error) {
	return s.pricingRepo.GetAllRatePlans(ctx)
}

// ============================================================================
// Helper Functions
// ============================================================================

// isValidHexColor validates hex color format
func isValidHexColor(color string) bool {
	if len(color) != 7 {
		return false
	}
	if color[0] != '#' {
		return false
	}
	for i := 1; i < 7; i++ {
		c := color[i]
		if !((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f')) {
			return false
		}
	}
	return true
}

// ============================================================================
// Cache Invalidation Methods
// ============================================================================

// InvalidateRateTiersCache invalidates rate tiers cache
func (s *PricingService) InvalidateRateTiersCache() error {
	if s.cache == nil {
		return nil
	}

	if err := s.cache.Delete(cache.RateTiersKey()); err != nil {
		return fmt.Errorf("failed to invalidate rate tiers cache: %w", err)
	}

	return nil
}

// InvalidatePricingCalendarCache invalidates pricing calendar cache
func (s *PricingService) InvalidatePricingCalendarCache() error {
	if s.cache == nil {
		return nil
	}

	// Delete all pricing calendar keys
	if err := s.cache.DeletePattern(cache.PricingCalendarPrefix + ":*"); err != nil {
		return fmt.Errorf("failed to invalidate pricing calendar cache: %w", err)
	}

	return nil
}

// InvalidateRatePricingCache invalidates rate pricing cache
func (s *PricingService) InvalidateRatePricingCache() error {
	if s.cache == nil {
		return nil
	}

	// Delete all rate pricing keys
	if err := s.cache.DeletePattern(cache.RatePricingPrefix + ":*"); err != nil {
		return fmt.Errorf("failed to invalidate rate pricing cache: %w", err)
	}

	return nil
}

// InvalidateAllPricingCache invalidates all pricing related caches
func (s *PricingService) InvalidateAllPricingCache() error {
	if err := s.InvalidateRateTiersCache(); err != nil {
		return err
	}
	if err := s.InvalidatePricingCalendarCache(); err != nil {
		return err
	}
	if err := s.InvalidateRatePricingCache(); err != nil {
		return err
	}
	return nil
}
