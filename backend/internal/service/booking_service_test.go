package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockBookingRepository is a mock implementation of BookingRepository
type MockBookingRepository struct {
	mock.Mock
}

func (m *MockBookingRepository) CreateBookingHold(ctx context.Context, req *models.CreateBookingHoldRequest) (*models.CreateBookingHoldResponse, error) {
	args := m.Called(ctx, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.CreateBookingHoldResponse), args.Error(1)
}

func (m *MockBookingRepository) GetVoucherByCode(ctx context.Context, code string) (*models.Voucher, error) {
	args := m.Called(ctx, code)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Voucher), args.Error(1)
}

func (m *MockBookingRepository) GetRatePlan(ctx context.Context, ratePlanID int) (*models.RatePlan, error) {
	args := m.Called(ctx, ratePlanID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RatePlan), args.Error(1)
}

func (m *MockBookingRepository) GetCancellationPolicy(ctx context.Context, policyID int) (*models.CancellationPolicy, error) {
	args := m.Called(ctx, policyID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.CancellationPolicy), args.Error(1)
}

func (m *MockBookingRepository) CreateBooking(ctx context.Context, guestID int, voucherID *int, totalAmount float64, policyName, policyDescription string) (*models.Booking, error) {
	args := m.Called(ctx, guestID, voucherID, totalAmount, policyName, policyDescription)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Booking), args.Error(1)
}

func (m *MockBookingRepository) CreateBookingDetail(ctx context.Context, detail *models.BookingDetail) error {
	args := m.Called(ctx, detail)
	if args.Error(0) == nil {
		detail.BookingDetailID = 1
	}
	return args.Error(0)
}

func (m *MockBookingRepository) CreateBookingGuest(ctx context.Context, guest *models.BookingGuest) error {
	args := m.Called(ctx, guest)
	return args.Error(0)
}

func (m *MockBookingRepository) CreateBookingNightlyLog(ctx context.Context, log *models.BookingNightlyLog) error {
	args := m.Called(ctx, log)
	return args.Error(0)
}

func (m *MockBookingRepository) IncrementVoucherUsage(ctx context.Context, voucherID int) error {
	args := m.Called(ctx, voucherID)
	return args.Error(0)
}

func (m *MockBookingRepository) GetBookingByID(ctx context.Context, bookingID int) (*models.BookingWithDetails, error) {
	args := m.Called(ctx, bookingID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.BookingWithDetails), args.Error(1)
}

func (m *MockBookingRepository) ConfirmBooking(ctx context.Context, bookingID int) (*models.ConfirmBookingResponse, error) {
	args := m.Called(ctx, bookingID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.ConfirmBookingResponse), args.Error(1)
}

func (m *MockBookingRepository) CancelBooking(ctx context.Context, bookingID int) (*models.CancelBookingResponse, error) {
	args := m.Called(ctx, bookingID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.CancelBookingResponse), args.Error(1)
}

func (m *MockBookingRepository) GetBookingsByGuestID(ctx context.Context, guestID int, status string, limit, offset int) ([]models.BookingWithDetails, int, error) {
	args := m.Called(ctx, guestID, status, limit, offset)
	if args.Get(0) == nil {
		return nil, args.Int(1), args.Error(2)
	}
	return args.Get(0).([]models.BookingWithDetails), args.Int(1), args.Error(2)
}

func (m *MockBookingRepository) CheckIn(ctx context.Context, bookingDetailID, roomID int) (*models.CheckInResponse, error) {
	args := m.Called(ctx, bookingDetailID, roomID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.CheckInResponse), args.Error(1)
}

func (m *MockBookingRepository) CheckOut(ctx context.Context, bookingID int) (*models.CheckOutResponse, error) {
	args := m.Called(ctx, bookingID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.CheckOutResponse), args.Error(1)
}

func (m *MockBookingRepository) MoveRoom(ctx context.Context, assignmentID, newRoomID int) (*models.MoveRoomResponse, error) {
	args := m.Called(ctx, assignmentID, newRoomID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MoveRoomResponse), args.Error(1)
}

func (m *MockBookingRepository) MarkNoShow(ctx context.Context, bookingID int) (*models.MarkNoShowResponse, error) {
	args := m.Called(ctx, bookingID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MarkNoShowResponse), args.Error(1)
}

func (m *MockBookingRepository) GetArrivals(ctx context.Context, date time.Time) ([]models.ArrivalInfo, error) {
	args := m.Called(ctx, date)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.ArrivalInfo), args.Error(1)
}

func (m *MockBookingRepository) GetDepartures(ctx context.Context, date time.Time) ([]models.DepartureInfo, error) {
	args := m.Called(ctx, date)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.DepartureInfo), args.Error(1)
}

func (m *MockBookingRepository) GetAvailableRoomsForCheckIn(ctx context.Context, roomTypeID int) ([]models.AvailableRoomForCheckIn, error) {
	args := m.Called(ctx, roomTypeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.AvailableRoomForCheckIn), args.Error(1)
}

// MockRoomRepository is a mock implementation of RoomRepository
type MockRoomRepository struct {
	mock.Mock
}

