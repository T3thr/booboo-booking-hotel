# Reporting Module - Quick Reference

## Overview

The Reporting Module provides comprehensive analytics and reporting capabilities for the hotel booking system. It includes occupancy reports, revenue analysis, voucher usage tracking, no-show statistics, and CSV export functionality.

## Architecture

```
┌─────────────────┐
│  Report Handler │ ← HTTP Layer (Gin)
└────────┬────────┘
         │
┌────────▼────────┐
│ Report Service  │ ← Business Logic
└────────┬────────┘
         │
┌────────▼────────┐
│Report Repository│ ← Data Access (PostgreSQL)
└─────────────────┘
```

## API Endpoints

All reporting endpoints require Manager role authentication.

### 1. Occupancy Report

**Endpoint:** `GET /api/reports/occupancy`

**Description:** Retrieve occupancy statistics for a date range.

**Query Parameters:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format
- `room_type_id` (optional): Filter by specific room type
- `group_by` (optional): Group by day, week, or month (default: day)

**Response:**
```json
{
  "data": [
    {
      "date": "2024-01-15T00:00:00Z",
      "room_type_id": 1,
      "room_type_name": "Deluxe Room",
      "total_rooms": 20,
      "booked_rooms": 15,
      "occupancy_rate": 75.00,
      "available_rooms": 5
    }
  ],
  "start_date": "2024-01-01",
  "end_date": "2024-01-31",
  "group_by": "day"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8080/api/reports/occupancy?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Revenue Report

**Endpoint:** `GET /api/reports/revenue`

**Description:** Retrieve revenue statistics and ADR (Average Daily Rate) for a date range.

**Query Parameters:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format
- `room_type_id` (optional): Filter by specific room type
- `rate_plan_id` (optional): Filter by specific rate plan
- `group_by` (optional): Group by day, week, or month (default: day)

**Response:**
```json
{
  "data": [
    {
      "date": "2024-01-15T00:00:00Z",
      "room_type_id": 1,
      "room_type_name": "Deluxe Room",
      "rate_plan_id": 1,
      "rate_plan_name": "Standard Rate",
      "total_revenue": 15000.00,
      "booking_count": 10,
      "room_nights": 30,
      "adr": 500.00
    }
  ],
  "start_date": "2024-01-01",
  "end_date": "2024-01-31",
  "group_by": "day"
}
```

**Calculations:**
- **ADR (Average Daily Rate)** = Total Revenue / Room Nights
- Only includes bookings with status: Confirmed, CheckedIn, or Completed

**Example:**
```bash
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-01-31&group_by=week" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Voucher Report

**Endpoint:** `GET /api/reports/vouchers`

**Description:** Retrieve voucher usage statistics and conversion rates.

**Query Parameters:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format

**Response:**
```json
{
  "data": [
    {
      "voucher_id": 1,
      "code": "SUMMER2024",
      "discount_type": "Percentage",
      "discount_value": 20.00,
      "total_uses": 45,
      "total_discount": 9000.00,
      "total_revenue": 45000.00,
      "conversion_rate": 45.00,
      "expiry_date": "2024-08-31T00:00:00Z"
    }
  ],
  "start_date": "2024-01-01",
  "end_date": "2024-01-31"
}
```

**Calculations:**
- **Conversion Rate** = (Total Uses / Max Uses) × 100
- **Total Discount** = Sum of all discounts applied using this voucher

**Example:**
```bash
curl -X GET "http://localhost:8080/api/reports/vouchers?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. No-Show Report

**Endpoint:** `GET /api/reports/no-shows`

**Description:** Retrieve no-show statistics with guest information and penalties.

**Query Parameters:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format

**Response:**
```json
{
  "data": [
    {
      "date": "2024-01-15T14:30:00Z",
      "booking_id": 123,
      "guest_name": "John Doe",
      "guest_email": "john@example.com",
      "guest_phone": "+1234567890",
      "room_type_name": "Deluxe Room",
      "check_in_date": "2024-01-15T00:00:00Z",
      "check_out_date": "2024-01-17T00:00:00Z",
      "total_amount": 1000.00,
      "penalty_charged": 500.00
    }
  ],
  "start_date": "2024-01-01",
  "end_date": "2024-01-31"
}
```

**Penalty Calculation:**
- Non-Refundable policies: 100% of total amount
- Other policies: 50% of total amount (default)

**Example:**
```bash
curl -X GET "http://localhost:8080/api/reports/no-shows?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. Report Summary

**Endpoint:** `GET /api/reports/summary`

**Description:** Retrieve aggregated statistics for a date range.

**Query Parameters:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format

