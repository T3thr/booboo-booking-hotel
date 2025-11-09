package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/database"
	"github.com/jackc/pgx/v5"
)

// BookingRepository handles booking database operations
type BookingRepository struct {
	db *database.DB
}

// NewBookingRepository creates a new booking repository
func NewBookingRepository(db *database.DB) *BookingRepository {
	return &BookingRepository{db: db}
}

// CreateBookingHold calls the PostgreSQL function to create a booking hold
func (r *BookingRepository) CreateBookingHold(ctx context.Context, req *models.CreateBookingHoldRequest) (*models.CreateBookingHoldResponse, error) {
	query := `
		SELECT success, message, expiry_time FROM create_booking_hold($1, $2, $3, $4::date, $5::date)
	`

	var success bool
	var message string
	var expiryTime *time.Time

	err := r.db.Pool.QueryRow(ctx, query,
		req.SessionID,
		req.GuestAccountID,
		req.RoomTypeID,
		req.CheckIn,
		req.CheckOut,
	).Scan(&success, &message, &expiryTime)

	if err != nil {
		return nil, fmt.Errorf("failed to create booking hold: %w", err)
	}

	response := &models.CreateBookingHoldResponse{
		Success: success,
		Message: message,
	}

	if expiryTime != nil {
		response.HoldExpiry = *expiryTime
	}

	return response, nil
}

// CreateBooking creates a new booking with details
func (r *BookingRepository) CreateBooking(ctx context.Context, guestID int, voucherID *int, totalAmount float64, policyName, policyDescription string) (*models.Booking, error) {
	query := `
		INSERT INTO bookings (guest_id, voucher_id, total_amount, status, policy_name, policy_description)
		VALUES ($1, $2, $3, 'PendingPayment', $4, $5)
		RETURNING booking_id, guest_id, voucher_id, total_amount, status, created_at, updated_at, policy_name, policy_description
	`

	// Convert guestID to *int for NULL support
	var guestIDPtr *int
	if guestID > 0 {
		guestIDPtr = &guestID
	}

	var booking models.Booking
	err := r.db.Pool.QueryRow(ctx, query,
		guestIDPtr,
		voucherID,
		totalAmount,
		policyName,
		policyDescription,
	).Scan(
		&booking.BookingID,
		&booking.GuestID,
		&booking.VoucherID,
		&booking.TotalAmount,
		&booking.Status,
		&booking.CreatedAt,
		&booking.UpdatedAt,
		&booking.PolicyName,
		&booking.PolicyDescription,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create booking: %w", err)
	}

	return &booking, nil
}

// CreateBookingDetail creates a booking detail
func (r *BookingRepository) CreateBookingDetail(ctx context.Context, detail *models.BookingDetail) error {
	query := `
		INSERT INTO booking_details (booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING booking_detail_id
	`

	return r.db.Pool.QueryRow(ctx, query,
		detail.BookingID,
		detail.RoomTypeID,
		detail.RatePlanID,
		detail.CheckInDate,
		detail.CheckOutDate,
		detail.NumGuests,
	).Scan(&detail.BookingDetailID)
}

// CreateBookingGuest creates a booking guest
func (r *BookingRepository) CreateBookingGuest(ctx context.Context, guest *models.BookingGuest) error {
	query := `
		INSERT INTO booking_guests (booking_detail_id, first_name, last_name, phone, email, type, is_primary)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING booking_guest_id
	`

	return r.db.Pool.QueryRow(ctx, query,
		guest.BookingDetailID,
		guest.FirstName,
		guest.LastName,
		guest.Phone,
		guest.Email,
		guest.Type,
		guest.IsPrimary,
	).Scan(&guest.BookingGuestID)
}

// CreateBookingNightlyLog creates a nightly log entry
func (r *BookingRepository) CreateBookingNightlyLog(ctx context.Context, log *models.BookingNightlyLog) error {
	query := `
		INSERT INTO booking_nightly_log (booking_detail_id, date, quoted_price)
		VALUES ($1, $2, $3)
		RETURNING booking_nightly_log_id
	`

	return r.db.Pool.QueryRow(ctx, query,
		log.BookingDetailID,
		log.Date,
		log.QuotedPrice,
	).Scan(&log.BookingNightlyLogID)
}

