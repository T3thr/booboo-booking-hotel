package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/hotel-booking-system/backend/internal/service"

	"github.com/gin-gonic/gin"
)

type ReportHandler struct {
	reportService *service.ReportService
}

func NewReportHandler(reportService *service.ReportService) *ReportHandler {
	return &ReportHandler{
		reportService: reportService,
	}
}

// GetOccupancyReport godoc
// @Summary Get occupancy report
// @Description Retrieve occupancy statistics for a date range
// @Tags reports
// @Accept json
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Param room_type_id query int false "Room type ID filter"
// @Param group_by query string false "Group by: day, week, month" default(day)
// @Success 200 {array} models.OccupancyReport
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/occupancy [get]
func (h *ReportHandler) GetOccupancyReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")
	groupBy := c.DefaultQuery("group_by", "day")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	var roomTypeID *int
	if roomTypeIDStr := c.Query("room_type_id"); roomTypeIDStr != "" {
		id, err := strconv.Atoi(roomTypeIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_type_id"})
			return
		}
		roomTypeID = &id
	}

	reports, err := h.reportService.GetOccupancyReport(c.Request.Context(), startDate, endDate, roomTypeID, groupBy)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":       reports,
		"start_date": startDate.Format("2006-01-02"),
		"end_date":   endDate.Format("2006-01-02"),
		"group_by":   groupBy,
	})
}

// GetRevenueReport godoc
// @Summary Get revenue report
// @Description Retrieve revenue statistics for a date range
// @Tags reports
// @Accept json
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Param room_type_id query int false "Room type ID filter"
// @Param rate_plan_id query int false "Rate plan ID filter"
// @Param group_by query string false "Group by: day, week, month" default(day)
// @Success 200 {array} models.RevenueReport
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/revenue [get]
func (h *ReportHandler) GetRevenueReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")
	groupBy := c.DefaultQuery("group_by", "day")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	var roomTypeID *int
	if roomTypeIDStr := c.Query("room_type_id"); roomTypeIDStr != "" {
		id, err := strconv.Atoi(roomTypeIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_type_id"})
			return
		}
		roomTypeID = &id
	}

	var ratePlanID *int
	if ratePlanIDStr := c.Query("rate_plan_id"); ratePlanIDStr != "" {
		id, err := strconv.Atoi(ratePlanIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rate_plan_id"})
			return
		}
		ratePlanID = &id
	}

	reports, err := h.reportService.GetRevenueReport(c.Request.Context(), startDate, endDate, roomTypeID, ratePlanID, groupBy)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":       reports,
		"start_date": startDate.Format("2006-01-02"),
		"end_date":   endDate.Format("2006-01-02"),
		"group_by":   groupBy,
	})
}

// GetVoucherReport godoc
// @Summary Get voucher usage report
// @Description Retrieve voucher usage statistics
// @Tags reports
// @Accept json
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Success 200 {array} models.VoucherReport
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/vouchers [get]
func (h *ReportHandler) GetVoucherReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	reports, err := h.reportService.GetVoucherReport(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":       reports,
		"start_date": startDate.Format("2006-01-02"),
		"end_date":   endDate.Format("2006-01-02"),
	})
}

// GetNoShowReport godoc
// @Summary Get no-show report
// @Description Retrieve no-show statistics
// @Tags reports
// @Accept json
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Success 200 {array} models.NoShowReport
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/no-shows [get]
func (h *ReportHandler) GetNoShowReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	reports, err := h.reportService.GetNoShowReport(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":       reports,
		"start_date": startDate.Format("2006-01-02"),
		"end_date":   endDate.Format("2006-01-02"),
	})
}

// GetReportSummary godoc
// @Summary Get report summary
// @Description Retrieve aggregated statistics for a date range
// @Tags reports
// @Accept json
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Success 200 {object} models.ReportSummary
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/summary [get]
func (h *ReportHandler) GetReportSummary(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	summary, err := h.reportService.GetReportSummary(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, summary)
}

// GetComparisonReport godoc
// @Summary Get year-over-year comparison
// @Description Retrieve comparison with same period last year
// @Tags reports
// @Accept json
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Success 200 {object} models.ComparisonData
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/comparison [get]
func (h *ReportHandler) GetComparisonReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	comparison, err := h.reportService.GetComparisonReport(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, comparison)
}

