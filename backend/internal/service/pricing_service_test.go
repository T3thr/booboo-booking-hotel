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

// MockPricingRepository is a mock implementation of PricingRepository
type MockPricingRepository struct {
	mock.Mock
}

func (m *MockPricingRepository) GetAllRateTiers(ctx context.Context) ([]models.RateTier, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.RateTier), args.Error(1)
}

func (m *MockPricingRepository) GetRateTierByID(ctx context.Context, id int) (*models.RateTier, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RateTier), args.Error(1)
}

func (m *MockPricingRepository) CreateRateTier(ctx context.Context, req *models.CreateRateTierRequest) (*models.RateTier, error) {
	args := m.Called(ctx, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RateTier), args.Error(1)
}

func (m *MockPricingRepository) UpdateRateTier(ctx context.Context, id int, req *models.UpdateRateTierRequest) (*models.RateTier, error) {
	args := m.Called(ctx, id, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RateTier), args.Error(1)
}

func (m *MockPricingRepository) GetPricingCalendar(ctx context.Context, startDate, endDate time.Time) ([]models.PricingCalendar, error) {
	args := m.Called(ctx, startDate, endDate)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.PricingCalendar), args.Error(1)
}

func (m *MockPricingRepository) UpdatePricingCalendar(ctx context.Context, req *models.UpdatePricingCalendarRequest) error {
	args := m.Called(ctx, req)
	return args.Error(0)
}

func (m *MockPricingRepository) GetAllRatePricing(ctx context.Context) ([]models.RatePricingWithDetails, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.RatePricingWithDetails), args.Error(1)
}

func (m *MockPricingRepository) GetRatePricingByPlan(ctx context.Context, ratePlanID int) ([]models.RatePricingWithDetails, error) {
	args := m.Called(ctx, ratePlanID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.RatePricingWithDetails), args.Error(1)
}

func (m *MockPricingRepository) UpdateRatePricing(ctx context.Context, req *models.UpdateRatePricingRequest) error {
	args := m.Called(ctx, req)
	return args.Error(0)
}

func (m *MockPricingRepository) BulkUpdateRatePricing(ctx context.Context, req *models.BulkUpdateRatePricingRequest) error {
	args := m.Called(ctx, req)
	return args.Error(0)
}

func (m *MockPricingRepository) GetAllRatePlans(ctx context.Context) ([]models.RatePlan, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]models.RatePlan), args.Error(1)
}

