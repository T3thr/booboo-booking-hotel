package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
)

// BookingService handles booking business logic
type BookingService struct {
	bookingRepo *repository.BookingRepository
	roomRepo    *repository.RoomRepository
}

// NewBookingService creates a new booking service
func NewBookingService(bookingRepo *repository.BookingRepository, roomRepo *repository.RoomRepository) *BookingService {
	return &BookingService{
		bookingRepo: bookingRepo,
		roomRepo:    roomRepo,
	}
}

// CreateBookingHold creates a temporary hold on inventory
func (s *BookingService) CreateBookingHold(ctx context.Context, req *models.CreateBookingHoldRequest) (*models.CreateBookingHoldResponse, error) {
	// Validate dates
	checkIn, err := time.Parse("2006-01-02", req.CheckIn)
	if err != nil {
		return nil, errors.New("invalid check-in date format")
	}

	checkOut, err := time.Parse("2006-01-02", req.CheckOut)
	if err != nil {
		return nil, errors.New("invalid check-out date format")
	}

	if !checkOut.After(checkIn) {
		return nil, errors.New("check-out date must be after check-in date")
	}

	if checkIn.Before(time.Now().Truncate(24 * time.Hour)) {
		return nil, errors.New("check-in date cannot be in the past")
	}

	// Call repository to create hold
	return s.bookingRepo.CreateBookingHold(ctx, req)
}

// CreateBooking creates a new booking with all details
func (s *BookingService) CreateBooking(ctx context.Context, guestID int, req *models.CreateBookingRequest) (*models.CreateBookingResponse, error) {
	// Validate request
	if len(req.Details) == 0 {
		return nil, errors.New("at least one booking detail is required")
	}

	// Get voucher if provided
	var voucherID *int
	var discountAmount float64

	if req.VoucherCode != nil && *req.VoucherCode != "" {
		voucher, err := s.bookingRepo.GetVoucherByCode(ctx, *req.VoucherCode)
		if err != nil {
			return nil, fmt.Errorf("failed to get voucher: %w", err)
		}
		if voucher == nil {
			return nil, errors.New("invalid or expired voucher code")
		}
		voucherID = &voucher.VoucherID
	}

	// Calculate total amount and get policy
	var totalAmount float64
	var policyName, policyDescription string

	for i, detail := range req.Details {
		// Validate dates
		checkIn, err := time.Parse("2006-01-02", detail.CheckIn)
		if err != nil {
			return nil, fmt.Errorf("invalid check-in date for detail %d", i+1)
		}

		checkOut, err := time.Parse("2006-01-02", detail.CheckOut)
		if err != nil {
			return nil, fmt.Errorf("invalid check-out date for detail %d", i+1)
		}

		if !checkOut.After(checkIn) {
			return nil, fmt.Errorf("check-out must be after check-in for detail %d", i+1)
		}

		// Get rate plan and policy (use first detail's policy for the booking)
		if i == 0 {
			ratePlan, err := s.bookingRepo.GetRatePlan(ctx, detail.RatePlanID)
			if err != nil {
				return nil, fmt.Errorf("failed to get rate plan: %w", err)
			}
			if ratePlan == nil {
				return nil, errors.New("invalid rate plan")
			}

			policy, err := s.bookingRepo.GetCancellationPolicy(ctx, ratePlan.PolicyID)
			if err != nil {
				return nil, fmt.Errorf("failed to get cancellation policy: %w", err)
			}
			if policy == nil {
				return nil, errors.New("cancellation policy not found")
			}

			policyName = policy.Name
			policyDescription = policy.Description
		}

		// Calculate price for this detail
		pricing, err := s.roomRepo.GetPricingForDateRange(ctx, detail.RoomTypeID, detail.RatePlanID, checkIn, checkOut)
		if err != nil {
			return nil, fmt.Errorf("failed to get pricing for detail %d: %w", i+1, err)
		}

		var detailTotal float64
		for _, price := range pricing {
			detailTotal += price.Price
		}
		totalAmount += detailTotal
	}

	// Apply voucher discount
	if voucherID != nil {
		voucher, _ := s.bookingRepo.GetVoucherByCode(ctx, *req.VoucherCode)
		if voucher.DiscountType == "Percentage" {
			discountAmount = totalAmount * (voucher.DiscountValue / 100)
		} else {
			discountAmount = voucher.DiscountValue
		}
		totalAmount -= discountAmount
		if totalAmount < 0 {
			totalAmount = 0
		}
	}

	// Create booking
	booking, err := s.bookingRepo.CreateBooking(ctx, guestID, voucherID, totalAmount, policyName, policyDescription)
	if err != nil {
		return nil, fmt.Errorf("failed to create booking: %w", err)
	}

	// Create booking details
	for _, detail := range req.Details {
		checkIn, _ := time.Parse("2006-01-02", detail.CheckIn)
		checkOut, _ := time.Parse("2006-01-02", detail.CheckOut)

		bookingDetail := &models.BookingDetail{
			BookingID:    booking.BookingID,
			RoomTypeID:   detail.RoomTypeID,
			RatePlanID:   detail.RatePlanID,
			CheckInDate:  checkIn,
			CheckOutDate: checkOut,
			NumGuests:    detail.NumGuests,
		}

		err = s.bookingRepo.CreateBookingDetail(ctx, bookingDetail)
		if err != nil {
			return nil, fmt.Errorf("failed to create booking detail: %w", err)
		}

		// Create guests
		for _, guest := range detail.Guests {
			bookingGuest := &models.BookingGuest{
				BookingDetailID: bookingDetail.BookingDetailID,
				FirstName:       guest.FirstName,
				LastName:        guest.LastName,
				Phone:           guest.Phone,
				Type:            guest.Type,
				IsPrimary:       guest.IsPrimary,
			}

			err = s.bookingRepo.CreateBookingGuest(ctx, bookingGuest)
			if err != nil {
				return nil, fmt.Errorf("failed to create booking guest: %w", err)
			}
		}

		// NOTE: Nightly logs will be created by confirm_booking() function
		// when the booking is confirmed, not here during creation
	}

	// Increment voucher usage if used
	if voucherID != nil {
		err = s.bookingRepo.IncrementVoucherUsage(ctx, *voucherID)
		if err != nil {
			// Log error but don't fail the booking
			fmt.Printf("Warning: failed to increment voucher usage: %v\n", err)
		}
	}

	return &models.CreateBookingResponse{
		BookingID:   booking.BookingID,
		TotalAmount: totalAmount,
		Status:      booking.Status,
		Message:     "Booking created successfully",
	}, nil
}

