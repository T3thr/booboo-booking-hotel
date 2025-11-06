package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
	"github.com/hotel-booking-system/backend/pkg/cache"
)

// RoomService handles room business logic
type RoomService struct {
	roomRepo *repository.RoomRepository
	cache    *cache.RedisCache
}

// NewRoomService creates a new room service
func NewRoomService(roomRepo *repository.RoomRepository, redisCache *cache.RedisCache) *RoomService {
	return &RoomService{
		roomRepo: roomRepo,
		cache:    redisCache,
	}
}

// SearchAvailableRooms searches for available rooms and calculates prices
func (s *RoomService) SearchAvailableRooms(ctx context.Context, req *models.SearchRoomsRequest) (*models.SearchRoomsResponse, error) {
	// Parse dates
	checkIn, err := time.Parse("2006-01-02", req.CheckIn)
	if err != nil {
		return nil, fmt.Errorf("รูปแบบวันที่ check-in ไม่ถูกต้อง: %w", err)
	}

	checkOut, err := time.Parse("2006-01-02", req.CheckOut)
	if err != nil {
		return nil, fmt.Errorf("รูปแบบวันที่ check-out ไม่ถูกต้อง: %w", err)
	}

	// Validate dates
	if !checkOut.After(checkIn) {
		return nil, errors.New("วันที่ check-out ต้องอยู่หลังวันที่ check-in")
	}

	// Check if check-in is in the past
	today := time.Now().Truncate(24 * time.Hour)
	if checkIn.Before(today) {
		return nil, errors.New("วันที่ check-in ต้องไม่อยู่ในอดีต")
	}

	// Calculate total nights
	totalNights := int(checkOut.Sub(checkIn).Hours() / 24)

	// Search available rooms
	roomTypes, err := s.roomRepo.SearchAvailableRooms(ctx, checkIn, checkOut, req.Guests)
	if err != nil {
		return nil, fmt.Errorf("failed to search rooms from repository: %w", err)
	}

	// Get default rate plan
	ratePlanID, err := s.roomRepo.GetDefaultRatePlanID(ctx)
	if err != nil {
		// If no rate plan exists, return rooms without pricing
		return &models.SearchRoomsResponse{
			RoomTypes:   roomTypes,
			CheckIn:     req.CheckIn,
			CheckOut:    req.CheckOut,
			Guests:      req.Guests,
			TotalNights: totalNights,
		}, nil
	}

	// Enrich room types with amenities and pricing
	for i := range roomTypes {
		// Get amenities
		amenities, err := s.roomRepo.GetRoomTypeAmenities(ctx, roomTypes[i].RoomTypeID)
		if err != nil {
			return nil, fmt.Errorf("failed to get amenities: %w", err)
		}
		roomTypes[i].Amenities = amenities

		// Get nightly prices
		nightlyPrices, err := s.roomRepo.GetNightlyPrices(ctx, roomTypes[i].RoomTypeID, ratePlanID, checkIn, checkOut)
		if err != nil {
			return nil, fmt.Errorf("failed to get prices: %w", err)
		}
		roomTypes[i].NightlyPrices = nightlyPrices

		// Calculate total price
		var totalPrice float64
		for _, price := range nightlyPrices {
			totalPrice += price.Price
		}
		roomTypes[i].TotalPrice = &totalPrice

		// Calculate average price per night
		if totalNights > 0 {
			avgPrice := totalPrice / float64(totalNights)
			roomTypes[i].PricePerNight = &avgPrice
		}
	}

	response := &models.SearchRoomsResponse{
		RoomTypes:   roomTypes,
		CheckIn:     req.CheckIn,
		CheckOut:    req.CheckOut,
		Guests:      req.Guests,
		TotalNights: totalNights,
	}

	// If no rooms found, suggest alternative dates
	if len(roomTypes) == 0 {
		alternatives := s.generateAlternativeDates(checkIn)
		response.AlternativeDates = alternatives
	}

	return response, nil
}

// GetAllRoomTypes retrieves all room types with amenities
func (s *RoomService) GetAllRoomTypes(ctx context.Context) ([]models.RoomType, error) {
	// Try to get from cache first
	if s.cache != nil {
		cacheKey := cache.RoomTypesKey()
		var cachedRoomTypes []models.RoomType
		if err := s.cache.Get(cacheKey, &cachedRoomTypes); err == nil {
			return cachedRoomTypes, nil
		}
	}

	// Cache miss - get from database
	roomTypes, err := s.roomRepo.GetAllRoomTypes(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get room types: %w", err)
	}

	// Enrich with amenities
	for i := range roomTypes {
		amenities, err := s.roomRepo.GetRoomTypeAmenities(ctx, roomTypes[i].RoomTypeID)
		if err != nil {
			return nil, fmt.Errorf("failed to get amenities: %w", err)
		}
		roomTypes[i].Amenities = amenities
	}

	// Store in cache
	if s.cache != nil {
		cacheKey := cache.RoomTypesKey()
		_ = s.cache.Set(cacheKey, roomTypes, cache.RoomTypesExpiration)
	}

	return roomTypes, nil
}

