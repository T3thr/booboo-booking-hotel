package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
)

type PolicyHandler struct {
	policyService *service.PolicyService
}

func NewPolicyHandler(policyService *service.PolicyService) *PolicyHandler {
	return &PolicyHandler{
		policyService: policyService,
	}
}

// ============================================================================
// Cancellation Policy Handlers
// ============================================================================

// GetAllCancellationPolicies retrieves all cancellation policies
// GET /api/policies/cancellation
func (h *PolicyHandler) GetAllCancellationPolicies(c *gin.Context) {
	policies, err := h.policyService.GetAllCancellationPolicies(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to retrieve cancellation policies",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    policies,
	})
}

// GetCancellationPolicyByID retrieves a cancellation policy by ID
// GET /api/policies/cancellation/:id
func (h *PolicyHandler) GetCancellationPolicyByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid policy ID",
		})
		return
	}

	policy, err := h.policyService.GetCancellationPolicyByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Cancellation policy not found",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    policy,
	})
}

// CreateCancellationPolicy creates a new cancellation policy
// POST /api/policies/cancellation
func (h *PolicyHandler) CreateCancellationPolicy(c *gin.Context) {
	var req models.CreateCancellationPolicyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	policy, err := h.policyService.CreateCancellationPolicy(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to create cancellation policy",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Cancellation policy created successfully",
		"data":    policy,
	})
}

// UpdateCancellationPolicy updates a cancellation policy
// PUT /api/policies/cancellation/:id
func (h *PolicyHandler) UpdateCancellationPolicy(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid policy ID",
		})
		return
	}

	var req models.UpdateCancellationPolicyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	policy, err := h.policyService.UpdateCancellationPolicy(c.Request.Context(), id, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to update cancellation policy",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cancellation policy updated successfully",
		"data":    policy,
	})
}

// DeleteCancellationPolicy deletes a cancellation policy
// DELETE /api/policies/cancellation/:id
func (h *PolicyHandler) DeleteCancellationPolicy(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid policy ID",
		})
		return
	}

	err = h.policyService.DeleteCancellationPolicy(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to delete cancellation policy",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Cancellation policy deleted successfully",
	})
}

// ============================================================================
// Voucher Handlers
// ============================================================================

// GetAllVouchers retrieves all vouchers
// GET /api/vouchers
func (h *PolicyHandler) GetAllVouchers(c *gin.Context) {
	vouchers, err := h.policyService.GetAllVouchers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to retrieve vouchers",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    vouchers,
	})
}

// GetVoucherByID retrieves a voucher by ID
// GET /api/vouchers/:id
func (h *PolicyHandler) GetVoucherByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid voucher ID",
		})
		return
	}

	voucher, err := h.policyService.GetVoucherByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Voucher not found",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    voucher,
	})
}

// CreateVoucher creates a new voucher
// POST /api/vouchers
func (h *PolicyHandler) CreateVoucher(c *gin.Context) {
	var req models.CreateVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	voucher, err := h.policyService.CreateVoucher(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to create voucher",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Voucher created successfully",
		"data":    voucher,
	})
}

// UpdateVoucher updates a voucher
// PUT /api/vouchers/:id
func (h *PolicyHandler) UpdateVoucher(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid voucher ID",
		})
		return
	}

	var req models.UpdateVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	voucher, err := h.policyService.UpdateVoucher(c.Request.Context(), id, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to update voucher",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Voucher updated successfully",
		"data":    voucher,
	})
}

// DeleteVoucher deletes a voucher
// DELETE /api/vouchers/:id
func (h *PolicyHandler) DeleteVoucher(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid voucher ID",
		})
		return
	}

	err = h.policyService.DeleteVoucher(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to delete voucher",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Voucher deleted successfully",
	})
}

// ValidateVoucher validates a voucher code
// POST /api/vouchers/validate
func (h *PolicyHandler) ValidateVoucher(c *gin.Context) {
	var req models.ValidateVoucherRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid request body",
			"details": err.Error(),
		})
		return
	}

	response, err := h.policyService.ValidateVoucher(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to validate voucher",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}
