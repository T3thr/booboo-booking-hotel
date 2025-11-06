# Task 33: Reporting Module - Quick Start Guide

## Overview

This guide helps you quickly test the Reporting Module and understand how to use all reporting endpoints.

## Prerequisites

1. Backend server running on `http://localhost:8080`
2. Database with seed data (including manager account and bookings)
3. PowerShell (for Windows) or curl (for Linux/Mac)

## Quick Test (PowerShell)

### 1. Run the automated test script

```powershell
cd backend
.\test_report_module.ps1
```

This script will:
- Login as manager
- Test all report endpoints
- Test filtered and grouped reports
- Test CSV exports
- Test year-over-year comparison
- Display results

## Manual Testing

### 1. Login as Manager

```powershell
$loginResponse = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/auth/login" `
  -ContentType "application/json" `
  -Body '{"email":"manager@hotel.com","password":"password123"}'

$token = $loginResponse.data.accessToken
Write-Host "Logged in as manager. Token: $token"
```

### 2. Get Occupancy Report

```powershell
# Get daily occupancy for January 2024
$occupancy = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/occupancy?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Occupancy Report:"
$occupancy.data | Format-Table date, room_type_name, total_rooms, booked_rooms, occupancy_rate, available_rooms
```

### 3. Get Occupancy Report (Filtered by Room Type)

```powershell
# Get occupancy for specific room type
$occupancyFiltered = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/occupancy?start_date=2024-01-01&end_date=2024-01-31&room_type_id=1" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Filtered Occupancy Report:"
$occupancyFiltered.data | Format-Table date, room_type_name, occupancy_rate
```

### 4. Get Occupancy Report (Grouped by Week)

```powershell
# Get weekly occupancy
$occupancyWeekly = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/occupancy?start_date=2024-01-01&end_date=2024-03-31&group_by=week" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Weekly Occupancy Report:"
$occupancyWeekly.data | Format-Table date, total_rooms, booked_rooms, occupancy_rate
```

### 5. Get Revenue Report

```powershell
# Get daily revenue for January 2024
$revenue = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Revenue Report:"
$revenue.data | Format-Table date, room_type_name, rate_plan_name, total_revenue, booking_count, room_nights, adr
```

### 6. Get Revenue Report (Grouped by Week)

```powershell
# Get weekly revenue
$revenueWeekly = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-03-31&group_by=week" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Weekly Revenue Report:"
$revenueWeekly.data | Format-Table date, total_revenue, booking_count, adr
```

### 7. Get Voucher Usage Report

```powershell
# Get voucher usage statistics
$vouchers = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/vouchers?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Voucher Usage Report:"
$vouchers.data | Format-Table code, discount_type, discount_value, total_uses, total_discount, conversion_rate
```

### 8. Get No-Show Report

```powershell
# Get no-show statistics
$noShows = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/no-shows?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "No-Show Report:"
$noShows.data | Format-Table date, booking_id, guest_name, room_type_name, total_amount, penalty_charged
```

### 9. Get Summary Report

```powershell
# Get aggregated statistics
$summary = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/summary?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Summary Report:"
Write-Host "Total Revenue: $($summary.total_revenue)"
Write-Host "Total Bookings: $($summary.total_bookings)"
Write-Host "Total Room Nights: $($summary.total_room_nights)"
Write-Host "Average Occupancy: $($summary.avg_occupancy)%"
Write-Host "ADR: $($summary.adr)"
Write-Host "No-Show Count: $($summary.no_show_count)"
Write-Host "No-Show Rate: $($summary.no_show_rate)%"
```

### 10. Get Year-over-Year Comparison

```powershell
# Compare with same period last year
$comparison = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/comparison?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Year-over-Year Comparison:"
Write-Host "Current Period Revenue: $($comparison.current_period.total_revenue)"
Write-Host "Previous Period Revenue: $($comparison.previous_period.total_revenue)"
Write-Host "Revenue Change: $($comparison.revenue_change_percent)%"
Write-Host "Occupancy Change: $($comparison.occupancy_change_percent)%"
Write-Host "ADR Change: $($comparison.adr_change_percent)%"
```

