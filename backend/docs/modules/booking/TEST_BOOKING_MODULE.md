# Booking Module Testing Guide

## Overview
This document provides instructions for testing the Booking Module implementation (Task 15).

## Components Implemented

### 1. Models (`internal/models/booking.go`)
- ✅ Booking
- ✅ BookingDetail
- ✅ BookingGuest
- ✅ BookingNightlyLog
- ✅ BookingHold
- ✅ RoomAssignment
- ✅ Voucher
- ✅ CancellationPolicy
- ✅ RatePlan
- ✅ Request/Response DTOs

### 2. Repository (`internal/repository/booking_repository.go`)
- ✅ CreateBookingHold - calls PostgreSQL function
- ✅ CreateBooking - creates booking record
- ✅ CreateBookingDetail - creates booking details
- ✅ CreateBookingGuest - creates guest records
- ✅ CreateBookingNightlyLog - creates nightly pricing logs
- ✅ ConfirmBooking - calls PostgreSQL function
- ✅ CancelBooking - calls appropriate PostgreSQL function
- ✅ GetBookingByID - retrieves booking with all details
- ✅ GetBookingsByGuestID - retrieves bookings for a guest
- ✅ GetVoucherByCode - retrieves and validates voucher
- ✅ IncrementVoucherUsage - increments voucher usage
- ✅ GetCancellationPolicy - retrieves policy
- ✅ GetRatePlan - retrieves rate plan

### 3. Service (`internal/service/booking_service.go`)
- ✅ CreateBookingHold - validates and creates hold
- ✅ CreateBooking - creates booking with all details
- ✅ ConfirmBooking - confirms pending booking
- ✅ CancelBooking - cancels booking with authorization
- ✅ GetBookingByID - retrieves booking with authorization
- ✅ GetBookingsByGuestID - retrieves bookings with pagination

### 4. Handler (`internal/handlers/booking_handler.go`)
- ✅ CreateBookingHold - POST /api/bookings/hold
- ✅ CreateBooking - POST /api/bookings
- ✅ ConfirmBooking - POST /api/bookings/:id/confirm
- ✅ CancelBooking - POST /api/bookings/:id/cancel
- ✅ GetBookings - GET /api/bookings
- ✅ GetBookingByID - GET /api/bookings/:id

### 5. Router (`internal/router/router.go`)
- ✅ Booking routes registered
- ✅ Authentication middleware applied
- ✅ Public hold endpoint
- ✅ Protected booking endpoints

## API Endpoints

### 1. Create Booking Hold (Public)
```bash
POST /api/bookings/hold
Content-Type: application/json

{
  "session_id": "unique-session-id",
  "room_type_id": 1,
  "check_in": "2025-12-01",
  "check_out": "2025-12-03"
}

Response:
{
  "hold_id": 1,
  "success": true,
  "message": "สร้าง hold สำเร็จ",
  "hold_expiry": "2025-11-02T10:30:00Z"
}
```

### 2. Create Booking (Protected)
```bash
POST /api/bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "session_id": "unique-session-id",
  "voucher_code": "DISCOUNT10",
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
        },
        {
          "first_name": "Jane",
          "last_name": "Doe",
          "type": "Adult",
          "is_primary": false
        }
      ]
    }
  ]
}

Response:
{
  "booking_id": 1,
  "total_amount": 5400.00,
  "status": "PendingPayment",
  "message": "Booking created successfully"
}
```

### 3. Confirm Booking (Protected)
```bash
POST /api/bookings/1/confirm
Authorization: Bearer <token>
Content-Type: application/json

{
  "booking_id": 1,
  "payment_method": "credit_card",
  "payment_id": "pay_123456"
}

Response:
{
  "success": true,
  "message": "ยืนยันการจองสำเร็จ"
}
```

### 4. Cancel Booking (Protected)
```bash
POST /api/bookings/1/cancel
Authorization: Bearer <token>
Content-Type: application/json

{
  "booking_id": 1,
  "reason": "Change of plans"
}

Response:
{
  "success": true,
  "message": "ยกเลิกการจองสำเร็จ",
  "refund_amount": 5400.00
}
```

### 5. Get Bookings (Protected)
```bash
GET /api/bookings?status=Confirmed&limit=10&offset=0
Authorization: Bearer <token>

Response:
{
  "bookings": [...],
  "total": 5,
  "limit": 10,
  "offset": 0
}
```

### 6. Get Booking by ID (Protected)
```bash
GET /api/bookings/1
Authorization: Bearer <token>

Response:
{
  "booking_id": 1,
  "guest_id": 1,
  "total_amount": 5400.00,
  "status": "Confirmed",
  "policy_name": "Standard Cancellation",
  "policy_description": "Free cancellation up to 7 days before check-in",
  "details": [
    {
      "booking_detail_id": 1,
      "room_type_id": 1,
      "room_type_name": "Deluxe Room",
      "check_in_date": "2025-12-01T00:00:00Z",
      "check_out_date": "2025-12-03T00:00:00Z",
      "num_guests": 2,
      "guests": [...],
      "nightly_prices": [...]
    }
  ]
}
```

