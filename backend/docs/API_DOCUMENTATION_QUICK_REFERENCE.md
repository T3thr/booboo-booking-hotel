# API Documentation - Quick Reference

## 🚀 Quick Start

### View Documentation
```bash
# 1. Start backend server
cd backend && go run cmd/server/main.go

# 2. Open browser
http://localhost:8080/docs
```

### Test an Endpoint
```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!","firstName":"Test","lastName":"User","phone":"0812345678"}'

# Login (save the token)
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!"}'

# Search rooms
curl "http://localhost:8080/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2"
```

## 📁 Documentation Files

```
backend/docs/
├── swagger.yaml                    # OpenAPI 3.0 specification
├── README.md                       # Overview and usage
├── INDEX.md                        # Documentation index
├── TESTING_GUIDE.md                # Testing instructions
├── API_DOCUMENTATION_SUMMARY.md    # Completion summary
├── setup-swagger-ui.sh             # Setup (Linux/Mac)
├── setup-swagger-ui.bat            # Setup (Windows)
├── verify-documentation.sh         # Verify (Linux/Mac)
├── verify-documentation.bat        # Verify (Windows)
└── examples/
    ├── auth-examples.md            # Auth examples
    ├── booking-examples.md         # Booking examples
    └── room-examples.md            # Room examples
```

## 🔑 Authentication

```bash
# Get token from login
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Use in requests
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/auth/me
```

## 📊 API Modules (67+ Endpoints)

### Health (2)
- `GET /health` - API health
- `GET /health/db` - Database health

### Auth (4)
- `POST /api/auth/register` - Register
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Get profile
- `PUT /api/auth/profile` - Update profile

### Rooms (5)
- `GET /api/rooms/search` - Search rooms
- `GET /api/rooms/types` - Get room types
- `GET /api/rooms/types/:id` - Get room type
- `GET /api/rooms/types/:id/pricing` - Get pricing
- `GET /api/rooms/status` - Room dashboard (Receptionist)

### Bookings (6)
- `POST /api/bookings/hold` - Create hold
- `POST /api/bookings` - Create booking
- `GET /api/bookings` - Get bookings
- `GET /api/bookings/:id` - Get booking
- `POST /api/bookings/:id/confirm` - Confirm
- `POST /api/bookings/:id/cancel` - Cancel

### Check-in (4) - Receptionist
- `POST /api/checkin` - Check-in
- `POST /api/checkin/move-room` - Move room
- `GET /api/checkin/arrivals` - Arrivals
- `GET /api/checkin/available-rooms/:id` - Available rooms

### Check-out (2) - Receptionist
- `POST /api/checkout` - Check-out
- `GET /api/checkout/departures` - Departures

### Housekeeping (5) - Housekeeper
- `GET /api/housekeeping/tasks` - Tasks
- `PUT /api/housekeeping/rooms/:id/status` - Update status
- `POST /api/housekeeping/rooms/:id/inspect` - Inspect
- `GET /api/housekeeping/inspection` - Inspection queue
- `POST /api/housekeeping/rooms/:id/maintenance` - Report issue

### Pricing (10) - Manager
- `GET/POST/PUT /api/pricing/tiers` - Rate tiers
- `GET/PUT /api/pricing/calendar` - Pricing calendar
- `GET/PUT /api/pricing/rates` - Rate pricing
- `POST /api/pricing/rates/bulk` - Bulk update
- `GET /api/pricing/plans` - Rate plans

### Inventory (4) - Manager
- `GET /api/inventory` - Get inventory
- `GET /api/inventory/:roomTypeId/:date` - Get by date
- `PUT /api/inventory` - Update
- `POST /api/inventory/bulk` - Bulk update

### Policies (5) - Manager
- `GET/POST/PUT/DELETE /api/policies/cancellation` - Policies

### Vouchers (6)
- `POST /api/vouchers/validate` - Validate (Public)
- `GET/POST/PUT/DELETE /api/vouchers` - Manage (Manager)

### Reports (10) - Manager
- `GET /api/reports/occupancy` - Occupancy
- `GET /api/reports/revenue` - Revenue
- `GET /api/reports/vouchers` - Vouchers
- `GET /api/reports/no-shows` - No-shows
- `GET /api/reports/summary` - Summary
- `GET /api/reports/comparison` - Comparison
- `GET /api/reports/export/*` - Export (4 endpoints)

### Admin (4) - Manager
- `POST /api/admin/night-audit/trigger` - Trigger audit
- `GET /api/admin/night-audit/status` - Audit status
- `POST /api/admin/hold-cleanup/trigger` - Trigger cleanup
- `GET /api/admin/hold-cleanup/status` - Cleanup status

## 🔒 Rate Limits

- Auth: 5 req/min
- Search: 20 req/min
- Booking: 10 req/min
- General: 100 req/min

## 📝 Response Codes

- `200` OK
- `201` Created
- `400` Bad Request
- `401` Unauthorized
- `403` Forbidden
- `404` Not Found
- `429` Rate Limited
- `500` Server Error

## 🛠️ Tools

### Swagger UI
```
http://localhost:8080/docs
```

### Postman
```
Import: backend/BOOKING_MODULE_POSTMAN.json
```

### cURL
```bash
# See examples in:
backend/docs/examples/*.md
```

## ✅ Verification

```bash
# Linux/Mac
./backend/docs/verify-documentation.sh

# Windows
backend\docs\verify-documentation.bat
```

## 📚 More Info

- **Full Documentation:** [backend/docs/README.md](./docs/README.md)
- **Testing Guide:** [backend/docs/TESTING_GUIDE.md](./docs/TESTING_GUIDE.md)
- **Examples:** [backend/docs/examples/](./docs/examples/)
- **OpenAPI Spec:** [backend/docs/swagger.yaml](./docs/swagger.yaml)

## 🎯 Common Tasks

### Register & Login
```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Pass123!","firstName":"John","lastName":"Doe","phone":"0812345678"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Pass123!"}'
```

### Search & Book
```bash
# Search
curl "http://localhost:8080/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2"

# Create hold
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"sess123","roomTypeId":1,"checkIn":"2025-12-01","checkOut":"2025-12-05"}'

# Create booking
curl -X POST http://localhost:8080/api/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"sess123","bookingDetails":[{"roomTypeId":1,"ratePlanId":1,"checkInDate":"2025-12-01","checkOutDate":"2025-12-05","numGuests":2}],"guests":[{"firstName":"John","lastName":"Doe","type":"Adult","isPrimary":true}]}'
```

### View Bookings
```bash
# Get all bookings
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/bookings

# Get specific booking
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/bookings/1
```

## 🐛 Troubleshooting

### Swagger UI not loading
1. Check server is running
2. Verify `backend/docs/swagger-ui` exists
3. Check browser console

### 401 Unauthorized
1. Get fresh token from login
2. Use format: `Bearer <token>`
3. Check token expiry

### 403 Forbidden
1. Check user role
2. Verify endpoint permissions
3. See role requirements in docs

### 429 Rate Limited
1. Wait for rate limit reset
2. Check rate limit headers
3. Reduce request frequency

## 📞 Support

- **Documentation:** [backend/docs/](./docs/)
- **Examples:** [backend/docs/examples/](./docs/examples/)
- **Tests:** [backend/internal/handlers/*_test.go](./internal/handlers/)
- **Quick Refs:** [backend/*_QUICK_REFERENCE.md](.)

---

**Task 46: API Documentation** ✅ Completed  
**Last Updated:** November 3, 2025