// ConfirmBooking confirms a pending booking
func (s *BookingService) ConfirmBooking(ctx context.Context, bookingID int) (*models.ConfirmBookingResponse, error) {
	// Verify booking exists and is in correct status
	booking, err := s.bookingRepo.GetBookingByID(ctx, bookingID)
	if err != nil {
		return nil, fmt.Errorf("failed to get booking: %w", err)
	}
	if booking == nil {
		return &models.ConfirmBookingResponse{
			Success: false,
			Message: "Booking not found",
		}, nil
	}

	if booking.Status != "PendingPayment" {
		return &models.ConfirmBookingResponse{
			Success: false,
			Message: fmt.Sprintf("Cannot confirm booking with status: %s", booking.Status),
		}, nil
	}

	// Call repository to confirm booking
	return s.bookingRepo.ConfirmBooking(ctx, bookingID)
}

// CancelBooking cancels a booking
func (s *BookingService) CancelBooking(ctx context.Context, bookingID int, guestID int) (*models.CancelBookingResponse, error) {
	// Verify booking exists and belongs to guest
	booking, err := s.bookingRepo.GetBookingByID(ctx, bookingID)
	if err != nil {
		return nil, fmt.Errorf("failed to get booking: %w", err)
	}
	if booking == nil {
		return &models.CancelBookingResponse{
			Success: false,
			Message: "Booking not found",
		}, nil
	}

	if booking.GuestID != guestID {
		return &models.CancelBookingResponse{
			Success: false,
			Message: "Unauthorized to cancel this booking",
		}, nil
	}

	// Check if booking can be cancelled
	if booking.Status == "Completed" || booking.Status == "Cancelled" {
		return &models.CancelBookingResponse{
			Success: false,
			Message: fmt.Sprintf("Cannot cancel booking with status: %s", booking.Status),
		}, nil
	}

	// Call repository to cancel booking
	return s.bookingRepo.CancelBooking(ctx, bookingID)
}

// GetBookingByID retrieves a booking by ID
func (s *BookingService) GetBookingByID(ctx context.Context, bookingID int, guestID int) (*models.BookingWithDetails, error) {
	booking, err := s.bookingRepo.GetBookingByID(ctx, bookingID)
	if err != nil {
		return nil, fmt.Errorf("failed to get booking: %w", err)
	}
	if booking == nil {
		return nil, nil
	}

	// Verify booking belongs to guest
	if booking.GuestID != guestID {
		return nil, errors.New("unauthorized to view this booking")
	}

	return booking, nil
}

