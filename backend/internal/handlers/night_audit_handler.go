package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/jobs"
)

// NightAuditHandler handles night audit related requests
type NightAuditHandler struct {
	nightAudit *jobs.NightAuditJob
}

// NewNightAuditHandler creates a new night audit handler
func NewNightAuditHandler(nightAudit *jobs.NightAuditJob) *NightAuditHandler {
	return &NightAuditHandler{
		nightAudit: nightAudit,
	}
}

// TriggerManual manually triggers the night audit process
// POST /api/admin/night-audit/trigger
func (h *NightAuditHandler) TriggerManual(c *gin.Context) {
	result, err := h.nightAudit.RunManual()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to run night audit",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        "Night audit completed successfully",
		"timestamp":      result.Timestamp,
		"rooms_updated":  result.RoomsUpdated,
		"execution_time": result.ExecutionTime.String(),
	})
}

// GetStatus returns the status of the night audit scheduler
// GET /api/admin/night-audit/status
func (h *NightAuditHandler) GetStatus(c *gin.Context) {
	nextRun := h.nightAudit.GetNextRunTime()
	isRunning := h.nightAudit.IsRunning()

	c.JSON(http.StatusOK, gin.H{
		"is_running": isRunning,
		"next_run":   nextRun,
		"schedule":   "Daily at 02:00 AM",
	})
}
