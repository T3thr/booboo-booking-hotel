# Pricing Management Module - Quick Reference

## Overview

The Pricing Management Module provides comprehensive APIs for hotel managers to manage:
- **Rate Tiers**: Seasonal pricing levels (Low Season, High Season, Peak Season)
- **Pricing Calendar**: Assign rate tiers to specific dates
- **Rate Pricing Matrix**: Set prices for each combination of rate plan, room type, and rate tier

## Requirements Covered

- **14.1-14.7**: Rate Tier & Pricing Calendar Management
- **15.1-15.7**: Rate Plan & Pricing Configuration

## Architecture

```
┌─────────────────┐
│  Pricing Handler│
└────────┬────────┘
         │
┌────────▼────────┐
│ Pricing Service │
└────────┬────────┘
         │
┌────────▼────────────┐
│ Pricing Repository  │
└────────┬────────────┘
         │
┌────────▼────────┐
│   PostgreSQL    │
│  - rate_tiers   │
│  - pricing_cal  │
│  - rate_pricing │
└─────────────────┘
```

## API Endpoints

### Rate Tier Management

#### 1. Get All Rate Tiers
```http
GET /api/pricing/tiers
Authorization: Bearer {manager_token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "rate_tier_id": 1,
      "name": "Low Season",
      "description": "ฤดูต่ำ - ราคาพิเศษสำหรับช่วงที่มีผู้เข้าพักน้อย",
      "display_order": 1,
      "color_code": "#4CAF50",
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### 2. Get Rate Tier by ID
```http
GET /api/pricing/tiers/:id
Authorization: Bearer {manager_token}
```

#### 3. Create Rate Tier
```http
POST /api/pricing/tiers
Authorization: Bearer {manager_token}
Content-Type: application/json

{
  "name": "Super Peak Season",
  "description": "ฤดูสูงสุดพิเศษ",
  "display_order": 5,
  "color_code": "#FF0000"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Rate tier created successfully",
  "data": {
    "rate_tier_id": 5,
    "name": "Super Peak Season",
    ...
  }
}
```

#### 4. Update Rate Tier
```http
PUT /api/pricing/tiers/:id
Authorization: Bearer {manager_token}
Content-Type: application/json