**Response:**
```json
{
  "start_date": "2024-01-01T00:00:00Z",
  "end_date": "2024-01-31T00:00:00Z",
  "total_revenue": 150000.00,
  "total_bookings": 100,
  "total_room_nights": 300,
  "avg_occupancy": 75.50,
  "adr": 500.00,
  "no_show_count": 5,
  "no_show_rate": 5.00
}
```

**Calculations:**
- **Average Occupancy** = Average of daily occupancy rates
- **ADR** = Total Revenue / Total Room Nights
- **No-Show Rate** = (No-Show Count / Total Bookings) × 100

**Example:**
```bash
curl -X GET "http://localhost:8080/api/reports/summary?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 6. Comparison Report (Year-over-Year)

**Endpoint:** `GET /api/reports/comparison`

**Description:** Compare current period with the same period last year.

**Query Parameters:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format

**Response:**
```json
{
  "current_period": {
    "start_date": "2024-01-01T00:00:00Z",
    "end_date": "2024-01-31T00:00:00Z",
    "total_revenue": 150000.00,
    "total_bookings": 100,
    "total_room_nights": 300,
    "avg_occupancy": 75.50,
    "adr": 500.00,
    "no_show_count": 5,
    "no_show_rate": 5.00
  },
  "previous_period": {
    "start_date": "2023-01-01T00:00:00Z",
    "end_date": "2023-01-31T00:00:00Z",
    "total_revenue": 120000.00,
    "total_bookings": 90,
    "total_room_nights": 270,
    "avg_occupancy": 70.00,
    "adr": 444.44,
    "no_show_count": 8,
    "no_show_rate": 8.89
  },
  "revenue_change_percent": 25.00,
  "occupancy_change_percent": 7.86,
  "adr_change_percent": 12.50
}
```

**Example:**
```bash
curl -X GET "http://localhost:8080/api/reports/comparison?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## CSV Export Endpoints

All export endpoints return CSV files with appropriate headers.

### 1. Export Occupancy Report

**Endpoint:** `GET /api/reports/export/occupancy`

**Query Parameters:** Same as occupancy report

**Response:** CSV file with columns:
- Date
- Room Type
- Total Rooms
- Booked Rooms
- Occupancy Rate (%)
- Available Rooms

**Example:**
```bash
curl -X GET "http://localhost:8080/api/reports/export/occupancy?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -o occupancy_report.csv
```

### 2. Export Revenue Report

**Endpoint:** `GET /api/reports/export/revenue`

**Query Parameters:** Same as revenue report

**Response:** CSV file with columns:
- Date
- Room Type
- Rate Plan
- Total Revenue
- Booking Count
- Room Nights
- ADR

### 3. Export Voucher Report

**Endpoint:** `GET /api/reports/export/vouchers`

**Query Parameters:** Same as voucher report

**Response:** CSV file with columns:
- Code
- Discount Type
- Discount Value
- Total Uses
- Total Discount
- Total Revenue
- Conversion Rate (%)
- Expiry Date

### 4. Export No-Show Report

**Endpoint:** `GET /api/reports/export/no-shows`

**Query Parameters:** Same as no-show report

**Response:** CSV file with columns:
- Date
- Booking ID
- Guest Name
- Email
- Phone
- Room Type
- Check-in Date
- Check-out Date
- Total Amount
- Penalty Charged

## Code Structure

### Models (`internal/models/report.go`)

```go
type OccupancyReport struct {
    Date           time.Time
    RoomTypeID     *int
    RoomTypeName   *string
    TotalRooms     int
    BookedRooms    int
    OccupancyRate  float64
    AvailableRooms int
}

type RevenueReport struct {
    Date         time.Time
    RoomTypeID   *int
    RoomTypeName *string
    RatePlanID   *int
    RatePlanName *string
    TotalRevenue float64
    BookingCount int
    RoomNights   int
    ADR          float64
}

type VoucherReport struct {
    VoucherID      int
    Code           string
    DiscountType   string
    DiscountValue  float64
    TotalUses      int
    TotalDiscount  float64
    TotalRevenue   float64
    ConversionRate float64
    ExpiryDate     time.Time
}

type NoShowReport struct {
    Date           time.Time
    BookingID      int
    GuestName      string
    GuestEmail     string
    GuestPhone     string
    RoomTypeName   string
    CheckInDate    time.Time
    CheckOutDate   time.Time
    TotalAmount    float64
    PenaltyCharged float64
}

type ReportSummary struct {
    StartDate      time.Time
    EndDate        time.Time
    TotalRevenue   float64
    TotalBookings  int
    TotalRoomNights int
    AvgOccupancy   float64
    ADR            float64
    NoShowCount    int
    NoShowRate     float64
}

type ComparisonData struct {
    CurrentPeriod   ReportSummary
    PreviousPeriod  ReportSummary
    RevenueChange   float64
    OccupancyChange float64
    ADRChange       float64
}
```

