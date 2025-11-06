package service

import (
	"context"
	"errors"
	"fmt"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
)

// HousekeepingService handles housekeeping business logic
type HousekeepingService struct {
	housekeepingRepo *repository.HousekeepingRepository
}

// NewHousekeepingService creates a new housekeeping service
func NewHousekeepingService(housekeepingRepo *repository.HousekeepingRepository) *HousekeepingService {
	return &HousekeepingService{
		housekeepingRepo: housekeepingRepo,
	}
}

// GetHousekeepingTasks retrieves all housekeeping tasks with summary
func (s *HousekeepingService) GetHousekeepingTasks(ctx context.Context) (*models.HousekeepingTasksResponse, error) {
	// Get tasks
	tasks, err := s.housekeepingRepo.GetHousekeepingTasks(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get tasks: %w", err)
	}

	// Get summary
	summary, err := s.housekeepingRepo.GetTaskSummary(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get summary: %w", err)
	}

	return &models.HousekeepingTasksResponse{
		Tasks:      tasks,
		TotalTasks: len(tasks),
		Summary:    *summary,
	}, nil
}

// UpdateRoomStatus updates the housekeeping status of a room
func (s *HousekeepingService) UpdateRoomStatus(ctx context.Context, roomID int, status string) error {
	// Validate status
	validStatuses := []string{"Dirty", "Cleaning", "Clean", "Inspected", "MaintenanceRequired", "OutOfService"}
	if !contains(validStatuses, status) {
		return errors.New("invalid housekeeping status")
	}

	// Get current room status
	room, err := s.housekeepingRepo.GetRoomByID(ctx, roomID)
	if err != nil {
		return fmt.Errorf("failed to get room: %w", err)
	}

	// Validate status transitions
	if err := s.validateStatusTransition(room.HousekeepingStatus, status); err != nil {
		return err
	}

	// Update status
	if err := s.housekeepingRepo.UpdateRoomStatus(ctx, roomID, status); err != nil {
		return fmt.Errorf("failed to update status: %w", err)
	}

	return nil
}

// InspectRoom allows supervisor to approve or reject a cleaned room
func (s *HousekeepingService) InspectRoom(ctx context.Context, roomID int, approved bool, notes string) error {
	// Get current room status
	room, err := s.housekeepingRepo.GetRoomByID(ctx, roomID)
	if err != nil {
		return fmt.Errorf("failed to get room: %w", err)
	}

	// Validate that room is in Clean status
	if room.HousekeepingStatus != "Clean" {
		return errors.New("room must be in Clean status to be inspected")
	}

	// Update status based on approval
	var newStatus string
	if approved {
		newStatus = "Inspected"
	} else {
		newStatus = "Dirty"
	}

	if err := s.housekeepingRepo.UpdateRoomStatus(ctx, roomID, newStatus); err != nil {
		return fmt.Errorf("failed to update status: %w", err)
	}

	return nil
}

// GetRoomsForInspection retrieves all rooms ready for inspection
func (s *HousekeepingService) GetRoomsForInspection(ctx context.Context) ([]models.HousekeepingTask, error) {
	tasks, err := s.housekeepingRepo.GetRoomsForInspection(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get rooms for inspection: %w", err)
	}

	return tasks, nil
}

// ReportMaintenance marks a room as requiring maintenance
func (s *HousekeepingService) ReportMaintenance(ctx context.Context, roomID int, description string) error {
	// Get current room status
	_, err := s.housekeepingRepo.GetRoomByID(ctx, roomID)
	if err != nil {
		return fmt.Errorf("failed to get room: %w", err)
	}

	// Update status to MaintenanceRequired
	if err := s.housekeepingRepo.UpdateRoomStatus(ctx, roomID, "MaintenanceRequired"); err != nil {
		return fmt.Errorf("failed to update status: %w", err)
	}

	// In a full implementation, we would also create a maintenance ticket here
	// For now, we just update the status

	return nil
}

// validateStatusTransition validates if a status transition is allowed
func (s *HousekeepingService) validateStatusTransition(currentStatus, newStatus string) error {
	// Define allowed transitions
	allowedTransitions := map[string][]string{
		"Dirty":               {"Cleaning", "MaintenanceRequired", "OutOfService"},
		"Cleaning":            {"Clean", "Dirty", "MaintenanceRequired"},
		"Clean":               {"Inspected", "Dirty", "MaintenanceRequired"},
		"Inspected":           {"Dirty", "MaintenanceRequired", "OutOfService"},
		"MaintenanceRequired": {"Dirty", "OutOfService"},
		"OutOfService":        {"Dirty"},
	}

	// Check if transition is allowed
	allowed, exists := allowedTransitions[currentStatus]
	if !exists {
		return fmt.Errorf("unknown current status: %s", currentStatus)
	}

	if !contains(allowed, newStatus) {
		return fmt.Errorf("invalid status transition from %s to %s", currentStatus, newStatus)
	}

	return nil
}

// contains checks if a string slice contains a specific string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
