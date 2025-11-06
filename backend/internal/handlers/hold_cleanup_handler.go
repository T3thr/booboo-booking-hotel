package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/jobs"
)

// HoldCleanupHandler handles HTTP requests for hold cleanup operations
type HoldCleanupHandler struct {
	holdCleanup *jobs.HoldCleanupJob
}

// NewHoldCleanupHandler creates a new hold cleanup handler
func NewHoldCleanupHandler(holdCleanup *jobs.HoldCleanupJob) *HoldCleanupHandler {
	return &HoldCleanupHandler{
		holdCleanup: holdCleanup,
	}
}

// TriggerManual triggers a manual hold cleanup
// POST /api/admin/hold-cleanup/trigger
func (h *HoldCleanupHandler) TriggerManual(c *gin.Context) {
	result, err := h.holdCleanup.RunManual()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to execute hold cleanup",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":         result.Success,
		"holds_released":  result.HoldsReleased,
		"timestamp":       result.Timestamp,
		"execution_time":  result.ExecutionTime.String(),
		"message":         "Hold cleanup executed successfully",
	})
}

// GetStatus returns the current status of the hold cleanup job
// GET /api/admin/hold-cleanup/status
func (h *HoldCleanupHandler) GetStatus(c *gin.Context) {
	stats := h.holdCleanup.GetStats()
	
	c.JSON(http.StatusOK, gin.H{
		"is_running":    stats["is_running"],
		"next_run_time": stats["next_run_time"],
		"schedule":      stats["schedule"],
	})
}