// GetRoomTypeByID retrieves a specific room type with details
func (s *RoomService) GetRoomTypeByID(ctx context.Context, roomTypeID int) (*models.RoomTypeDetailResponse, error) {
	// Try to get from cache first
	if s.cache != nil {
		cacheKey := cache.RoomTypeKey(roomTypeID)
		var cachedResponse models.RoomTypeDetailResponse
		if err := s.cache.Get(cacheKey, &cachedResponse); err == nil {
			return &cachedResponse, nil
		}
	}

	// Cache miss - get from database
	roomType, err := s.roomRepo.GetRoomTypeByID(ctx, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get room type: %w", err)
	}

	if roomType == nil {
		return nil, errors.New("room type not found")
	}

	// Get amenities
	amenities, err := s.roomRepo.GetRoomTypeAmenities(ctx, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get amenities: %w", err)
	}
	roomType.Amenities = amenities

	// Get rooms
	rooms, err := s.roomRepo.GetRoomsByRoomType(ctx, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get rooms: %w", err)
	}

	response := &models.RoomTypeDetailResponse{
		RoomType: *roomType,
		Rooms:    rooms,
	}

	// Store in cache
	if s.cache != nil {
		cacheKey := cache.RoomTypeKey(roomTypeID)
		_ = s.cache.Set(cacheKey, response, cache.RoomTypesExpiration)
	}

	return response, nil
}

// GetRoomTypePricing calculates pricing for a specific room type and date range
func (s *RoomService) GetRoomTypePricing(ctx context.Context, roomTypeID int, checkIn, checkOut string) (*models.RoomType, error) {
	// Parse dates
	checkInDate, err := time.Parse("2006-01-02", checkIn)
	if err != nil {
		return nil, errors.New("รูปแบบวันที่ check-in ไม่ถูกต้อง")
	}

	checkOutDate, err := time.Parse("2006-01-02", checkOut)
	if err != nil {
		return nil, errors.New("รูปแบบวันที่ check-out ไม่ถูกต้อง")
	}

	// Validate dates
	if !checkOutDate.After(checkInDate) {
		return nil, errors.New("วันที่ check-out ต้องอยู่หลังวันที่ check-in")
	}

	// Get room type
	roomType, err := s.roomRepo.GetRoomTypeByID(ctx, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get room type: %w", err)
	}

	if roomType == nil {
		return nil, errors.New("room type not found")
	}

	// Get default rate plan
	ratePlanID, err := s.roomRepo.GetDefaultRatePlanID(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get rate plan: %w", err)
	}

	// Get nightly prices
	nightlyPrices, err := s.roomRepo.GetNightlyPrices(ctx, roomTypeID, ratePlanID, checkInDate, checkOutDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get prices: %w", err)
	}
	roomType.NightlyPrices = nightlyPrices

	// Calculate total price
	var totalPrice float64
	for _, price := range nightlyPrices {
		totalPrice += price.Price
	}
	roomType.TotalPrice = &totalPrice

	// Calculate total nights
	totalNights := int(checkOutDate.Sub(checkInDate).Hours() / 24)
	if totalNights > 0 {
		avgPrice := totalPrice / float64(totalNights)
		roomType.PricePerNight = &avgPrice
	}

	return roomType, nil
}

// generateAlternativeDates generates alternative date suggestions (±3 days)
func (s *RoomService) generateAlternativeDates(checkIn time.Time) []string {
	alternatives := make([]string, 0, 6)
	
	// -3 to -1 days
	for i := -3; i <= -1; i++ {
		date := checkIn.AddDate(0, 0, i)
		if date.After(time.Now()) {
			alternatives = append(alternatives, date.Format("2006-01-02"))
		}
	}
	
	// +1 to +3 days
	for i := 1; i <= 3; i++ {
		date := checkIn.AddDate(0, 0, i)
		alternatives = append(alternatives, date.Format("2006-01-02"))
	}
	
	return alternatives
}

// GetAllRoomsWithStatus retrieves all rooms with their current status
func (s *RoomService) GetAllRoomsWithStatus(ctx context.Context) (*models.RoomStatusDashboardResponse, error) {
	rooms, err := s.roomRepo.GetAllRoomsWithStatus(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get room statuses: %w", err)
	}

	// Calculate summary
	summary := models.RoomStatusSummary{
		TotalRooms: len(rooms),
	}

	for _, room := range rooms {
		if room.OccupancyStatus == "Occupied" {
			summary.Occupied++
		} else if room.OccupancyStatus == "Vacant" {
			switch room.HousekeepingStatus {
			case "Inspected":
				summary.VacantInspected++
			case "Clean":
				summary.VacantClean++
			case "Dirty", "Cleaning":
				summary.VacantDirty++
			case "MaintenanceRequired":
				summary.MaintenanceRequired++
			case "OutOfService":
				summary.OutOfService++
			}
		}
	}

	return &models.RoomStatusDashboardResponse{
		Rooms:   rooms,
		Summary: summary,
	}, nil
}

// InvalidateRoomTypeCache invalidates cache for a specific room type
func (s *RoomService) InvalidateRoomTypeCache(roomTypeID int) error {
	if s.cache == nil {
		return nil
	}

	// Invalidate specific room type
	if err := s.cache.Delete(cache.RoomTypeKey(roomTypeID)); err != nil {
		return fmt.Errorf("failed to invalidate room type cache: %w", err)
	}

	// Invalidate all room types list
	if err := s.cache.Delete(cache.RoomTypesKey()); err != nil {
		return fmt.Errorf("failed to invalidate room types list cache: %w", err)
	}

	return nil
}

// InvalidateAllRoomTypesCache invalidates all room types cache
func (s *RoomService) InvalidateAllRoomTypesCache() error {
	if s.cache == nil {
		return nil
	}

	// Delete all room type related keys
	if err := s.cache.DeletePattern(cache.RoomTypePrefix + ":*"); err != nil {
		return fmt.Errorf("failed to invalidate room type caches: %w", err)
	}

	if err := s.cache.Delete(cache.RoomTypesKey()); err != nil {
		return fmt.Errorf("failed to invalidate room types list cache: %w", err)
	}

	return nil
}
