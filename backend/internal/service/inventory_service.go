package service

import (
	"context"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
)

type InventoryService struct {
	inventoryRepo *repository.InventoryRepository
	roomRepo      *repository.RoomRepository
}

func NewInventoryService(inventoryRepo *repository.InventoryRepository, roomRepo *repository.RoomRepository) *InventoryService {
	return &InventoryService{
		inventoryRepo: inventoryRepo,
		roomRepo:      roomRepo,
	}
}

// GetInventory retrieves inventory for a specific room type and date range
func (s *InventoryService) GetInventory(ctx context.Context, roomTypeID int, startDate, endDate string) ([]models.RoomInventoryWithDetails, error) {
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

	// Verify room type exists
	_, err = s.roomRepo.GetRoomTypeByID(ctx, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("invalid room type ID: %w", err)
	}

	return s.inventoryRepo.GetInventory(ctx, roomTypeID, start, end)
}

// GetAllInventory retrieves inventory for all room types within a date range
func (s *InventoryService) GetAllInventory(ctx context.Context, startDate, endDate string) ([]models.RoomInventoryWithDetails, error) {
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

	return s.inventoryRepo.GetAllInventory(ctx, start, end)
}

// UpdateInventory updates inventory for a specific date
func (s *InventoryService) UpdateInventory(ctx context.Context, req *models.UpdateInventoryRequest) error {
	// Parse date
	date, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		return fmt.Errorf("invalid date format: %w", err)
	}

	// Verify room type exists
	_, err = s.roomRepo.GetRoomTypeByID(ctx, req.RoomTypeID)
	if err != nil {
		return fmt.Errorf("invalid room type ID: %w", err)
	}

	// Validate allotment
	if req.Allotment < 0 {
		return fmt.Errorf("allotment cannot be negative")
	}

	// Validate against current bookings
	err = s.inventoryRepo.ValidateInventoryUpdate(ctx, req.RoomTypeID, date, req.Allotment)
	if err != nil {
		return err
	}

	return s.inventoryRepo.UpdateInventory(ctx, req.RoomTypeID, date, req.Allotment)
}

// BulkUpdateInventory updates inventory for a date range
func (s *InventoryService) BulkUpdateInventory(ctx context.Context, req *models.BulkUpdateInventoryRequest) ([]models.InventoryValidationError, error) {
	// Parse dates
	start, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		return nil, fmt.Errorf("invalid start date format: %w", err)
	}

	end, err := time.Parse("2006-01-02", req.EndDate)
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

	// Verify room type exists
	_, err = s.roomRepo.GetRoomTypeByID(ctx, req.RoomTypeID)
	if err != nil {
		return nil, fmt.Errorf("invalid room type ID: %w", err)
	}

	// Validate allotment
	if req.Allotment < 0 {
		return nil, fmt.Errorf("allotment cannot be negative")
	}

	// Perform bulk update with validation
	validationErrors, err := s.inventoryRepo.BulkUpdateInventory(ctx, req.RoomTypeID, start, end, req.Allotment)
	if err != nil {
		return nil, err
	}

	return validationErrors, nil
}

// GetInventoryByDate retrieves inventory for a specific date
func (s *InventoryService) GetInventoryByDate(ctx context.Context, roomTypeID int, date string) (*models.RoomInventory, error) {
	// Parse date
	parsedDate, err := time.Parse("2006-01-02", date)
	if err != nil {
		return nil, fmt.Errorf("invalid date format: %w", err)
	}

	// Verify room type exists
	_, err = s.roomRepo.GetRoomTypeByID(ctx, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("invalid room type ID: %w", err)
	}

	return s.inventoryRepo.GetInventoryByDate(ctx, roomTypeID, parsedDate)
}
