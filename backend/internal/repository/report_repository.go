package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"

	"github.com/jackc/pgx/v5/pgxpool"
)

type ReportRepository struct {
	db *pgxpool.Pool
}

func NewReportRepository(db *pgxpool.Pool) *ReportRepository {
	return &ReportRepository{db: db}
}

// GetOccupancyReport retrieves occupancy statistics for a date range
func (r *ReportRepository) GetOccupancyReport(ctx context.Context, startDate, endDate time.Time, roomTypeID *int) ([]models.OccupancyReport, error) {
	query := `
		SELECT 
			ri.date,
			rt.room_type_id,
			rt.name as room_type_name,
			ri.allotment as total_rooms,
			ri.booked_count as booked_rooms,
			CASE 
				WHEN ri.allotment > 0 THEN (ri.booked_count::DECIMAL / ri.allotment::DECIMAL) * 100
				ELSE 0
			END as occupancy_rate,
			(ri.allotment - ri.booked_count - ri.tentative_count) as available_rooms
		FROM room_inventory ri
		JOIN room_types rt ON ri.room_type_id = rt.room_type_id
		WHERE ri.date >= $1 AND ri.date <= $2
	`

	args := []interface{}{startDate, endDate}
	
	if roomTypeID != nil {
		query += " AND ri.room_type_id = $3"
		args = append(args, *roomTypeID)
	}

	query += " ORDER BY ri.date, rt.name"

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query occupancy report: %w", err)
	}
	defer rows.Close()

	var reports []models.OccupancyReport
	for rows.Next() {
		var report models.OccupancyReport
		err := rows.Scan(
			&report.Date,
			&report.RoomTypeID,
			&report.RoomTypeName,
			&report.TotalRooms,
			&report.BookedRooms,
			&report.OccupancyRate,
			&report.AvailableRooms,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan occupancy report: %w", err)
		}
		reports = append(reports, report)
	}

	return reports, nil
}

// GetRevenueReport retrieves revenue statistics for a date range
func (r *ReportRepository) GetRevenueReport(ctx context.Context, startDate, endDate time.Time, roomTypeID, ratePlanID *int) ([]models.RevenueReport, error) {
	query := `
		SELECT 
			bnl.date,
			rt.room_type_id,
			rt.name as room_type_name,
			rp.rate_plan_id,
			rp.name as rate_plan_name,
			SUM(bnl.quoted_price) as total_revenue,
			COUNT(DISTINCT bd.booking_id) as booking_count,
			COUNT(bnl.booking_nightly_log_id) as room_nights,
			CASE 
				WHEN COUNT(bnl.booking_nightly_log_id) > 0 
				THEN SUM(bnl.quoted_price) / COUNT(bnl.booking_nightly_log_id)
				ELSE 0
			END as adr
		FROM booking_nightly_log bnl
		JOIN booking_details bd ON bnl.booking_detail_id = bd.booking_detail_id
		JOIN bookings b ON bd.booking_id = b.booking_id
		JOIN room_types rt ON bd.room_type_id = rt.room_type_id
		JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
		WHERE bnl.date >= $1 AND bnl.date <= $2
		  AND b.status IN ('Confirmed', 'CheckedIn', 'Completed')
	`

	args := []interface{}{startDate, endDate}
	argCount := 2

	if roomTypeID != nil {
		argCount++
		query += fmt.Sprintf(" AND bd.room_type_id = $%d", argCount)
		args = append(args, *roomTypeID)
	}

	if ratePlanID != nil {
		argCount++
		query += fmt.Sprintf(" AND bd.rate_plan_id = $%d", argCount)
		args = append(args, *ratePlanID)
	}

	query += " GROUP BY bnl.date, rt.room_type_id, rt.name, rp.rate_plan_id, rp.name ORDER BY bnl.date, rt.name"

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query revenue report: %w", err)
	}
	defer rows.Close()

	var reports []models.RevenueReport
	for rows.Next() {
		var report models.RevenueReport
		err := rows.Scan(
			&report.Date,
			&report.RoomTypeID,
			&report.RoomTypeName,
			&report.RatePlanID,
			&report.RatePlanName,
			&report.TotalRevenue,
			&report.BookingCount,
			&report.RoomNights,
			&report.ADR,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan revenue report: %w", err)
		}
		reports = append(reports, report)
	}

	return reports, nil
}

// GetVoucherReport retrieves voucher usage statistics
func (r *ReportRepository) GetVoucherReport(ctx context.Context, startDate, endDate time.Time) ([]models.VoucherReport, error) {
	query := `
		SELECT 
			v.voucher_id,
			v.code,
			v.discount_type,
			v.discount_value,
			COUNT(b.booking_id) as total_uses,
			SUM(
				CASE 
					WHEN v.discount_type = 'Percentage' THEN b.total_amount * (v.discount_value / 100)
					WHEN v.discount_type = 'FixedAmount' THEN v.discount_value
					ELSE 0
				END
			) as total_discount,
			SUM(b.total_amount) as total_revenue,
			CASE 
				WHEN v.max_uses > 0 THEN (COUNT(b.booking_id)::DECIMAL / v.max_uses::DECIMAL) * 100
				ELSE 0
			END as conversion_rate,
			v.expiry_date
		FROM vouchers v
		LEFT JOIN bookings b ON v.voucher_id = b.voucher_id
			AND b.created_at >= $1 AND b.created_at <= $2
			AND b.status IN ('Confirmed', 'CheckedIn', 'Completed')
		GROUP BY v.voucher_id, v.code, v.discount_type, v.discount_value, v.max_uses, v.expiry_date
		ORDER BY total_uses DESC
	`

	rows, err := r.db.Query(ctx, query, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query voucher report: %w", err)
	}
	defer rows.Close()

	var reports []models.VoucherReport
	for rows.Next() {
		var report models.VoucherReport
		var totalRevenue *float64
		var totalDiscount *float64
		
		err := rows.Scan(
			&report.VoucherID,
			&report.Code,
			&report.DiscountType,
			&report.DiscountValue,
			&report.TotalUses,
			&totalDiscount,
			&totalRevenue,
			&report.ConversionRate,
			&report.ExpiryDate,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan voucher report: %w", err)
		}
		
		if totalRevenue != nil {
			report.TotalRevenue = *totalRevenue
		}
		if totalDiscount != nil {
			report.TotalDiscount = *totalDiscount
		}
		
		reports = append(reports, report)
	}

	return reports, nil
}

