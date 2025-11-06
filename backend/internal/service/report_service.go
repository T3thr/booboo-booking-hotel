package service

import (
	"context"
	"encoding/csv"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/repository"
)

type ReportService struct {
	reportRepo *repository.ReportRepository
}

func NewReportService(reportRepo *repository.ReportRepository) *ReportService {
	return &ReportService{
		reportRepo: reportRepo,
	}
}

// GetOccupancyReport retrieves occupancy statistics
func (s *ReportService) GetOccupancyReport(ctx context.Context, startDate, endDate time.Time, roomTypeID *int, groupBy string) ([]models.OccupancyReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	reports, err := s.reportRepo.GetOccupancyReport(ctx, startDate, endDate, roomTypeID)
	if err != nil {
		return nil, err
	}

	// Group by week or month if requested
	if groupBy == "week" || groupBy == "month" {
		reports = s.groupOccupancyReports(reports, groupBy)
	}

	return reports, nil
}

// GetRevenueReport retrieves revenue statistics
func (s *ReportService) GetRevenueReport(ctx context.Context, startDate, endDate time.Time, roomTypeID, ratePlanID *int, groupBy string) ([]models.RevenueReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	reports, err := s.reportRepo.GetRevenueReport(ctx, startDate, endDate, roomTypeID, ratePlanID)
	if err != nil {
		return nil, err
	}

	// Group by week or month if requested
	if groupBy == "week" || groupBy == "month" {
		reports = s.groupRevenueReports(reports, groupBy)
	}

	return reports, nil
}

// GetVoucherReport retrieves voucher usage statistics
func (s *ReportService) GetVoucherReport(ctx context.Context, startDate, endDate time.Time) ([]models.VoucherReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return s.reportRepo.GetVoucherReport(ctx, startDate, endDate)
}

// GetNoShowReport retrieves no-show statistics
func (s *ReportService) GetNoShowReport(ctx context.Context, startDate, endDate time.Time) ([]models.NoShowReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return s.reportRepo.GetNoShowReport(ctx, startDate, endDate)
}

// GetReportSummary retrieves aggregated statistics
func (s *ReportService) GetReportSummary(ctx context.Context, startDate, endDate time.Time) (*models.ReportSummary, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return s.reportRepo.GetReportSummary(ctx, startDate, endDate)
}

// GetComparisonReport retrieves year-over-year comparison
func (s *ReportService) GetComparisonReport(ctx context.Context, startDate, endDate time.Time) (*models.ComparisonData, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	// Get current period summary
	currentSummary, err := s.reportRepo.GetReportSummary(ctx, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get current period summary: %w", err)
	}

	// Calculate previous period dates (same period last year)
	duration := endDate.Sub(startDate)
	prevEndDate := startDate.AddDate(-1, 0, 0)
	prevStartDate := prevEndDate.Add(-duration)

	// Get previous period summary
	prevSummary, err := s.reportRepo.GetReportSummary(ctx, prevStartDate, prevEndDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get previous period summary: %w", err)
	}

	// Calculate percentage changes
	comparison := &models.ComparisonData{
		CurrentPeriod:  *currentSummary,
		PreviousPeriod: *prevSummary,
	}

	if prevSummary.TotalRevenue > 0 {
		comparison.RevenueChange = ((currentSummary.TotalRevenue - prevSummary.TotalRevenue) / prevSummary.TotalRevenue) * 100
	}

	if prevSummary.AvgOccupancy > 0 {
		comparison.OccupancyChange = ((currentSummary.AvgOccupancy - prevSummary.AvgOccupancy) / prevSummary.AvgOccupancy) * 100
	}

	if prevSummary.ADR > 0 {
		comparison.ADRChange = ((currentSummary.ADR - prevSummary.ADR) / prevSummary.ADR) * 100
	}

	return comparison, nil
}

// ExportOccupancyToCSV exports occupancy report to CSV format
func (s *ReportService) ExportOccupancyToCSV(reports []models.OccupancyReport) (string, error) {
	var builder strings.Builder
	writer := csv.NewWriter(&builder)

	// Write header
	header := []string{"Date", "Room Type", "Total Rooms", "Booked Rooms", "Occupancy Rate (%)", "Available Rooms"}
	if err := writer.Write(header); err != nil {
		return "", err
	}

	// Write data
	for _, report := range reports {
		roomType := "All"
		if report.RoomTypeName != nil {
			roomType = *report.RoomTypeName
		}

		row := []string{
			report.Date.Format("2006-01-02"),
			roomType,
			strconv.Itoa(report.TotalRooms),
			strconv.Itoa(report.BookedRooms),
			fmt.Sprintf("%.2f", report.OccupancyRate),
			strconv.Itoa(report.AvailableRooms),
		}
		if err := writer.Write(row); err != nil {
			return "", err
		}
	}

	writer.Flush()
	return builder.String(), writer.Error()
}

