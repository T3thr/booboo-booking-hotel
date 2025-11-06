package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
	"github.com/hotel-booking-system/backend/pkg/utils"
)

// HousekeepingHandler handles housekeeping HTTP requests
type HousekeepingHandler struct {
	housekeepingService *service.HousekeepingService
}

// NewHousekeepingHandler creates a new housekeeping handler
func NewHousekeepingHandler(housekeepingService *service.HousekeepingService) *HousekeepingHandler {
	return &HousekeepingHandler{
		housekeepingService: housekeepingService,
	}
}

// GetTasks retrieves all housekeeping tasks
// @Summary Get housekeeping tasks
// @Description Get list of all rooms that need cleaning or inspection
// @Tags housekeeping
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.HousekeepingTasksResponse
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/housekeeping/tasks [get]
func (h *HousekeepingHandler) GetTasks(c *gin.Context) {
	response, err := h.housekeepingService.GetHousekeepingTasks(c.Request.Context())
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get housekeeping tasks")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, response)
}

// UpdateRoomStatus updates the housekeeping status of a room
// @Summary Update room housekeeping status
// @Description Update the housekeeping status of a specific room
// @Tags housekeeping
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "Room ID"
// @Param request body models.UpdateRoomStatusRequest true "Status update request"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/housekeeping/rooms/{id}/status [put]
func (h *HousekeepingHandler) UpdateRoomStatus(c *gin.Context) {
	// Get room ID from path
	roomIDStr := c.Param("id")
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid room ID")
		return
	}

	// Parse request body
	var req models.UpdateRoomStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err.Error())
		return
	}

	// Update status
	if err := h.housekeepingService.UpdateRoomStatus(c.Request.Context(), roomID, req.Status); err != nil {
		if err.Error() == "invalid housekeeping status" ||
			err.Error() == "room must be in Clean status to be inspected" {
			utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
			return
		}
		if err.Error() == "failed to get room: room not found" {
			utils.ErrorResponse(c, http.StatusNotFound, "Room not found")
			return
		}
		// Check for invalid transition errors
		if len(err.Error()) > 25 && err.Error()[:25] == "invalid status transition" {
			utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to update room status")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, gin.H{
		"message": "Room status updated successfully",
		"room_id": roomID,
		"status":  req.Status,
	})
}

// InspectRoom allows supervisor to inspect and approve/reject a cleaned room
// @Summary Inspect a cleaned room
// @Description Supervisor inspects a room and approves or rejects it
// @Tags housekeeping
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "Room ID"
// @Param request body models.InspectRoomRequest true "Inspection request"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/housekeeping/rooms/{id}/inspect [post]
func (h *HousekeepingHandler) InspectRoom(c *gin.Context) {
	// Get room ID from path
	roomIDStr := c.Param("id")
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid room ID")
		return
	}

	// Parse request body
	var req models.InspectRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err.Error())
		return
	}

	// Inspect room
	if err := h.housekeepingService.InspectRoom(c.Request.Context(), roomID, req.Approved, req.Notes); err != nil {
		if err.Error() == "room must be in Clean status to be inspected" {
			utils.ErrorResponse(c, http.StatusBadRequest, err.Error())
			return
		}
		if err.Error() == "failed to get room: room not found" {
			utils.ErrorResponse(c, http.StatusNotFound, "Room not found")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to inspect room")
		return
	}

	status := "rejected"
	if req.Approved {
		status = "approved"
	}

	utils.SuccessResponse(c, http.StatusOK, gin.H{
		"message": "Room inspection completed",
		"room_id": roomID,
		"status":  status,
	})
}

// GetRoomsForInspection retrieves all rooms ready for inspection
// @Summary Get rooms for inspection
// @Description Get list of all rooms that are ready for supervisor inspection
// @Tags housekeeping
// @Produce json
// @Security BearerAuth
// @Success 200 {object} []models.HousekeepingTask
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/housekeeping/inspection [get]
func (h *HousekeepingHandler) GetRoomsForInspection(c *gin.Context) {
	tasks, err := h.housekeepingService.GetRoomsForInspection(c.Request.Context())
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to get rooms for inspection")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, tasks)
}

// ReportMaintenance reports a maintenance issue for a room
// @Summary Report maintenance issue
// @Description Report a maintenance issue for a specific room
// @Tags housekeeping
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "Room ID"
// @Param request body models.ReportMaintenanceRequest true "Maintenance report"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/housekeeping/rooms/{id}/maintenance [post]
func (h *HousekeepingHandler) ReportMaintenance(c *gin.Context) {
	// Get room ID from path
	roomIDStr := c.Param("id")
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid room ID")
		return
	}

	// Parse request body
	var req models.ReportMaintenanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err.Error())
		return
	}

	// Report maintenance
	if err := h.housekeepingService.ReportMaintenance(c.Request.Context(), roomID, req.Description); err != nil {
		if err.Error() == "failed to get room: room not found" {
			utils.ErrorResponse(c, http.StatusNotFound, "Room not found")
			return
		}
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to report maintenance")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, gin.H{
		"message":     "Maintenance issue reported successfully",
		"room_id":     roomID,
		"description": req.Description,
	})
}
