package models

import "time"

// RoomInventory represents the inventory for a specific room type on a specific date
type RoomInventory struct {
	RoomTypeID     int       `json:"room_type_id" db:"room_type_id"`
	Date           time.Time `json:"date" db:"date"`
	Allotment      int       `json:"allotment" db:"allotment"`
	BookedCount    int       `json:"booked_count" db:"booked_count"`
	TentativeCount int       `json:"tentative_count" db:"tentative_count"`
	Available      int       `json:"available"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time `json:"updated_at" db:"updated_at"`
}

// RoomInventoryWithDetails includes room type information
type RoomInventoryWithDetails struct {
	RoomTypeID     int       `json:"room_type_id" db:"room_type_id"`
	RoomTypeName   string    `json:"room_type_name" db:"room_type_name"`
	Date           time.Time `json:"date" db:"date"`
	Allotment      int       `json:"allotment" db:"allotment"`
	BookedCount    int       `json:"booked_count" db:"booked_count"`
	TentativeCount int       `json:"tentative_count" db:"tentative_count"`
	Available      int       `json:"available"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time `json:"updated_at" db:"updated_at"`
}

// UpdateInventoryRequest represents the request to update inventory for a single date
type UpdateInventoryRequest struct {
	RoomTypeID int    `json:"room_type_id" binding:"required"`
	Date       string `json:"date" binding:"required"`
	Allotment  int    `json:"allotment" binding:"required,min=0"`
}

// BulkUpdateInventoryRequest represents the request to update inventory for a date range
type BulkUpdateInventoryRequest struct {
	RoomTypeID int    `json:"room_type_id" binding:"required"`
	StartDate  string `json:"start_date" binding:"required"`
	EndDate    string `json:"end_date" binding:"required"`
	Allotment  int    `json:"allotment" binding:"required,min=0"`
}

// InventoryValidationError represents validation errors for inventory updates
type InventoryValidationError struct {
	Date    string `json:"date"`
	Message string `json:"message"`
}
