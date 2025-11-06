package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/database"
)

type InventoryRepository struct {
	db *database.DB
}

func NewInventoryRepository(db *database.DB) *InventoryRepository {
	return &InventoryRepository{db: db}
}

// GetInventory retrieves inventory for a specific room type and date range
func (r *InventoryRepository) GetInventory(ctx context.Context, roomTypeID int, startDate, endDate time.Time) ([]models.RoomInventoryWithDetails, error) {
	query := `
		SELECT 
			ri.room_type_id,
			rt.name as room_type_name,
			ri.date,
			ri.allotment,
			ri.booked_count,
			ri.tentative_count,
			(ri.allotment - ri.booked_count - ri.tentative_count) as available,
			ri.created_at,
			ri.updated_at
		FROM room_inventory ri
		JOIN room_types rt ON ri.room_type_id = rt.room_type_id
		WHERE ri.room_type_id = $1 
		  AND ri.date >= $2 
		  AND ri.date <= $3
		ORDER BY ri.date
	`

	rows, err := r.db.Pool.Query(ctx, query, roomTypeID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query inventory: %w", err)
	}
	defer rows.Close()

	var inventories []models.RoomInventoryWithDetails
	for rows.Next() {
		var inv models.RoomInventoryWithDetails
		err := rows.Scan(
			&inv.RoomTypeID,
			&inv.RoomTypeName,
			&inv.Date,
			&inv.Allotment,
			&inv.BookedCount,
			&inv.TentativeCount,
			&inv.Available,
			&inv.CreatedAt,
			&inv.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan inventory: %w", err)
		}
		inventories = append(inventories, inv)
	}

	return inventories, nil
}

// GetAllInventory retrieves inventory for all room types within a date range
func (r *InventoryRepository) GetAllInventory(ctx context.Context, startDate, endDate time.Time) ([]models.RoomInventoryWithDetails, error) {
	query := `
		SELECT 
			ri.room_type_id,
			rt.name as room_type_name,
			ri.date,
			ri.allotment,
			ri.booked_count,
			ri.tentative_count,
			(ri.allotment - ri.booked_count - ri.tentative_count) as available,
			ri.created_at,
			ri.updated_at
		FROM room_inventory ri
		JOIN room_types rt ON ri.room_type_id = rt.room_type_id
		WHERE ri.date >= $1 AND ri.date <= $2
		ORDER BY rt.name, ri.date
	`

	rows, err := r.db.Pool.Query(ctx, query, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query all inventory: %w", err)
	}
	defer rows.Close()

	var inventories []models.RoomInventoryWithDetails
	for rows.Next() {
		var inv models.RoomInventoryWithDetails
		err := rows.Scan(
			&inv.RoomTypeID,
			&inv.RoomTypeName,
			&inv.Date,
			&inv.Allotment,
			&inv.BookedCount,
			&inv.TentativeCount,
			&inv.Available,
			&inv.CreatedAt,
			&inv.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan inventory: %w", err)
		}
		inventories = append(inventories, inv)
	}

	return inventories, nil
}

// GetInventoryByDate retrieves inventory for a specific date
func (r *InventoryRepository) GetInventoryByDate(ctx context.Context, roomTypeID int, date time.Time) (*models.RoomInventory, error) {
	query := `
		SELECT 
			room_type_id,
			date,
			allotment,
			booked_count,
			tentative_count,
			created_at,
			updated_at
		FROM room_inventory
		WHERE room_type_id = $1 AND date = $2
	`

	var inv models.RoomInventory
	err := r.db.Pool.QueryRow(ctx, query, roomTypeID, date).Scan(
		&inv.RoomTypeID,
		&inv.Date,
		&inv.Allotment,
		&inv.BookedCount,
		&inv.TentativeCount,
		&inv.CreatedAt,
		&inv.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get inventory: %w", err)
	}

	inv.Available = inv.Allotment - inv.BookedCount - inv.TentativeCount
	return &inv, nil
}

