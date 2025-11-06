package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
	"github.com/hotel-booking-system/backend/internal/service"
	"github.com/hotel-booking-system/backend/pkg/config"
	"github.com/hotel-booking-system/backend/pkg/database"
	"github.com/stretchr/testify/assert"
)

func setupRoomTestRouter() (*gin.Engine, *RoomHandler) {
	gin.SetMode(gin.TestMode)

	// Load config
	cfg, err := config.Load()
	if err != nil {
		panic(err)
	}

	// Connect to database
	db, err := database.Connect(cfg.Database)
	if err != nil {
		panic(err)
	}

	// Initialize dependencies
	roomRepo := repository.NewRoomRepository(db)
	roomService := service.NewRoomService(roomRepo)
	roomHandler := NewRoomHandler(roomService)

	// Setup router
	r := gin.New()
	return r, roomHandler
}

func TestGetAllRoomTypes(t *testing.T) {
	r, handler := setupRoomTestRouter()

	// Setup route
	r.GET("/api/rooms/types", handler.GetAllRoomTypes)

	// Create request
	req, _ := http.NewRequest("GET", "/api/rooms/types", nil)
	w := httptest.NewRecorder()

	// Perform request
	r.ServeHTTP(w, req)

	// Assert response
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.True(t, response["success"].(bool))
	assert.NotNil(t, response["data"])
}

func TestSearchRooms(t *testing.T) {
	r, handler := setupRoomTestRouter()

	// Setup route
	r.GET("/api/rooms/search", handler.SearchRooms)

	// Test valid search
	t.Run("Valid Search", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.True(t, response["success"].(bool))
	})

	// Test missing parameters
	t.Run("Missing Parameters", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/search?checkIn=2025-12-01", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	// Test invalid date format
	t.Run("Invalid Date Format", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/search?checkIn=invalid&checkOut=2025-12-05&guests=2", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	// Test checkout before checkin
	t.Run("Checkout Before Checkin", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/search?checkIn=2025-12-05&checkOut=2025-12-01&guests=2", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

func TestGetRoomTypeByID(t *testing.T) {
	r, handler := setupRoomTestRouter()

	// Setup route
	r.GET("/api/rooms/types/:id", handler.GetRoomTypeByID)

	// Test valid ID (assuming room type 1 exists from seed data)
	t.Run("Valid Room Type ID", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/types/1", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		// Should return 200 if room type exists, or 404 if not
		assert.True(t, w.Code == http.StatusOK || w.Code == http.StatusNotFound)
	})

	// Test invalid ID
	t.Run("Invalid Room Type ID", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/types/invalid", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

func TestGetRoomTypePricing(t *testing.T) {
	r, handler := setupRoomTestRouter()

	// Setup route
	r.GET("/api/rooms/types/:id/pricing", handler.GetRoomTypePricing)

	// Test valid pricing request
	t.Run("Valid Pricing Request", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/types/1/pricing?checkIn=2025-12-01&checkOut=2025-12-05", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		// Should return 200 if room type exists, or 404 if not
		assert.True(t, w.Code == http.StatusOK || w.Code == http.StatusNotFound)
	})

	// Test missing dates
	t.Run("Missing Dates", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/rooms/types/1/pricing", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}
