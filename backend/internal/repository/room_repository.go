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

// RoomRepository handles room database operations
type RoomRepository struct {
	db *database.DB
}

// NewRoomRepository creates a new room repository
func NewRoomRepository(db *database.DB) *RoomRepository {
	return &RoomRepository{db: db}
}

// SearchAvailableRooms searches for available rooms based on criteria
func (r *RoomRepository) SearchAvailableRooms(ctx context.Context, checkIn, checkOut time.Time, guests int) ([]models.RoomType, error) {
	// First, ensure inventory exists for the date range
	if err := r.ensureInventoryExists(ctx, checkIn, checkOut); err != nil {
		return nil, fmt.Errorf("failed to ensure inventory exists: %w", err)
	}

	query := `
		WITH date_range AS (
			SELECT generate_series($1::date, $2::date - interval '1 day', interval '1 day')::date AS date
		),
		daily_availability AS (
			SELECT 
				rt.room_type_id,
				dr.date,
				COALESCE(ri.allotment, rt.default_allotment) as total_allotment,
				COALESCE(ri.booked_count, 0) as booked,
				COALESCE(ri.tentative_count, 0) as tentative,
				COALESCE(ri.allotment, rt.default_allotment) - 
					COALESCE(ri.booked_count, 0) - 
					COALESCE(ri.tentative_count, 0) as available
			FROM room_types rt
			CROSS JOIN date_range dr
			LEFT JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id AND ri.date = dr.date
			WHERE rt.max_occupancy >= $3
		),
		available_room_types AS (
			SELECT 
				room_type_id,
				MIN(available) as min_available,
				COUNT(*) as total_days
			FROM daily_availability
			GROUP BY room_type_id
			HAVING MIN(available) > 0
			   AND COUNT(*) = ($2::date - $1::date)
		)
		SELECT 
			rt.room_type_id,
			rt.name,
			rt.description,
			rt.max_occupancy,
			rt.default_allotment,
			art.min_available as available_rooms
		FROM room_types rt
		INNER JOIN available_room_types art ON rt.room_type_id = art.room_type_id
		ORDER BY rt.name
	`

	rows, err := r.db.Pool.Query(ctx, query, checkIn, checkOut, guests)
	if err != nil {
		return nil, fmt.Errorf("database query failed (checkIn=%s, checkOut=%s, guests=%d): %w", 
			checkIn.Format("2006-01-02"), checkOut.Format("2006-01-02"), guests, err)
	}
	defer rows.Close()

	var roomTypes []models.RoomType
	for rows.Next() {
		var rt models.RoomType
		var availableRooms int
		if err := rows.Scan(
			&rt.RoomTypeID,
			&rt.Name,
			&rt.Description,
			&rt.MaxOccupancy,
			&rt.DefaultAllotment,
			&availableRooms,
		); err != nil {
			return nil, fmt.Errorf("failed to scan room type row: %w", err)
		}
		rt.AvailableRooms = &availableRooms
		roomTypes = append(roomTypes, rt)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating result rows: %w", err)
	}

	return roomTypes, nil
}

// ensureInventoryExists creates inventory records if they don't exist
func (r *RoomRepository) ensureInventoryExists(ctx context.Context, checkIn, checkOut time.Time) error {
	query := `
		INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
		SELECT 
			rt.room_type_id,
			d::date,
			rt.default_allotment,
			0,
			0
		FROM room_types rt
		CROSS JOIN generate_series($1::timestamp, $2::timestamp - interval '1 day', interval '1 day') AS d
		ON CONFLICT (room_type_id, date) DO NOTHING
	`

	_, err := r.db.Pool.Exec(ctx, query, checkIn, checkOut)
	if err != nil {
		return fmt.Errorf("failed to create inventory: %w", err)
	}

	return nil
}

