package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
)

type PaymentProofHandler struct {
	paymentProofService *service.PaymentProofService
}

func NewPaymentProofHandler(paymentProofService *service.PaymentProofService) *PaymentProofHandler {
	return &PaymentProofHandler{
		paymentProofService: paymentProofService,
	}
}

// GetPaymentProofs handles GET /api/payment-proofs with pagination
func (h *PaymentProofHandler) GetPaymentProofs(c *gin.Context) {
	status := c.DefaultQuery("status", "pending")
	
	// Parse pagination parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	
	// Calculate offset
	offset := (page - 1) * limit
	if offset < 0 {
		offset = 0
	}

	paymentProofs, totalCount, err := h.paymentProofService.GetPaymentProofs(c.Request.Context(), status, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Calculate pagination metadata
	totalPages := (totalCount + limit - 1) / limit
	if totalPages < 1 {
		totalPages = 1
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    paymentProofs,
		"pagination": gin.H{
			"total":        totalCount,
			"page":         page,
			"limit":        limit,
			"total_pages":  totalPages,
			"has_next":     page < totalPages,
			"has_previous": page > 1,
		},
	})
}

// ApprovePaymentProof handles POST /api/payment-proofs/:id/approve
// Note: :id is booking_id for now (until we implement payment proof upload)
func (h *PaymentProofHandler) ApprovePaymentProof(c *gin.Context) {
	idStr := c.Param("id")
	bookingID, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid booking ID",
		})
		return
	}

	var req models.PaymentProofRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// Notes is optional, so empty body is ok
		req.Notes = nil
	}

	err = h.paymentProofService.ApprovePaymentProof(c.Request.Context(), bookingID, req.Notes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Booking approved successfully",
	})
}

// RejectPaymentProof handles POST /api/payment-proofs/:id/reject
// Note: :id is booking_id for now (until we implement payment proof upload)
func (h *PaymentProofHandler) RejectPaymentProof(c *gin.Context) {
	idStr := c.Param("id")
	bookingID, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid booking ID",
		})
		return
	}

	var req models.PaymentProofRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// Notes is optional, so empty body is ok
		req.Notes = nil
	}

	err = h.paymentProofService.RejectPaymentProof(c.Request.Context(), bookingID, req.Notes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Booking rejected successfully",
	})
}

// GetPaymentProofByID handles GET /api/payment-proofs/:id
func (h *PaymentProofHandler) GetPaymentProofByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid payment proof ID",
		})
		return
	}

	paymentProof, err := h.paymentProofService.GetPaymentProofByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	if paymentProof == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Payment proof not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    paymentProof,
	})
}
