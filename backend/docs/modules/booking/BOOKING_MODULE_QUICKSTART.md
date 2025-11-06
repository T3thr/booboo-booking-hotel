# Booking Module Quick Start Guide

Get started with the Booking Module in 5 minutes!

## Prerequisites

✅ PostgreSQL running on port 5432  
✅ All migrations applied (001-008)  
✅ Seed data loaded  
✅ Backend server running on port 8080

## Quick Test (5 minutes)

### Step 1: Start the Server (if not running)

```bash
cd backend
go run cmd/server/main.go
```

Server should start on `http://localhost:8080`

### Step 2: Run Automated Tests

```powershell
cd backend
.\test_booking_module.ps1
```

This will:
1. Register a test user
2. Login and get token
3. Search for rooms
4. Create a booking hold
5. Create a booking
6. Confirm the booking
7. View booking details
8. Cancel the booking

**Expected:** All 11 tests pass ✅

### Step 3: Manual Test with cURL

#### 3.1 Register & Login

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "1234567890",
    "password": "password123"
  }'

# Login (save the token)
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

**Save the `accessToken` from the response!**

#### 3.2 Create Booking Hold

```bash
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "my-session-123",
    "room_type_id": 1,
    "check_in": "2025-12-01",
    "check_out": "2025-12-03"
  }'
```

**Expected:** Hold created with 15-minute expiry

#### 3.3 Create Booking

```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "session_id": "my-session-123",
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
  }'
```

**Save the `booking_id` from the response!**

#### 3.4 Confirm Booking

```bash
curl -X POST http://localhost:8080/api/bookings/1/confirm \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "booking_id": 1,
    "payment_method": "credit_card",
    "payment_id": "pay_123456"
  }'
```

**Expected:** Booking confirmed successfully

#### 3.5 View Booking

```bash
curl -X GET http://localhost:8080/api/bookings/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Expected:** Complete booking details with status "Confirmed"

---

## Using Postman (Recommended)

### Import Collection

1. Open Postman
2. Click "Import"
3. Select `backend/BOOKING_MODULE_POSTMAN.json`
4. Collection imported with all endpoints!

### Run Collection

1. Open "Hotel Booking System - Booking Module" collection
2. Run "1. Auth" → "Register" (or skip if already registered)
3. Run "1. Auth" → "Login" (token auto-saved)
4. Run "2. Room Search" → "Search Available Rooms"
5. Run "3. Booking Flow" → "Create Booking Hold"
6. Run "3. Booking Flow" → "Create Booking" (booking_id auto-saved)
7. Run "3. Booking Flow" → "Confirm Booking"
8. Run "4. View Bookings" → "Get Booking by ID"
9. Run "5. Cancel Booking" → "Cancel Booking"

**All requests should return 200/201 status!**

---

## Common Issues & Solutions

### Issue 1: "Server not running"
**Solution:** Start the server
```bash
cd backend
go run cmd/server/main.go
```

### Issue 2: "Database connection failed"
**Solution:** Check PostgreSQL is running
```bash
# Windows
Get-Service postgresql*

# Check connection
psql -U postgres -d hotel_booking -c "SELECT 1"
```

### Issue 3: "No rooms available"
**Solution:** Load seed data
```bash
cd database/migrations
psql -U postgres -d hotel_booking -f 003_create_pricing_inventory_tables.sql
```

### Issue 4: "Invalid token"
**Solution:** Login again to get a fresh token
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

### Issue 5: "Booking hold failed"
**Solution:** Check inventory has available rooms
```sql
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
  AND date BETWEEN '2025-12-01' AND '2025-12-03';
```

---

## API Endpoints Cheat Sheet

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/bookings/hold` | POST | No | Create hold |
| `/api/bookings` | POST | Yes | Create booking |
| `/api/bookings/:id/confirm` | POST | Yes | Confirm booking |
| `/api/bookings/:id/cancel` | POST | Yes | Cancel booking |
| `/api/bookings` | GET | Yes | List bookings |
| `/api/bookings/:id` | GET | Yes | Get booking |

---

## Database Quick Checks

### Check Hold
```sql
SELECT * FROM booking_holds 
WHERE session_id = 'my-session-123';
```

### Check Inventory
```sql
SELECT date, allotment, booked_count, tentative_count,
       (allotment - booked_count - tentative_count) as available
FROM room_inventory 
WHERE room_type_id = 1 
  AND date BETWEEN '2025-12-01' AND '2025-12-03'
ORDER BY date;
```