// GetRoomTypeAmenities retrieves amenities for a room type
func (r *RoomRepository) GetRoomTypeAmenities(ctx context.Context, roomTypeID int) ([]models.Amenity, error) {
	query := `
		SELECT a.amenity_id, a.name
		FROM amenities a
		INNER JOIN room_type_amenities rta ON a.amenity_id = rta.amenity_id
		WHERE rta.room_type_id = $1
		ORDER BY a.name
	`

	rows, err := r.db.Pool.Query(ctx, query, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get amenities: %w", err)
	}
	defer rows.Close()

	var amenities []models.Amenity
	for rows.Next() {
		var amenity models.Amenity
		if err := rows.Scan(&amenity.AmenityID, &amenity.Name); err != nil {
			return nil, fmt.Errorf("failed to scan amenity: %w", err)
		}
		amenities = append(amenities, amenity)
	}

	return amenities, nil
}

// GetNightlyPrices calculates prices for each night in the date range
func (r *RoomRepository) GetNightlyPrices(ctx context.Context, roomTypeID int, ratePlanID int, checkIn, checkOut time.Time) ([]models.NightlyPrice, error) {
	query := `
		WITH date_range AS (
			SELECT generate_series($1::date, $2::date - interval '1 day', interval '1 day')::date AS date
		)
		SELECT 
			dr.date,
			COALESCE(rp.price, 0) as price
		FROM date_range dr
		LEFT JOIN pricing_calendar pc ON dr.date = pc.date
		LEFT JOIN rate_pricing rp ON rp.room_type_id = $3 
			AND rp.rate_plan_id = $4
			AND rp.rate_tier_id = pc.rate_tier_id
		ORDER BY dr.date
	`

	rows, err := r.db.Pool.Query(ctx, query, checkIn, checkOut, roomTypeID, ratePlanID)
	if err != nil {
		return nil, fmt.Errorf("failed to get nightly prices: %w", err)
	}
	defer rows.Close()

	var prices []models.NightlyPrice
	for rows.Next() {
		var date time.Time
		var price float64
		if err := rows.Scan(&date, &price); err != nil {
			return nil, fmt.Errorf("failed to scan price: %w", err)
		}
		prices = append(prices, models.NightlyPrice{
			Date:  date.Format("2006-01-02"),
			Price: price,
		})
	}

	return prices, nil
}

