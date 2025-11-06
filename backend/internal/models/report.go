package models

import "time"

// OccupancyReport represents occupancy statistics
type OccupancyReport struct {
	Date           time.Time `json:"date"`
	RoomTypeID     *int      `json:"room_type_id,omitempty"`
	RoomTypeName   *string   `json:"room_type_name,omitempty"`
	TotalRooms     int       `json:"total_rooms"`
	BookedRooms    int       `json:"booked_rooms"`
	OccupancyRate  float64   `json:"occupancy_rate"`
	AvailableRooms int       `json:"available_rooms"`
}

// RevenueReport represents revenue statistics
type RevenueReport struct {
	Date         time.Time `json:"date"`
	RoomTypeID   *int      `json:"room_type_id,omitempty"`
	RoomTypeName *string   `json:"room_type_name,omitempty"`
	RatePlanID   *int      `json:"rate_plan_id,omitempty"`
	RatePlanName *string   `json:"rate_plan_name,omitempty"`
	TotalRevenue float64   `json:"total_revenue"`
	BookingCount int       `json:"booking_count"`
	RoomNights   int       `json:"room_nights"`
	ADR          float64   `json:"adr"` // Average Daily Rate
}

// VoucherReport represents voucher usage statistics
type VoucherReport struct {
	VoucherID      int       `json:"voucher_id"`
	Code           string    `json:"code"`
	DiscountType   string    `json:"discount_type"`
	DiscountValue  float64   `json:"discount_value"`
	TotalUses      int       `json:"total_uses"`
	TotalDiscount  float64   `json:"total_discount"`
	TotalRevenue   float64   `json:"total_revenue"`
	ConversionRate float64   `json:"conversion_rate"`
	ExpiryDate     time.Time `json:"expiry_date"`
}

// NoShowReport represents no-show statistics
type NoShowReport struct {
	Date           time.Time `json:"date"`
	BookingID      int       `json:"booking_id"`
	GuestName      string    `json:"guest_name"`
	GuestEmail     string    `json:"guest_email"`
	GuestPhone     string    `json:"guest_phone"`
	RoomTypeName   string    `json:"room_type_name"`
	CheckInDate    time.Time `json:"check_in_date"`
	CheckOutDate   time.Time `json:"check_out_date"`
	TotalAmount    float64   `json:"total_amount"`
	PenaltyCharged float64   `json:"penalty_charged"`
}

// ReportSummary represents aggregated report data
type ReportSummary struct {
	StartDate      time.Time `json:"start_date"`
	EndDate        time.Time `json:"end_date"`
	TotalRevenue   float64   `json:"total_revenue"`
	TotalBookings  int       `json:"total_bookings"`
	TotalRoomNights int      `json:"total_room_nights"`
	AvgOccupancy   float64   `json:"avg_occupancy"`
	ADR            float64   `json:"adr"`
	NoShowCount    int       `json:"no_show_count"`
	NoShowRate     float64   `json:"no_show_rate"`
}

// ComparisonData represents year-over-year comparison
type ComparisonData struct {
	CurrentPeriod  ReportSummary `json:"current_period"`
	PreviousPeriod ReportSummary `json:"previous_period"`
	RevenueChange  float64       `json:"revenue_change_percent"`
	OccupancyChange float64      `json:"occupancy_change_percent"`
	ADRChange      float64       `json:"adr_change_percent"`
}
