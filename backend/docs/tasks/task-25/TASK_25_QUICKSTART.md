# Task 25: Check-in/Check-out Module - Quick Start Guide

## Overview

This guide will help you quickly get started with the Check-in/Check-out Module backend implementation.

## Prerequisites

1. **Database Setup**
   - PostgreSQL 15+ running
   - Migrations 001-011 applied (includes check_in, check_out, move_room functions)
   - Test data loaded

2. **Backend Running**
   ```bash
   cd backend
   go run cmd/server/main.go
   ```

3. **Receptionist Account**
   Create a receptionist account if not exists:
   ```sql
   -- First, create a guest record
   INSERT INTO guests (first_name, last_name, email, phone)
   VALUES ('Front', 'Desk', 'receptionist@hotel.com', '1234567890');

   -- Then create the account with receptionist role
   INSERT INTO guest_accounts (guest_id, hashed_password, role)
   VALUES (
     (SELECT guest_id FROM guests WHERE email = 'receptionist@hotel.com'),
     '$2a$10$YourHashedPasswordHere',  -- Use bcrypt to hash 'password123'
     'receptionist'
   );
   ```

## Quick Test (5 Minutes)

### Step 1: Login as Receptionist

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "receptionist@hotel.com",
    "password": "password123"
  }'
```

**Save the token:**
```bash
TOKEN="<your_token_here>"
```

### Step 2: View Today's Arrivals

```bash
curl -X GET "http://localhost:8080/api/checkin/arrivals" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "arrivals": [
    {
      "booking_id": 1,
      "booking_detail_id": 1,
      "guest_name": "John Doe",
      "room_type_name": "Deluxe Room",
      "check_in_date": "2024-01-15T00:00:00Z",
      "check_out_date": "2024-01-17T00:00:00Z",
      "num_guests": 2,
      "status": "Confirmed",
      "room_number": null
    }
  ],
  "count": 1
}
```

### Step 3: Get Available Rooms

```bash
curl -X GET "http://localhost:8080/api/checkin/available-rooms/1" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "rooms": [
    {
      "room_id": 1,
      "room_number": "101",
      "occupancy_status": "Vacant",
      "housekeeping_status": "Inspected"
    }
  ],
  "count": 1
}
```

### Step 4: Perform Check-in

```bash
curl -X POST http://localhost:8080/api/checkin \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking_detail_id": 1,
    "room_id": 1
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Check-in สำเร็จ",
  "room_number": "101"
}
```

### Step 5: View Today's Departures

```bash
curl -X GET "http://localhost:8080/api/checkout/departures" \
  -H "Authorization: Bearer $TOKEN"
```

### Step 6: Perform Check-out

```bash
curl -X POST http://localhost:8080/api/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": 1
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Check-out สำเร็จ",
  "total_amount": 3000.00
}
```

## Common Operations

### Move Guest to Another Room

```bash
curl -X POST http://localhost:8080/api/checkin/move-room \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_assignment_id": 1,
    "new_room_id": 2,
    "reason": "Air conditioning issue in original room"
  }'
```

### Mark Booking as No-Show

```bash
curl -X POST http://localhost:8080/api/bookings/1/no-show \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "notes": "Guest did not arrive by end of check-in day"
  }'
```

### Get Arrivals for Specific Date

```bash
curl -X GET "http://localhost:8080/api/checkin/arrivals?date=2024-01-20" \
  -H "Authorization: Bearer $TOKEN"
```

## Using PowerShell Test Script

Run the automated test script:

```powershell
cd backend
.\test_checkin_module.ps1
```

This script will:
1. Login as receptionist
2. Get today's arrivals
3. Get available rooms
4. Perform check-in (if data available)
5. Get today's departures
6. Perform check-out (if data available)
7. Test room move (if applicable)

## Troubleshooting

### Error: "No authorization header provided"
**Solution:** Make sure you include the Authorization header with Bearer token.

### Error: "Insufficient permissions"
**Solution:** Ensure the user has 'receptionist' role in the database.

### Error: "ห้องยังไม่พร้อมสำหรับ check-in"
**Solution:** The room must be Vacant and either Clean or Inspected. Check room status:
```sql
SELECT room_id, room_number, occupancy_status, housekeeping_status 
FROM rooms 
WHERE room_id = 1;
```

### Error: "Booking not found or cannot be marked as no-show"
**Solution:** Only Confirmed bookings can be marked as no-show. Check booking status:
```sql
SELECT booking_id, status FROM bookings WHERE booking_id = 1;
```

### Error: "Cannot check out booking with status: Confirmed"
**Solution:** Booking must be CheckedIn before check-out. Perform check-in first.

## Test Data Setup

If you need test data, run these SQL commands:

```sql
-- Create a confirmed booking for today
INSERT INTO bookings (guest_id, total_amount, status, policy_name, policy_description)
VALUES (1, 3000.00, 'Confirmed', 'Standard', 'Free cancellation up to 24 hours before check-in');

-- Create booking detail
INSERT INTO booking_details (booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests)
VALUES (
  (SELECT MAX(booking_id) FROM bookings),
  1,
  1,
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '2 days',
  2
);

-- Ensure you have a vacant and clean room
UPDATE rooms 
SET occupancy_status = 'Vacant', housekeeping_status = 'Inspected'
WHERE room_id = 1;
```

## API Endpoints Summary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/checkin` | POST | Check in a guest |
| `/api/checkout` | POST | Check out a guest |
| `/api/checkin/move-room` | POST | Move guest to another room |
| `/api/bookings/:id/no-show` | POST | Mark booking as no-show |
| `/api/checkin/arrivals` | GET | Get arrivals for a date |
| `/api/checkout/departures` | GET | Get departures for a date |
| `/api/checkin/available-rooms/:roomTypeId` | GET | Get available rooms |

## Next Steps

1. **Frontend Integration**
   - Create receptionist dashboard
   - Implement check-in/out UI
   - Add room status visualization

2. **Testing**
   - Run integration tests
   - Test error scenarios
   - Test concurrent operations

3. **Monitoring**
   - Add logging
   - Track metrics
   - Monitor errors

## Additional Resources

- **Full API Reference:** `CHECKIN_CHECKOUT_REFERENCE.md`
- **Implementation Summary:** `TASK_25_SUMMARY.md`
- **Verification Checklist:** `TASK_25_VERIFICATION.md`
- **Test Script:** `test_checkin_module.ps1`

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the full API reference
3. Check database logs for errors
4. Verify PostgreSQL functions are deployed

## Success Criteria

You've successfully set up the module when:
- ✅ You can login as receptionist
- ✅ You can view arrivals and departures
- ✅ You can perform check-in
- ✅ You can perform check-out
- ✅ Room statuses update correctly
- ✅ Booking statuses update correctly

Happy coding! 🎉
