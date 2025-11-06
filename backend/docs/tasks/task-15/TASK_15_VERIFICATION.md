# Task 15 Verification Guide

## Quick Verification Steps

### 1. File Structure Check

Verify all files exist:
```bash
# Models
ls backend/internal/models/booking.go

# Repository
ls backend/internal/repository/booking_repository.go

# Service
ls backend/internal/service/booking_service.go

# Handlers
ls backend/internal/handlers/booking_handler.go

# Documentation
ls backend/TEST_BOOKING_MODULE.md
ls backend/BOOKING_MODULE_POSTMAN.json
ls backend/BOOKING_QUICK_REFERENCE.md
ls TASK_15_COMPLETION.md
```

### 2. Code Compilation Check

```bash
cd backend
go mod tidy
go build -o bin/server ./cmd/server
```

Expected: No compilation errors

### 3. Database Prerequisites

Ensure these migrations are applied:
```sql
-- Check migrations
SELECT * FROM schema_migrations ORDER BY version;

-- Should include:
-- 001 - Guests tables
-- 002 - Room management
-- 003 - Pricing & inventory
-- 004 - Bookings tables
-- 005 - create_booking_hold function
-- 006 - confirm_booking function
-- 007 - cancel_booking functions
-- 008 - release_expired_holds function
```

### 4. Seed Data Check

Verify required data exists:
```sql
-- Check rate plans
SELECT * FROM rate_plans;

-- Check rate tiers
SELECT * FROM rate_tiers;

-- Check pricing calendar (should have future dates)
SELECT * FROM pricing_calendar WHERE date >= CURRENT_DATE LIMIT 10;

-- Check rate pricing
SELECT * FROM rate_pricing;

-- Check cancellation policies
SELECT * FROM cancellation_policies;

-- Check room types
SELECT * FROM room_types;

-- Check room inventory
SELECT * FROM room_inventory WHERE date >= CURRENT_DATE LIMIT 10;
```

### 5. API Endpoint Verification

Start the server:
```bash
cd backend
go run cmd/server/main.go
```

Test endpoints:

#### Health Check
```bash
curl http://localhost:8080/health
# Expected: {"status":"ok","message":"Hotel Booking System API is running"}
```

#### Register User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "email": "test@example.com",
    "phone": "1234567890",
    "password": "password123"
  }'
# Expected: 201 Created with user data
```

#### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
# Expected: 200 OK with accessToken
# Save the token for next requests
```

#### Create Booking Hold
```bash
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test-session-123",
    "room_type_id": 1,
    "check_in": "2025-12-01",
    "check_out": "2025-12-03"
  }'
# Expected: 200 OK with hold_id and success: true
```

#### Create Booking (requires token)
```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "session_id": "test-session-123",
    "details": [
      {
        "room_type_id": 1,
        "rate_plan_id": 1,
        "check_in": "2025-12-01",
        "check_out": "2025-12-03",
        "num_guests": 2,
        "guests": [
          {
            "first_name": "John",
            "last_name": "Doe",
            "type": "Adult",
            "is_primary": true
          }
        ]
      }
    ]
  }'
# Expected: 201 Created with booking_id
```

#### Get Bookings
```bash
curl -X GET http://localhost:8080/api/bookings \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
# Expected: 200 OK with bookings array
```

#### Get Booking by ID
```bash
curl -X GET http://localhost:8080/api/bookings/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
# Expected: 200 OK with booking details
```

#### Confirm Booking
```bash
curl -X POST http://localhost:8080/api/bookings/1/confirm \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "booking_id": 1,
    "payment_method": "credit_card",
    "payment_id": "pay_test_123"
  }'
# Expected: 200 OK with success: true
```

#### Cancel Booking
```bash
curl -X POST http://localhost:8080/api/bookings/1/cancel \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "booking_id": 1,
    "reason": "Testing cancellation"
  }'
# Expected: 200 OK with success: true and refund_amount
```

### 6. Database State Verification

After each operation, verify database state:

#### After Hold Creation
```sql
-- Check hold was created
SELECT * FROM booking_holds WHERE session_id = 'test-session-123';

-- Check tentative_count increased
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
  AND date BETWEEN '2025-12-01' AND '2025-12-03';
```

#### After Booking Creation
```sql
-- Check booking
SELECT * FROM bookings WHERE booking_id = 1;

-- Check booking details
SELECT * FROM booking_details WHERE booking_id = 1;

-- Check guests
SELECT * FROM booking_guests WHERE booking_detail_id = 1;

-- Check nightly logs
SELECT * FROM booking_nightly_log WHERE booking_detail_id = 1;
```

#### After Confirmation
```sql
-- Check booking status
SELECT status FROM bookings WHERE booking_id = 1;
-- Expected: 'Confirmed'

-- Check inventory (tentative should decrease, booked should increase)
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
  AND date BETWEEN '2025-12-01' AND '2025-12-03';

-- Check holds were deleted
SELECT * FROM booking_holds WHERE session_id = 'test-session-123';
-- Expected: No rows
```

