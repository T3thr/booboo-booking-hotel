package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
)

type InventoryHandler struct {
	inventoryService *service.InventoryService
}

func NewInventoryHandler(inventoryService *service.InventoryService) *InventoryHandler {
	return &InventoryHandler{
		inventoryService: inventoryService,
	}
}

// GetInventory retrieves inventory for a specific room type and date range
// GET /api/inventory?room_type_id=1&start_date=2024-01-01&end_date=2024-12-31
func (h *InventoryHandler) GetInventory(c *gin.Context) {
	roomTypeIDStr := c.Query("room_type_id")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	// If room_type_id is not provided, get all inventory
	if roomTypeIDStr == "" {
		if startDate == "" || endDate == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "start_date and end_date are required",
			})
			return
		}

		inventory, err := h.inventoryService.GetAllInventory(c.Request.Context(), startDate, endDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Failed to retrieve inventory",
				"details": err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    inventory,
		})
		return
	}

	// Get inventory for specific room type
	roomTypeID, err := strconv.Atoi(roomTypeIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid room_type_id",
		})
		return
	}

	if startDate == "" || endDate == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "start_date and end_date are required",
		})
		return
	}

	inventory, err := h.inventoryService.GetInventory(c.Request.Context(), roomTypeID, startDate, endDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to retrieve inventory",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    inventory,
	})
}

// GetInventoryByDate retrieves inventory for a specific room type and date
// GET /api/inventory/:roomTypeId/:date
func (h *InventoryHandler) GetInventoryByDate(c *gin.Context) {
	roomTypeID, err := strconv.Atoi(c.Param("roomTypeId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid room type ID",
		})
		return
	}

	date := c.Param("date")
	if date == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Date is required",
		})
		return
	}

	inventory, err := h.inventoryService.GetInventoryByDate(c.Request.Context(), roomTypeID, date)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Inventory not found",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    inventory,
	})
}

// UpdateInventory updates inventory for a specific date
// PUT /api/inventory
func (h *InventoryHandler) UpdateInventory(c *gin.Context) {
	var req models.UpdateInventoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	err := h.inventoryService.UpdateInventory(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to update inventory",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Inventory updated successfully",
	})
}

// BulkUpdateInventory updates inventory for a date range
// POST /api/inventory/bulk
func (h *InventoryHandler) BulkUpdateInventory(c *gin.Context) {
	var req models.BulkUpdateInventoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	validationErrors, err := h.inventoryService.BulkUpdateInventory(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to bulk update inventory",
			"details": err.Error(),
		})
		return
	}

	// If there are validation errors, return them with 400 status
	if len(validationErrors) > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success":          false,
			"error":            "Cannot update inventory for some dates due to existing bookings",
			"validation_errors": validationErrors,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Inventory bulk updated successfully",
	})
}
