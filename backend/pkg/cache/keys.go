package cache

import (
	"fmt"
	"time"
)

// Cache key prefixes
const (
	RoomTypesPrefix      = "room_types"
	RoomTypePrefix       = "room_type"
	PricingCalendarPrefix = "pricing_calendar"
	RateTiersPrefix      = "rate_tiers"
	RatePricingPrefix    = "rate_pricing"
)

// Cache expiration times
const (
	RoomTypesExpiration      = 24 * time.Hour  // Room types rarely change
	PricingCalendarExpiration = 6 * time.Hour   // Pricing changes occasionally
	RateTiersExpiration      = 24 * time.Hour  // Rate tiers rarely change
	RatePricingExpiration    = 12 * time.Hour  // Rate pricing changes occasionally
)

// Key generators
func RoomTypesKey() string {
	return fmt.Sprintf("%s:all", RoomTypesPrefix)
}

func RoomTypeKey(roomTypeID int) string {
	return fmt.Sprintf("%s:%d", RoomTypePrefix, roomTypeID)
}

func PricingCalendarKey(startDate, endDate string) string {
	return fmt.Sprintf("%s:%s:%s", PricingCalendarPrefix, startDate, endDate)
}

func RateTiersKey() string {
	return fmt.Sprintf("%s:all", RateTiersPrefix)
}

func RatePricingKey(ratePlanID, roomTypeID int) string {
	return fmt.Sprintf("%s:%d:%d", RatePricingPrefix, ratePlanID, roomTypeID)
}

func RatePricingMatrixKey() string {
	return fmt.Sprintf("%s:matrix", RatePricingPrefix)
}
