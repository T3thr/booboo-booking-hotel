package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/pkg/utils"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockAuthRepository is a mock implementation of AuthRepository
type MockAuthRepository struct {
	mock.Mock
}

func (m *MockAuthRepository) EmailExists(ctx context.Context, email string) (bool, error) {
	args := m.Called(ctx, email)
	return args.Bool(0), args.Error(1)
}

func (m *MockAuthRepository) CreateGuest(ctx context.Context, guest *models.Guest) error {
	args := m.Called(ctx, guest)
	// Set a mock ID for the guest
	if args.Error(0) == nil {
		guest.GuestID = 1
		guest.CreatedAt = time.Now()
		guest.UpdatedAt = time.Now()
	}
	return args.Error(0)
}

func (m *MockAuthRepository) CreateGuestAccount(ctx context.Context, guestID int, hashedPassword string) error {
	args := m.Called(ctx, guestID, hashedPassword)
	return args.Error(0)
}

func (m *MockAuthRepository) GetGuestByEmail(ctx context.Context, email string) (*models.Guest, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Guest), args.Error(1)
}

func (m *MockAuthRepository) GetGuestAccountByGuestID(ctx context.Context, guestID int) (*models.GuestAccount, error) {
	args := m.Called(ctx, guestID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.GuestAccount), args.Error(1)
}

func (m *MockAuthRepository) UpdateLastLogin(ctx context.Context, guestAccountID int) error {
	args := m.Called(ctx, guestAccountID)
	return args.Error(0)
}

func (m *MockAuthRepository) GetGuestByID(ctx context.Context, guestID int) (*models.Guest, error) {
	args := m.Called(ctx, guestID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Guest), args.Error(1)
}

func (m *MockAuthRepository) UpdateGuest(ctx context.Context, guest *models.Guest) error {
	args := m.Called(ctx, guest)
	return args.Error(0)
}