## Testing Flow

### Complete Booking Flow Test

1. **Register a user** (if not already registered)
```bash
POST /api/auth/register
{
  "first_name": "Test",
  "last_name": "User",
  "email": "test@example.com",
  "phone": "1234567890",
  "password": "password123"
}
```

2. **Login to get token**
```bash
POST /api/auth/login
{
  "email": "test@example.com",
  "password": "password123"
}
```

3. **Search for available rooms**
```bash
GET /api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-03&guests=2
```

4. **Create booking hold**
```bash
POST /api/bookings/hold
{
  "session_id": "test-session-123",
  "room_type_id": 1,
  "check_in": "2025-12-01",
  "check_out": "2025-12-03"
}
```

5. **Create booking**
```bash
POST /api/bookings
Authorization: Bearer <token>
{
  "session_id": "test-session-123",
  "details": [...]
}
```

6. **Confirm booking** (simulate payment)
```bash
POST /api/bookings/:id/confirm
Authorization: Bearer <token>
{
  "booking_id": 1,
  "payment_method": "credit_card",
  "payment_id": "pay_test_123"
}
```

7. **View booking**
```bash
GET /api/bookings/:id
Authorization: Bearer <token>
```

8. **Cancel booking** (optional)
```bash
POST /api/bookings/:id/cancel
Authorization: Bearer <token>
{
  "booking_id": 1,
  "reason": "Testing cancellation"
}
```

## Prerequisites

Before testing, ensure:

1. ✅ PostgreSQL database is running
2. ✅ All migrations are applied (001-008)
3. ✅ Seed data is loaded:
   - Guests and accounts
   - Room types and rooms
   - Rate tiers and pricing calendar
   - Rate plans and pricing
   - Cancellation policies
4. ✅ Backend server is running

## Expected Behavior

### Success Cases
- Hold creation succeeds when rooms are available
- Booking creation succeeds with valid data
- Confirmation moves booking from PendingPayment to Confirmed
- Cancellation calculates refund based on policy
- Authorization prevents accessing other users' bookings

### Error Cases
- Hold fails when no rooms available
- Booking fails with invalid dates
- Confirmation fails for non-PendingPayment bookings
- Cancellation fails for completed bookings
- Unauthorized access returns 403

## Database Verification

After each operation, verify in PostgreSQL:

```sql
-- Check booking hold
SELECT * FROM booking_holds WHERE session_id = 'test-session-123';

-- Check inventory changes
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
  AND date BETWEEN '2025-12-01' AND '2025-12-03';

-- Check booking
SELECT * FROM bookings WHERE booking_id = 1;

-- Check booking details
SELECT * FROM booking_details WHERE booking_id = 1;

-- Check guests
SELECT * FROM booking_guests WHERE booking_detail_id = 1;

-- Check nightly logs
SELECT * FROM booking_nightly_log WHERE booking_detail_id = 1;
```

## Integration with PostgreSQL Functions

The module integrates with these PostgreSQL functions:

1. **create_booking_hold** (Migration 005)
   - Atomically reserves inventory
   - Creates hold records
   - Sets 15-minute expiry

2. **confirm_booking** (Migration 006)
   - Moves tentative to booked count
   - Updates booking status
   - Deletes holds

3. **cancel_confirmed_booking** (Migration 007)
   - Returns inventory
   - Calculates refund
   - Updates status

4. **cancel_pending_booking** (Migration 007)
   - Returns tentative inventory
   - Updates status

5. **release_expired_holds** (Migration 008)
   - Cleans up expired holds
   - Returns tentative inventory

## Performance Considerations

- All critical operations use database transactions
- Inventory updates are atomic
- Holds expire automatically after 15 minutes
- Pagination is implemented for listing bookings

## Security Features

- JWT authentication required for booking operations
- Users can only access their own bookings
- Hold creation can be public (for guest checkout)
- Authorization checks in service layer

## Next Steps

After testing this module:
1. Implement frontend booking UI (Task 16-21)
2. Add email notifications
3. Implement payment gateway integration
4. Add booking modification features
5. Implement staff check-in/check-out (Task 22-29)

## Troubleshooting

### Common Issues

1. **"No rate plans found"**
   - Ensure seed data includes rate plans
   - Check rate_plans table

2. **"Pricing not available"**
   - Ensure pricing_calendar has data
   - Check rate_pricing table

3. **"Booking hold failed"**
   - Check room_inventory has sufficient allotment
   - Verify dates are in the future

4. **"Unauthorized"**
   - Ensure JWT token is valid
   - Check Authorization header format

## Requirements Coverage

This implementation covers:
- ✅ Requirement 3.1-3.8: Booking Hold
- ✅ Requirement 4.1-4.9: Payment and Confirmation
- ✅ Requirement 5.1-5.7: Booking History
- ✅ Requirement 6.1-6.9: Cancellation

All requirements from the design document are implemented and ready for testing.
