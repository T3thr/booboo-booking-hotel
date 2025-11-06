# Task 30: Pricing Management Module - Quick Start Guide

## Overview

This guide will help you quickly test the Pricing Management Module.

## Prerequisites

1. **PostgreSQL running** with database created
2. **Migrations applied** (001-004)
3. **Backend server running** on port 8080
4. **Manager account created** in database

## Quick Setup

### 1. Create Manager Account

```sql
-- Connect to your database
psql -U postgres -d hotel_booking

-- Create manager account
INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Hotel', 'Manager', 'manager@hotel.com', '0812345678')
ON CONFLICT (email) DO NOTHING;

-- Hash password "Manager123!" using bcrypt
-- You can use: https://bcrypt-generator.com/
-- Or run this in Go: bcrypt.GenerateFromPassword([]byte("Manager123!"), bcrypt.DefaultCost)

INSERT INTO guest_accounts (guest_id, hashed_password, role)
SELECT 
    guest_id, 
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- Manager123!
    'manager'
FROM guests 
WHERE email = 'manager@hotel.com'
ON CONFLICT (guest_id) DO UPDATE SET role = 'manager';
```

### 2. Start Backend Server

```bash
cd backend
go run cmd/server/main.go
```

Wait for: `Server starting on :8080`

### 3. Run Automated Tests

```powershell
cd backend
.\test_pricing_module.ps1
```

## Quick Test with curl

### Step 1: Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"Manager123!"}'
```

Copy the token from response.

### Step 2: Get Rate Tiers
```bash
curl -X GET http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Step 3: Get Pricing Calendar
```bash
curl -X GET "http://localhost:8080/api/pricing/calendar?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Step 4: Get Rate Pricing Matrix
```bash
curl -X GET http://localhost:8080/api/pricing/rates \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Quick Test with PowerShell

```powershell
# Login
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
  -Method POST `
  -Body '{"email":"manager@hotel.com","password":"Manager123!"}' `
  -ContentType "application/json"

$token = $loginResponse.data.token
$headers = @{"Authorization" = "Bearer $token"}

# Get rate tiers
$tiers = Invoke-RestMethod -Uri "http://localhost:8080/api/pricing/tiers" `
  -Method GET -Headers $headers

$tiers.data | Format-Table

# Get pricing calendar
$calendar = Invoke-RestMethod -Uri "http://localhost:8080/api/pricing/calendar?start_date=2024-01-01&end_date=2024-01-31" `
  -Method GET -Headers $headers

$calendar.data | Select-Object -First 10 | Format-Table

# Get rate pricing
$pricing = Invoke-RestMethod -Uri "http://localhost:8080/api/pricing/rates" `
  -Method GET -Headers $headers

$pricing.data | Format-Table
```

## Common Operations

### Create New Rate Tier
```bash
curl -X POST http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Special Event",
    "description": "ราคาพิเศษสำหรับงานอีเวนต์",
    "display_order": 5,
    "color_code": "#9C27B0"
  }'
```

### Update Pricing Calendar for New Year
```bash
curl -X PUT http://localhost:8080/api/pricing/calendar \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2024-12-25",
    "end_date": "2025-01-05",
    "rate_tier_id": 4,
    "notes": "ช่วงปีใหม่"
  }'
```

### Increase All Prices by 10%
```bash
curl -X POST http://localhost:8080/api/pricing/rates/bulk \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rate_plan_id": 1,
    "adjustment_type": "percentage",
    "adjustment_value": 10.0
  }'
```

### Update Single Price
```bash
curl -X PUT http://localhost:8080/api/pricing/rates \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rate_plan_id": 1,
    "room_type_id": 1,
    "rate_tier_id": 1,
    "price": 1500.00
  }'
```

## Verify Results

### Check Rate Tiers in Database
```sql
SELECT * FROM rate_tiers ORDER BY display_order;
```

### Check Pricing Calendar
```sql
SELECT 
    pc.date,
    rt.name as tier_name,
    pc.notes
FROM pricing_calendar pc
JOIN rate_tiers rt ON pc.rate_tier_id = rt.rate_tier_id
WHERE pc.date >= CURRENT_DATE
ORDER BY pc.date
LIMIT 10;
```

### Check Rate Pricing Matrix
```sql
SELECT 
    rpl.name as rate_plan,
    rt.name as room_type,
    tier.name as rate_tier,
    rp.price
FROM rate_pricing rp
JOIN rate_plans rpl ON rp.rate_plan_id = rpl.rate_plan_id
JOIN room_types rt ON rp.room_type_id = rt.room_type_id
JOIN rate_tiers tier ON rp.rate_tier_id = tier.rate_tier_id
ORDER BY rpl.name, rt.name, tier.display_order;
```

## Troubleshooting

### Problem: 401 Unauthorized
**Solution:** Token expired or invalid. Login again.

### Problem: 403 Forbidden
**Solution:** User is not a manager. Check role in database:
```sql
SELECT g.email, ga.role 
FROM guests g 
JOIN guest_accounts ga ON g.guest_id = ga.guest_id 
WHERE g.email = 'manager@hotel.com';
```

### Problem: 404 Not Found
**Solution:** Check the endpoint URL is correct.

### Problem: 500 Internal Server Error
**Solution:** Check server logs for details. Common causes:
- Database connection issue
- Invalid foreign key reference
- Constraint violation

### Problem: Manager account doesn't exist
**Solution:** Run the SQL script in step 1 again.

## Next Steps

1. ✅ Test all endpoints
2. ✅ Verify data in database
3. 📝 Review API documentation in `PRICING_MODULE_REFERENCE.md`
4. 🎨 Integrate with frontend
5. 📊 Create pricing management UI

## API Documentation

For complete API documentation, see:
- `backend/PRICING_MODULE_REFERENCE.md` - Full API reference
- `backend/TASK_30_SUMMARY.md` - Implementation summary
- `backend/TASK_30_VERIFICATION.md` - Verification checklist

## Support

If you encounter issues:
1. Check server logs
2. Verify database connection
3. Confirm manager role is set
4. Review error messages
5. Check the verification checklist

## Success Indicators

✅ All tests pass  
✅ Can create/update rate tiers  
✅ Can update pricing calendar  
✅ Can update rate pricing matrix  
✅ Authorization works correctly  
✅ Data persists in database  

## Time Estimate

- Setup: 5 minutes
- Testing: 10 minutes
- Verification: 5 minutes
- **Total: ~20 minutes**

Happy testing! 🎉
