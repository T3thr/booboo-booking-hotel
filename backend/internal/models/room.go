package models

// RoomType represents a type of room
type RoomType struct {
	RoomTypeID        int       `json:"room_type_id" db:"room_type_id"`
	Name              string    `json:"name" db:"name"`
	Description       string    `json:"description" db:"description"`
	MaxOccupancy      int       `json:"max_occupancy" db:"max_occupancy"`
	DefaultAllotment  int       `json:"default_allotment" db:"default_allotment"`
	BasePrice         *float64  `json:"base_price,omitempty" db:"base_price"`
	ImageURL          *string   `json:"image_url,omitempty" db:"image_url"`
	Amenities         []Amenity `json:"amenities,omitempty"`
	AvailableRooms    *int      `json:"available_rooms"` // Remove omitempty to always include this field
	TotalPrice        *float64  `json:"total_price,omitempty"`
	PricePerNight     *float64  `json:"price_per_night,omitempty"`
	NightlyPrices     []NightlyPrice `json:"nightly_prices,omitempty"`
}

// Room represents a physical room
type Room struct {
	RoomID              int       `json:"room_id" db:"room_id"`
	RoomTypeID          int       `json:"room_type_id" db:"room_type_id"`
	RoomNumber          string    `json:"room_number" db:"room_number"`
	OccupancyStatus     string    `json:"occupancy_status" db:"occupancy_status"`
	HousekeepingStatus  string    `json:"housekeeping_status" db:"housekeeping_status"`
	RoomTypeName        *string   `json:"room_type_name,omitempty" db:"room_type_name"`
}

// Amenity represents a room amenity
type Amenity struct {
	AmenityID int    `json:"amenity_id" db:"amenity_id"`
	Name      string `json:"name" db:"name"`
}



// NightlyPrice represents the price for a specific night
type NightlyPrice struct {
	Date  string  `json:"date"`
	Price float64 `json:"price"`
}

// SearchRoomsRequest represents room search parameters
type SearchRoomsRequest struct {
	CheckIn  string `form:"checkIn" binding:"required"`
	CheckOut string `form:"checkOut" binding:"required"`
	Guests   int    `form:"guests" binding:"required,min=1"`
}

// SearchRoomsResponse represents the search results
type SearchRoomsResponse struct {
	RoomTypes      []RoomType `json:"room_types"`
	CheckIn        string     `json:"check_in"`
	CheckOut       string     `json:"check_out"`
	Guests         int        `json:"guests"`
	TotalNights    int        `json:"total_nights"`
	AlternativeDates []string `json:"alternative_dates,omitempty"`
}

// RoomTypeDetailResponse represents detailed room type information
type RoomTypeDetailResponse struct {
	RoomType
	Rooms []Room `json:"rooms,omitempty"`
}

// RoomStatus represents the current status of a room with guest information
type RoomStatus struct {
	RoomID             int     `json:"room_id"`
	RoomNumber         string  `json:"room_number"`
	OccupancyStatus    string  `json:"occupancy_status"`
	HousekeepingStatus string  `json:"housekeeping_status"`
	RoomTypeID         int     `json:"room_type_id"`
	RoomTypeName       string  `json:"room_type_name"`
	GuestName          string  `json:"guest_name,omitempty"`
	ExpectedCheckout   *string `json:"expected_checkout,omitempty"`
}

// RoomStatusSummary represents a summary of room statuses
type RoomStatusSummary struct {
	TotalRooms         int `json:"total_rooms"`
	VacantClean        int `json:"vacant_clean"`
	VacantInspected    int `json:"vacant_inspected"`
	VacantDirty        int `json:"vacant_dirty"`
	Occupied           int `json:"occupied"`
	OutOfService       int `json:"out_of_service"`
	MaintenanceRequired int `json:"maintenance_required"`
}

// RoomStatusDashboardResponse represents the complete dashboard data
type RoomStatusDashboardResponse struct {
	Rooms   []RoomStatus      `json:"rooms"`
	Summary RoomStatusSummary `json:"summary"`
}
