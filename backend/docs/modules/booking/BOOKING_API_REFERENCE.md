# Booking API Reference

Quick reference for the Booking Module API endpoints.

## Base URL
```
http://localhost:8080/api
```

## Authentication
Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## Endpoints

### 1. Create Booking Hold
Creates a temporary hold on inventory (15 minutes).

**Endpoint:** `POST /bookings/hold`  
**Auth:** Optional (public endpoint)

**Request:**
```json
{
  "session_id": "unique-session-id",
  "guest_account_id": 1,  // Optional, auto-filled if authenticated
  "room_type_id": 1,
  "check_in": "2025-12-01",
  "check_out": "2025-12-03"
}
```

**Response (200 OK):**
```json
{
  "hold_id": 123,
  "success": true,
  "message": "สร้าง hold สำเร็จ",
  "hold_expiry": "2025-11-03T10:30:00Z"
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "ห้องไม่ว่างสำหรับวันที่เลือก"
}
```

---

### 2. Create Booking
Creates a new booking with guest details.

**Endpoint:** `POST /bookings`  
**Auth:** Required

**Request:**
```json
{
  "session_id": "unique-session-id",
  "voucher_code": "DISCOUNT10",  // Optional
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
```

**Response (201 Created):**
```json
{
  "booking_id": 1,
  "total_amount": 5400.00,
  "status": "PendingPayment",
  "message": "Booking created successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid data
- `401 Unauthorized` - Missing or invalid token
- `500 Internal Server Error` - Server error

---

### 3. Confirm Booking
Confirms a pending booking after payment.

**Endpoint:** `POST /bookings/:id/confirm`  
**Auth:** Required

**Request:**
```json
{
  "booking_id": 1,
  "payment_method": "credit_card",
  "payment_id": "pay_123456789"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "ยืนยันการจองสำเร็จ"
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Cannot confirm booking with status: Confirmed"
}
```

---

### 4. Get Bookings
Retrieves all bookings for the authenticated user.

**Endpoint:** `GET /bookings`  
**Auth:** Required

**Query Parameters:**
- `status` (optional) - Filter by status (Confirmed, PendingPayment, etc.)
- `limit` (optional) - Number of results (default: 20, max: 100)
- `offset` (optional) - Pagination offset (default: 0)

**Example:**
```
GET /bookings?status=Confirmed&limit=10&offset=0
```

**Response (200 OK):**
```json
{
  "bookings": [
    {
      "booking_id": 1,
      "guest_id": 1,
      "total_amount": 5400.00,
      "status": "Confirmed",
      "created_at": "2025-11-03T10:00:00Z",
      "updated_at": "2025-11-03T10:05:00Z",
      "policy_name": "Standard Cancellation",
      "policy_description": "Free cancellation up to 7 days before check-in",
      "details": [
        {
          "booking_detail_id": 1,
          "room_type_id": 1,
          "room_type_name": "Deluxe Room",
          "rate_plan_id": 1,
          "check_in_date": "2025-12-01T00:00:00Z",
          "check_out_date": "2025-12-03T00:00:00Z",
          "num_guests": 2,
          "guests": [
            {
              "booking_guest_id": 1,
              "first_name": "John",
              "last_name": "Doe",
              "type": "Adult",
              "is_primary": true
            }
          ],
          "nightly_prices": [
            {
              "date": "2025-12-01T00:00:00Z",
              "quoted_price": 2700.00
            },
            {
              "date": "2025-12-02T00:00:00Z",
              "quoted_price": 2700.00
            }
          ],
          "room_number": "101"  // Only if checked in
        }
      ]
    }
  ],
  "total": 5,
  "limit": 10,
  "offset": 0
}
```

---

### 5. Get Booking by ID
Retrieves a specific booking with full details.

**Endpoint:** `GET /bookings/:id`  
**Auth:** Required

**Example:**
```
GET /bookings/1
```

**Response (200 OK):**
```json
{
  "booking_id": 1,
  "guest_id": 1,
  "voucher_id": null,
  "total_amount": 5400.00,
  "status": "Confirmed",
  "created_at": "2025-11-03T10:00:00Z",
  "updated_at": "2025-11-03T10:05:00Z",
  "policy_name": "Standard Cancellation",
  "policy_description": "Free cancellation up to 7 days before check-in",
  "details": [...]
}
```

**Error Responses:**
- `400 Bad Request` - Invalid booking ID
- `403 Forbidden` - Unauthorized to view this booking
- `404 Not Found` - Booking not found

---

### 6. Cancel Booking
Cancels a booking and calculates refund.

**Endpoint:** `POST /bookings/:id/cancel`  
**Auth:** Required

**Request:**
```json
{
  "booking_id": 1,
  "reason": "Change of plans"  // Optional
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "ยกเลิกการจองสำเร็จ",
  "refund_amount": 5400.00
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Cannot cancel booking with status: Completed"
}
```

---

## Booking Status Flow

```
PendingPayment → Confirmed → CheckedIn → Completed
       ↓              ↓
   Cancelled      Cancelled
