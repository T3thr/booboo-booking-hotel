package models

import "time"

// HousekeepingTask represents a room that needs cleaning
type HousekeepingTask struct {
	RoomID             int       `json:"room_id" db:"room_id"`
	RoomNumber         string    `json:"room_number" db:"room_number"`
	RoomTypeID         int       `json:"room_type_id" db:"room_type_id"`
	RoomTypeName       string    `json:"room_type_name" db:"room_type_name"`
	OccupancyStatus    string    `json:"occupancy_status" db:"occupancy_status"`
	HousekeepingStatus string    `json:"housekeeping_status" db:"housekeeping_status"`
	Priority           int       `json:"priority" db:"priority"`
	LastUpdated        time.Time `json:"last_updated" db:"last_updated"`
	EstimatedTime      *int      `json:"estimated_time,omitempty" db:"estimated_time"` // in minutes
}

// UpdateRoomStatusRequest represents a request to update room status
type UpdateRoomStatusRequest struct {
	Status string `json:"status" binding:"required"`
}

// ReportMaintenanceRequest represents a maintenance issue report
type ReportMaintenanceRequest struct {
	Description string `json:"description" binding:"required"`
}

// InspectRoomRequest represents a room inspection request
type InspectRoomRequest struct {
	Approved bool   `json:"approved" binding:"required"`
	Notes    string `json:"notes,omitempty"`
}

// HousekeepingTasksResponse represents the response for task list
type HousekeepingTasksResponse struct {
	Tasks      []HousekeepingTask `json:"tasks"`
	TotalTasks int                `json:"total_tasks"`
	Summary    TaskSummary        `json:"summary"`
}

// TaskSummary provides a summary of tasks by status
type TaskSummary struct {
	Dirty               int `json:"dirty"`
	Cleaning            int `json:"cleaning"`
	Clean               int `json:"clean"`
	Inspected           int `json:"inspected"`
	MaintenanceRequired int `json:"maintenance_required"`
}

// RoomStatusUpdate represents a room status update log
type RoomStatusUpdate struct {
	RoomID    int       `json:"room_id" db:"room_id"`
	OldStatus string    `json:"old_status" db:"old_status"`
	NewStatus string    `json:"new_status" db:"new_status"`
	UpdatedBy int       `json:"updated_by" db:"updated_by"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	Notes     string    `json:"notes,omitempty" db:"notes"`
}