func (m *MockRoomRepository) GetPricingForDateRange(ctx context.Context, roomTypeID, ratePlanID int, checkIn, checkOut time.Time) ([]models.NightlyPrice, error) {
	args := m.Called(ctx, roomTypeID, ratePlanID, checkIn, checkOut)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.NightlyPrice), args.Error(1)
}

// TestBookingService_CreateBookingHold tests the CreateBookingHold method
func TestBookingService_CreateBookingHold(t *testing.T) {
	tomorrow := time.Now().AddDate(0, 0, 1).Format("2006-01-02")
	dayAfter := time.Now().AddDate(0, 0, 2).Format("2006-01-02")

	tests := []struct {
		name          string
		request       *models.CreateBookingHoldRequest
		setupMock     func(*MockBookingRepository)
		expectedError string
		checkResponse func(*testing.T, *models.CreateBookingHoldResponse)
	}{
		{
			name: "successful hold creation",
			request: &models.CreateBookingHoldRequest{
				SessionID:      "session123",
				GuestAccountID: 1,
				RoomTypeID:     1,
				CheckIn:        tomorrow,
				CheckOut:       dayAfter,
			},
			setupMock: func(m *MockBookingRepository) {
				m.On("CreateBookingHold", mock.Anything, mock.AnythingOfType("*models.CreateBookingHoldRequest")).
					Return(&models.CreateBookingHoldResponse{
						HoldID:  1,
						Success: true,
						Message: "Hold created successfully",
					}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.CreateBookingHoldResponse) {
				assert.NotNil(t, resp)
				assert.True(t, resp.Success)
				assert.Equal(t, int64(1), resp.HoldID)
			},
		},
		{
			name: "invalid check-in date format",
			request: &models.CreateBookingHoldRequest{
				SessionID:      "session123",
				GuestAccountID: 1,
				RoomTypeID:     1,
				CheckIn:        "invalid-date",
				CheckOut:       dayAfter,
			},
			setupMock:     func(m *MockBookingRepository) {},
			expectedError: "invalid check-in date format",
		},
		{
			name: "check-out before check-in",
			request: &models.CreateBookingHoldRequest{
				SessionID:      "session123",
				GuestAccountID: 1,
				RoomTypeID:     1,
				CheckIn:        dayAfter,
				CheckOut:       tomorrow,
			},
			setupMock:     func(m *MockBookingRepository) {},
			expectedError: "check-out date must be after check-in date",
		},
		{
			name: "check-in in the past",
			request: &models.CreateBookingHoldRequest{
				SessionID:      "session123",
				GuestAccountID: 1,
				RoomTypeID:     1,
				CheckIn:        "2020-01-01",
				CheckOut:       "2020-01-02",
			},
			setupMock:     func(m *MockBookingRepository) {},
			expectedError: "check-in date cannot be in the past",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockBookingRepo := new(MockBookingRepository)
			mockRoomRepo := new(MockRoomRepository)
			tt.setupMock(mockBookingRepo)

			service := NewBookingService(mockBookingRepo, mockRoomRepo)
			resp, err := service.CreateBookingHold(context.Background(), tt.request)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, resp)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, resp)
				}
			}

			mockBookingRepo.AssertExpectations(t)
		})
	}
}

// TestBookingService_ConfirmBooking tests the ConfirmBooking method
func TestBookingService_ConfirmBooking(t *testing.T) {
	tests := []struct {
		name          string
		bookingID     int
		setupMock     func(*MockBookingRepository)
		expectedError string
		checkResponse func(*testing.T, *models.ConfirmBookingResponse)
	}{
		{
			name:      "successful confirmation",
			bookingID: 1,
			setupMock: func(m *MockBookingRepository) {
				booking := &models.BookingWithDetails{
					Booking: models.Booking{
						BookingID: 1,
						Status:    "PendingPayment",
					},
				}
				m.On("GetBookingByID", mock.Anything, 1).Return(booking, nil)
				m.On("ConfirmBooking", mock.Anything, 1).Return(&models.ConfirmBookingResponse{
					Success: true,
					Message: "Booking confirmed successfully",
				}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.ConfirmBookingResponse) {
				assert.NotNil(t, resp)
				assert.True(t, resp.Success)
			},
		},
		{
			name:      "booking not found",
			bookingID: 999,
			setupMock: func(m *MockBookingRepository) {
				m.On("GetBookingByID", mock.Anything, 999).Return(nil, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.ConfirmBookingResponse) {
				assert.NotNil(t, resp)
				assert.False(t, resp.Success)
				assert.Contains(t, resp.Message, "not found")
			},
		},
		{
			name:      "booking already confirmed",
			bookingID: 1,
			setupMock: func(m *MockBookingRepository) {
				booking := &models.BookingWithDetails{
					Booking: models.Booking{
						BookingID: 1,
						Status:    "Confirmed",
					},
				}
				m.On("GetBookingByID", mock.Anything, 1).Return(booking, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.ConfirmBookingResponse) {
				assert.NotNil(t, resp)
				assert.False(t, resp.Success)
				assert.Contains(t, resp.Message, "Cannot confirm")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockBookingRepo := new(MockBookingRepository)
			mockRoomRepo := new(MockRoomRepository)
			tt.setupMock(mockBookingRepo)

			service := NewBookingService(mockBookingRepo, mockRoomRepo)
			resp, err := service.ConfirmBooking(context.Background(), tt.bookingID)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, resp)
				}
			}

			mockBookingRepo.AssertExpectations(t)
		})
	}
}