// UpdateInventory updates or creates inventory for a specific date
func (r *InventoryRepository) UpdateInventory(ctx context.Context, roomTypeID int, date time.Time, allotment int) error {
	query := `
		INSERT INTO room_inventory (room_type_id, date, allotment)
		VALUES ($1, $2, $3)
		ON CONFLICT (room_type_id, date)
		DO UPDATE SET 
			allotment = EXCLUDED.allotment,
			updated_at = CURRENT_TIMESTAMP
		WHERE room_inventory.allotment >= room_inventory.booked_count + room_inventory.tentative_count
		  OR EXCLUDED.allotment >= room_inventory.booked_count + room_inventory.tentative_count
	`

	result, err := r.db.Pool.Exec(ctx, query, roomTypeID, date, allotment)
	if err != nil {
		return fmt.Errorf("failed to update inventory: %w", err)
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("cannot reduce allotment below current bookings")
	}

	return nil
}

// BulkUpdateInventory updates inventory for a date range
func (r *InventoryRepository) BulkUpdateInventory(ctx context.Context, roomTypeID int, startDate, endDate time.Time, allotment int) ([]models.InventoryValidationError, error) {
	// First, check which dates would violate the constraint
	checkQuery := `
		SELECT date, booked_count, tentative_count
		FROM room_inventory
		WHERE room_type_id = $1 
		  AND date >= $2 
		  AND date <= $3
		  AND (booked_count + tentative_count) > $4
	`

	rows, err := r.db.Pool.Query(ctx, checkQuery, roomTypeID, startDate, endDate, allotment)
	if err != nil {
		return nil, fmt.Errorf("failed to check inventory constraints: %w", err)
	}
	defer rows.Close()

	var validationErrors []models.InventoryValidationError
	for rows.Next() {
		var date time.Time
		var bookedCount, tentativeCount int
		err := rows.Scan(&date, &bookedCount, &tentativeCount)
		if err != nil {
			return nil, fmt.Errorf("failed to scan validation error: %w", err)
		}

		validationErrors = append(validationErrors, models.InventoryValidationError{
			Date:    date.Format("2006-01-02"),
			Message: fmt.Sprintf("Cannot reduce allotment to %d. Current bookings: %d (booked: %d, tentative: %d)", 
				allotment, bookedCount+tentativeCount, bookedCount, tentativeCount),
		})
	}

	// If there are validation errors, return them without updating
	if len(validationErrors) > 0 {
		return validationErrors, nil
	}

	// Perform the bulk update
	updateQuery := `
		INSERT INTO room_inventory (room_type_id, date, allotment)
		SELECT $1, date_series.date, $4
		FROM generate_series($2::date, $3::date, '1 day'::interval) as date_series(date)
		ON CONFLICT (room_type_id, date)
		DO UPDATE SET 
			allotment = EXCLUDED.allotment,
			updated_at = CURRENT_TIMESTAMP
	`

	_, err = r.db.Pool.Exec(ctx, updateQuery, roomTypeID, startDate, endDate, allotment)
	if err != nil {
		return nil, fmt.Errorf("failed to bulk update inventory: %w", err)
	}

	return nil, nil
}

// ValidateInventoryUpdate checks if an inventory update is valid
func (r *InventoryRepository) ValidateInventoryUpdate(ctx context.Context, roomTypeID int, date time.Time, newAllotment int) error {
	query := `
		SELECT booked_count, tentative_count
		FROM room_inventory
		WHERE room_type_id = $1 AND date = $2
	`

	var bookedCount, tentativeCount int
	err := r.db.Pool.QueryRow(ctx, query, roomTypeID, date).Scan(&bookedCount, &tentativeCount)
	if err != nil {
		// If no record exists, it's valid
		return nil
	}

	currentBookings := bookedCount + tentativeCount
	if newAllotment < currentBookings {
		return fmt.Errorf("cannot reduce allotment to %d, current bookings: %d (booked: %d, tentative: %d)",
			newAllotment, currentBookings, bookedCount, tentativeCount)
	}

	return nil
}
