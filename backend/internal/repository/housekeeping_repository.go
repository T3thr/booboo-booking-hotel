package repository

import (
	"context"
	"fmt"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/database"
)

// HousekeepingRepository handles housekeeping database operations
type HousekeepingRepository struct {
	db *database.DB
}

// NewHousekeepingRepository creates a new housekeeping repository
func NewHousekeepingRepository(db *database.DB) *HousekeepingRepository {
	return &HousekeepingRepository{db: db}
}

// GetHousekeepingTasks retrieves all rooms that need cleaning or inspection
func (r *HousekeepingRepository) GetHousekeepingTasks(ctx context.Context) ([]models.HousekeepingTask, error) {
	query := `
		SELECT 
			r.room_id,
			r.room_number,
			r.room_type_id,
			rt.name as room_type_name,
			r.occupancy_status,
			r.housekeeping_status,
			CASE 
				WHEN r.housekeeping_status = 'Dirty' AND r.occupancy_status = 'Vacant' THEN 1
				WHEN r.housekeeping_status = 'Dirty' AND r.occupancy_status = 'Occupied' THEN 2
				WHEN r.housekeeping_status = 'Cleaning' THEN 3
				WHEN r.housekeeping_status = 'Clean' THEN 4
				ELSE 5
			END as priority,
			CURRENT_TIMESTAMP as last_updated,
			CASE 
				WHEN rt.name ILIKE '%suite%' THEN 45
				WHEN rt.name ILIKE '%deluxe%' THEN 35
				ELSE 25
			END as estimated_time
		FROM rooms r
		INNER JOIN room_types rt ON r.room_type_id = rt.room_type_id
		WHERE r.housekeeping_status IN ('Dirty', 'Cleaning', 'Clean')
		ORDER BY priority ASC, r.room_number ASC
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get housekeeping tasks: %w", err)
	}
	defer rows.Close()

	var tasks []models.HousekeepingTask
	for rows.Next() {
		var task models.HousekeepingTask
		if err := rows.Scan(
			&task.RoomID,
			&task.RoomNumber,
			&task.RoomTypeID,
			&task.RoomTypeName,
			&task.OccupancyStatus,
			&task.HousekeepingStatus,
			&task.Priority,
			&task.LastUpdated,
			&task.EstimatedTime,
		); err != nil {
			return nil, fmt.Errorf("failed to scan task: %w", err)
		}
		tasks = append(tasks, task)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}

	return tasks, nil
}

// GetTaskSummary retrieves a summary of tasks by status
func (r *HousekeepingRepository) GetTaskSummary(ctx context.Context) (*models.TaskSummary, error) {
	query := `
		SELECT 
			COUNT(*) FILTER (WHERE housekeeping_status = 'Dirty') as dirty,
			COUNT(*) FILTER (WHERE housekeeping_status = 'Cleaning') as cleaning,
			COUNT(*) FILTER (WHERE housekeeping_status = 'Clean') as clean,
			COUNT(*) FILTER (WHERE housekeeping_status = 'Inspected') as inspected,
			COUNT(*) FILTER (WHERE housekeeping_status = 'MaintenanceRequired') as maintenance_required
		FROM rooms
	`

	var summary models.TaskSummary
	err := r.db.Pool.QueryRow(ctx, query).Scan(
		&summary.Dirty,
		&summary.Cleaning,
		&summary.Clean,
		&summary.Inspected,
		&summary.MaintenanceRequired,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get task summary: %w", err)
	}

	return &summary, nil
}

// UpdateRoomStatus updates the housekeeping status of a room
func (r *HousekeepingRepository) UpdateRoomStatus(ctx context.Context, roomID int, status string) error {
	query := `
		UPDATE rooms
		SET housekeeping_status = $1
		WHERE room_id = $2
	`

	result, err := r.db.Pool.Exec(ctx, query, status, roomID)
	if err != nil {
		return fmt.Errorf("failed to update room status: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("room not found")
	}

	return nil
}

// GetRoomByID retrieves a room by ID
func (r *HousekeepingRepository) GetRoomByID(ctx context.Context, roomID int) (*models.Room, error) {
	query := `
		SELECT 
			room_id,
			room_type_id,
			room_number,
			occupancy_status,
			housekeeping_status
		FROM rooms
		WHERE room_id = $1
	`

	var room models.Room
	err := r.db.Pool.QueryRow(ctx, query, roomID).Scan(
		&room.RoomID,
		&room.RoomTypeID,
		&room.RoomNumber,
		&room.OccupancyStatus,
		&room.HousekeepingStatus,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get room: %w", err)
	}

	return &room, nil
}

// GetRoomsForInspection retrieves all rooms that are ready for inspection
func (r *HousekeepingRepository) GetRoomsForInspection(ctx context.Context) ([]models.HousekeepingTask, error) {
	query := `
		SELECT 
			r.room_id,
			r.room_number,
			r.room_type_id,
			rt.name as room_type_name,
			r.occupancy_status,
			r.housekeeping_status,
			4 as priority,
			CURRENT_TIMESTAMP as last_updated,
			5 as estimated_time
		FROM rooms r
		INNER JOIN room_types rt ON r.room_type_id = rt.room_type_id
		WHERE r.housekeeping_status = 'Clean'
		ORDER BY r.room_number ASC
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get rooms for inspection: %w", err)
	}
	defer rows.Close()

	var tasks []models.HousekeepingTask
	for rows.Next() {
		var task models.HousekeepingTask
		if err := rows.Scan(
			&task.RoomID,
			&task.RoomNumber,
			&task.RoomTypeID,
			&task.RoomTypeName,
			&task.OccupancyStatus,
			&task.HousekeepingStatus,
			&task.Priority,
			&task.LastUpdated,
			&task.EstimatedTime,
		); err != nil {
			return nil, fmt.Errorf("failed to scan task: %w", err)
		}
		tasks = append(tasks, task)
	}

	return tasks, nil
}