### Check Booking
```sql
SELECT b.booking_id, b.status, b.total_amount, b.created_at,
       bd.check_in_date, bd.check_out_date, rt.name as room_type
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
WHERE b.booking_id = 1;
```

### Check Guests
```sql
SELECT bg.first_name, bg.last_name, bg.type, bg.is_primary
FROM booking_guests bg
JOIN booking_details bd ON bg.booking_detail_id = bd.booking_detail_id
WHERE bd.booking_id = 1;
```

### Check Nightly Prices
```sql
SELECT bnl.date, bnl.quoted_price
FROM booking_nightly_log bnl
JOIN booking_details bd ON bnl.booking_detail_id = bd.booking_detail_id
WHERE bd.booking_id = 1
ORDER BY bnl.date;
```

---

## Code Examples

### Go - Create Booking Service

```go
import (
    "github.com/hotel-booking-system/backend/internal/service"
    "github.com/hotel-booking-system/backend/internal/repository"
)

// Initialize
bookingRepo := repository.NewBookingRepository(db)
roomRepo := repository.NewRoomRepository(db)
bookingService := service.NewBookingService(bookingRepo, roomRepo)

// Create booking
req := &models.CreateBookingRequest{
    SessionID: "session-123",
    Details: []models.CreateBookingDetailRequest{
        {
            RoomTypeID: 1,
            RatePlanID: 1,
            CheckIn: "2025-12-01",
            CheckOut: "2025-12-03",
            NumGuests: 2,
            Guests: []models.CreateGuestRequest{
                {
                    FirstName: "John",
                    LastName: "Doe",
                    Type: "Adult",
                    IsPrimary: true,
                },
            },
        },
    },
}

response, err := bookingService.CreateBooking(ctx, guestID, req)
```

### JavaScript - Fetch API

```javascript
// Create booking hold
const holdResponse = await fetch('http://localhost:8080/api/bookings/hold', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    session_id: 'session-123',
    room_type_id: 1,
    check_in: '2025-12-01',
    check_out: '2025-12-03',
  }),
});

const hold = await holdResponse.json();
console.log('Hold created:', hold.hold_id);

// Create booking
const bookingResponse = await fetch('http://localhost:8080/api/bookings', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  },
  body: JSON.stringify({
    session_id: 'session-123',
    details: [{
      room_type_id: 1,
      rate_plan_id: 1,
      check_in: '2025-12-01',
      check_out: '2025-12-03',
      num_guests: 2,
      guests: [{
        first_name: 'John',
        last_name: 'Doe',
        type: 'Adult',
        is_primary: true,
      }],
    }],
  }),
});

const booking = await bookingResponse.json();
console.log('Booking created:', booking.booking_id);
```

---

## Next Steps

After getting familiar with the Booking Module:

1. **Read Full Documentation**
   - `backend/BOOKING_API_REFERENCE.md` - Complete API reference
   - `backend/TEST_BOOKING_MODULE.md` - Detailed testing guide
   - `TASK_15_VERIFICATION.md` - Verification document

2. **Integrate with Frontend**
   - Task 16: Set up Next.js project
   - Task 17: Configure NextAuth.js
   - Task 18: Create API client
   - Task 19-21: Build booking UI

3. **Add Features**
   - Email notifications
   - Payment gateway integration
   - Booking modifications
   - Advanced reporting

---

## Support

**Documentation:**
- API Reference: `backend/BOOKING_API_REFERENCE.md`
- Testing Guide: `backend/TEST_BOOKING_MODULE.md`
- Verification: `TASK_15_VERIFICATION.md`

**Testing:**
- Automated: `backend/test_booking_module.ps1`
- Postman: `backend/BOOKING_MODULE_POSTMAN.json`

**Database:**
- Migrations: `database/migrations/`
- Functions: Migrations 005-008

---

## Quick Reference

**Booking Status Flow:**
```
PendingPayment → Confirmed → CheckedIn → Completed
       ↓              ↓
   Cancelled      Cancelled
```

**Hold Expiry:** 15 minutes

**Guest Types:** Adult, Child

**Discount Types:** Percentage, FixedAmount

**Date Format:** YYYY-MM-DD (e.g., 2025-12-01)

---

**Happy Coding! 🚀**