{
  "description": "Updated description",
  "color_code": "#FF5722",
  "is_active": true
}
```

### Pricing Calendar Management

#### 5. Get Pricing Calendar
```http
GET /api/pricing/calendar?start_date=2024-01-01&end_date=2024-12-31
Authorization: Bearer {manager_token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "date": "2024-01-01T00:00:00Z",
      "rate_tier_id": 4,
      "rate_tier": {
        "rate_tier_id": 4,
        "name": "Peak Season",
        "color_code": "#F44336"
      },
      "notes": "ช่วงปีใหม่",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### 6. Update Pricing Calendar
```http
PUT /api/pricing/calendar
Authorization: Bearer {manager_token}
Content-Type: application/json

{
  "start_date": "2024-12-20",
  "end_date": "2024-12-31",
  "rate_tier_id": 4,
  "notes": "ช่วงปีใหม่"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Pricing calendar updated successfully"
}
```

### Rate Pricing Matrix Management

#### 7. Get All Rate Pricing
```http
GET /api/pricing/rates
Authorization: Bearer {manager_token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "rate_plan_id": 1,
      "rate_plan_name": "Standard Rate",
      "room_type_id": 1,
      "room_type_name": "Standard Room",
      "rate_tier_id": 1,
      "rate_tier_name": "Low Season",
      "price": 1200.00,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### 8. Get Rate Pricing by Plan
```http
GET /api/pricing/rates/plan/:planId
Authorization: Bearer {manager_token}
```

#### 9. Update Single Rate Pricing
```http
PUT /api/pricing/rates
Authorization: Bearer {manager_token}
Content-Type: application/json

{
  "rate_plan_id": 1,
  "room_type_id": 1,
  "rate_tier_id": 1,
  "price": 1500.00
}
```

**Response:**
```json
{
  "success": true,
  "message": "Rate pricing updated successfully"
}
```

#### 10. Bulk Update Rate Pricing
```http
POST /api/pricing/rates/bulk
Authorization: Bearer {manager_token}
Content-Type: application/json

{
  "rate_plan_id": 1,
  "adjustment_type": "percentage",
  "adjustment_value": 10.0,
  "room_type_ids": [1, 2, 3],
  "rate_tier_ids": [1, 2]
}
```

**Adjustment Types:**
- `percentage`: Increase/decrease by percentage (e.g., 10 = +10%, -15 = -15%)
- `fixed`: Increase/decrease by fixed amount (e.g., 500 = +500 baht, -200 = -200 baht)

**Response:**
```json
{
  "success": true,
  "message": "Rate pricing bulk updated successfully"
}
```

#### 11. Get All Rate Plans
```http
GET /api/pricing/plans
Authorization: Bearer {manager_token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "rate_plan_id": 1,
      "name": "Standard Rate",
      "description": "แผนราคามาตรฐาน - ยกเลิกฟรีได้จนถึง 24 ชั่วโมงก่อนเช็คอิน",
      "policy_id": 1,
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Authorization

All pricing endpoints require:
1. Valid JWT token in Authorization header
2. User role must be `manager`

**Example:**
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Error Response (403 Forbidden):**
```json
{
  "success": false,
  "error": "Insufficient permissions"
}
```

## Database Schema

### rate_tiers
```sql
CREATE TABLE rate_tiers (
    rate_tier_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    display_order INT NOT NULL DEFAULT 0,
    color_code VARCHAR(7),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### pricing_calendar
```sql
CREATE TABLE pricing_calendar (
    date DATE PRIMARY KEY,
    rate_tier_id INT NOT NULL REFERENCES rate_tiers(rate_tier_id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### rate_pricing
```sql
CREATE TABLE rate_pricing (
    rate_plan_id INT NOT NULL REFERENCES rate_plans(rate_plan_id),
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id),
    rate_tier_id INT NOT NULL REFERENCES rate_tiers(rate_tier_id),
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (rate_plan_id, room_type_id, rate_tier_id)
);
```

## Testing

### Run Test Script
```powershell
cd backend
.\test_pricing_module.ps1
```

### Manual Testing with curl

1. **Login as Manager:**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"Manager123!"}'
```

2. **Get Rate Tiers:**
```bash
curl -X GET http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer YOUR_TOKEN"
```

3. **Update Pricing Calendar:**
```bash
curl -X PUT http://localhost:8080/api/pricing/calendar \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2024-12-20",
    "end_date": "2024-12-31",
    "rate_tier_id": 4,
    "notes": "ช่วงปีใหม่"
  }'
```

4. **Bulk Update Pricing (10% increase):**
```bash
curl -X POST http://localhost:8080/api/pricing/rates/bulk \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rate_plan_id": 1,
    "adjustment_type": "percentage",
    "adjustment_value": 10.0,
    "room_type_ids": [1, 2, 3],
    "rate_tier_ids": [1, 2, 3, 4]
  }'
```

## Common Use Cases

### 1. Set Peak Season Pricing for New Year
```json
PUT /api/pricing/calendar
{
  "start_date": "2024-12-25",
  "end_date": "2025-01-05",
  "rate_tier_id": 4,
  "notes": "ช่วงปีใหม่"
}
```

### 2. Increase All Prices by 15%
```json
POST /api/pricing/rates/bulk
{
  "rate_plan_id": 1,
  "adjustment_type": "percentage",
  "adjustment_value": 15.0
}
```

### 3. Set Weekend Pricing
```json
PUT /api/pricing/calendar
{
  "start_date": "2024-01-06",
  "end_date": "2024-01-07",
  "rate_tier_id": 3,
  "notes": "วันหยุดสุดสัปดาห์"
}
```

### 4. Create Special Event Tier
```json
POST /api/pricing/tiers
{
  "name": "Special Event",
  "description": "ราคาพิเศษสำหรับงานอีเวนต์",
  "display_order": 5,
  "color_code": "#9C27B0"
}
```

## Error Handling

### Common Errors

**400 Bad Request:**
```json
{
  "success": false,
  "error": "Invalid request body",
  "details": "end date must be after start date"
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "error": "Invalid or expired token"
}
```

**403 Forbidden:**
```json
{
  "success": false,
  "error": "Insufficient permissions"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "error": "Rate tier not found"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "error": "Failed to update rate pricing",
  "details": "database connection error"
}
```

## Best Practices

1. **Always validate dates** before updating pricing calendar
2. **Use bulk updates** for efficiency when changing multiple prices
3. **Set color codes** for better visual representation in UI
4. **Add notes** to pricing calendar for special events/holidays
5. **Test pricing changes** in a staging environment first
6. **Keep display_order** consistent for proper tier ordering
7. **Use percentage adjustments** for seasonal price changes
8. **Backup pricing data** before major changes

## Integration with Booking System

The pricing module integrates with the booking system through:

1. **Room Search**: Uses `pricing_calendar` and `rate_pricing` to calculate prices
2. **Booking Creation**: Stores snapshot of pricing at booking time
3. **Rate Plans**: Links to cancellation policies

**Price Calculation Flow:**
```
1. User searches for rooms (check-in to check-out dates)
2. System queries pricing_calendar for each date
3. Gets rate_tier_id for each date
4. Joins with rate_pricing to get price per night
5. Sums up total price for the stay
```

## Next Steps

1. Implement frontend UI for pricing management
2. Add price history tracking
3. Implement price comparison reports
4. Add automated pricing rules (e.g., dynamic pricing)
5. Create pricing templates for quick setup

## Support

For issues or questions:
- Check the test script output
- Review the error messages
- Verify manager role is assigned correctly
- Check database constraints

## Related Documentation

- [Requirements Document](../../.kiro/specs/hotel-reservation-system/requirements.md)
- [Design Document](../../.kiro/specs/hotel-reservation-system/design.md)
- [Database Schema](../../database/migrations/003_create_pricing_inventory_tables.sql)
- [API Router](../internal/router/router.go)