// GetBookingsByGuestID retrieves all bookings for a guest
func (s *BookingService) GetBookingsByGuestID(ctx context.Context, guestID int, status string, limit, offset int) (*models.GetBookingsResponse, error) {
	// Set defaults
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	if offset < 0 {
		offset = 0
	}

	bookings, total, err := s.bookingRepo.GetBookingsByGuestID(ctx, guestID, status, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get bookings: %w", err)
	}

	return &models.GetBookingsResponse{
		Bookings: bookings,
		Total:    total,
		Limit:    limit,
		Offset:   offset,
	}, nil
}

// CheckIn performs check-in for a guest
func (s *BookingService) CheckIn(ctx context.Context, bookingDetailID, roomID int) (*models.CheckInResponse, error) {
	// Validate that the booking detail exists and is in correct status
	// This is handled by the PostgreSQL function, but we can add additional validation here if needed

	return s.bookingRepo.CheckIn(ctx, bookingDetailID, roomID)
}

// CheckOut performs check-out for a guest
func (s *BookingService) CheckOut(ctx context.Context, bookingID int) (*models.CheckOutResponse, error) {
	// Validate that the booking exists and is in correct status
	booking, err := s.bookingRepo.GetBookingByID(ctx, bookingID)
	if err != nil {
		return nil, fmt.Errorf("failed to get booking: %w", err)
	}
	if booking == nil {
		return &models.CheckOutResponse{
			Success: false,
			Message: "Booking not found",
		}, nil
	}

	if booking.Status != "CheckedIn" {
		return &models.CheckOutResponse{
			Success: false,
			Message: fmt.Sprintf("Cannot check out booking with status: %s", booking.Status),
		}, nil
	}

	return s.bookingRepo.CheckOut(ctx, bookingID)
}

// MoveRoom moves a guest to another room
func (s *BookingService) MoveRoom(ctx context.Context, assignmentID, newRoomID int) (*models.MoveRoomResponse, error) {
	// The PostgreSQL function handles all validation
	return s.bookingRepo.MoveRoom(ctx, assignmentID, newRoomID)
}

// MarkNoShow marks a booking as no-show
func (s *BookingService) MarkNoShow(ctx context.Context, bookingID int) (*models.MarkNoShowResponse, error) {
	// Validate that the booking exists
	booking, err := s.bookingRepo.GetBookingByID(ctx, bookingID)
	if err != nil {
		return nil, fmt.Errorf("failed to get booking: %w", err)
	}
	if booking == nil {
		return &models.MarkNoShowResponse{
			Success: false,
			Message: "Booking not found",
		}, nil
	}

	// Only confirmed bookings can be marked as no-show
	if booking.Status != "Confirmed" {
		return &models.MarkNoShowResponse{
			Success: false,
			Message: fmt.Sprintf("Cannot mark booking with status %s as no-show", booking.Status),
		}, nil
	}

	return s.bookingRepo.MarkNoShow(ctx, bookingID)
}

// GetArrivals retrieves bookings arriving on a specific date
func (s *BookingService) GetArrivals(ctx context.Context, dateStr string) ([]models.ArrivalInfo, error) {
	// Parse date or use today
	var date time.Time
	var err error

	if dateStr == "" {
		date = time.Now().Truncate(24 * time.Hour)
	} else {
		date, err = time.Parse("2006-01-02", dateStr)
		if err != nil {
			return nil, errors.New("invalid date format, use YYYY-MM-DD")
		}
	}

	return s.bookingRepo.GetArrivals(ctx, date)
}

// GetDepartures retrieves bookings departing on a specific date
func (s *BookingService) GetDepartures(ctx context.Context, dateStr string) ([]models.DepartureInfo, error) {
	// Parse date or use today
	var date time.Time
	var err error

	if dateStr == "" {
		date = time.Now().Truncate(24 * time.Hour)
	} else {
		date, err = time.Parse("2006-01-02", dateStr)
		if err != nil {
			return nil, errors.New("invalid date format, use YYYY-MM-DD")
		}
	}

	return s.bookingRepo.GetDepartures(ctx, date)
}

// GetAvailableRoomsForCheckIn retrieves rooms available for check-in
func (s *BookingService) GetAvailableRoomsForCheckIn(ctx context.Context, roomTypeID int) ([]models.AvailableRoomForCheckIn, error) {
	return s.bookingRepo.GetAvailableRoomsForCheckIn(ctx, roomTypeID)
}

// GetBookingsByPhone retrieves bookings by phone number
func (s *BookingService) GetBookingsByPhone(ctx context.Context, phone string) ([]models.BookingWithDetails, error) {
	return s.bookingRepo.GetBookingsByPhone(ctx, phone)
}