// ConfirmBooking calls the PostgreSQL function to confirm a booking
func (r *BookingRepository) ConfirmBooking(ctx context.Context, bookingID int) (*models.ConfirmBookingResponse, error) {
	query := `
		SELECT * FROM confirm_booking($1)
	`

	var success bool
	var message string
	var returnedBookingID *int // Function returns booking_id as third column

	err := r.db.Pool.QueryRow(ctx, query, bookingID).Scan(&success, &message, &returnedBookingID)
	if err != nil {
		return nil, fmt.Errorf("failed to confirm booking: %w", err)
	}

	return &models.ConfirmBookingResponse{
		Success: success,
		Message: message,
	}, nil
}

// CancelBooking calls the appropriate PostgreSQL function to cancel a booking
func (r *BookingRepository) CancelBooking(ctx context.Context, bookingID int) (*models.CancelBookingResponse, error) {
	// First, get the booking status
	var status string
	statusQuery := `SELECT status FROM bookings WHERE booking_id = $1`
	err := r.db.Pool.QueryRow(ctx, statusQuery, bookingID).Scan(&status)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return &models.CancelBookingResponse{
				Success: false,
				Message: "Booking not found",
			}, nil
		}
		return nil, fmt.Errorf("failed to get booking status: %w", err)
	}

	var query string
	if status == "Confirmed" || status == "CheckedIn" {
		query = `SELECT * FROM cancel_confirmed_booking($1)`
	} else if status == "PendingPayment" {
		query = `SELECT * FROM cancel_pending_booking($1)`
	} else {
		return &models.CancelBookingResponse{
			Success: false,
			Message: fmt.Sprintf("Cannot cancel booking with status: %s", status),
		}, nil
	}

	var success bool
	var message string
	var refundAmount *float64

	err = r.db.Pool.QueryRow(ctx, query, bookingID).Scan(&success, &message, &refundAmount)
	if err != nil {
		return nil, fmt.Errorf("failed to cancel booking: %w", err)
	}

	response := &models.CancelBookingResponse{
		Success: success,
		Message: message,
	}

	if refundAmount != nil {
		response.RefundAmount = *refundAmount
	}

	return response, nil
}

// GetBookingByID retrieves a booking by ID with all details
func (r *BookingRepository) GetBookingByID(ctx context.Context, bookingID int) (*models.BookingWithDetails, error) {
	// Get booking
	bookingQuery := `
		SELECT booking_id, guest_id, voucher_id, total_amount, status, 
		       created_at, updated_at, policy_name, policy_description
		FROM bookings
		WHERE booking_id = $1
	`

	var booking models.Booking
	err := r.db.Pool.QueryRow(ctx, bookingQuery, bookingID).Scan(
		&booking.BookingID,
		&booking.GuestID,
		&booking.VoucherID,
		&booking.TotalAmount,
		&booking.Status,
		&booking.CreatedAt,
		&booking.UpdatedAt,
		&booking.PolicyName,
		&booking.PolicyDescription,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get booking: %w", err)
	}

	// Get booking details
	details, err := r.getBookingDetails(ctx, bookingID)
	if err != nil {
		return nil, err
	}

	return &models.BookingWithDetails{
		Booking: booking,
		Details: details,
	}, nil
}

