package repository

import (
	"context"
	"fmt"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/database"
	"github.com/jackc/pgx/v5"
)

type PaymentProofRepository struct {
	db *database.DB
}

func NewPaymentProofRepository(db *database.DB) *PaymentProofRepository {
	return &PaymentProofRepository{db: db}
}

// GetPaymentProofs retrieves all bookings with PendingPayment status (with or without payment proof)
// Supports pagination with limit and offset
func (r *PaymentProofRepository) GetPaymentProofs(ctx context.Context, status string, limit, offset int) ([]models.PaymentProof, int, error) {
	// Get total count first
	countQuery := `
		SELECT COUNT(DISTINCT b.booking_id)
		FROM bookings b
		WHERE b.status = 'PendingPayment'
	`
	
	var totalCount int
	err := r.db.Pool.QueryRow(ctx, countQuery).Scan(&totalCount)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count payment proofs: %w", err)
	}
	
	// Use subquery to get primary guest info properly
	query := `
		WITH primary_guest_info AS (
			SELECT DISTINCT ON (bd.booking_id)
				bd.booking_id,
				bg.first_name,
				bg.last_name,
				bg.email,
				bg.phone
			FROM booking_details bd
			JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
			WHERE bg.is_primary = true
			ORDER BY bd.booking_id, bd.booking_detail_id
		),
		room_info AS (
			SELECT DISTINCT ON (bd.booking_id)
				bd.booking_id,
				rt.name as room_type_name,
				bd.check_in_date,
				bd.check_out_date
			FROM booking_details bd
			JOIN room_types rt ON bd.room_type_id = rt.room_type_id
			ORDER BY bd.booking_id, bd.booking_detail_id
		)
		SELECT 
			COALESCE(pp.payment_proof_id, 0) as payment_proof_id,
			b.booking_id,
			COALESCE(pp.proof_url, '') as proof_url,
			COALESCE(pp.status, 'pending') as status,
			COALESCE(pp.notes, '') as notes,
			COALESCE(pp.created_at, b.created_at) as created_at,
			COALESCE(pp.updated_at, b.updated_at) as updated_at,
			CONCAT(COALESCE(pgi.first_name, 'Guest'), ' ', COALESCE(pgi.last_name, '')) as guest_name,
			COALESCE(pgi.email, 'N/A') as guest_email,
			COALESCE(pgi.phone, 'N/A') as guest_phone,
			COALESCE(ri.room_type_name, 'Unknown Room') as room_type_name,
			COALESCE(ri.check_in_date, b.created_at::date) as check_in_date,
			COALESCE(ri.check_out_date, b.created_at::date + 1) as check_out_date,
			b.total_amount,
			'bank_transfer' as payment_method
		FROM bookings b
		LEFT JOIN primary_guest_info pgi ON b.booking_id = pgi.booking_id
		LEFT JOIN room_info ri ON b.booking_id = ri.booking_id
		LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
		WHERE b.status = 'PendingPayment'
		ORDER BY b.created_at DESC, b.booking_id DESC
		LIMIT $1 OFFSET $2
	`

	rows, err := r.db.Pool.Query(ctx, query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query payment proofs: %w", err)
	}
	defer rows.Close()

	var paymentProofs []models.PaymentProof
	for rows.Next() {
		var pp models.PaymentProof
		err := rows.Scan(
			&pp.PaymentProofID,
			&pp.BookingID,
			&pp.ProofURL,
			&pp.Status,
			&pp.Notes,
			&pp.CreatedAt,
			&pp.UpdatedAt,
			&pp.GuestName,
			&pp.GuestEmail,
			&pp.GuestPhone,
			&pp.RoomTypeName,
			&pp.CheckInDate,
			&pp.CheckOutDate,
			&pp.TotalAmount,
			&pp.PaymentMethod,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan payment proof: %w", err)
		}
		paymentProofs = append(paymentProofs, pp)
	}

	if err = rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("rows iteration error: %w", err)
	}

	return paymentProofs, totalCount, nil
}

