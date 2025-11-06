package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
)

type PricingHandler struct {
	pricingService *service.PricingService
}

func NewPricingHandler(pricingService *service.PricingService) *PricingHandler {
	return &PricingHandler{
		pricingService: pricingService,
	}
}

// ============================================================================
// Rate Tier Handlers
// ============================================================================

// GetAllRateTiers retrieves all rate tiers
// GET /api/pricing/tiers
func (h *PricingHandler) GetAllRateTiers(c *gin.Context) {
	tiers, err := h.pricingService.GetAllRateTiers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to retrieve rate tiers",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    tiers,
	})
}

// GetRateTierByID retrieves a rate tier by ID
// GET /api/pricing/tiers/:id
func (h *PricingHandler) GetRateTierByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid rate tier ID",
		})
		return
	}

	tier, err := h.pricingService.GetRateTierByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Rate tier not found",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    tier,
	})
}

// CreateRateTier creates a new rate tier
// POST /api/pricing/tiers
func (h *PricingHandler) CreateRateTier(c *gin.Context) {
	var req models.CreateRateTierRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	tier, err := h.pricingService.CreateRateTier(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to create rate tier",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Rate tier created successfully",
		"data":    tier,
	})
}

// UpdateRateTier updates a rate tier
// PUT /api/pricing/tiers/:id
func (h *PricingHandler) UpdateRateTier(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid rate tier ID",
		})
		return
	}

	var req models.UpdateRateTierRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	tier, err := h.pricingService.UpdateRateTier(c.Request.Context(), id, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to update rate tier",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Rate tier updated successfully",
		"data":    tier,
	})
}

// ============================================================================
// Pricing Calendar Handlers
// ============================================================================

// GetPricingCalendar retrieves pricing calendar for a date range
// GET /api/pricing/calendar?start_date=2024-01-01&end_date=2024-12-31
func (h *PricingHandler) GetPricingCalendar(c *gin.Context) {
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	if startDate == "" || endDate == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "start_date and end_date are required",
		})
		return
	}

	calendar, err := h.pricingService.GetPricingCalendar(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to retrieve pricing calendar",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    calendar,
	})
}

// UpdatePricingCalendar updates pricing calendar for a date range
// PUT /api/pricing/calendar
func (h *PricingHandler) UpdatePricingCalendar(c *gin.Context) {
	var req models.UpdatePricingCalendarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	err := h.pricingService.UpdatePricingCalendar(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to update pricing calendar",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Pricing calendar updated successfully",
	})
}

// ============================================================================
// Rate Pricing Handlers
// ============================================================================

// GetAllRatePricing retrieves all rate pricing with details
// GET /api/pricing/rates
func (h *PricingHandler) GetAllRatePricing(c *gin.Context) {
	pricings, err := h.pricingService.GetAllRatePricing(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to retrieve rate pricing",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    pricings,
	})
}

// GetRatePricingByPlan retrieves rate pricing for a specific rate plan
// GET /api/pricing/rates/plan/:planId
func (h *PricingHandler) GetRatePricingByPlan(c *gin.Context) {
	planID, err := strconv.Atoi(c.Param("planId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid rate plan ID",
		})
		return
	}

	pricings, err := h.pricingService.GetRatePricingByPlan(c.Request.Context(), planID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to retrieve rate pricing",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    pricings,
	})
}

// UpdateRatePricing updates or creates a rate pricing entry
// PUT /api/pricing/rates
func (h *PricingHandler) UpdateRatePricing(c *gin.Context) {
	var req models.UpdateRatePricingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	err := h.pricingService.UpdateRatePricing(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to update rate pricing",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Rate pricing updated successfully",
	})
}

// BulkUpdateRatePricing updates multiple rate pricing entries
// POST /api/pricing/rates/bulk
func (h *PricingHandler) BulkUpdateRatePricing(c *gin.Context) {
	var req models.BulkUpdateRatePricingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	err := h.pricingService.BulkUpdateRatePricing(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to bulk update rate pricing",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Rate pricing bulk updated successfully",
	})
}

// GetAllRatePlans retrieves all rate plans
// GET /api/pricing/plans
func (h *PricingHandler) GetAllRatePlans(c *gin.Context) {
	plans, err := h.pricingService.GetAllRatePlans(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to retrieve rate plans",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    plans,
	})
}