### Repository Layer (`internal/repository/report_repository.go`)

Handles all database queries for reports using PostgreSQL with pgx driver.

Key methods:
- `GetOccupancyReport()` - Query room_inventory for occupancy data
- `GetRevenueReport()` - Query booking_nightly_log for revenue data
- `GetVoucherReport()` - Query vouchers and bookings for usage stats
- `GetNoShowReport()` - Query bookings with NoShow status
- `GetReportSummary()` - Aggregate statistics using CTEs

### Service Layer (`internal/service/report_service.go`)

Implements business logic and data transformations.

Key features:
- Date validation
- Grouping by week/month
- CSV export generation
- Year-over-year comparison calculations

### Handler Layer (`internal/handlers/report_handler.go`)

HTTP request handlers with Gin framework.

Features:
- Query parameter parsing
- Date format validation
- CSV file generation with proper headers
- Error handling

## Testing

Run the test script:

```powershell
.\test_report_module.ps1
```

The script tests:
1. Manager authentication
2. All report endpoints
3. Filtered reports
4. Grouped reports (weekly/monthly)
5. CSV exports
6. Year-over-year comparison

## Database Queries

### Occupancy Report Query

```sql
SELECT 
    ri.date,
    rt.room_type_id,
    rt.name as room_type_name,
    ri.allotment as total_rooms,
    ri.booked_count as booked_rooms,
    CASE 
        WHEN ri.allotment > 0 
        THEN (ri.booked_count::DECIMAL / ri.allotment::DECIMAL) * 100
        ELSE 0
    END as occupancy_rate,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available_rooms
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= $1 AND ri.date <= $2
ORDER BY ri.date, rt.name
```

### Revenue Report Query

```sql
SELECT 
    bnl.date,
    rt.room_type_id,
    rt.name as room_type_name,
    rp.rate_plan_id,
    rp.name as rate_plan_name,
    SUM(bnl.quoted_price) as total_revenue,
    COUNT(DISTINCT bd.booking_id) as booking_count,
    COUNT(bnl.booking_nightly_log_id) as room_nights,
    CASE 
        WHEN COUNT(bnl.booking_nightly_log_id) > 0 
        THEN SUM(bnl.quoted_price) / COUNT(bnl.booking_nightly_log_id)
        ELSE 0
    END as adr
FROM booking_nightly_log bnl
JOIN booking_details bd ON bnl.booking_detail_id = bd.booking_detail_id
JOIN bookings b ON bd.booking_id = b.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
WHERE bnl.date >= $1 AND bnl.date <= $2
  AND b.status IN ('Confirmed', 'CheckedIn', 'Completed')
GROUP BY bnl.date, rt.room_type_id, rt.name, rp.rate_plan_id, rp.name
ORDER BY bnl.date, rt.name
```

## Common Use Cases

### 1. Monthly Performance Review

```bash
# Get summary for current month
curl -X GET "http://localhost:8080/api/reports/summary?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Compare with last year
curl -X GET "http://localhost:8080/api/reports/comparison?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Weekly Revenue Analysis

```bash
# Get revenue grouped by week
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-03-31&group_by=week" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Room Type Performance

```bash
# Get revenue for specific room type
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-01-31&room_type_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Voucher Campaign Analysis

```bash
# Get voucher usage statistics
curl -X GET "http://localhost:8080/api/reports/vouchers?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. Export for Accounting

```bash
# Export revenue report to CSV
curl -X GET "http://localhost:8080/api/reports/export/revenue?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -o revenue_january_2024.csv
```

## Error Handling

All endpoints return appropriate HTTP status codes:

- `200 OK` - Successful request
- `400 Bad Request` - Invalid parameters (missing dates, invalid format)
- `401 Unauthorized` - Missing or invalid token
- `403 Forbidden` - Insufficient permissions (not a manager)
- `500 Internal Server Error` - Database or server error

Error response format:
```json
{
  "error": "start_date and end_date are required"
}
```

## Performance Considerations

1. **Date Range Limits**: Large date ranges may take longer to process
2. **Indexing**: Ensure proper indexes on date columns
3. **Caching**: Consider caching frequently accessed reports
4. **Pagination**: For very large datasets, consider implementing pagination

## Security

- All endpoints require authentication (JWT token)
- Only users with "manager" role can access reports
- SQL injection protection through parameterized queries
- No sensitive data exposure in error messages

## Future Enhancements

Potential improvements:
- PDF export support
- Scheduled report generation
- Email delivery of reports
- Custom date range presets (last 7 days, last month, etc.)
- Real-time dashboard updates
- More granular filtering options
- Forecasting and predictive analytics
