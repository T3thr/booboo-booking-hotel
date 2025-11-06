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

// MockRoomRepositoryForService is a mock implementation of RoomRepository for service tests
type MockRoomRepositoryForService struct {
	mock.Mock
}

func (m *MockRoomRepositoryForService) SearchAvailableRooms(ctx context.Context, checkIn, checkOut time.Time, guests int) ([]models.RoomType, error) {
	args := m.Called(ctx, checkIn, checkOut, guests)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.RoomType), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetDefaultRatePlanID(ctx context.Context) (int, error) {
	args := m.Called(ctx)
	return args.Int(0), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetRoomTypeAmenities(ctx context.Context, roomTypeID int) ([]models.Amenity, error) {
	args := m.Called(ctx, roomTypeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.Amenity), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetNightlyPrices(ctx context.Context, roomTypeID, ratePlanID int, checkIn, checkOut time.Time) ([]models.NightlyPrice, error) {
	args := m.Called(ctx, roomTypeID, ratePlanID, checkIn, checkOut)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.NightlyPrice), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetAllRoomTypes(ctx context.Context) ([]models.RoomType, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.RoomType), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetRoomTypeByID(ctx context.Context, roomTypeID int) (*models.RoomType, error) {
	args := m.Called(ctx, roomTypeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RoomType), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetRoomsByRoomType(ctx context.Context, roomTypeID int) ([]models.Room, error) {
	args := m.Called(ctx, roomTypeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.Room), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetAllRoomsWithStatus(ctx context.Context) ([]models.RoomWithStatus, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.RoomWithStatus), args.Error(1)
}

func (m *MockRoomRepositoryForService) GetPricingForDateRange(ctx context.Context, roomTypeID, ratePlanID int, checkIn, checkOut time.Time) ([]models.NightlyPrice, error) {
	args := m.Called(ctx, roomTypeID, ratePlanID, checkIn, checkOut)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.NightlyPrice), args.Error(1)
}

// TestRoomService_SearchAvailableRooms tests the SearchAvailableRooms method
func TestRoomService_SearchAvailableRooms(t *testing.T) {
	tomorrow := time.Now().AddDate(0, 0, 1)
	dayAfter := time.Now().AddDate(0, 0, 2)
	tomorrowStr := tomorrow.Format("2006-01-02")
	dayAfterStr := dayAfter.Format("2006-01-02")

	tests := []struct {
		name          string
		request       *models.SearchRoomsRequest
		setupMock     func(*MockRoomRepositoryForService)
		expectedError string
		checkResponse func(*testing.T, *models.SearchRoomsResponse)
	}{
		{
			name: "successful search with pricing",
			request: &models.SearchRoomsRequest{
				CheckIn:  tomorrowStr,
				CheckOut: dayAfterStr,
				Guests:   2,
			},
			setupMock: func(m *MockRoomRepositoryForService) {
				roomTypes := []models.RoomType{
					{
						RoomTypeID:   1,
						Name:         "Deluxe Room",
						MaxOccupancy: 2,
					},
				}
				m.On("SearchAvailableRooms", mock.Anything, tomorrow, dayAfter, 2).Return(roomTypes, nil)
				m.On("GetDefaultRatePlanID", mock.Anything).Return(1, nil)
				m.On("GetRoomTypeAmenities", mock.Anything, 1).Return([]models.Amenity{
					{AmenityID: 1, Name: "WiFi"},
				}, nil)
				m.On("GetNightlyPrices", mock.Anything, 1, 1, tomorrow, dayAfter).Return([]models.NightlyPrice{
					{Date: tomorrow, Price: 100.00},
				}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.SearchRoomsResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 1, len(resp.RoomTypes))
				assert.Equal(t, 1, resp.TotalNights)
				assert.NotNil(t, resp.RoomTypes[0].TotalPrice)
				assert.Equal(t, 100.00, *resp.RoomTypes[0].TotalPrice)
				assert.NotNil(t, resp.RoomTypes[0].PricePerNight)
				assert.Equal(t, 100.00, *resp.RoomTypes[0].PricePerNight)
			},
		},
		{
			name: "invalid check-in date format",
			request: &models.SearchRoomsRequest{
				CheckIn:  "invalid-date",
				CheckOut: dayAfterStr,
				Guests:   2,
			},
			setupMock:     func(m *MockRoomRepositoryForService) {},
			expectedError: "รูปแบบวันที่ check-in ไม่ถูกต้อง",
		},
		{
			name: "check-out before check-in",
			request: &models.SearchRoomsRequest{
				CheckIn:  dayAfterStr,
				CheckOut: tomorrowStr,
				Guests:   2,
			},
			setupMock:     func(m *MockRoomRepositoryForService) {},
			expectedError: "วันที่ check-out ต้องอยู่หลังวันที่ check-in",
		},
		{
			name: "check-in in the past",
			request: &models.SearchRoomsRequest{
				CheckIn:  "2020-01-01",
				CheckOut: "2020-01-02",
				Guests:   2,
			},
			setupMock:     func(m *MockRoomRepositoryForService) {},
			expectedError: "วันที่ check-in ต้องไม่อยู่ในอดีต",
		},
		{
			name: "no rooms available - returns alternatives",
			request: &models.SearchRoomsRequest{
				CheckIn:  tomorrowStr,
				CheckOut: dayAfterStr,
				Guests:   2,
			},
			setupMock: func(m *MockRoomRepositoryForService) {
				m.On("SearchAvailableRooms", mock.Anything, tomorrow, dayAfter, 2).Return([]models.RoomType{}, nil)
				m.On("GetDefaultRatePlanID", mock.Anything).Return(1, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.SearchRoomsResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 0, len(resp.RoomTypes))
				assert.NotNil(t, resp.AlternativeDates)
				assert.Greater(t, len(resp.AlternativeDates), 0)
			},
		},
		{
			name: "search without rate plan - returns rooms without pricing",
			request: &models.SearchRoomsRequest{
				CheckIn:  tomorrowStr,
				CheckOut: dayAfterStr,
				Guests:   2,
			},
			setupMock: func(m *MockRoomRepositoryForService) {
				roomTypes := []models.RoomType{
					{
						RoomTypeID:   1,
						Name:         "Deluxe Room",
						MaxOccupancy: 2,
					},
				}
				m.On("SearchAvailableRooms", mock.Anything, tomorrow, dayAfter, 2).Return(roomTypes, nil)
				m.On("GetDefaultRatePlanID", mock.Anything).Return(0, errors.New("no rate plan"))
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.SearchRoomsResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 1, len(resp.RoomTypes))
				assert.Nil(t, resp.RoomTypes[0].TotalPrice)
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockRoomRepositoryForService)
			tt.setupMock(mockRepo)

			service := NewRoomService(mockRepo)
			resp, err := service.SearchAvailableRooms(context.Background(), tt.request)

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

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestRoomService_GetRoomTypePricing tests the GetRoomTypePricing method
func TestRoomService_GetRoomTypePricing(t *testing.T) {
	tomorrow := time.Now().AddDate(0, 0, 1)
	dayAfter := time.Now().AddDate(0, 0, 3)
	tomorrowStr := tomorrow.Format("2006-01-02")
	dayAfterStr := dayAfter.Format("2006-01-02")

	tests := []struct {
		name          string
		roomTypeID    int
		checkIn       string
		checkOut      string
		setupMock     func(*MockRoomRepositoryForService)
		expectedError string
		checkResponse func(*testing.T, *models.RoomType)
	}{
		{
			name:       "successful pricing calculation",
			roomTypeID: 1,
			checkIn:    tomorrowStr,
			checkOut:   dayAfterStr,
			setupMock: func(m *MockRoomRepositoryForService) {
				roomType := &models.RoomType{
					RoomTypeID:   1,
					Name:         "Deluxe Room",
					MaxOccupancy: 2,
				}
				m.On("GetRoomTypeByID", mock.Anything, 1).Return(roomType, nil)
				m.On("GetDefaultRatePlanID", mock.Anything).Return(1, nil)
				m.On("GetNightlyPrices", mock.Anything, 1, 1, tomorrow, dayAfter).Return([]models.NightlyPrice{
					{Date: tomorrow, Price: 100.00},
					{Date: tomorrow.AddDate(0, 0, 1), Price: 120.00},
				}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, roomType *models.RoomType) {
				assert.NotNil(t, roomType)
				assert.Equal(t, "Deluxe Room", roomType.Name)
				assert.NotNil(t, roomType.TotalPrice)
				assert.Equal(t, 220.00, *roomType.TotalPrice)
				assert.NotNil(t, roomType.PricePerNight)
				assert.Equal(t, 110.00, *roomType.PricePerNight) // Average of 100 and 120
			},
		},
		{
			name:          "invalid check-in date",
			roomTypeID:    1,
			checkIn:       "invalid-date",
			checkOut:      dayAfterStr,
			setupMock:     func(m *MockRoomRepositoryForService) {},
			expectedError: "รูปแบบวันที่ check-in ไม่ถูกต้อง",
		},
		{
			name:       "room type not found",
			roomTypeID: 999,
			checkIn:    tomorrowStr,
			checkOut:   dayAfterStr,
			setupMock: func(m *MockRoomRepositoryForService) {
				m.On("GetRoomTypeByID", mock.Anything, 999).Return(nil, nil)
			},
			expectedError: "room type not found",
		},
		{
			name:       "pricing calculation with variable rates",
			roomTypeID: 1,
			checkIn:    tomorrowStr,
			checkOut:   dayAfterStr,
			setupMock: func(m *MockRoomRepositoryForService) {
				roomType := &models.RoomType{
					RoomTypeID:   1,
					Name:         "Suite",
					MaxOccupancy: 4,
				}
				m.On("GetRoomTypeByID", mock.Anything, 1).Return(roomType, nil)
				m.On("GetDefaultRatePlanID", mock.Anything).Return(1, nil)
				m.On("GetNightlyPrices", mock.Anything, 1, 1, tomorrow, dayAfter).Return([]models.NightlyPrice{
					{Date: tomorrow, Price: 150.00},
					{Date: tomorrow.AddDate(0, 0, 1), Price: 200.00},
				}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, roomType *models.RoomType) {
				assert.NotNil(t, roomType)
				assert.Equal(t, 2, len(roomType.NightlyPrices))
				assert.Equal(t, 350.00, *roomType.TotalPrice)
				assert.Equal(t, 175.00, *roomType.PricePerNight)
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockRoomRepositoryForService)
			tt.setupMock(mockRepo)

			service := NewRoomService(mockRepo)
			roomType, err := service.GetRoomTypePricing(context.Background(), tt.roomTypeID, tt.checkIn, tt.checkOut)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, roomType)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, roomType)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestRoomService_GetAllRoomTypes tests the GetAllRoomTypes method
func TestRoomService_GetAllRoomTypes(t *testing.T) {
	tests := []struct {
		name          string
		setupMock     func(*MockRoomRepositoryForService)
		expectedError string
		checkResponse func(*testing.T, []models.RoomType)
	}{
		{
			name: "successful retrieval with amenities",
			setupMock: func(m *MockRoomRepositoryForService) {
				roomTypes := []models.RoomType{
					{RoomTypeID: 1, Name: "Deluxe"},
					{RoomTypeID: 2, Name: "Suite"},
				}
				m.On("GetAllRoomTypes", mock.Anything).Return(roomTypes, nil)
				m.On("GetRoomTypeAmenities", mock.Anything, 1).Return([]models.Amenity{
					{AmenityID: 1, Name: "WiFi"},
				}, nil)
				m.On("GetRoomTypeAmenities", mock.Anything, 2).Return([]models.Amenity{
					{AmenityID: 1, Name: "WiFi"},
					{AmenityID: 2, Name: "TV"},
				}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, roomTypes []models.RoomType) {
				assert.NotNil(t, roomTypes)
				assert.Equal(t, 2, len(roomTypes))
				assert.Equal(t, 1, len(roomTypes[0].Amenities))
				assert.Equal(t, 2, len(roomTypes[1].Amenities))
			},
		},
		{
			name: "database error",
			setupMock: func(m *MockRoomRepositoryForService) {
				m.On("GetAllRoomTypes", mock.Anything).Return(nil, errors.New("database error"))
			},
			expectedError: "failed to get room types",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockRoomRepositoryForService)
			tt.setupMock(mockRepo)

			service := NewRoomService(mockRepo)
			roomTypes, err := service.GetAllRoomTypes(context.Background())

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, roomTypes)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestRoomService_GetAllRoomsWithStatus tests the GetAllRoomsWithStatus method
func TestRoomService_GetAllRoomsWithStatus(t *testing.T) {
	tests := []struct {
		name          string
		setupMock     func(*MockRoomRepositoryForService)
		expectedError string
		checkResponse func(*testing.T, *models.RoomStatusDashboardResponse)
	}{
		{
			name: "successful retrieval with summary calculation",
			setupMock: func(m *MockRoomRepositoryForService) {
				rooms := []models.RoomWithStatus{
					{RoomID: 1, OccupancyStatus: "Occupied", HousekeepingStatus: "Dirty"},
					{RoomID: 2, OccupancyStatus: "Vacant", HousekeepingStatus: "Inspected"},
					{RoomID: 3, OccupancyStatus: "Vacant", HousekeepingStatus: "Clean"},
					{RoomID: 4, OccupancyStatus: "Vacant", HousekeepingStatus: "Dirty"},
					{RoomID: 5, OccupancyStatus: "Vacant", HousekeepingStatus: "MaintenanceRequired"},
				}
				m.On("GetAllRoomsWithStatus", mock.Anything).Return(rooms, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.RoomStatusDashboardResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 5, resp.Summary.TotalRooms)
				assert.Equal(t, 1, resp.Summary.Occupied)
				assert.Equal(t, 1, resp.Summary.VacantInspected)
				assert.Equal(t, 1, resp.Summary.VacantClean)
				assert.Equal(t, 1, resp.Summary.VacantDirty)
				assert.Equal(t, 1, resp.Summary.MaintenanceRequired)
			},
		},
		{
			name: "database error",
			setupMock: func(m *MockRoomRepositoryForService) {
				m.On("GetAllRoomsWithStatus", mock.Anything).Return(nil, errors.New("database error"))
			},
			expectedError: "failed to get room statuses",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockRoomRepositoryForService)
			tt.setupMock(mockRepo)

			service := NewRoomService(mockRepo)
			resp, err := service.GetAllRoomsWithStatus(context.Background())

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, resp)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestGenerateAlternativeDates tests the alternative date generation
func TestGenerateAlternativeDates(t *testing.T) {
	service := NewRoomService(nil)
	
	// Test with a future date
	futureDate := time.Now().AddDate(0, 0, 10)
	alternatives := service.generateAlternativeDates(futureDate)
	
	// Should have 6 alternatives (3 before, 3 after)
	assert.Equal(t, 6, len(alternatives))
	
	// Test with a date close to today
	nearDate := time.Now().AddDate(0, 0, 2)
	alternatives = service.generateAlternativeDates(nearDate)
	
	// Should have fewer alternatives (only future dates)
	assert.LessOrEqual(t, len(alternatives), 6)
	assert.Greater(t, len(alternatives), 0)
}
