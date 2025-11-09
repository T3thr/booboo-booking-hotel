package models

import (
	"time"
)

// PaymentProof represents a payment proof submission
type PaymentProof struct {
	PaymentProofID  int       `json:"payment_proof_id" db:"payment_proof_id"`
	BookingID       int       `json:"booking_id" db:"booking_id"`
	ProofURL        string    `json:"proof_url" db:"proof_url"`
	Status          string    `json:"status" db:"status"` // pending, approved, rejected
	Notes           string    `json:"notes,omitempty" db:"notes"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
	
	// Joined fields from bookings
	GuestName       string    `json:"guest_name" db:"guest_name"`
	GuestEmail      string    `json:"guest_email" db:"guest_email"`
	GuestPhone      string    `json:"guest_phone" db:"guest_phone"`
	RoomTypeName    string    `json:"room_type_name" db:"room_type_name"`
	CheckInDate     time.Time `json:"check_in_date" db:"check_in_date"`
	CheckOutDate    time.Time `json:"check_out_date" db:"check_out_date"`
	TotalAmount     float64   `json:"amount" db:"total_amount"`
	PaymentMethod   string    `json:"payment_method" db:"payment_method"`
}

// PaymentProofRequest represents request to approve/reject payment proof
type PaymentProofRequest struct {
	Status string  `json:"status" validate:"required,oneof=approved rejected"`
	Notes  *string `json:"notes"`
}