// ExportOccupancyReport godoc
// @Summary Export occupancy report to CSV
// @Description Export occupancy statistics to CSV format
// @Tags reports
// @Accept json
// @Produce text/csv
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Param room_type_id query int false "Room type ID filter"
// @Param group_by query string false "Group by: day, week, month" default(day)
// @Success 200 {string} string "CSV content"
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/export/occupancy [get]
func (h *ReportHandler) ExportOccupancyReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")
	groupBy := c.DefaultQuery("group_by", "day")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	var roomTypeID *int
	if roomTypeIDStr := c.Query("room_type_id"); roomTypeIDStr != "" {
		id, err := strconv.Atoi(roomTypeIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_type_id"})
			return
		}
		roomTypeID = &id
	}

	reports, err := h.reportService.GetOccupancyReport(c.Request.Context(), startDate, endDate, roomTypeID, groupBy)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	csv, err := h.reportService.ExportOccupancyToCSV(reports)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate CSV"})
		return
	}

	filename := "occupancy_report_" + startDate.Format("20060102") + "_" + endDate.Format("20060102") + ".csv"
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "text/csv")
	c.String(http.StatusOK, csv)
}

// ExportRevenueReport godoc
// @Summary Export revenue report to CSV
// @Description Export revenue statistics to CSV format
// @Tags reports
// @Accept json
// @Produce text/csv
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Param room_type_id query int false "Room type ID filter"
// @Param rate_plan_id query int false "Rate plan ID filter"
// @Param group_by query string false "Group by: day, week, month" default(day)
// @Success 200 {string} string "CSV content"
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/export/revenue [get]
func (h *ReportHandler) ExportRevenueReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")
	groupBy := c.DefaultQuery("group_by", "day")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	var roomTypeID *int
	if roomTypeIDStr := c.Query("room_type_id"); roomTypeIDStr != "" {
		id, err := strconv.Atoi(roomTypeIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid room_type_id"})
			return
		}
		roomTypeID = &id
	}

	var ratePlanID *int
	if ratePlanIDStr := c.Query("rate_plan_id"); ratePlanIDStr != "" {
		id, err := strconv.Atoi(ratePlanIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rate_plan_id"})
			return
		}
		ratePlanID = &id
	}

	reports, err := h.reportService.GetRevenueReport(c.Request.Context(), startDate, endDate, roomTypeID, ratePlanID, groupBy)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	csv, err := h.reportService.ExportRevenueToCSV(reports)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate CSV"})
		return
	}

	filename := "revenue_report_" + startDate.Format("20060102") + "_" + endDate.Format("20060102") + ".csv"
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "text/csv")
	c.String(http.StatusOK, csv)
}

// ExportVoucherReport godoc
// @Summary Export voucher report to CSV
// @Description Export voucher usage statistics to CSV format
// @Tags reports
// @Accept json
// @Produce text/csv
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Success 200 {string} string "CSV content"
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/export/vouchers [get]
func (h *ReportHandler) ExportVoucherReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	reports, err := h.reportService.GetVoucherReport(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	csv, err := h.reportService.ExportVoucherToCSV(reports)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate CSV"})
		return
	}

	filename := "voucher_report_" + startDate.Format("20060102") + "_" + endDate.Format("20060102") + ".csv"
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "text/csv")
	c.String(http.StatusOK, csv)
}

// ExportNoShowReport godoc
// @Summary Export no-show report to CSV
// @Description Export no-show statistics to CSV format
// @Tags reports
// @Accept json
// @Produce text/csv
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Success 200 {string} string "CSV content"
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/reports/export/no-shows [get]
func (h *ReportHandler) ExportNoShowReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "start_date and end_date are required"})
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_date format, use YYYY-MM-DD"})
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_date format, use YYYY-MM-DD"})
		return
	}

	reports, err := h.reportService.GetNoShowReport(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	csv, err := h.reportService.ExportNoShowToCSV(reports)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate CSV"})
		return
	}

	filename := "noshow_report_" + startDate.Format("20060102") + "_" + endDate.Format("20060102") + ".csv"
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "text/csv")
	c.String(http.StatusOK, csv)
}