// TestBookingService_CancelBooking tests the CancelBooking method
func TestBookingService_CancelBooking(t *testing.T) {
	tests := []struct {
		name          string
		bookingID     int
		guestID       int
		setupMock     func(*MockBookingRepository)
		expectedError string
		checkResponse func(*testing.T, *models.CancelBookingResponse)
	}{
		{
			name:      "successful cancellation",
			bookingID: 1,
			guestID:   1,
			setupMock: func(m *MockBookingRepository) {
				booking := &models.BookingWithDetails{
					Booking: models.Booking{
						BookingID: 1,
						GuestID:   1,
						Status:    "Confirmed",
					},
				}
				m.On("GetBookingByID", mock.Anything, 1).Return(booking, nil)
				m.On("CancelBooking", mock.Anything, 1).Return(&models.CancelBookingResponse{
					Success:      true,
					Message:      "Booking cancelled successfully",
					RefundAmount: 100.0,
				}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.CancelBookingResponse) {
				assert.NotNil(t, resp)
				assert.True(t, resp.Success)
				assert.Equal(t, 100.0, resp.RefundAmount)
			},
		},
		{
			name:      "unauthorized cancellation",
			bookingID: 1,
			guestID:   2,
			setupMock: func(m *MockBookingRepository) {
				booking := &models.BookingWithDetails{
					Booking: models.Booking{
						BookingID: 1,
						GuestID:   1,
						Status:    "Confirmed",
					},
				}
				m.On("GetBookingByID", mock.Anything, 1).Return(booking, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.CancelBookingResponse) {
				assert.NotNil(t, resp)
				assert.False(t, resp.Success)
				assert.Contains(t, resp.Message, "Unauthorized")
			},
		},
		{
			name:      "cannot cancel completed booking",
			bookingID: 1,
			guestID:   1,
			setupMock: func(m *MockBookingRepository) {
				booking := &models.BookingWithDetails{
					Booking: models.Booking{
						BookingID: 1,
						GuestID:   1,
						Status:    "Completed",
					},
				}
				m.On("GetBookingByID", mock.Anything, 1).Return(booking, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.CancelBookingResponse) {
				assert.NotNil(t, resp)
				assert.False(t, resp.Success)
				assert.Contains(t, resp.Message, "Cannot cancel")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockBookingRepo := new(MockBookingRepository)
			mockRoomRepo := new(MockRoomRepository)
			tt.setupMock(mockBookingRepo)

			service := NewBookingService(mockBookingRepo, mockRoomRepo)
			resp, err := service.CancelBooking(context.Background(), tt.bookingID, tt.guestID)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, resp)
				}
			}

			mockBookingRepo.AssertExpectations(t)
		})
	}
}

// TestBookingService_GetBookingsByGuestID tests the GetBookingsByGuestID method
func TestBookingService_GetBookingsByGuestID(t *testing.T) {
	tests := []struct {
		name          string
		guestID       int
		status        string
		limit         int
		offset        int
		setupMock     func(*MockBookingRepository)
		expectedError string
		checkResponse func(*testing.T, *models.GetBookingsResponse)
	}{
		{
			name:    "successful retrieval with defaults",
			guestID: 1,
			status:  "",
			limit:   0,
			offset:  0,
			setupMock: func(m *MockBookingRepository) {
				bookings := []models.BookingWithDetails{
					{
						Booking: models.Booking{
							BookingID: 1,
							GuestID:   1,
							Status:    "Confirmed",
						},
					},
				}
				m.On("GetBookingsByGuestID", mock.Anything, 1, "", 20, 0).Return(bookings, 1, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.GetBookingsResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 1, len(resp.Bookings))
				assert.Equal(t, 1, resp.Total)
				assert.Equal(t, 20, resp.Limit)
			},
		},
		{
			name:    "with custom limit and offset",
			guestID: 1,
			status:  "Confirmed",
			limit:   10,
			offset:  5,
			setupMock: func(m *MockBookingRepository) {
				bookings := []models.BookingWithDetails{}
				m.On("GetBookingsByGuestID", mock.Anything, 1, "Confirmed", 10, 5).Return(bookings, 0, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.GetBookingsResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 0, len(resp.Bookings))
				assert.Equal(t, 10, resp.Limit)
				assert.Equal(t, 5, resp.Offset)
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockBookingRepo := new(MockBookingRepository)
			mockRoomRepo := new(MockRoomRepository)
			tt.setupMock(mockBookingRepo)

			service := NewBookingService(mockBookingRepo, mockRoomRepo)
			resp, err := service.GetBookingsByGuestID(context.Background(), tt.guestID, tt.status, tt.limit, tt.offset)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, resp)
				}
			}

			mockBookingRepo.AssertExpectations(t)
		})
	}
}