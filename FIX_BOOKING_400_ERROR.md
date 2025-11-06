# Booking 400 Error - Fixed

## Problem
After fixing the 404 errors, the booking creation was returning a 400 error:
```
Create booking failed: 400
[GIN-debug] redirecting request 307: /api/bookings/ --> /api/bookings/
[POST] 400 | 999µs | ::1 | /api/bookings/
```

## Root Cause
The backend's `CreateBookingRequest` struct requires a `session_id` field:

```go
type CreateBookingRequest struct {
	SessionID   string                  `json:"session_id" binding:"required"`
	VoucherCode *string                 `json:"voucher_code,omitempty"`
	Details     []CreateBookingDetailRequest `json:"details" binding:"required,min=1,dive"`
}
```

But the frontend's `bookingApi.create()` function was not including the `session_id` in the request body, causing the backend to reject it with a 400 Bad Request.

## Solution
Updated the `bookingApi.create()` function to:
1. Get or generate a session ID (same logic as `createHold`)
2. Include the `session_id` in the request body

The session ID is stored in `sessionStorage` and reused across the booking flow, ensuring the hold and booking creation use the same session.

## Files Changed
- `frontend/src/lib/api.ts` - Added session_id to booking creation request

## Testing
The booking creation should now work correctly:
1. Search for rooms
2. Select a room and create a hold
3. Fill in guest information
4. Submit booking - should succeed without 400 error