// ExportRevenueToCSV exports revenue report to CSV format
func (s *ReportService) ExportRevenueToCSV(reports []models.RevenueReport) (string, error) {
	var builder strings.Builder
	writer := csv.NewWriter(&builder)

	// Write header
	header := []string{"Date", "Room Type", "Rate Plan", "Total Revenue", "Booking Count", "Room Nights", "ADR"}
	if err := writer.Write(header); err != nil {
		return "", err
	}

	// Write data
	for _, report := range reports {
		roomType := "All"
		if report.RoomTypeName != nil {
			roomType = *report.RoomTypeName
		}

		ratePlan := "All"
		if report.RatePlanName != nil {
			ratePlan = *report.RatePlanName
		}

		row := []string{
			report.Date.Format("2006-01-02"),
			roomType,
			ratePlan,
			fmt.Sprintf("%.2f", report.TotalRevenue),
			strconv.Itoa(report.BookingCount),
			strconv.Itoa(report.RoomNights),
			fmt.Sprintf("%.2f", report.ADR),
		}
		if err := writer.Write(row); err != nil {
			return "", err
		}
	}

	writer.Flush()
	return builder.String(), writer.Error()
}

// ExportVoucherToCSV exports voucher report to CSV format
func (s *ReportService) ExportVoucherToCSV(reports []models.VoucherReport) (string, error) {
	var builder strings.Builder
	writer := csv.NewWriter(&builder)

	// Write header
	header := []string{"Code", "Discount Type", "Discount Value", "Total Uses", "Total Discount", "Total Revenue", "Conversion Rate (%)", "Expiry Date"}
	if err := writer.Write(header); err != nil {
		return "", err
	}

	// Write data
	for _, report := range reports {
		row := []string{
			report.Code,
			report.DiscountType,
			fmt.Sprintf("%.2f", report.DiscountValue),
			strconv.Itoa(report.TotalUses),
			fmt.Sprintf("%.2f", report.TotalDiscount),
			fmt.Sprintf("%.2f", report.TotalRevenue),
			fmt.Sprintf("%.2f", report.ConversionRate),
			report.ExpiryDate.Format("2006-01-02"),
		}
		if err := writer.Write(row); err != nil {
			return "", err
		}
	}

	writer.Flush()
	return builder.String(), writer.Error()
}

// ExportNoShowToCSV exports no-show report to CSV format
func (s *ReportService) ExportNoShowToCSV(reports []models.NoShowReport) (string, error) {
	var builder strings.Builder
	writer := csv.NewWriter(&builder)

	// Write header
	header := []string{"Date", "Booking ID", "Guest Name", "Email", "Phone", "Room Type", "Check-in Date", "Check-out Date", "Total Amount", "Penalty Charged"}
	if err := writer.Write(header); err != nil {
		return "", err
	}

	// Write data
	for _, report := range reports {
		row := []string{
			report.Date.Format("2006-01-02"),
			strconv.Itoa(report.BookingID),
			report.GuestName,
			report.GuestEmail,
			report.GuestPhone,
			report.RoomTypeName,
			report.CheckInDate.Format("2006-01-02"),
			report.CheckOutDate.Format("2006-01-02"),
			fmt.Sprintf("%.2f", report.TotalAmount),
			fmt.Sprintf("%.2f", report.PenaltyCharged),
		}
		if err := writer.Write(row); err != nil {
			return "", err
		}
	}

	writer.Flush()
	return builder.String(), writer.Error()
}

// Helper function to group occupancy reports
func (s *ReportService) groupOccupancyReports(reports []models.OccupancyReport, groupBy string) []models.OccupancyReport {
	grouped := make(map[string]*models.OccupancyReport)

	for _, report := range reports {
		var key string
		if groupBy == "week" {
			year, week := report.Date.ISOWeek()
			key = fmt.Sprintf("%d-W%02d", year, week)
		} else if groupBy == "month" {
			key = report.Date.Format("2006-01")
		}

		if existing, ok := grouped[key]; ok {
			existing.TotalRooms += report.TotalRooms
			existing.BookedRooms += report.BookedRooms
			existing.AvailableRooms += report.AvailableRooms
		} else {
			grouped[key] = &report
		}
	}

	// Recalculate occupancy rates
	result := make([]models.OccupancyReport, 0, len(grouped))
	for _, report := range grouped {
		if report.TotalRooms > 0 {
			report.OccupancyRate = (float64(report.BookedRooms) / float64(report.TotalRooms)) * 100
		}
		result = append(result, *report)
	}

	return result
}

// Helper function to group revenue reports
func (s *ReportService) groupRevenueReports(reports []models.RevenueReport, groupBy string) []models.RevenueReport {
	grouped := make(map[string]*models.RevenueReport)

	for _, report := range reports {
		var key string
		if groupBy == "week" {
			year, week := report.Date.ISOWeek()
			key = fmt.Sprintf("%d-W%02d", year, week)
		} else if groupBy == "month" {
			key = report.Date.Format("2006-01")
		}

		if existing, ok := grouped[key]; ok {
			existing.TotalRevenue += report.TotalRevenue
			existing.BookingCount += report.BookingCount
			existing.RoomNights += report.RoomNights
		} else {
			grouped[key] = &report
		}
	}

	// Recalculate ADR
	result := make([]models.RevenueReport, 0, len(grouped))
	for _, report := range grouped {
		if report.RoomNights > 0 {
			report.ADR = report.TotalRevenue / float64(report.RoomNights)
		}
		result = append(result, *report)
	}

	return result
}