// getBookingDetails retrieves all details for a booking
func (r *BookingRepository) getBookingDetails(ctx context.Context, bookingID int) ([]models.BookingDetailWithGuests, error) {
	detailsQuery := `
		SELECT bd.booking_detail_id, bd.booking_id, bd.room_type_id, bd.rate_plan_id,
		       bd.check_in_date, bd.check_out_date, bd.num_guests, rt.name as room_type_name
		FROM booking_details bd
		JOIN room_types rt ON bd.room_type_id = rt.room_type_id
		WHERE bd.booking_id = $1
		ORDER BY bd.booking_detail_id
	`

	rows, err := r.db.Pool.Query(ctx, detailsQuery, bookingID)
	if err != nil {
		return nil, fmt.Errorf("failed to get booking details: %w", err)
	}
	defer rows.Close()

	var details []models.BookingDetailWithGuests
	for rows.Next() {
		var detail models.BookingDetailWithGuests
		err := rows.Scan(
			&detail.BookingDetailID,
			&detail.BookingID,
			&detail.RoomTypeID,
			&detail.RatePlanID,
			&detail.CheckInDate,
			&detail.CheckOutDate,
			&detail.NumGuests,
			&detail.RoomTypeName,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan booking detail: %w", err)
		}

		// Get guests for this detail
		guests, err := r.getBookingGuests(ctx, detail.BookingDetailID)
		if err != nil {
			return nil, err
		}
		detail.Guests = guests

		// Get nightly prices
		nightlyPrices, err := r.getBookingNightlyPrices(ctx, detail.BookingDetailID)
		if err != nil {
			return nil, err
		}
		detail.NightlyPrices = nightlyPrices

		// Get room number if assigned
		roomNumber, err := r.getAssignedRoomNumber(ctx, detail.BookingDetailID)
		if err == nil && roomNumber != "" {
			detail.RoomNumber = &roomNumber
		}

		details = append(details, detail)
	}

	return details, nil
}

// getBookingGuests retrieves guests for a booking detail
func (r *BookingRepository) getBookingGuests(ctx context.Context, bookingDetailID int) ([]models.BookingGuest, error) {
	query := `
		SELECT booking_guest_id, booking_detail_id, first_name, last_name, phone, type, is_primary
		FROM booking_guests
		WHERE booking_detail_id = $1
		ORDER BY is_primary DESC, booking_guest_id
	`

	rows, err := r.db.Pool.Query(ctx, query, bookingDetailID)
	if err != nil {
		return nil, fmt.Errorf("failed to get booking guests: %w", err)
	}
	defer rows.Close()

	var guests []models.BookingGuest
	for rows.Next() {
		var guest models.BookingGuest
		err := rows.Scan(
			&guest.BookingGuestID,
			&guest.BookingDetailID,
			&guest.FirstName,
			&guest.LastName,
			&guest.Phone,
			&guest.Type,
			&guest.IsPrimary,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan booking guest: %w", err)
		}
		guests = append(guests, guest)
	}

	return guests, nil
}

// getBookingNightlyPrices retrieves nightly prices for a booking detail
func (r *BookingRepository) getBookingNightlyPrices(ctx context.Context, bookingDetailID int) ([]models.BookingNightlyLog, error) {
	query := `
		SELECT booking_nightly_log_id, booking_detail_id, date, quoted_price
		FROM booking_nightly_log
		WHERE booking_detail_id = $1
		ORDER BY date
	`

	rows, err := r.db.Pool.Query(ctx, query, bookingDetailID)
	if err != nil {
		return nil, fmt.Errorf("failed to get nightly prices: %w", err)
	}
	defer rows.Close()

	var prices []models.BookingNightlyLog
	for rows.Next() {
		var price models.BookingNightlyLog
		err := rows.Scan(
			&price.BookingNightlyLogID,
			&price.BookingDetailID,
			&price.Date,
			&price.QuotedPrice,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan nightly price: %w", err)
		}
		prices = append(prices, price)
	}

	return prices, nil
}

// getAssignedRoomNumber retrieves the assigned room number for a booking detail
func (r *BookingRepository) getAssignedRoomNumber(ctx context.Context, bookingDetailID int) (string, error) {
	query := `
		SELECT r.room_number
		FROM room_assignments ra
		JOIN rooms r ON ra.room_id = r.room_id
		WHERE ra.booking_detail_id = $1 AND ra.status = 'Active'
		LIMIT 1
	`

	var roomNumber string
	err := r.db.Pool.QueryRow(ctx, query, bookingDetailID).Scan(&roomNumber)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", nil
		}
		return "", err
	}

	return roomNumber, nil
}