// TestPricingService_CreateRateTier tests the CreateRateTier method
func TestPricingService_CreateRateTier(t *testing.T) {
	validColor := "#FF0000"
	invalidColor := "FF0000"

	tests := []struct {
		name          string
		request       *models.CreateRateTierRequest
		setupMock     func(*MockPricingRepository)
		expectedError string
		checkResponse func(*testing.T, *models.RateTier)
	}{
		{
			name: "successful creation with color",
			request: &models.CreateRateTierRequest{
				Name:      "High Season",
				ColorCode: &validColor,
			},
			setupMock: func(m *MockPricingRepository) {
				m.On("CreateRateTier", mock.Anything, mock.AnythingOfType("*models.CreateRateTierRequest")).
					Return(&models.RateTier{
						RateTierID: 1,
						Name:       "High Season",
						ColorCode:  &validColor,
					}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, tier *models.RateTier) {
				assert.NotNil(t, tier)
				assert.Equal(t, "High Season", tier.Name)
				assert.Equal(t, validColor, *tier.ColorCode)
			},
		},
		{
			name: "invalid color code format",
			request: &models.CreateRateTierRequest{
				Name:      "High Season",
				ColorCode: &invalidColor,
			},
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "invalid color code format",
		},
		{
			name: "successful creation without color",
			request: &models.CreateRateTierRequest{
				Name: "Standard",
			},
			setupMock: func(m *MockPricingRepository) {
				m.On("CreateRateTier", mock.Anything, mock.AnythingOfType("*models.CreateRateTierRequest")).
					Return(&models.RateTier{
						RateTierID: 2,
						Name:       "Standard",
					}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, tier *models.RateTier) {
				assert.NotNil(t, tier)
				assert.Equal(t, "Standard", tier.Name)
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockPricingRepository)
			tt.setupMock(mockRepo)

			service := NewPricingService(mockRepo)
			tier, err := service.CreateRateTier(context.Background(), tt.request)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, tier)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, tier)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestPricingService_GetPricingCalendar tests the GetPricingCalendar method
func TestPricingService_GetPricingCalendar(t *testing.T) {
	today := time.Now().Format("2006-01-02")
	tomorrow := time.Now().AddDate(0, 0, 1).Format("2006-01-02")
	nextYear := time.Now().AddDate(1, 0, 1).Format("2006-01-02")

	tests := []struct {
		name          string
		startDate     string
		endDate       string
		setupMock     func(*MockPricingRepository)
		expectedError string
		checkResponse func(*testing.T, []models.PricingCalendar)
	}{
		{
			name:      "successful retrieval",
			startDate: today,
			endDate:   tomorrow,
			setupMock: func(m *MockPricingRepository) {
				m.On("GetPricingCalendar", mock.Anything, mock.AnythingOfType("time.Time"), mock.AnythingOfType("time.Time")).
					Return([]models.PricingCalendar{
						{
							Date:       time.Now(),
							RateTierID: 1,
						},
					}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, calendar []models.PricingCalendar) {
				assert.NotNil(t, calendar)
				assert.Equal(t, 1, len(calendar))
			},
		},
		{
			name:          "invalid start date format",
			startDate:     "invalid-date",
			endDate:       tomorrow,
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "invalid start date format",
		},
		{
			name:          "invalid end date format",
			startDate:     today,
			endDate:       "invalid-date",
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "invalid end date format",
		},
		{
			name:          "end date before start date",
			startDate:     tomorrow,
			endDate:       today,
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "end date must be after start date",
		},
		{
			name:          "date range exceeds 1 year",
			startDate:     today,
			endDate:       nextYear,
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "date range cannot exceed 1 year",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockPricingRepository)
			tt.setupMock(mockRepo)

			service := NewPricingService(mockRepo)
			calendar, err := service.GetPricingCalendar(context.Background(), tt.startDate, tt.endDate)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, calendar)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, calendar)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestPricingService_UpdatePricingCalendar tests the UpdatePricingCalendar method
func TestPricingService_UpdatePricingCalendar(t *testing.T) {
	today := time.Now().Format("2006-01-02")
	tomorrow := time.Now().AddDate(0, 0, 1).Format("2006-01-02")

	tests := []struct {
		name          string
		request       *models.UpdatePricingCalendarRequest
		setupMock     func(*MockPricingRepository)
		expectedError string
	}{
		{
			name: "successful update",
			request: &models.UpdatePricingCalendarRequest{
				StartDate:  today,
				EndDate:    tomorrow,
				RateTierID: 1,
			},
			setupMock: func(m *MockPricingRepository) {
				m.On("GetRateTierByID", mock.Anything, 1).Return(&models.RateTier{
					RateTierID: 1,
					Name:       "High Season",
				}, nil)
				m.On("UpdatePricingCalendar", mock.Anything, mock.AnythingOfType("*models.UpdatePricingCalendarRequest")).
					Return(nil)
			},
			expectedError: "",
		},
		{
			name: "invalid rate tier",
			request: &models.UpdatePricingCalendarRequest{
				StartDate:  today,
				EndDate:    tomorrow,
				RateTierID: 999,
			},
			setupMock: func(m *MockPricingRepository) {
				m.On("GetRateTierByID", mock.Anything, 999).Return(nil, errors.New("not found"))
			},
			expectedError: "invalid rate tier ID",
		},
		{
			name: "end date before start date",
			request: &models.UpdatePricingCalendarRequest{
				StartDate:  tomorrow,
				EndDate:    today,
				RateTierID: 1,
			},
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "end date must be after start date",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockPricingRepository)
			tt.setupMock(mockRepo)

			service := NewPricingService(mockRepo)
			err := service.UpdatePricingCalendar(context.Background(), tt.request)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestPricingService_UpdateRatePricing tests the UpdateRatePricing method
func TestPricingService_UpdateRatePricing(t *testing.T) {
	tests := []struct {
		name          string
		request       *models.UpdateRatePricingRequest
		setupMock     func(*MockPricingRepository)
		expectedError string
	}{
		{
			name: "successful update",
			request: &models.UpdateRatePricingRequest{
				RatePlanID: 1,
				RoomTypeID: 1,
				RateTierID: 1,
				Price:      100.00,
			},
			setupMock: func(m *MockPricingRepository) {
				m.On("UpdateRatePricing", mock.Anything, mock.AnythingOfType("*models.UpdateRatePricingRequest")).
					Return(nil)
			},
			expectedError: "",
		},
		{
			name: "negative price",
			request: &models.UpdateRatePricingRequest{
				RatePlanID: 1,
				RoomTypeID: 1,
				RateTierID: 1,
				Price:      -10.00,
			},
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "price cannot be negative",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockPricingRepository)
			tt.setupMock(mockRepo)

			service := NewPricingService(mockRepo)
			err := service.UpdateRatePricing(context.Background(), tt.request)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestPricingService_BulkUpdateRatePricing tests the BulkUpdateRatePricing method
func TestPricingService_BulkUpdateRatePricing(t *testing.T) {
	tests := []struct {
		name          string
		request       *models.BulkUpdateRatePricingRequest
		setupMock     func(*MockPricingRepository)
		expectedError string
	}{
		{
			name: "successful percentage adjustment",
			request: &models.BulkUpdateRatePricingRequest{
				RatePlanID:      1,
				AdjustmentType:  "percentage",
				AdjustmentValue: 10.0,
			},
			setupMock: func(m *MockPricingRepository) {
				m.On("BulkUpdateRatePricing", mock.Anything, mock.AnythingOfType("*models.BulkUpdateRatePricingRequest")).
					Return(nil)
			},
			expectedError: "",
		},
		{
			name: "successful fixed adjustment",
			request: &models.BulkUpdateRatePricingRequest{
				RatePlanID:      1,
				AdjustmentType:  "fixed",
				AdjustmentValue: 50.0,
			},
			setupMock: func(m *MockPricingRepository) {
				m.On("BulkUpdateRatePricing", mock.Anything, mock.AnythingOfType("*models.BulkUpdateRatePricingRequest")).
					Return(nil)
			},
			expectedError: "",
		},
		{
			name: "invalid adjustment type",
			request: &models.BulkUpdateRatePricingRequest{
				RatePlanID:      1,
				AdjustmentType:  "invalid",
				AdjustmentValue: 10.0,
			},
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "adjustment type must be 'percentage' or 'fixed'",
		},
		{
			name: "percentage adjustment too low",
			request: &models.BulkUpdateRatePricingRequest{
				RatePlanID:      1,
				AdjustmentType:  "percentage",
				AdjustmentValue: -150.0,
			},
			setupMock:     func(m *MockPricingRepository) {},
			expectedError: "percentage adjustment cannot be less than -100",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockPricingRepository)
			tt.setupMock(mockRepo)

			service := NewPricingService(mockRepo)
			err := service.BulkUpdateRatePricing(context.Background(), tt.request)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestPricingService_GetAllRateTiers tests the GetAllRateTiers method
func TestPricingService_GetAllRateTiers(t *testing.T) {
	tests := []struct {
		name          string
		setupMock     func(*MockPricingRepository)
		expectedError string
		checkResponse func(*testing.T, []models.RateTier)
	}{
		{
			name: "successful retrieval",
			setupMock: func(m *MockPricingRepository) {
				m.On("GetAllRateTiers", mock.Anything).Return([]models.RateTier{
					{RateTierID: 1, Name: "Low Season"},
					{RateTierID: 2, Name: "High Season"},
				}, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, tiers []models.RateTier) {
				assert.NotNil(t, tiers)
				assert.Equal(t, 2, len(tiers))
			},
		},
		{
			name: "database error",
			setupMock: func(m *MockPricingRepository) {
				m.On("GetAllRateTiers", mock.Anything).Return(nil, errors.New("database error"))
			},
			expectedError: "database error",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockPricingRepository)
			tt.setupMock(mockRepo)

			service := NewPricingService(mockRepo)
			tiers, err := service.GetAllRateTiers(context.Background())

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, tiers)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestIsValidHexColor tests the hex color validation helper
func TestIsValidHexColor(t *testing.T) {
	tests := []struct {
		name     string
		color    string
		expected bool
	}{
		{"valid uppercase", "#FF0000", true},
		{"valid lowercase", "#ff0000", true},
		{"valid mixed case", "#Ff00Aa", true},
		{"missing hash", "FF0000", false},
		{"too short", "#FF00", false},
		{"too long", "#FF00000", false},
		{"invalid characters", "#GG0000", false},
		{"empty string", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := isValidHexColor(tt.color)
			assert.Equal(t, tt.expected, result)
		})
	}
}