// GetAllRoomTypes retrieves all room types
func (r *RoomRepository) GetAllRoomTypes(ctx context.Context) ([]models.RoomType, error) {
	query := `
		SELECT 
			room_type_id,
			name,
			description,
			max_occupancy,
			default_allotment
		FROM room_types
		ORDER BY name
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get room types: %w", err)
	}
	defer rows.Close()

	var roomTypes []models.RoomType
	for rows.Next() {
		var rt models.RoomType
		if err := rows.Scan(
			&rt.RoomTypeID,
			&rt.Name,
			&rt.Description,
			&rt.MaxOccupancy,
			&rt.DefaultAllotment,
		); err != nil {
			return nil, fmt.Errorf("failed to scan room type: %w", err)
		}
		roomTypes = append(roomTypes, rt)
	}

	return roomTypes, nil
}

// GetRoomTypeByID retrieves a specific room type by ID
func (r *RoomRepository) GetRoomTypeByID(ctx context.Context, roomTypeID int) (*models.RoomType, error) {
	query := `
		SELECT 
			room_type_id,
			name,
			description,
			max_occupancy,
			default_allotment
		FROM room_types
		WHERE room_type_id = $1
	`

	var rt models.RoomType
	err := r.db.Pool.QueryRow(ctx, query, roomTypeID).Scan(
		&rt.RoomTypeID,
		&rt.Name,
		&rt.Description,
		&rt.MaxOccupancy,
		&rt.DefaultAllotment,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get room type: %w", err)
	}

	return &rt, nil
}

// GetRoomsByRoomType retrieves all rooms for a specific room type
func (r *RoomRepository) GetRoomsByRoomType(ctx context.Context, roomTypeID int) ([]models.Room, error) {
	query := `
		SELECT 
			room_id,
			room_type_id,
			room_number,
			occupancy_status,
			housekeeping_status
		FROM rooms
		WHERE room_type_id = $1
		ORDER BY room_number
	`

	rows, err := r.db.Pool.Query(ctx, query, roomTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get rooms: %w", err)
	}
	defer rows.Close()

	var rooms []models.Room
	for rows.Next() {
		var room models.Room
		if err := rows.Scan(
			&room.RoomID,
			&room.RoomTypeID,
			&room.RoomNumber,
			&room.OccupancyStatus,
			&room.HousekeepingStatus,
		); err != nil {
			return nil, fmt.Errorf("failed to scan room: %w", err)
		}
		rooms = append(rooms, room)
	}

	return rooms, nil
}

// GetDefaultRatePlanID retrieves the default rate plan ID
func (r *RoomRepository) GetDefaultRatePlanID(ctx context.Context) (int, error) {
	query := `SELECT rate_plan_id FROM rate_plans ORDER BY rate_plan_id LIMIT 1`
	
	var ratePlanID int
	err := r.db.Pool.QueryRow(ctx, query).Scan(&ratePlanID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, errors.New("no rate plans found")
		}
		return 0, fmt.Errorf("failed to get default rate plan: %w", err)
	}
	
	return ratePlanID, nil
}

// PricingDetail represents pricing for a specific date
type PricingDetail struct {
	Date  time.Time
	Price float64
}

// GetPricingForDateRange retrieves pricing for each date in the range
func (r *RoomRepository) GetPricingForDateRange(ctx context.Context, roomTypeID int, ratePlanID int, checkIn, checkOut time.Time) ([]PricingDetail, error) {
	query := `
		WITH date_range AS (
			SELECT generate_series($1::date, $2::date - interval '1 day', interval '1 day')::date AS date
		)
		SELECT 
			dr.date,
			COALESCE(rp.price, 0) as price
		FROM date_range dr
		LEFT JOIN pricing_calendar pc ON dr.date = pc.date
		LEFT JOIN rate_pricing rp ON rp.room_type_id = $3 
			AND rp.rate_plan_id = $4
			AND rp.rate_tier_id = pc.rate_tier_id
		ORDER BY dr.date
	`

	rows, err := r.db.Pool.Query(ctx, query, checkIn, checkOut, roomTypeID, ratePlanID)
	if err != nil {
		return nil, fmt.Errorf("failed to get pricing: %w", err)
	}
	defer rows.Close()

	var pricing []PricingDetail
	for rows.Next() {
		var detail PricingDetail
		if err := rows.Scan(&detail.Date, &detail.Price); err != nil {
			return nil, fmt.Errorf("failed to scan pricing: %w", err)
		}
		pricing = append(pricing, detail)
	}

	return pricing, nil
}

// GetAllRoomsWithStatus retrieves all rooms with their current status and guest information
func (r *RoomRepository) GetAllRoomsWithStatus(ctx context.Context) ([]models.RoomStatus, error) {
	query := `
		SELECT 
			r.room_id,
			r.room_number,
			r.occupancy_status,
			r.housekeeping_status,
			rt.room_type_id,
			rt.name as room_type_name,
			COALESCE(g.first_name || ' ' || g.last_name, '') as guest_name,
			bd.check_out_date as expected_checkout
		FROM rooms r
		INNER JOIN room_types rt ON r.room_type_id = rt.room_type_id
		LEFT JOIN room_assignments ra ON r.room_id = ra.room_id AND ra.status = 'Active'
		LEFT JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
		LEFT JOIN bookings b ON bd.booking_id = b.booking_id
		LEFT JOIN guests g ON b.guest_id = g.guest_id
		ORDER BY r.room_number
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get room statuses: %w", err)
	}
	defer rows.Close()

	var roomStatuses []models.RoomStatus
	for rows.Next() {
		var rs models.RoomStatus
		var guestName *string
		var expectedCheckout *time.Time

		if err := rows.Scan(
			&rs.RoomID,
			&rs.RoomNumber,
			&rs.OccupancyStatus,
			&rs.HousekeepingStatus,
			&rs.RoomTypeID,
			&rs.RoomTypeName,
			&guestName,
			&expectedCheckout,
		); err != nil {
			return nil, fmt.Errorf("failed to scan room status: %w", err)
		}

		if guestName != nil {
			rs.GuestName = *guestName
		}
		if expectedCheckout != nil {
			checkoutStr := expectedCheckout.Format("2006-01-02")
			rs.ExpectedCheckout = &checkoutStr
		}

		roomStatuses = append(roomStatuses, rs)
	}

	return roomStatuses, nil
}
