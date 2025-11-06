# Task 30: Pricing Management Module - Verification Checklist

## Pre-requisites

Before testing, ensure:
- [ ] PostgreSQL is running
- [ ] Database migrations are applied (001-004)
- [ ] Go backend server is running
- [ ] Manager account exists in database

### Create Manager Account (if needed)

```sql
-- First, create a guest record
INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Hotel', 'Manager', 'manager@hotel.com', '0812345678')
ON CONFLICT (email) DO NOTHING;

-- Then create the account with manager role
-- Password: Manager123! (hashed with bcrypt)
INSERT INTO guest_accounts (guest_id, hashed_password, role)
SELECT 
    guest_id, 
    '$2a$10$YourHashedPasswordHere',
    'manager'
FROM guests 
WHERE email = 'manager@hotel.com'
ON CONFLICT (guest_id) DO UPDATE SET role = 'manager';
```

## Verification Steps

### Step 1: Code Structure ✅

Verify all files are created:
- [x] `backend/internal/models/pricing.go`
- [x] `backend/internal/repository/pricing_repository.go`
- [x] `backend/internal/service/pricing_service.go`
- [x] `backend/internal/handlers/pricing_handler.go`
- [x] `backend/internal/router/router.go` (updated)
- [x] `backend/test_pricing_module.ps1`
- [x] `backend/PRICING_MODULE_REFERENCE.md`
- [x] `backend/TASK_30_SUMMARY.md`

### Step 2: Build Verification

```bash
cd backend
go build -o bin/server ./cmd/server
```

Expected: No compilation errors

### Step 3: Start Server

```bash
cd backend
go run cmd/server/main.go
```

Expected output:
```
Server starting on :8080
Database connected successfully
```

### Step 4: Run Automated Tests

```powershell
cd backend
.\test_pricing_module.ps1
```

Expected results:
- ✅ Login as Manager
- ✅ Get All Rate Tiers
- ✅ Create New Rate Tier
- ✅ Update Rate Tier
- ✅ Get Pricing Calendar
- ✅ Update Pricing Calendar
- ✅ Get All Rate Plans
- ✅ Get All Rate Pricing (Matrix)
- ✅ Get Rate Pricing by Plan
- ✅ Update Single Rate Pricing
- ✅ Bulk Update Rate Pricing
- ✅ Test Authorization

### Step 5: Manual API Testing

#### 5.1 Login as Manager
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "manager@hotel.com",
    "password": "Manager123!"
  }'
```

Expected: 200 OK with token

#### 5.2 Get Rate Tiers
```bash
curl -X GET http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: 200 OK with list of rate tiers (4 tiers)

#### 5.3 Create Rate Tier
```bash
curl -X POST http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Season",
    "description": "Test tier",
    "display_order": 99,
    "color_code": "#9C27B0"
  }'
```

Expected: 201 Created with new tier data

#### 5.4 Get Pricing Calendar
```bash
curl -X GET "http://localhost:8080/api/pricing/calendar?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: 200 OK with calendar data for January

#### 5.5 Update Pricing Calendar
```bash
curl -X PUT http://localhost:8080/api/pricing/calendar \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2024-12-25",
    "end_date": "2024-12-31",
    "rate_tier_id": 4,
    "notes": "ช่วงปีใหม่"
  }'
```

Expected: 200 OK with success message

#### 5.6 Get Rate Pricing Matrix
```bash
curl -X GET http://localhost:8080/api/pricing/rates \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: 200 OK with pricing matrix (24+ entries)

#### 5.7 Update Single Rate Pricing
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

Expected: 200 OK with success message

#### 5.8 Bulk Update Rate Pricing
```bash
curl -X POST http://localhost:8080/api/pricing/rates/bulk \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rate_plan_id": 1,
    "adjustment_type": "percentage",
    "adjustment_value": 10.0,
    "room_type_ids": [1, 2],
    "rate_tier_ids": [1, 2]
  }'
```

Expected: 200 OK with success message

#### 5.9 Test Authorization (Guest Access)
```bash
# Login as guest
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "Password123!"
  }'

# Try to access pricing with guest token
curl -X GET http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer GUEST_TOKEN"
```

Expected: 403 Forbidden

### Step 6: Database Verification

#### 6.1 Check Rate Tiers
```sql
SELECT * FROM rate_tiers ORDER BY display_order;
```

Expected: At least 4 rate tiers (Low, Standard, High, Peak)

#### 6.2 Check Pricing Calendar
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

Expected: Calendar entries with tier assignments

#### 6.3 Check Rate Pricing Matrix
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

Expected: Complete pricing matrix (2 plans × 3 room types × 4 tiers = 24 entries)

### Step 7: Integration Testing

#### 7.1 Room Search with Pricing
```bash
curl -X GET "http://localhost:8080/api/rooms/search?checkIn=2024-12-25&checkOut=2024-12-27&guests=2"
```

Expected: Room search results should include prices calculated from the pricing matrix

