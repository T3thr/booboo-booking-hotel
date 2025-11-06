package handlers

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
	"github.com/hotel-booking-system/backend/pkg/utils"
)

// RoomHandler handles room HTTP requests
type RoomHandler struct {
	roomService *service.RoomService
}

// NewRoomHandler creates a new room handler
func NewRoomHandler(roomService *service.RoomService) *RoomHandler {
	return &RoomHandler{
		roomService: roomService,
	}
}

// SearchRooms searches for available rooms
// @Summary Search available rooms
// @Tags rooms
// @Accept json
// @Produce json
// @Param checkIn query string true "Check-in date (YYYY-MM-DD)"
// @Param checkOut query string true "Check-out date (YYYY-MM-DD)"
// @Param guests query int true "Number of guests"
// @Success 200 {object} models.SearchRoomsResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/rooms/search [get]
func (h *RoomHandler) SearchRooms(c *gin.Context) {
	var req models.SearchRoomsRequest

	if err := c.ShouldBindQuery(&req); err != nil {
		log.Printf("ERROR [SearchRooms]: Bind query failed: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request parameters",
			"message": err.Error(),
		})
		return
	}

	log.Printf("INFO [SearchRooms]: Request - CheckIn: %s, CheckOut: %s, Guests: %d", 
		req.CheckIn, req.CheckOut, req.Guests)

	response, err := h.roomService.SearchAvailableRooms(c.Request.Context(), &req)
	if err != nil {
		// Log the actual error for debugging
		log.Printf("ERROR [SearchRooms]: SearchAvailableRooms failed: %v", err)
		c.Error(err)
		
		// Check for validation errors
		if err.Error() == "รูปแบบวันที่ check-in ไม่ถูกต้อง" ||
			err.Error() == "รูปแบบวันที่ check-out ไม่ถูกต้อง" ||
			err.Error() == "วันที่ check-out ต้องอยู่หลังวันที่ check-in" ||
			err.Error() == "วันที่ check-in ต้องไม่อยู่ในอดีต" {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   err.Error(),
			})
			return
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to search rooms",
			"message": err.Error(),
		})
		return
	}

	log.Printf("INFO [SearchRooms]: Success - Found %d room types", len(response.RoomTypes))
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// GetAllRoomTypes retrieves all room types
// @Summary Get all room types
// @Tags rooms
// @Produce json
// @Success 200 {array} models.RoomType
// @Failure 500 {object} map[string]string
// @Router /api/rooms/types [get]
func (h *RoomHandler) GetAllRoomTypes(c *gin.Context) {
	roomTypes, err := h.roomService.GetAllRoomTypes(c.Request.Context())
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get room types")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, roomTypes)
}

// GetRoomTypeByID retrieves a specific room type with details
// @Summary Get room type by ID
// @Tags rooms
// @Produce json
// @Param id path int true "Room Type ID"
// @Success 200 {object} models.RoomTypeDetailResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/rooms/types/{id} [get]
func (h *RoomHandler) GetRoomTypeByID(c *gin.Context) {
	idStr := c.Param("id")
	roomTypeID, err := strconv.Atoi(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid room type ID")
		return
	}

	roomType, err := h.roomService.GetRoomTypeByID(c.Request.Context(), roomTypeID)
	if err != nil {
		if err.Error() == "room type not found" {
			utils.ErrorResponse(c, http.StatusNotFound, "Room type not found")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get room type")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, roomType)
}

// GetRoomTypePricing calculates pricing for a specific room type
// @Summary Get room type pricing
// @Tags rooms
// @Produce json
// @Param id path int true "Room Type ID"
// @Param checkIn query string true "Check-in date (YYYY-MM-DD)"
// @Param checkOut query string true "Check-out date (YYYY-MM-DD)"
// @Success 200 {object} models.RoomType
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/rooms/types/{id}/pricing [get]
func (h *RoomHandler) GetRoomTypePricing(c *gin.Context) {
	idStr := c.Param("id")
	roomTypeID, err := strconv.Atoi(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid room type ID")
		return
	}

	checkIn := c.Query("checkIn")
	checkOut := c.Query("checkOut")

	if checkIn == "" || checkOut == "" {
		utils.ErrorResponse(c, http.StatusBadRequest, "checkIn and checkOut are required")
		return
	}

	roomType, err := h.roomService.GetRoomTypePricing(c.Request.Context(), roomTypeID, checkIn, checkOut)
	if err != nil {
		if err.Error() == "room type not found" {
			utils.ErrorResponse(c, http.StatusNotFound, "Room type not found")
			return
		}
		if err.Error() == "รูปแบบวันที่ check-in ไม่ถูกต้อง" ||
			err.Error() == "รูปแบบวันที่ check-out ไม่ถูกต้อง" ||
			err.Error() == "วันที่ check-out ต้องอยู่หลังวันที่ check-in" {
			utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get pricing")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, roomType)
}

// GetRoomStatusDashboard retrieves all rooms with their current status
// @Summary Get room status dashboard
// @Description Get all rooms with their current occupancy and housekeeping status
// @Tags rooms
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.RoomStatusDashboardResponse
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/rooms/status [get]
func (h *RoomHandler) GetRoomStatusDashboard(c *gin.Context) {
	dashboard, err := h.roomService.GetAllRoomsWithStatus(c.Request.Context())
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get room status dashboard")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, dashboard)
}