// GetBookingsByGuestID retrieves all bookings for a guest
func (r *BookingRepository) GetBookingsByGuestID(ctx context.Context, guestID int, status string, limit, offset int) ([]models.BookingWithDetails, int, error) {
	// Build query with optional status filter
	whereClause := "WHERE guest_id = $1"
	args := []interface{}{guestID}
	argCount := 1

	if status != "" {
		argCount++
		whereClause += fmt.Sprintf(" AND status = $%d", argCount)
		args = append(args, status)
	}

	// Get total count
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM bookings %s", whereClause)
	var total int
	err := r.db.Pool.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count bookings: %w", err)
	}

	// Get bookings
	argCount++
	limitArg := argCount
	argCount++
	offsetArg := argCount

	query := fmt.Sprintf(`
		SELECT booking_id, guest_id, voucher_id, total_amount, status,
		       created_at, updated_at, policy_name, policy_description
		FROM bookings
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, limitArg, offsetArg)

	args = append(args, limit, offset)

	rows, err := r.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get bookings: %w", err)
	}
	defer rows.Close()

	var bookings []models.BookingWithDetails
	for rows.Next() {
		var booking models.Booking
		err := rows.Scan(
			&booking.BookingID,
			&booking.GuestID,
			&booking.VoucherID,
			&booking.TotalAmount,
			&booking.Status,
			&booking.CreatedAt,
			&booking.UpdatedAt,
			&booking.PolicyName,
			&booking.PolicyDescription,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan booking: %w", err)
		}

		// Get details for each booking
		details, err := r.getBookingDetails(ctx, booking.BookingID)
		if err != nil {
			return nil, 0, err
		}

		bookings = append(bookings, models.BookingWithDetails{
			Booking: booking,
			Details: details,
		})
	}

	return bookings, total, nil
}

// GetVoucherByCode retrieves a voucher by code
func (r *BookingRepository) GetVoucherByCode(ctx context.Context, code string) (*models.Voucher, error) {
	query := `
		SELECT voucher_id, code, discount_type, discount_value, expiry_date, max_uses, current_uses
		FROM vouchers
		WHERE code = $1 AND expiry_date >= CURRENT_DATE AND current_uses < max_uses
	`

	var voucher models.Voucher
	err := r.db.Pool.QueryRow(ctx, query, code).Scan(
		&voucher.VoucherID,
		&voucher.Code,
		&voucher.DiscountType,
		&voucher.DiscountValue,
		&voucher.ExpiryDate,
		&voucher.MaxUses,
		&voucher.CurrentUses,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get voucher: %w", err)
	}

	return &voucher, nil
}

// IncrementVoucherUsage increments the usage count of a voucher
func (r *BookingRepository) IncrementVoucherUsage(ctx context.Context, voucherID int) error {
	query := `
		UPDATE vouchers
		SET current_uses = current_uses + 1
		WHERE voucher_id = $1 AND current_uses < max_uses
	`

	result, err := r.db.Pool.Exec(ctx, query, voucherID)
	if err != nil {
		return fmt.Errorf("failed to increment voucher usage: %w", err)
	}

	if result.RowsAffected() == 0 {
		return errors.New("voucher usage limit reached")
	}

	return nil
}

// GetCancellationPolicy retrieves a cancellation policy by ID
func (r *BookingRepository) GetCancellationPolicy(ctx context.Context, policyID int) (*models.CancellationPolicy, error) {
	query := `
		SELECT policy_id, name, description, days_before_check_in, refund_percentage
		FROM cancellation_policies
		WHERE policy_id = $1
	`

	var policy models.CancellationPolicy
	err := r.db.Pool.QueryRow(ctx, query, policyID).Scan(
		&policy.PolicyID,
		&policy.Name,
		&policy.Description,
		&policy.DaysBeforeCheckIn,
		&policy.RefundPercentage,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get cancellation policy: %w", err)
	}

	return &policy, nil
}

// GetRatePlan retrieves a rate plan by ID
func (r *BookingRepository) GetRatePlan(ctx context.Context, ratePlanID int) (*models.RatePlan, error) {
	query := `
		SELECT rate_plan_id, name, description, policy_id
		FROM rate_plans
		WHERE rate_plan_id = $1
	`

	var ratePlan models.RatePlan
	err := r.db.Pool.QueryRow(ctx, query, ratePlanID).Scan(
		&ratePlan.RatePlanID,
		&ratePlan.Name,
		&ratePlan.Description,
		&ratePlan.PolicyID,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get rate plan: %w", err)
	}

	return &ratePlan, nil
}

// CheckIn calls the PostgreSQL function to check in a guest
func (r *BookingRepository) CheckIn(ctx context.Context, bookingDetailID, roomID int) (*models.CheckInResponse, error) {
	query := `
		SELECT * FROM check_in($1, $2)
	`

	var success bool
	var message string

	err := r.db.Pool.QueryRow(ctx, query, bookingDetailID, roomID).Scan(&success, &message)
	if err != nil {
		return nil, fmt.Errorf("failed to check in: %w", err)
	}

	response := &models.CheckInResponse{
		Success: success,
		Message: message,
	}

	// Get room number if successful
	if success {
		roomNumber, err := r.getRoomNumber(ctx, roomID)
		if err == nil {
			response.RoomNumber = roomNumber
		}
	}

	return response, nil
}

// CheckOut calls the PostgreSQL function to check out a guest
func (r *BookingRepository) CheckOut(ctx context.Context, bookingID int) (*models.CheckOutResponse, error) {
	query := `
		SELECT * FROM check_out($1)
	`

	var success bool
	var message string

	err := r.db.Pool.QueryRow(ctx, query, bookingID).Scan(&success, &message)
	if err != nil {
		return nil, fmt.Errorf("failed to check out: %w", err)
	}

	response := &models.CheckOutResponse{
		Success: success,
		Message: message,
	}

	// Get total amount if successful
	if success {
		totalAmount, err := r.getBookingTotalAmount(ctx, bookingID)
		if err == nil {
			response.TotalAmount = totalAmount
		}
	}

	return response, nil
}

// MoveRoom calls the PostgreSQL function to move a guest to another room
func (r *BookingRepository) MoveRoom(ctx context.Context, assignmentID, newRoomID int) (*models.MoveRoomResponse, error) {
	query := `
		SELECT * FROM move_room($1, $2)
	`

	var success bool
	var message string

	err := r.db.Pool.QueryRow(ctx, query, assignmentID, newRoomID).Scan(&success, &message)
	if err != nil {
		return nil, fmt.Errorf("failed to move room: %w", err)
	}

	response := &models.MoveRoomResponse{
		Success: success,
		Message: message,
	}

	// Get new room number if successful
	if success {
		roomNumber, err := r.getRoomNumber(ctx, newRoomID)
		if err == nil {
			response.NewRoomNumber = roomNumber
		}
	}

	return response, nil
}

// MarkNoShow marks a booking as no-show
func (r *BookingRepository) MarkNoShow(ctx context.Context, bookingID int) (*models.MarkNoShowResponse, error) {
	query := `
		UPDATE bookings
		SET status = 'NoShow', updated_at = NOW()
		WHERE booking_id = $1 AND status = 'Confirmed'
		RETURNING booking_id
	`

	var returnedID int
	err := r.db.Pool.QueryRow(ctx, query, bookingID).Scan(&returnedID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return &models.MarkNoShowResponse{
				Success: false,
				Message: "Booking not found or cannot be marked as no-show",
			}, nil
		}
		return nil, fmt.Errorf("failed to mark no-show: %w", err)
	}

	return &models.MarkNoShowResponse{
		Success: true,
		Message: "Booking marked as no-show successfully",
	}, nil
}

// GetArrivals retrieves bookings arriving on a specific date
func (r *BookingRepository) GetArrivals(ctx context.Context, date time.Time) ([]models.ArrivalInfo, error) {
	query := `
		WITH primary_guest AS (
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
		)
		SELECT 
			b.booking_id,
			bd.booking_detail_id,
			-- Use guest account name if available, otherwise use booking_guests data
			COALESCE(
				CONCAT(g.first_name, ' ', g.last_name), 
				CONCAT(pg.first_name, ' ', pg.last_name), 
				'Guest'
			) as guest_name,
			rt.name as room_type_name,
			bd.room_type_id,
			bd.check_in_date,
			bd.check_out_date,
			bd.num_guests,
			b.status,
			r.room_number,
			-- Payment status logic: if booking is Confirmed or CheckedIn, payment is approved
			CASE 
				WHEN b.status IN ('Confirmed', 'CheckedIn', 'Completed') THEN 'approved'
				WHEN pp.status IS NOT NULL THEN pp.status
				ELSE 'none'
			END as payment_status,
			pp.proof_url as payment_proof_url,
			pp.payment_proof_id
		FROM bookings b
		LEFT JOIN guests g ON b.guest_id = g.guest_id
		JOIN booking_details bd ON b.booking_id = bd.booking_id
		LEFT JOIN primary_guest pg ON b.booking_id = pg.booking_id
		JOIN room_types rt ON bd.room_type_id = rt.room_type_id
		LEFT JOIN room_assignments ra ON bd.booking_detail_id = ra.booking_detail_id AND ra.status = 'Active'
		LEFT JOIN rooms r ON ra.room_id = r.room_id
		LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
		WHERE bd.check_in_date = $1
		  AND b.status IN ('Confirmed', 'CheckedIn')
		ORDER BY b.status DESC, bd.check_in_date
	`

	rows, err := r.db.Pool.Query(ctx, query, date)
	if err != nil {
		return nil, fmt.Errorf("failed to get arrivals: %w", err)
	}
	defer rows.Close()

	var arrivals []models.ArrivalInfo
	for rows.Next() {
		var arrival models.ArrivalInfo
		err := rows.Scan(
			&arrival.BookingID,
			&arrival.BookingDetailID,
			&arrival.GuestName,
			&arrival.RoomTypeName,
			&arrival.RoomTypeID,
			&arrival.CheckInDate,
			&arrival.CheckOutDate,
			&arrival.NumGuests,
			&arrival.Status,
			&arrival.RoomNumber,
			&arrival.PaymentStatus,
			&arrival.PaymentProofURL,
			&arrival.PaymentProofID,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan arrival: %w", err)
		}
		arrivals = append(arrivals, arrival)
	}

	return arrivals, nil
}

// GetDepartures retrieves bookings departing on a specific date
func (r *BookingRepository) GetDepartures(ctx context.Context, date time.Time) ([]models.DepartureInfo, error) {
	query := `
		SELECT 
			b.booking_id,
			CONCAT(g.first_name, ' ', g.last_name) as guest_name,
			r.room_number,
			bd.check_out_date,
			b.total_amount,
			b.status
		FROM bookings b
		JOIN guests g ON b.guest_id = g.guest_id
		JOIN booking_details bd ON b.booking_id = bd.booking_id
		JOIN room_assignments ra ON bd.booking_detail_id = ra.booking_detail_id AND ra.status = 'Active'
		JOIN rooms r ON ra.room_id = r.room_id
		WHERE bd.check_out_date = $1
		  AND b.status = 'CheckedIn'
		ORDER BY bd.check_out_date
	`

	rows, err := r.db.Pool.Query(ctx, query, date)
	if err != nil {
		return nil, fmt.Errorf("failed to get departures: %w", err)
	}
	defer rows.Close()

	var departures []models.DepartureInfo
	for rows.Next() {
		var departure models.DepartureInfo
		err := rows.Scan(
			&departure.BookingID,
			&departure.GuestName,
			&departure.RoomNumber,
			&departure.CheckOutDate,
			&departure.TotalAmount,
			&departure.Status,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan departure: %w", err)
		}
		departures = append(departures, departure)
	}

	return departures, nil
}

// GetAvailableRoomsForCheckIn retrieves rooms available for check-in for a specific room type
func (r *BookingRepository) GetAvailableRoomsForCheckIn(ctx context.Context, roomTypeID int) ([]models.AvailableRoomForCheckIn, error) {
	query := `
		SELECT 
			room_id,
			room_number,
			occupancy_status,
			housekeeping_status
		FROM rooms
		WHERE room_type_id = $1
		  AND occupancy_status = 'Vacant'
		  AND housekeeping_status IN ('Clean', 'Inspected')
		ORDER BY 
			CASE housekeeping_status
				WHEN 'Inspected' THEN 1
				WHEN 'Clean' THEN 2
			END,
			room_number
	`

	rows, err := r.db.Pool.Query(ctx, query, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get available rooms: %w", err)
	}
	defer rows.Close()

	var rooms []models.AvailableRoomForCheckIn
	for rows.Next() {
		var room models.AvailableRoomForCheckIn
		err := rows.Scan(
			&room.RoomID,
			&room.RoomNumber,
			&room.OccupancyStatus,
			&room.HousekeepingStatus,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan room: %w", err)
		}
		rooms = append(rooms, room)
	}

	return rooms, nil
}

// getRoomNumber retrieves the room number for a room ID
func (r *BookingRepository) getRoomNumber(ctx context.Context, roomID int) (string, error) {
	query := `SELECT room_number FROM rooms WHERE room_id = $1`
	
	var roomNumber string
	err := r.db.Pool.QueryRow(ctx, query, roomID).Scan(&roomNumber)
	if err != nil {
		return "", err
	}
	
	return roomNumber, nil
}

// getBookingTotalAmount retrieves the total amount for a booking
func (r *BookingRepository) getBookingTotalAmount(ctx context.Context, bookingID int) (float64, error) {
	query := `SELECT total_amount FROM bookings WHERE booking_id = $1`
	
	var totalAmount float64
	err := r.db.Pool.QueryRow(ctx, query, bookingID).Scan(&totalAmount)
	if err != nil {
		return 0, err
	}
	
	return totalAmount, nil
}

// GetActiveRoomAssignment retrieves the active room assignment for a booking detail
func (r *BookingRepository) GetActiveRoomAssignment(ctx context.Context, bookingDetailID int) (*models.RoomAssignment, error) {
	query := `
		SELECT room_assignment_id, booking_detail_id, room_id, check_in_datetime, check_out_datetime, status
		FROM room_assignments
		WHERE booking_detail_id = $1 AND status = 'Active'
		LIMIT 1
	`

	var assignment models.RoomAssignment
	err := r.db.Pool.QueryRow(ctx, query, bookingDetailID).Scan(
		&assignment.RoomAssignmentID,
		&assignment.BookingDetailID,
		&assignment.RoomID,
		&assignment.CheckInDateTime,
		&assignment.CheckOutDateTime,
		&assignment.Status,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get room assignment: %w", err)
	}

	return &assignment, nil
}

// GetBookingsByPhone retrieves all bookings for a phone number
func (r *BookingRepository) GetBookingsByPhone(ctx context.Context, phone string) ([]models.BookingWithDetails, error) {
	// Get bookings where primary guest has this phone number
	query := `
		SELECT DISTINCT b.booking_id, b.guest_id, b.voucher_id, b.total_amount, b.status,
		       b.created_at, b.updated_at, b.policy_name, b.policy_description
		FROM bookings b
		JOIN booking_details bd ON b.booking_id = bd.booking_id
		JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
		WHERE bg.phone = $1 AND bg.is_primary = true
		ORDER BY b.created_at DESC
	`

	rows, err := r.db.Pool.Query(ctx, query, phone)
	if err != nil {
		return nil, fmt.Errorf("failed to get bookings by phone: %w", err)
	}
	defer rows.Close()

	var bookings []models.BookingWithDetails
	for rows.Next() {
		var booking models.Booking
		err := rows.Scan(
			&booking.BookingID,
			&booking.GuestID,
			&booking.VoucherID,
			&booking.TotalAmount,
			&booking.Status,
			&booking.CreatedAt,
			&booking.UpdatedAt,
			&booking.PolicyName,
			&booking.PolicyDescription,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan booking: %w", err)
		}

		// Get details for each booking
		details, err := r.getBookingDetails(ctx, booking.BookingID)
		if err != nil {
			return nil, err
		}

		bookings = append(bookings, models.BookingWithDetails{
			Booking: booking,
			Details: details,
		})
	}

	return bookings, nil
}


// GetGuestByID retrieves a guest by ID
func (r *BookingRepository) GetGuestByID(ctx context.Context, guestID int) (*models.Guest, error) {
	query := `
		SELECT guest_id, first_name, last_name, email, phone, created_at, updated_at
		FROM guests
		WHERE guest_id = $1
	`

	var guest models.Guest
	err := r.db.Pool.QueryRow(ctx, query, guestID).Scan(
		&guest.GuestID,
		&guest.FirstName,
		&guest.LastName,
		&guest.Email,
		&guest.Phone,
		&guest.CreatedAt,
		&guest.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get guest: %w", err)
	}

	return &guest, nil
}