```

**Status Values:**
- `PendingPayment` - Booking created, awaiting payment
- `Confirmed` - Payment received, booking confirmed
- `CheckedIn` - Guest has checked in
- `Completed` - Guest has checked out
- `Cancelled` - Booking cancelled
- `NoShow` - Guest didn't show up

---

## Guest Type Values

- `Adult` - Adult guest
- `Child` - Child guest

---

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request - Invalid input data |
| 401 | Unauthorized - Missing or invalid token |
| 403 | Forbidden - Not authorized to access resource |
| 404 | Not Found - Resource not found |
| 500 | Internal Server Error - Server error |

---

## Common Error Messages

### Hold Creation
- "ห้องไม่ว่างสำหรับวันที่เลือก" - No rooms available
- "invalid check-in date format" - Invalid date format
- "check-out date must be after check-in date" - Invalid date range

### Booking Creation
- "at least one booking detail is required" - Missing details
- "invalid or expired voucher code" - Invalid voucher
- "invalid rate plan" - Rate plan not found
- "failed to get pricing" - Pricing not configured

### Confirmation
- "Booking not found" - Invalid booking ID
- "Cannot confirm booking with status: X" - Invalid status
- "Authentication required" - Missing token

### Cancellation
- "Unauthorized to cancel this booking" - Not your booking
- "Cannot cancel booking with status: X" - Invalid status

---

## Testing Tips

### 1. Get a Token
```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","last_name":"User","email":"test@example.com","phone":"1234567890","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 2. Create a Hold
```bash
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test-123","room_type_id":1,"check_in":"2025-12-01","check_out":"2025-12-03"}'
```

### 3. Create a Booking
```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d @booking_request.json
```

### 4. View Bookings
```bash
curl -X GET "http://localhost:8080/api/bookings?limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Database Verification

After operations, verify in PostgreSQL:

```sql
-- Check holds
SELECT * FROM booking_holds WHERE session_id = 'test-123';

-- Check inventory
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
  AND date BETWEEN '2025-12-01' AND '2025-12-03';

-- Check booking
SELECT * FROM bookings WHERE booking_id = 1;

-- Check details
SELECT bd.*, rt.name 
FROM booking_details bd
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
WHERE bd.booking_id = 1;

-- Check guests
SELECT * FROM booking_guests 
WHERE booking_detail_id IN (
  SELECT booking_detail_id FROM booking_details WHERE booking_id = 1
);

-- Check nightly logs
SELECT * FROM booking_nightly_log
WHERE booking_detail_id IN (
  SELECT booking_detail_id FROM booking_details WHERE booking_id = 1
);
```

---

## Integration with PostgreSQL Functions

The API calls these PostgreSQL functions:

1. `create_booking_hold(session_id, guest_account_id, room_type_id, check_in, check_out)`
2. `confirm_booking(booking_id)`
3. `cancel_confirmed_booking(booking_id)`
4. `cancel_pending_booking(booking_id)`
5. `release_expired_holds()` (background job)

---

## Rate Limiting

Currently no rate limiting is implemented. Consider adding:
- Max 10 holds per session per hour
- Max 5 bookings per user per day
- Max 100 API calls per user per hour

---

## Webhooks (Future)

Consider implementing webhooks for:
- Booking confirmed
- Booking cancelled
- Payment received
- Check-in completed
- Check-out completed

---

## Support

For issues or questions:
1. Check logs in `backend/logs/`
2. Verify database state
3. Check PostgreSQL function logs
4. Review error messages

---

## Version History

- v1.0.0 (2025-11-03) - Initial implementation
  - All booking endpoints
  - Hold management
  - Confirmation and cancellation
  - Full integration with PostgreSQL functions
