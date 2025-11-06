package models

import "time"

// Booking represents a booking in the system
type Booking struct {
	BookingID         int       `json:"booking_id" db:"booking_id"`
	GuestID           int       `json:"guest_id" db:"guest_id"`
	VoucherID         *int      `json:"voucher_id,omitempty" db:"voucher_id"`
	TotalAmount       float64   `json:"total_amount" db:"total_amount"`
	Status            string    `json:"status" db:"status"`
	CreatedAt         time.Time `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time `json:"updated_at" db:"updated_at"`
	PolicyName        string    `json:"policy_name" db:"policy_name"`
	PolicyDescription string    `json:"policy_description" db:"policy_description"`
}

// BookingDetail represents details of a booking
type BookingDetail struct {
	BookingDetailID int       `json:"booking_detail_id" db:"booking_detail_id"`
	BookingID       int       `json:"booking_id" db:"booking_id"`
	RoomTypeID      int       `json:"room_type_id" db:"room_type_id"`
	RatePlanID      int       `json:"rate_plan_id" db:"rate_plan_id"`
	CheckInDate     time.Time `json:"check_in_date" db:"check_in_date"`
	CheckOutDate    time.Time `json:"check_out_date" db:"check_out_date"`
	NumGuests       int       `json:"num_guests" db:"num_guests"`
}

// BookingGuest represents a guest in a booking
type BookingGuest struct {
	BookingGuestID  int     `json:"booking_guest_id" db:"booking_guest_id"`
	BookingDetailID int     `json:"booking_detail_id" db:"booking_detail_id"`
	FirstName       string  `json:"first_name" db:"first_name"`
	LastName        string  `json:"last_name" db:"last_name"`
	Phone           *string `json:"phone,omitempty" db:"phone"`
	Type            string  `json:"type" db:"type"`
	IsPrimary       bool    `json:"is_primary" db:"is_primary"`
}

// BookingNightlyLog represents the nightly pricing log
type BookingNightlyLog struct {
	BookingNightlyLogID int       `json:"booking_nightly_log_id" db:"booking_nightly_log_id"`
	BookingDetailID     int       `json:"booking_detail_id" db:"booking_detail_id"`
	Date                time.Time `json:"date" db:"date"`
	QuotedPrice         float64   `json:"quoted_price" db:"quoted_price"`
}

// BookingHold represents a temporary hold on inventory
type BookingHold struct {
	HoldID         int       `json:"hold_id" db:"hold_id"`
	SessionID      string    `json:"session_id" db:"session_id"`
	GuestAccountID *int      `json:"guest_account_id,omitempty" db:"guest_account_id"`
	RoomTypeID     int       `json:"room_type_id" db:"room_type_id"`
	Date           time.Time `json:"date" db:"date"`
	HoldExpiry     time.Time `json:"hold_expiry" db:"hold_expiry"`
}

// RoomAssignment represents a room assignment for a booking
type RoomAssignment struct {
	RoomAssignmentID  int        `json:"room_assignment_id" db:"room_assignment_id"`
	BookingDetailID   int        `json:"booking_detail_id" db:"booking_detail_id"`
	RoomID            int        `json:"room_id" db:"room_id"`
	CheckInDateTime   time.Time  `json:"check_in_datetime" db:"check_in_datetime"`
	CheckOutDateTime  *time.Time `json:"check_out_datetime,omitempty" db:"check_out_datetime"`
	Status            string     `json:"status" db:"status"`
}

// CreateBookingHoldRequest represents the request to create a booking hold
type CreateBookingHoldRequest struct {
	SessionID      string `json:"session_id" binding:"required"`
	GuestAccountID *int   `json:"guest_account_id,omitempty"`
	RoomTypeID     int    `json:"room_type_id" binding:"required"`
	CheckIn        string `json:"check_in" binding:"required"`
	CheckOut       string `json:"check_out" binding:"required"`
}

// CreateBookingHoldResponse represents the response from creating a hold
type CreateBookingHoldResponse struct {
	HoldID     int       `json:"hold_id"`
	Success    bool      `json:"success"`
	Message    string    `json:"message"`
	HoldExpiry time.Time `json:"hold_expiry,omitempty"`
}

// CreateBookingRequest represents the request to create a booking
type CreateBookingRequest struct {
	SessionID   string                  `json:"session_id" binding:"required"`
	VoucherCode *string                 `json:"voucher_code,omitempty"`
	Details     []CreateBookingDetailRequest `json:"details" binding:"required,min=1,dive"`
}

// CreateBookingDetailRequest represents details for a single room booking
type CreateBookingDetailRequest struct {
	RoomTypeID int                  `json:"room_type_id" binding:"required"`
	RatePlanID int                  `json:"rate_plan_id" binding:"required"`
	CheckIn    string               `json:"check_in" binding:"required"`
	CheckOut   string               `json:"check_out" binding:"required"`
	NumGuests  int                  `json:"num_guests" binding:"required,min=1"`
	Guests     []CreateGuestRequest `json:"guests" binding:"required,min=1,dive"`
}

// CreateGuestRequest represents a guest in the booking
type CreateGuestRequest struct {
	FirstName string  `json:"first_name" binding:"required,min=2,max=100"`
	LastName  string  `json:"last_name" binding:"required,min=2,max=100"`
	Phone     *string `json:"phone,omitempty"`
	Type      string  `json:"type" binding:"required,oneof=Adult Child"`
	IsPrimary bool    `json:"is_primary"`
}

// CreateBookingResponse represents the response from creating a booking
type CreateBookingResponse struct {
	BookingID   int     `json:"booking_id"`
	TotalAmount float64 `json:"total_amount"`
	Status      string  `json:"status"`
	Message     string  `json:"message"`
}

// ConfirmBookingRequest represents the request to confirm a booking
type ConfirmBookingRequest struct {
	BookingID     int    `json:"booking_id" binding:"required"`
	PaymentMethod string `json:"payment_method" binding:"required"`
	PaymentID     string `json:"payment_id" binding:"required"`
}

// ConfirmBookingResponse represents the response from confirming a booking
type ConfirmBookingResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// CancelBookingRequest represents the request to cancel a booking
type CancelBookingRequest struct {
	BookingID int    `json:"booking_id" binding:"required"`
	Reason    string `json:"reason,omitempty"`
}

// CancelBookingResponse represents the response from canceling a booking
type CancelBookingResponse struct {
	Success      bool    `json:"success"`
	Message      string  `json:"message"`
	RefundAmount float64 `json:"refund_amount,omitempty"`
}

// BookingWithDetails represents a booking with all its details
type BookingWithDetails struct {
	Booking
	Details []BookingDetailWithGuests `json:"details"`
	Guest   *Guest                    `json:"guest,omitempty"`
}

// BookingDetailWithGuests represents a booking detail with guests
type BookingDetailWithGuests struct {
	BookingDetail
	RoomTypeName  string              `json:"room_type_name"`
	Guests        []BookingGuest      `json:"guests"`
	NightlyPrices []BookingNightlyLog `json:"nightly_prices,omitempty"`
	RoomNumber    *string             `json:"room_number,omitempty"`
}

// GetBookingsRequest represents query parameters for getting bookings
type GetBookingsRequest struct {
	Status string `form:"status"`
	Limit  int    `form:"limit"`
	Offset int    `form:"offset"`
}

// GetBookingsResponse represents the response for getting bookings
type GetBookingsResponse struct {
	Bookings []BookingWithDetails `json:"bookings"`
	Total    int                  `json:"total"`
	Limit    int                  `json:"limit"`
	Offset   int                  `json:"offset"`
}



// CheckInRequest represents the request to check in a guest
type CheckInRequest struct {
	BookingDetailID int `json:"booking_detail_id" binding:"required"`
	RoomID          int `json:"room_id" binding:"required"`
}

// CheckInResponse represents the response from check-in
type CheckInResponse struct {
	Success    bool   `json:"success"`
	Message    string `json:"message"`
	RoomNumber string `json:"room_number,omitempty"`
}

// CheckOutRequest represents the request to check out a guest
type CheckOutRequest struct {
	BookingID int `json:"booking_id" binding:"required"`
}

// CheckOutResponse represents the response from check-out
type CheckOutResponse struct {
	Success     bool    `json:"success"`
	Message     string  `json:"message"`
	TotalAmount float64 `json:"total_amount,omitempty"`
}

// MoveRoomRequest represents the request to move a guest to another room
type MoveRoomRequest struct {
	RoomAssignmentID int    `json:"room_assignment_id" binding:"required"`
	NewRoomID        int    `json:"new_room_id" binding:"required"`
	Reason           string `json:"reason,omitempty"`
}

// MoveRoomResponse represents the response from moving a room
type MoveRoomResponse struct {
	Success       bool   `json:"success"`
	Message       string `json:"message"`
	NewRoomNumber string `json:"new_room_number,omitempty"`
}

// MarkNoShowRequest represents the request to mark a booking as no-show
type MarkNoShowRequest struct {
	BookingID int    `json:"booking_id" binding:"required"`
	Notes     string `json:"notes,omitempty"`
}

// MarkNoShowResponse represents the response from marking no-show
type MarkNoShowResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// GetArrivalsRequest represents query parameters for getting arrivals
type GetArrivalsRequest struct {
	Date string `form:"date"` // Format: YYYY-MM-DD, defaults to today
}

// GetDeparturesRequest represents query parameters for getting departures
type GetDeparturesRequest struct {
	Date string `form:"date"` // Format: YYYY-MM-DD, defaults to today
}

// ArrivalInfo represents information about an arriving guest
type ArrivalInfo struct {
	BookingID       int       `json:"booking_id" db:"booking_id"`
	BookingDetailID int       `json:"booking_detail_id" db:"booking_detail_id"`
	GuestName       string    `json:"guest_name" db:"guest_name"`
	RoomTypeName    string    `json:"room_type_name" db:"room_type_name"`
	CheckInDate     time.Time `json:"check_in_date" db:"check_in_date"`
	CheckOutDate    time.Time `json:"check_out_date" db:"check_out_date"`
	NumGuests       int       `json:"num_guests" db:"num_guests"`
	Status          string    `json:"status" db:"status"`
	RoomNumber      *string   `json:"room_number,omitempty" db:"room_number"`
}

// DepartureInfo represents information about a departing guest
type DepartureInfo struct {
	BookingID    int       `json:"booking_id" db:"booking_id"`
	GuestName    string    `json:"guest_name" db:"guest_name"`
	RoomNumber   string    `json:"room_number" db:"room_number"`
	CheckOutDate time.Time `json:"check_out_date" db:"check_out_date"`
	TotalAmount  float64   `json:"total_amount" db:"total_amount"`
	Status       string    `json:"status" db:"status"`
}

// AvailableRoomForCheckIn represents a room available for check-in
type AvailableRoomForCheckIn struct {
	RoomID              int    `json:"room_id" db:"room_id"`
	RoomNumber          string `json:"room_number" db:"room_number"`
	OccupancyStatus     string `json:"occupancy_status" db:"occupancy_status"`
	HousekeepingStatus  string `json:"housekeeping_status" db:"housekeeping_status"`
}