// GetNoShowReport retrieves no-show statistics
func (r *ReportRepository) GetNoShowReport(ctx context.Context, startDate, endDate time.Time) ([]models.NoShowReport, error) {
	query := `
		SELECT 
			b.updated_at as date,
			b.booking_id,
			g.first_name || ' ' || g.last_name as guest_name,
			g.email as guest_email,
			g.phone as guest_phone,
			rt.name as room_type_name,
			bd.check_in_date,
			bd.check_out_date,
			b.total_amount,
			CASE 
				WHEN b.policy_name LIKE '%Non-Refundable%' THEN b.total_amount
				ELSE b.total_amount * 0.5
			END as penalty_charged
		FROM bookings b
		JOIN guests g ON b.guest_id = g.guest_id
		JOIN booking_details bd ON b.booking_id = bd.booking_id
		JOIN room_types rt ON bd.room_type_id = rt.room_type_id
		WHERE b.status = 'NoShow'
		  AND b.updated_at >= $1 AND b.updated_at <= $2
		ORDER BY b.updated_at DESC
	`

	rows, err := r.db.Query(ctx, query, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query no-show report: %w", err)
	}
	defer rows.Close()

	var reports []models.NoShowReport
	for rows.Next() {
		var report models.NoShowReport
		err := rows.Scan(
			&report.Date,
			&report.BookingID,
			&report.GuestName,
			&report.GuestEmail,
			&report.GuestPhone,
			&report.RoomTypeName,
			&report.CheckInDate,
			&report.CheckOutDate,
			&report.TotalAmount,
			&report.PenaltyCharged,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan no-show report: %w", err)
		}
		reports = append(reports, report)
	}

	return reports, nil
}

// GetReportSummary retrieves aggregated statistics for a date range
func (r *ReportRepository) GetReportSummary(ctx context.Context, startDate, endDate time.Time) (*models.ReportSummary, error) {
	query := `
		WITH revenue_data AS (
			SELECT 
				SUM(bnl.quoted_price) as total_revenue,
				COUNT(DISTINCT bd.booking_id) as total_bookings,
				COUNT(bnl.booking_nightly_log_id) as total_room_nights
			FROM booking_nightly_log bnl
			JOIN booking_details bd ON bnl.booking_detail_id = bd.booking_detail_id
			JOIN bookings b ON bd.booking_id = b.booking_id
			WHERE bnl.date >= $1 AND bnl.date <= $2
			  AND b.status IN ('Confirmed', 'CheckedIn', 'Completed')
		),
		occupancy_data AS (
			SELECT 
				AVG(
					CASE 
						WHEN allotment > 0 THEN (booked_count::DECIMAL / allotment::DECIMAL) * 100
						ELSE 0
					END
				) as avg_occupancy
			FROM room_inventory
			WHERE date >= $1 AND date <= $2
		),
		noshow_data AS (
			SELECT COUNT(*) as no_show_count
			FROM bookings
			WHERE status = 'NoShow'
			  AND updated_at >= $1 AND updated_at <= $2
		)
		SELECT 
			COALESCE(rd.total_revenue, 0) as total_revenue,
			COALESCE(rd.total_bookings, 0) as total_bookings,
			COALESCE(rd.total_room_nights, 0) as total_room_nights,
			COALESCE(od.avg_occupancy, 0) as avg_occupancy,
			CASE 
				WHEN COALESCE(rd.total_room_nights, 0) > 0 
				THEN COALESCE(rd.total_revenue, 0) / rd.total_room_nights
				ELSE 0
			END as adr,
			COALESCE(nd.no_show_count, 0) as no_show_count,
			CASE 
				WHEN COALESCE(rd.total_bookings, 0) > 0 
				THEN (COALESCE(nd.no_show_count, 0)::DECIMAL / rd.total_bookings::DECIMAL) * 100
				ELSE 0
			END as no_show_rate
		FROM revenue_data rd
		CROSS JOIN occupancy_data od
		CROSS JOIN noshow_data nd
	`

	var summary models.ReportSummary
	summary.StartDate = startDate
	summary.EndDate = endDate

	err := r.db.QueryRow(ctx, query, startDate, endDate).Scan(
		&summary.TotalRevenue,
		&summary.TotalBookings,
		&summary.TotalRoomNights,
		&summary.AvgOccupancy,
		&summary.ADR,
		&summary.NoShowCount,
		&summary.NoShowRate,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to query report summary: %w", err)
	}

	return &summary, nil
}
