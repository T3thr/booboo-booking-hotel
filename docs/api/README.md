# API Documentation

REST API endpoints สำหรับระบบจองโรงแรม

## Base URL

- **Development:** `http://localhost:8080`
- **Production:** `https://your-domain.com`

## Authentication

API ใช้ JWT (JSON Web Token) สำหรับ authentication

### Headers

```
Authorization: Bearer <your-jwt-token>
Content-Type: application/json
```

## API Endpoints

### 🔐 Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "0812345678",
  "password": "securepassword123"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "id": 1,
  "email": "john@example.com",
  "role": "guest",
  "accessToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 🏨 Rooms

#### Search Available Rooms
```http
GET /api/rooms/search?checkIn=2025-02-01&checkOut=2025-02-03&guests=2
```

**Response:**
```json
[
  {
    "room_type_id": 1,
    "name": "Deluxe Room",
    "description": "Spacious room with city view",
    "max_occupancy": 2,
    "available_days": 2,
    "total_price": 4000.00,
    "amenities": ["WiFi", "TV", "Air Conditioning"]
  }
]
```

#### Get Room Types
```http
GET /api/rooms/types
```

#### Get Room Type Details
```http
GET /api/rooms/types/:id
```

### 📅 Bookings

#### Create Booking Hold
```http
POST /api/bookings/hold
Authorization: Bearer <token>
Content-Type: application/json

{
  "session_id": "unique-session-id",
  "room_type_id": 1,
  "check_in": "2025-02-01",
  "check_out": "2025-02-03"
}
```

#### Create Booking
```http
POST /api/bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "room_type_id": 1,
  "rate_plan_id": 1,
  "check_in_date": "2025-02-01",
  "check_out_date": "2025-02-03",
  "num_guests": 2,
  "guests": [
    {
      "first_name": "John",
      "last_name": "Doe",
      "type": "Adult",
      "is_primary": true
    }
  ],
  "voucher_code": "SUMMER2025"
}
```

#### Confirm Booking
```http
POST /api/bookings/:id/confirm
Authorization: Bearer <token>
```

#### Cancel Booking
```http
POST /api/bookings/:id/cancel
Authorization: Bearer <token>
```

#### Get Bookings
```http
GET /api/bookings
Authorization: Bearer <token>
```

#### Get Booking Details
```http
GET /api/bookings/:id
Authorization: Bearer <token>
```

### 🔑 Check-in/Check-out (Receptionist)

#### Check-in
```http
POST /api/checkin
Authorization: Bearer <token>
Content-Type: application/json

{
  "booking_detail_id": 1,
  "room_id": 101
}
```

#### Check-out
```http
POST /api/checkout
Authorization: Bearer <token>
Content-Type: application/json

{
  "booking_id": 1
}
```

#### Move Room
```http
POST /api/checkin/move-room
Authorization: Bearer <token>
Content-Type: application/json

{
  "assignment_id": 1,
  "new_room_id": 102
}
```

### 🧹 Housekeeping

#### Get Tasks
```http
GET /api/housekeeping/tasks
Authorization: Bearer <token>
```

#### Update Room Status
```http
PUT /api/housekeeping/rooms/:id/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "Clean"
}
```

### 💰 Pricing & Inventory (Manager)

#### Get Rate Tiers
```http
GET /api/pricing/tiers
Authorization: Bearer <token>
```

#### Create Rate Tier
```http
POST /api/pricing/tiers
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Peak Season",
  "description": "High demand period"
}
```

#### Get Pricing Calendar
```http
GET /api/pricing/calendar?start=2025-02-01&end=2025-02-28
Authorization: Bearer <token>
```

#### Get Inventory
```http
GET /api/inventory?room_type_id=1&start=2025-02-01&end=2025-02-28
Authorization: Bearer <token>
```

#### Update Inventory
```http
PUT /api/inventory
Authorization: Bearer <token>
Content-Type: application/json

{
  "room_type_id": 1,
  "date": "2025-02-01",
  "allotment": 10
}
```

### 📊 Reports (Manager)

#### Occupancy Report
```http
GET /api/reports/occupancy?start=2025-02-01&end=2025-02-28
Authorization: Bearer <token>
```

#### Revenue Report
```http
GET /api/reports/revenue?start=2025-02-01&end=2025-02-28
Authorization: Bearer <token>
```

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid request parameters"
}
```

### 401 Unauthorized
```json
{
  "error": "Invalid or missing authentication token"
}
```

### 403 Forbidden
```json
{
  "error": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

## Rate Limiting

- **Guest endpoints:** 100 requests per minute
- **Staff endpoints:** 200 requests per minute
- **Manager endpoints:** 500 requests per minute

## Postman Collection

Import the Postman collection for easy testing:
- [Booking Module Postman Collection](../../backend/BOOKING_MODULE_POSTMAN.json)

## Related Documentation

- [Backend API Reference](../../backend/BOOKING_API_REFERENCE.md)
- [Auth Quick Reference](../../backend/AUTH_QUICK_REFERENCE.md)
- [Room Search Quick Reference](../../backend/ROOM_SEARCH_QUICK_REFERENCE.md)
- [Booking Quick Reference](../../backend/BOOKING_QUICK_REFERENCE.md)

## Testing

### Using curl

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"first_name":"John","last_name":"Doe","email":"john@example.com","password":"pass123"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"pass123"}'

# Search rooms (with token)
curl -X GET "http://localhost:8080/api/rooms/search?checkIn=2025-02-01&checkOut=2025-02-03&guests=2" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Using Postman

1. Import collection from `backend/BOOKING_MODULE_POSTMAN.json`
2. Set environment variables:
   - `base_url`: `http://localhost:8080`
   - `token`: Your JWT token
3. Run requests

---

**Last Updated:** 2025-02-03