// TestAuthService_Register tests the Register method
func TestAuthService_Register(t *testing.T) {
	tests := []struct {
		name          string
		request       *models.RegisterRequest
		setupMock     func(*MockAuthRepository)
		expectedError string
		checkResponse func(*testing.T, *models.LoginResponse)
	}{
		{
			name: "successful registration",
			request: &models.RegisterRequest{
				FirstName: "John",
				LastName:  "Doe",
				Email:     "john@example.com",
				Phone:     "1234567890",
				Password:  "password123",
			},
			setupMock: func(m *MockAuthRepository) {
				m.On("EmailExists", mock.Anything, "john@example.com").Return(false, nil)
				m.On("CreateGuest", mock.Anything, mock.AnythingOfType("*models.Guest")).Return(nil)
				m.On("CreateGuestAccount", mock.Anything, 1, mock.AnythingOfType("string")).Return(nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.LoginResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 1, resp.ID)
				assert.Equal(t, "john@example.com", resp.Email)
				assert.Equal(t, "John", resp.FirstName)
				assert.Equal(t, "Doe", resp.LastName)
				assert.Equal(t, "guest", resp.Role)
				assert.NotEmpty(t, resp.AccessToken)
			},
		},
		{
			name: "email already exists",
			request: &models.RegisterRequest{
				FirstName: "Jane",
				LastName:  "Doe",
				Email:     "existing@example.com",
				Phone:     "1234567890",
				Password:  "password123",
			},
			setupMock: func(m *MockAuthRepository) {
				m.On("EmailExists", mock.Anything, "existing@example.com").Return(true, nil)
			},
			expectedError: "อีเมลนี้ถูกลงทะเบียนแล้ว",
		},
		{
			name: "database error on email check",
			request: &models.RegisterRequest{
				FirstName: "Jane",
				LastName:  "Doe",
				Email:     "jane@example.com",
				Phone:     "1234567890",
				Password:  "password123",
			},
			setupMock: func(m *MockAuthRepository) {
				m.On("EmailExists", mock.Anything, "jane@example.com").Return(false, errors.New("database error"))
			},
			expectedError: "failed to check email",
		},
		{
			name: "error creating guest",
			request: &models.RegisterRequest{
				FirstName: "Jane",
				LastName:  "Doe",
				Email:     "jane@example.com",
				Phone:     "1234567890",
				Password:  "password123",
			},
			setupMock: func(m *MockAuthRepository) {
				m.On("EmailExists", mock.Anything, "jane@example.com").Return(false, nil)
				m.On("CreateGuest", mock.Anything, mock.AnythingOfType("*models.Guest")).Return(errors.New("database error"))
			},
			expectedError: "failed to create guest",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockAuthRepository)
			tt.setupMock(mockRepo)

			service := NewAuthService(mockRepo, "test-secret")
			resp, err := service.Register(context.Background(), tt.request)

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

// TestAuthService_Login tests the Login method
func TestAuthService_Login(t *testing.T) {
	hashedPassword, _ := utils.HashPassword("password123")

	tests := []struct {
		name          string
		request       *models.LoginRequest
		setupMock     func(*MockAuthRepository)
		expectedError string
		checkResponse func(*testing.T, *models.LoginResponse)
	}{
		{
			name: "successful login",
			request: &models.LoginRequest{
				Email:    "john@example.com",
				Password: "password123",
			},
			setupMock: func(m *MockAuthRepository) {
				guest := &models.Guest{
					GuestID:   1,
					FirstName: "John",
					LastName:  "Doe",
					Email:     "john@example.com",
					Phone:     "1234567890",
				}
				account := &models.GuestAccount{
					GuestAccountID: 1,
					GuestID:        1,
					HashedPassword: hashedPassword,
				}
				m.On("GetGuestByEmail", mock.Anything, "john@example.com").Return(guest, nil)
				m.On("GetGuestAccountByGuestID", mock.Anything, 1).Return(account, nil)
				m.On("UpdateLastLogin", mock.Anything, 1).Return(nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, resp *models.LoginResponse) {
				assert.NotNil(t, resp)
				assert.Equal(t, 1, resp.ID)
				assert.Equal(t, "john@example.com", resp.Email)
				assert.Equal(t, "guest", resp.Role)
				assert.NotEmpty(t, resp.AccessToken)
			},
		},
		{
			name: "guest not found",
			request: &models.LoginRequest{
				Email:    "notfound@example.com",
				Password: "password123",
			},
			setupMock: func(m *MockAuthRepository) {
				m.On("GetGuestByEmail", mock.Anything, "notfound@example.com").Return(nil, nil)
			},
			expectedError: "อีเมลหรือรหัสผ่านไม่ถูกต้อง",
		},
		{
			name: "incorrect password",
			request: &models.LoginRequest{
				Email:    "john@example.com",
				Password: "wrongpassword",
			},
			setupMock: func(m *MockAuthRepository) {
				guest := &models.Guest{
					GuestID:   1,
					FirstName: "John",
					LastName:  "Doe",
					Email:     "john@example.com",
				}
				account := &models.GuestAccount{
					GuestAccountID: 1,
					GuestID:        1,
					HashedPassword: hashedPassword,
				}
				m.On("GetGuestByEmail", mock.Anything, "john@example.com").Return(guest, nil)
				m.On("GetGuestAccountByGuestID", mock.Anything, 1).Return(account, nil)
			},
			expectedError: "อีเมลหรือรหัสผ่านไม่ถูกต้อง",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockAuthRepository)
			tt.setupMock(mockRepo)

			service := NewAuthService(mockRepo, "test-secret")
			resp, err := service.Login(context.Background(), tt.request)

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

// TestAuthService_GetProfile tests the GetProfile method
func TestAuthService_GetProfile(t *testing.T) {
	tests := []struct {
		name          string
		guestID       int
		setupMock     func(*MockAuthRepository)
		expectedError string
		checkResponse func(*testing.T, *models.Guest)
	}{
		{
			name:    "successful get profile",
			guestID: 1,
			setupMock: func(m *MockAuthRepository) {
				guest := &models.Guest{
					GuestID:   1,
					FirstName: "John",
					LastName:  "Doe",
					Email:     "john@example.com",
					Phone:     "1234567890",
				}
				m.On("GetGuestByID", mock.Anything, 1).Return(guest, nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, guest *models.Guest) {
				assert.NotNil(t, guest)
				assert.Equal(t, 1, guest.GuestID)
				assert.Equal(t, "John", guest.FirstName)
			},
		},
		{
			name:    "guest not found",
			guestID: 999,
			setupMock: func(m *MockAuthRepository) {
				m.On("GetGuestByID", mock.Anything, 999).Return(nil, nil)
			},
			expectedError: "guest not found",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockAuthRepository)
			tt.setupMock(mockRepo)

			service := NewAuthService(mockRepo, "test-secret")
			guest, err := service.GetProfile(context.Background(), tt.guestID)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, guest)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, guest)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}

// TestAuthService_UpdateProfile tests the UpdateProfile method
func TestAuthService_UpdateProfile(t *testing.T) {
	tests := []struct {
		name          string
		guestID       int
		request       *models.UpdateProfileRequest
		setupMock     func(*MockAuthRepository)
		expectedError string
		checkResponse func(*testing.T, *models.Guest)
	}{
		{
			name:    "successful update",
			guestID: 1,
			request: &models.UpdateProfileRequest{
				FirstName: "Jane",
				LastName:  "Smith",
				Phone:     "9876543210",
			},
			setupMock: func(m *MockAuthRepository) {
				guest := &models.Guest{
					GuestID:   1,
					FirstName: "John",
					LastName:  "Doe",
					Email:     "john@example.com",
					Phone:     "1234567890",
				}
				m.On("GetGuestByID", mock.Anything, 1).Return(guest, nil)
				m.On("UpdateGuest", mock.Anything, mock.AnythingOfType("*models.Guest")).Return(nil)
			},
			expectedError: "",
			checkResponse: func(t *testing.T, guest *models.Guest) {
				assert.NotNil(t, guest)
				assert.Equal(t, "Jane", guest.FirstName)
				assert.Equal(t, "Smith", guest.LastName)
				assert.Equal(t, "9876543210", guest.Phone)
			},
		},
		{
			name:    "guest not found",
			guestID: 999,
			request: &models.UpdateProfileRequest{
				FirstName: "Jane",
				LastName:  "Smith",
				Phone:     "9876543210",
			},
			setupMock: func(m *MockAuthRepository) {
				m.On("GetGuestByID", mock.Anything, 999).Return(nil, nil)
			},
			expectedError: "guest not found",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockRepo := new(MockAuthRepository)
			tt.setupMock(mockRepo)

			service := NewAuthService(mockRepo, "test-secret")
			guest, err := service.UpdateProfile(context.Background(), tt.guestID, tt.request)

			if tt.expectedError != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, guest)
			} else {
				assert.NoError(t, err)
				if tt.checkResponse != nil {
					tt.checkResponse(t, guest)
				}
			}

			mockRepo.AssertExpectations(t)
		})
	}
}