#### After Cancellation
```sql
-- Check booking status
SELECT status FROM bookings WHERE booking_id = 1;
-- Expected: 'Cancelled'

-- Check inventory (booked_count should decrease)
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
  AND date BETWEEN '2025-12-01' AND '2025-12-03';
```

### 7. Error Handling Verification

Test error scenarios:

#### Invalid Date Format
```bash
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test",
    "room_type_id": 1,
    "check_in": "invalid-date",
    "check_out": "2025-12-03"
  }'
# Expected: 400 Bad Request
```

#### Unauthorized Access
```bash
curl -X GET http://localhost:8080/api/bookings
# Expected: 401 Unauthorized (no token)
```

#### Non-existent Booking
```bash
curl -X GET http://localhost:8080/api/bookings/99999 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
# Expected: 404 Not Found
```

#### Invalid Voucher
```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "session_id": "test",
    "voucher_code": "INVALID_CODE",
    "details": [...]
  }'
# Expected: 400 Bad Request with error message
```

### 8. Postman Collection Test

1. Import `backend/BOOKING_MODULE_POSTMAN.json` into Postman
2. Set `base_url` variable to `http://localhost:8080`
3. Run the collection in order:
   - Auth → Register
   - Auth → Login (saves token automatically)
   - Room Search → Search Available Rooms
   - Booking Flow → Create Booking Hold
   - Booking Flow → Create Booking (saves booking_id)
   - Booking Flow → Confirm Booking
   - View Bookings → Get All Bookings
   - View Bookings → Get Booking by ID
   - Cancel Booking → Cancel Booking (optional)

### 9. Concurrent Booking Test

Test race condition handling:

```bash
# Run multiple holds simultaneously for the same room
for i in {1..5}; do
  curl -X POST http://localhost:8080/api/bookings/hold \
    -H "Content-Type: application/json" \
    -d "{
      \"session_id\": \"concurrent-test-$i\",
      \"room_type_id\": 1,
      \"check_in\": \"2025-12-10\",
      \"check_out\": \"2025-12-12\"
    }" &
done
wait

# Check inventory - should not exceed allotment
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
  AND date = '2025-12-10';
```

### 10. Integration Test Checklist

- [ ] All files compile without errors
- [ ] Server starts successfully
- [ ] Health check endpoint responds
- [ ] User registration works
- [ ] User login returns valid JWT
- [ ] Hold creation succeeds with available rooms
- [ ] Hold creation fails with unavailable rooms
- [ ] Booking creation succeeds with valid data
- [ ] Booking creation fails with invalid data
- [ ] Booking confirmation updates status correctly
- [ ] Booking confirmation updates inventory correctly
- [ ] Booking list returns user's bookings only
- [ ] Booking detail shows complete information
- [ ] Booking cancellation calculates refund correctly
- [ ] Booking cancellation restores inventory
- [ ] Authorization prevents accessing other users' bookings
- [ ] Voucher application works correctly
- [ ] Nightly pricing logs are created
- [ ] Policy snapshot is saved at booking time
- [ ] Database constraints prevent invalid data

### 11. Performance Check

```bash
# Test response times
time curl -X GET http://localhost:8080/api/bookings \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Should be < 100ms for typical queries
```

### 12. Code Quality Check

```bash
# Run Go vet
cd backend
go vet ./...

# Run Go fmt
go fmt ./...

# Check for common issues
golint ./... 2>/dev/null || echo "golint not installed"
```

## Success Criteria

✅ All files exist and compile
✅ All endpoints respond correctly
✅ Database operations are atomic
✅ Authorization works correctly
✅ Error handling is comprehensive
✅ Documentation is complete
✅ Postman collection runs successfully
✅ Race conditions are prevented
✅ Requirements are fully covered

## Troubleshooting

### Server won't start
- Check PostgreSQL is running
- Verify .env file has correct database credentials
- Check port 8080 is not in use

### Database errors
- Ensure all migrations are applied
- Verify seed data exists
- Check database connection string

### Authentication errors
- Verify JWT_SECRET is set in .env
- Check token format in Authorization header
- Ensure token hasn't expired

### Booking creation fails
- Verify rate plans exist
- Check pricing calendar has data
- Ensure room inventory has allotment

## Next Steps After Verification

1. ✅ Verify all tests pass
2. ✅ Document any issues found
3. ✅ Fix any bugs discovered
4. ✅ Commit code to repository
5. ⏭️ Proceed to Task 16 (Frontend Setup)

## Support

For issues or questions:
1. Check `TEST_BOOKING_MODULE.md` for detailed testing guide
2. Review `BOOKING_QUICK_REFERENCE.md` for API reference
3. Check `TASK_15_COMPLETION.md` for implementation details
4. Review PostgreSQL function documentation in `database/migrations/`
