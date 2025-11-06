package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
)

// CheckInHandler handles check-in/check-out related HTTP requests
type CheckInHandler struct {
	bookingService *service.BookingService
}

// NewCheckInHandler creates a new check-in handler
func NewCheckInHandler(bookingService *service.BookingService) *CheckInHandler {
	return &CheckInHandler{
		bookingService: bookingService,
	}
}

// CheckIn handles POST /api/checkin
func (h *CheckInHandler) CheckIn(c *gin.Context) {
	var req models.CheckInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.bookingService.CheckIn(c.Request.Context(), req.BookingDetailID, req.RoomID)
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

// CheckOut handles POST /api/checkout
func (h *CheckInHandler) CheckOut(c *gin.Context) {
	var req models.CheckOutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.bookingService.CheckOut(c.Request.Context(), req.BookingID)
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

// MoveRoom handles POST /api/checkin/move-room
func (h *CheckInHandler) MoveRoom(c *gin.Context) {
	var req models.MoveRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.bookingService.MoveRoom(c.Request.Context(), req.RoomAssignmentID, req.NewRoomID)
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

// MarkNoShow handles POST /api/bookings/:id/no-show
func (h *CheckInHandler) MarkNoShow(c *gin.Context) {
	bookingID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid booking ID"})
		return
	}

	var req models.MarkNoShowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// Notes are optional, so we can proceed even if binding fails
		req.BookingID = bookingID
	} else {
		req.BookingID = bookingID
	}

	response, err := h.bookingService.MarkNoShow(c.Request.Context(), bookingID)
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

// GetArrivals handles GET /api/checkin/arrivals
func (h *CheckInHandler) GetArrivals(c *gin.Context) {
	var req models.GetArrivalsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	arrivals, err := h.bookingService.GetArrivals(c.Request.Context(), req.Date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"arrivals": arrivals,
		"count":    len(arrivals),
	})
}

// GetDepartures handles GET /api/checkout/departures
func (h *CheckInHandler) GetDepartures(c *gin.Context) {
	var req models.GetDeparturesRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	departures, err := h.bookingService.GetDepartures(c.Request.Context(), req.Date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"departures": departures,
		"count":      len(departures),
	})
}

// GetAvailableRooms handles GET /api/checkin/available-rooms/:roomTypeId
func (h *CheckInHandler) GetAvailableRooms(c *gin.Context) {
	roomTypeID, err := strconv.Atoi(c.Param("roomTypeId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room type ID"})
		return
	}

	rooms, err := h.bookingService.GetAvailableRoomsForCheckIn(c.Request.Context(), roomTypeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"rooms": rooms,
		"count": len(rooms),
	})
}