// UpdatePaymentProofStatus updates booking status and manages room inventory
func (r *PaymentProofRepository) UpdatePaymentProofStatus(ctx context.Context, bookingID int, status string, notes *string) error {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Get booking total amount
	var totalAmount float64
	err = tx.QueryRow(ctx, `SELECT total_amount FROM bookings WHERE booking_id = $1`, bookingID).Scan(&totalAmount)
	if err != nil {
		return fmt.Errorf("failed to get booking amount: %w", err)
	}

	// Update booking status if approved
	if status == "approved" {
		// Call the confirm_booking function which handles inventory and status update
		var success bool
		var message string
		var returnedBookingID *int
		
		err = tx.QueryRow(ctx, `SELECT * FROM confirm_booking($1)`, bookingID).Scan(&success, &message, &returnedBookingID)
		if err != nil {
			return fmt.Errorf("failed to confirm booking: %w", err)
		}
		
		if !success {
			return fmt.Errorf("booking confirmation failed: %s", message)
		}
		
		// Check if payment proof exists
		var existingID int
		err = tx.QueryRow(ctx, `SELECT payment_proof_id FROM payment_proofs WHERE booking_id = $1`, bookingID).Scan(&existingID)
		if err == pgx.ErrNoRows {
			// Insert new payment proof
			_, err = tx.Exec(ctx, `
				INSERT INTO payment_proofs (booking_id, payment_method, amount, status, notes, proof_url, created_at, updated_at)
				VALUES ($1, 'bank_transfer', $2, 'approved', $3, '', NOW(), NOW())
			`, bookingID, totalAmount, notes)
		} else if err == nil {
			// Update existing payment proof
			_, err = tx.Exec(ctx, `
				UPDATE payment_proofs 
				SET status = 'approved', 
				    notes = COALESCE($2, notes),
				    updated_at = NOW() 
				WHERE booking_id = $1
			`, bookingID, notes)
		}
		if err != nil {
			return fmt.Errorf("failed to update payment proof: %w", err)
		}
		
	} else if status == "rejected" {
		// Cancel the booking using cancel_pending_booking function
		var success bool
		var message string
		var refundAmount *float64
		
		err = tx.QueryRow(ctx, `SELECT * FROM cancel_pending_booking($1)`, bookingID).Scan(&success, &message, &refundAmount)
		if err != nil {
			return fmt.Errorf("failed to cancel booking: %w", err)
		}
		
		if !success {
			return fmt.Errorf("booking cancellation failed: %s", message)
		}
		
		// Check if payment proof exists
		var existingID int
		err = tx.QueryRow(ctx, `SELECT payment_proof_id FROM payment_proofs WHERE booking_id = $1`, bookingID).Scan(&existingID)
		if err == pgx.ErrNoRows {
			// Insert new payment proof
			_, err = tx.Exec(ctx, `
				INSERT INTO payment_proofs (booking_id, payment_method, amount, status, notes, proof_url, created_at, updated_at)
				VALUES ($1, 'bank_transfer', $2, 'rejected', $3, '', NOW(), NOW())
			`, bookingID, totalAmount, notes)
		} else if err == nil {
			// Update existing payment proof
			_, err = tx.Exec(ctx, `
				UPDATE payment_proofs 
				SET status = 'rejected', 
				    notes = COALESCE($2, notes),
				    updated_at = NOW() 
				WHERE booking_id = $1
			`, bookingID, notes)
		}
		if err != nil {
			return fmt.Errorf("failed to update payment proof: %w", err)
		}
	}

	return tx.Commit(ctx)
}

// GetPaymentProofByID retrieves a single payment proof by ID
func (r *PaymentProofRepository) GetPaymentProofByID(ctx context.Context, paymentProofID int) (*models.PaymentProof, error) {
	query := `
		SELECT 
			pp.payment_proof_id,
			pp.booking_id,
			pp.proof_url,
			pp.status,
			pp.notes,
			pp.created_at,
			pp.updated_at,
			CONCAT(g.first_name, ' ', g.last_name) as guest_name,
			rt.name as room_type_name,
			bd.check_in_date,
			bd.check_out_date,
			b.total_amount
		FROM payment_proofs pp
		JOIN bookings b ON pp.booking_id = b.booking_id
		JOIN guests g ON b.guest_id = g.guest_id
		JOIN booking_details bd ON b.booking_id = bd.booking_id
		JOIN room_types rt ON bd.room_type_id = rt.room_type_id
		WHERE pp.payment_proof_id = $1
	`

	var pp models.PaymentProof
	err := r.db.Pool.QueryRow(ctx, query, paymentProofID).Scan(
		&pp.PaymentProofID,
		&pp.BookingID,
		&pp.ProofURL,
		&pp.Status,
		&pp.Notes,
		&pp.CreatedAt,
		&pp.UpdatedAt,
		&pp.GuestName,
		&pp.RoomTypeName,
		&pp.CheckInDate,
		&pp.CheckOutDate,
		&pp.TotalAmount,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get payment proof: %w", err)
	}

	return &pp, nil
}