#### 7.2 Verify Price Calculation
- Check that prices match the rate tier assigned to the dates
- Verify total price is sum of nightly prices

### Step 8: Error Handling

#### 8.1 Invalid Date Range
```bash
curl -X GET "http://localhost:8080/api/pricing/calendar?start_date=2024-12-31&end_date=2024-01-01" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: 400 Bad Request - "end date must be after start date"

#### 8.2 Invalid Color Code
```bash
curl -X POST http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Invalid Tier",
    "color_code": "INVALID"
  }'
```

Expected: 500 Internal Server Error - "invalid color code format"

#### 8.3 Negative Price
```bash
curl -X PUT http://localhost:8080/api/pricing/rates \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rate_plan_id": 1,
    "room_type_id": 1,
    "rate_tier_id": 1,
    "price": -100.00
  }'
```

Expected: 400 Bad Request - validation error

#### 8.4 Missing Authorization
```bash
curl -X GET http://localhost:8080/api/pricing/tiers
```

Expected: 401 Unauthorized

### Step 9: Performance Testing

#### 9.1 Large Date Range
```bash
curl -X GET "http://localhost:8080/api/pricing/calendar?start_date=2024-01-01&end_date=2024-12-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Expected: Response within 1 second for 365 days

#### 9.2 Bulk Update Performance
```bash
curl -X POST http://localhost:8080/api/pricing/rates/bulk \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rate_plan_id": 1,
    "adjustment_type": "percentage",
    "adjustment_value": 5.0
  }'
```

Expected: Updates all prices in single transaction, response within 500ms

## Requirements Verification

### Requirement 14.1: Manager creates rate tiers
- [ ] Can create new rate tier via POST /api/pricing/tiers
- [ ] Tier includes name, description, display order, color code
- [ ] Validation works correctly

### Requirement 14.2: Manager assigns tiers to dates
- [ ] Can update pricing calendar via PUT /api/pricing/calendar
- [ ] Can assign tier to date range
- [ ] Changes are reflected immediately

### Requirement 14.3: System displays pricing calendar
- [ ] Can retrieve calendar via GET /api/pricing/calendar
- [ ] Includes tier information with color codes
- [ ] Date range filtering works

### Requirement 14.4: Bulk assign tiers
- [ ] Single API call updates multiple dates
- [ ] Uses generate_series for efficiency
- [ ] Transaction ensures atomicity

### Requirement 14.5: Default tier handling
- [ ] System uses Standard tier if not assigned
- [ ] No errors for missing calendar entries

### Requirement 14.6: Prevent tier deletion
- [ ] Database constraint prevents deletion of tiers in use
- [ ] Proper error message returned

### Requirement 14.7: Copy from previous year
- [ ] (Future enhancement - not implemented yet)

### Requirement 15.1: Manager creates rate plans
- [ ] Can retrieve rate plans via GET /api/pricing/plans
- [ ] Plans include cancellation policy reference

### Requirement 15.2: Set prices for combinations
- [ ] Can update single price via PUT /api/pricing/rates
- [ ] Supports all combinations (plan × room × tier)
- [ ] Upsert functionality works

### Requirement 15.3: Calculate nightly price
- [ ] Room search uses pricing matrix
- [ ] Joins calendar, tiers, and pricing correctly
- [ ] Total price is sum of nightly prices

### Requirement 15.4: Show "price not available"
- [ ] (Handled in room search module)

### Requirement 15.5: View pricing matrix
- [ ] Can retrieve full matrix via GET /api/pricing/rates
- [ ] Can filter by rate plan
- [ ] Includes all related entity names

### Requirement 15.6: Bulk update prices
- [ ] Percentage adjustment works
- [ ] Fixed amount adjustment works
- [ ] Can filter by room types and tiers
- [ ] Single transaction ensures consistency

### Requirement 15.7: Highlight unconfigured prices
- [ ] (Frontend feature - API provides data)

## Common Issues & Solutions

### Issue 1: Manager account not found
**Solution:** Run the SQL script to create manager account

### Issue 2: 403 Forbidden
**Solution:** Verify user role is 'manager' in database

### Issue 3: Invalid token
**Solution:** Login again to get fresh token

### Issue 4: Database connection error
**Solution:** Check PostgreSQL is running and .env is configured

### Issue 5: Compilation errors
**Solution:** Run `go mod tidy` to download dependencies

## Success Criteria

All checks must pass:
- [x] All files created
- [ ] Code compiles without errors
- [ ] Server starts successfully
- [ ] All automated tests pass
- [ ] Manual API tests return expected results
- [ ] Database queries show correct data
- [ ] Authorization works correctly
- [ ] Error handling is appropriate
- [ ] Performance is acceptable
- [ ] All requirements are met

## Sign-off

- [ ] Developer tested all endpoints
- [ ] Code reviewed
- [ ] Documentation complete
- [ ] Ready for frontend integration

**Tested by:** _________________  
**Date:** _________________  
**Status:** ☐ Pass ☐ Fail  
**Notes:** _________________