### 11. Export Occupancy Report to CSV

```powershell
# Export occupancy report
Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/export/occupancy?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"} `
  -OutFile "occupancy_report.csv"

Write-Host "Occupancy report exported to occupancy_report.csv"
```

### 12. Export Revenue Report to CSV

```powershell
# Export revenue report
Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/export/revenue?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"} `
  -OutFile "revenue_report.csv"

Write-Host "Revenue report exported to revenue_report.csv"
```

## Testing with curl (Linux/Mac)

### 1. Login

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"password123"}' \
  | jq -r '.data.accessToken')

echo "Token: $TOKEN"
```

### 2. Get Occupancy Report

```bash
curl -X GET "http://localhost:8080/api/reports/occupancy?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 3. Get Revenue Report

```bash
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 4. Get Voucher Report

```bash
curl -X GET "http://localhost:8080/api/reports/vouchers?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 5. Get No-Show Report

```bash
curl -X GET "http://localhost:8080/api/reports/no-shows?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 6. Get Summary

```bash
curl -X GET "http://localhost:8080/api/reports/summary?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 7. Get Comparison

```bash
curl -X GET "http://localhost:8080/api/reports/comparison?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 8. Export to CSV

```bash
curl -X GET "http://localhost:8080/api/reports/export/revenue?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN" \
  -o revenue_report.csv
```

## Common Test Scenarios

### Scenario 1: Monthly Performance Review

```powershell
# Get summary for current month
$summary = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/summary?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

# Compare with last year
$comparison = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/comparison?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Current Month Performance:"
Write-Host "Revenue: $($summary.total_revenue) (Change: $($comparison.revenue_change_percent)%)"
Write-Host "Occupancy: $($summary.avg_occupancy)% (Change: $($comparison.occupancy_change_percent)%)"
Write-Host "ADR: $($summary.adr) (Change: $($comparison.adr_change_percent)%)"
```

### Scenario 2: Weekly Revenue Trend

```powershell
# Get weekly revenue for Q1
$weeklyRevenue = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-03-31&group_by=week" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Weekly Revenue Trend:"
$weeklyRevenue.data | Format-Table date, total_revenue, booking_count, adr
```

### Scenario 3: Room Type Performance

```powershell
# Get revenue for each room type
$roomTypes = @(1, 2, 3)  # Assuming 3 room types

foreach ($roomTypeId in $roomTypes) {
    $revenue = Invoke-RestMethod -Method GET `
      -Uri "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-01-31&room_type_id=$roomTypeId" `
      -Headers @{Authorization="Bearer $token"}
    
    if ($revenue.data.Count -gt 0) {
        $totalRevenue = ($revenue.data | Measure-Object -Property total_revenue -Sum).Sum
        $roomTypeName = $revenue.data[0].room_type_name
        Write-Host "$roomTypeName Total Revenue: $totalRevenue"
    }
}
```

### Scenario 4: Voucher Campaign Analysis

```powershell
# Get voucher usage
$vouchers = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/vouchers?start_date=2024-01-01&end_date=2024-01-31" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Voucher Campaign Performance:"
foreach ($voucher in $vouchers.data) {
    Write-Host "Code: $($voucher.code)"
    Write-Host "  Uses: $($voucher.total_uses)"
    Write-Host "  Total Discount: $($voucher.total_discount)"
    Write-Host "  Revenue Generated: $($voucher.total_revenue)"
    Write-Host "  Conversion Rate: $($voucher.conversion_rate)%"
    Write-Host ""
}
```

### Scenario 5: Export All Reports for Accounting

