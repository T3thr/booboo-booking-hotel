package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
)

// BookingHandler handles booking-related HTTP requests
type BookingHandler struct {
	bookingService *service.BookingService
}

// NewBookingHandler creates a new booking handler
func NewBookingHandler(bookingService *service.BookingService) *BookingHandler {
	return &BookingHandler{
		bookingService: bookingService,
	}
}

// CreateBookingHold handles POST /api/bookings/hold
func (h *BookingHandler) CreateBookingHold(c *gin.Context) {
	var req models.CreateBookingHoldRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get guest account ID from context if authenticated
	if userID, exists := c.Get("user_id"); exists {
		guestAccountID := userID.(int)
		req.GuestAccountID = &guestAccountID
	}

	response, err := h.bookingService.CreateBookingHold(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if !response.Success {
		c.JSON(http.StatusBadRequest, gin.H{"error": response.Message})
		return
	}

	c.JSON(http.StatusOK, response)
}

// CreateBooking handles POST /api/bookings
func (h *BookingHandler) CreateBooking(c *gin.Context) {
	// Get guest ID from context (must be authenticated)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	guestID := userID.(int)

	var req models.CreateBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.bookingService.CreateBooking(c.Request.Context(), guestID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, response)
}

// ConfirmBooking handles POST /api/bookings/:id/confirm
func (h *BookingHandler) ConfirmBooking(c *gin.Context) {
	// Get guest ID from context (must be authenticated)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	guestID := userID.(int)

	bookingID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid booking ID"})
		return
	}

	var req models.ConfirmBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify booking belongs to user
	booking, err := h.bookingService.GetBookingByID(c.Request.Context(), bookingID, guestID)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
	if booking == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Booking not found"})
		return
	}

	response, err := h.bookingService.ConfirmBooking(c.Request.Context(), bookingID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if !response.Success {
		c.JSON(http.StatusBadRequest, gin.H{"error": response.Message})
		return
	}

	c.JSON(http.StatusOK, response)
}

// CancelBooking handles POST /api/bookings/:id/cancel
func (h *BookingHandler) CancelBooking(c *gin.Context) {
	// Get guest ID from context (must be authenticated)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	guestID := userID.(int)

	bookingID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid booking ID"})
		return
	}

	var req models.CancelBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.bookingService.CancelBooking(c.Request.Context(), bookingID, guestID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if !response.Success {
		c.JSON(http.StatusBadRequest, gin.H{"error": response.Message})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GetBookings handles GET /api/bookings
func (h *BookingHandler) GetBookings(c *gin.Context) {
	// Get guest ID from context (must be authenticated)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	guestID := userID.(int)

	var req models.GetBookingsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Set defaults
	if req.Limit == 0 {
		req.Limit = 20
	}

	response, err := h.bookingService.GetBookingsByGuestID(
		c.Request.Context(),
		guestID,
		req.Status,
		req.Limit,
		req.Offset,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GetBookingByID handles GET /api/bookings/:id
func (h *BookingHandler) GetBookingByID(c *gin.Context) {
	// Get guest ID from context (must be authenticated)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}
	guestID := userID.(int)

	bookingID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid booking ID"})
		return
	}

	booking, err := h.bookingService.GetBookingByID(c.Request.Context(), bookingID, guestID)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	if booking == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Booking not found"})
		return
	}

	c.JSON(http.StatusOK, booking)
}

// SearchBookingsByPhone handles GET /api/bookings/search?phone=xxx
func (h *BookingHandler) SearchBookingsByPhone(c *gin.Context) {
	phone := c.Query("phone")
	if phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Phone number is required"})
		return
	}

	bookings, err := h.bookingService.GetBookingsByPhone(c.Request.Context(), phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"bookings": bookings,
		"total":    len(bookings),
	})
}

// SyncBookings handles POST /api/bookings/sync (placeholder for future implementation)
func (h *BookingHandler) SyncBookings(c *gin.Context) {
	// This would link bookings from phone to user account
	// For now, return success as bookings are already searchable by phone
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Bookings are accessible via phone search",
	})
}