```powershell
$startDate = "2024-01-01"
$endDate = "2024-01-31"

# Export all reports
Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/export/occupancy?start_date=$startDate&end_date=$endDate" `
  -Headers @{Authorization="Bearer $token"} `
  -OutFile "occupancy_jan2024.csv"

Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/export/revenue?start_date=$startDate&end_date=$endDate" `
  -Headers @{Authorization="Bearer $token"} `
  -OutFile "revenue_jan2024.csv"

Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/export/vouchers?start_date=$startDate&end_date=$endDate" `
  -Headers @{Authorization="Bearer $token"} `
  -OutFile "vouchers_jan2024.csv"

Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/reports/export/no-shows?start_date=$startDate&end_date=$endDate" `
  -Headers @{Authorization="Bearer $token"} `
  -OutFile "noshows_jan2024.csv"

Write-Host "All reports exported successfully!"
```

## Understanding the Results

### Occupancy Report Fields
- **date**: Report date
- **room_type_name**: Name of room type
- **total_rooms**: Total rooms available (allotment)
- **booked_rooms**: Number of rooms booked
- **occupancy_rate**: Percentage of rooms occupied
- **available_rooms**: Rooms still available

### Revenue Report Fields
- **date**: Report date
- **room_type_name**: Name of room type
- **rate_plan_name**: Name of rate plan
- **total_revenue**: Total revenue generated
- **booking_count**: Number of bookings
- **room_nights**: Total room nights sold
- **adr**: Average Daily Rate (revenue / room nights)

### Voucher Report Fields
- **code**: Voucher code
- **discount_type**: Percentage or FixedAmount
- **discount_value**: Discount amount/percentage
- **total_uses**: Number of times used
- **total_discount**: Total discount given
- **total_revenue**: Revenue generated with voucher
- **conversion_rate**: Usage rate (uses / max_uses × 100)

### No-Show Report Fields
- **date**: Date marked as no-show
- **booking_id**: Booking ID
- **guest_name**: Guest name
- **guest_email**: Guest email
- **guest_phone**: Guest phone
- **room_type_name**: Room type booked
- **check_in_date**: Scheduled check-in
- **check_out_date**: Scheduled check-out
- **total_amount**: Booking total
- **penalty_charged**: Penalty amount

## Troubleshooting

### Issue: "Failed to login"
**Solution:** Ensure manager account exists in database. Check credentials.

### Issue: "Authorization header missing"
**Solution:** Include the Bearer token in Authorization header.

### Issue: "start_date and end_date are required"
**Solution:** Both parameters must be provided in YYYY-MM-DD format.

### Issue: "invalid date format"
**Solution:** Use YYYY-MM-DD format (e.g., "2024-01-31").

### Issue: "No data returned"
**Solution:** Check if there are bookings in the specified date range. Verify database has seed data.

### Issue: "CSV file is empty"
**Solution:** Ensure there is data for the date range. Check if bookings exist.

## Query Parameter Reference

### Common Parameters
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format

### Optional Filters
- `room_type_id`: Filter by specific room type (integer)
- `rate_plan_id`: Filter by specific rate plan (integer)
- `group_by`: Group results by day, week, or month (default: day)

### Grouping Options
- `day`: Daily breakdown (default)
- `week`: Weekly aggregation
- `month`: Monthly aggregation

## Next Steps

1. ✅ Test all endpoints with the automated script
2. ✅ Verify calculations are correct
3. ✅ Test filtering and grouping
4. ✅ Test CSV exports
5. ✅ Review documentation
6. ✅ Integrate with frontend

## Related Documentation

- [Reporting Module Reference](./REPORTING_MODULE_REFERENCE.md)
- [Requirements Document](../.kiro/specs/hotel-reservation-system/requirements.md) - Requirement 19.1-19.7
- [Design Document](../.kiro/specs/hotel-reservation-system/design.md)
- [Verification Checklist](./TASK_33_VERIFICATION.md)

---

**Last Updated:** November 2025  
**Status:** ✅ Ready for Testing
