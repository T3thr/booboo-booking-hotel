# API Documentation Testing Guide

This guide helps you test and verify the API documentation.

## Prerequisites

1. Backend server running on `http://localhost:8080`
2. Database with seed data
3. Tools: cURL, Postman, or Swagger UI

## Setup Swagger UI

### Option 1: Using the Setup Script

**Linux/Mac:**
```bash
chmod +x backend/docs/setup-swagger-ui.sh
./backend/docs/setup-swagger-ui.sh
```

**Windows:**
```cmd
backend\docs\setup-swagger-ui.bat
```

### Option 2: Manual Setup

1. Download Swagger UI from https://github.com/swagger-api/swagger-ui/releases
2. Extract the `dist` folder to `backend/docs/swagger-ui`
3. Update `swagger-initializer.js` to point to `/docs/swagger.yaml`

### Option 3: Use Online Tools

- Swagger Editor: https://editor.swagger.io/
- Swagger UI Online: https://petstore.swagger.io/

## Viewing the Documentation

### Local Swagger UI

1. Start the backend server:
```bash
cd backend
go run cmd/server/main.go
```

2. Open your browser to:
```
http://localhost:8080/docs
```

### VS Code Extension

1. Install "Swagger Viewer" extension
2. Open `backend/docs/swagger.yaml`
3. Press `Shift+Alt+P` and select "Preview Swagger"

## Testing Workflow

### 1. Test Health Endpoints

```bash
# API Health
curl http://localhost:8080/health

# Database Health
curl http://localhost:8080/health/db
```

Expected: Both should return `200 OK` with status information.

### 2. Test Authentication Flow

```bash
# Register a new user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "firstName": "Test",
    "lastName": "User",
    "phone": "0812345678"
  }'

# Save the accessToken from the response
export TOKEN="<your-access-token>"

# Get profile
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

Expected: 
- Register returns `201 Created` with user data and token
- Get profile returns `200 OK` with user information

### 3. Test Room Search

```bash
# Search for available rooms
curl "http://localhost:8080/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2"

# Get all room types
curl http://localhost:8080/api/rooms/types

# Get specific room type
curl http://localhost:8080/api/rooms/types/1

# Get pricing for specific dates
curl "http://localhost:8080/api/rooms/types/1/pricing?checkIn=2025-12-01&checkOut=2025-12-05"
```

Expected: All should return `200 OK` with room data.

### 4. Test Booking Flow

```bash
# Create a booking hold
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "test-session-123",
    "roomTypeId": 1,
    "checkIn": "2025-12-01",
    "checkOut": "2025-12-05"
  }'

# Create a booking (authenticated)
curl -X POST http://localhost:8080/api/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "test-session-123",
    "bookingDetails": [{
      "roomTypeId": 1,
      "ratePlanId": 1,
      "checkInDate": "2025-12-01",
      "checkOutDate": "2025-12-05",
      "numGuests": 2
    }],
    "guests": [{
      "firstName": "Test",
      "lastName": "User",
      "type": "Adult",
      "isPrimary": true
    }]
  }'

# Save the bookingId from the response
export BOOKING_ID=<your-booking-id>

# Confirm the booking
curl -X POST http://localhost:8080/api/bookings/$BOOKING_ID/confirm \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"paymentMethod": "credit_card"}'

# Get booking details
curl http://localhost:8080/api/bookings/$BOOKING_ID \
  -H "Authorization: Bearer $TOKEN"

# Get all bookings
curl "http://localhost:8080/api/bookings?status=Confirmed" \
  -H "Authorization: Bearer $TOKEN"
```

Expected:
- Hold returns `200 OK` with hold details
- Create booking returns `201 Created`
- Confirm returns `200 OK` with success message
- Get endpoints return `200 OK` with booking data

### 5. Test Error Scenarios

```bash
# Invalid date format
curl "http://localhost:8080/api/rooms/search?checkIn=invalid&checkOut=2025-12-05&guests=2"
# Expected: 400 Bad Request

# Past date
curl "http://localhost:8080/api/rooms/search?checkIn=2020-01-01&checkOut=2020-01-05&guests=2"
# Expected: 400 Bad Request

# Unauthorized access
curl http://localhost:8080/api/auth/me
# Expected: 401 Unauthorized

# Invalid credentials
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "wrong@example.com", "password": "wrong"}'
# Expected: 401 Unauthorized

# Duplicate email registration
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "firstName": "Test",
    "lastName": "User",
    "phone": "0812345678"
  }'
# Expected: 400 Bad Request with "อีเมลนี้ถูกลงทะเบียนแล้ว"
```

### 6. Test Role-Based Access

```bash
# Try to access receptionist endpoint as guest
curl http://localhost:8080/api/rooms/status \
  -H "Authorization: Bearer $TOKEN"
# Expected: 403 Forbidden

# Try to access manager endpoint as guest
curl http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer $TOKEN"
# Expected: 403 Forbidden
```

## Using Postman

1. Import the Postman collection:
   - File: `backend/BOOKING_MODULE_POSTMAN.json`

2. Set environment variables:
   - `baseUrl`: `http://localhost:8080`
   - `token`: (will be set automatically after login)

3. Run the collection:
   - Click "Run" button
   - Select all requests
   - Click "Run Hotel Booking System"

## Validation Checklist

### Documentation Completeness

- [ ] All endpoints are documented
- [ ] All request parameters are described
- [ ] All response codes are listed
- [ ] Request/response examples are provided
- [ ] Authentication requirements are clear
- [ ] Error responses are documented

### Accuracy

- [ ] Endpoint paths match actual routes
- [ ] Request schemas match actual models
- [ ] Response schemas match actual responses
- [ ] Examples use realistic data
- [ ] Status codes are correct

### Usability

- [ ] Documentation is easy to navigate
- [ ] Tags group related endpoints
- [ ] Descriptions are clear and helpful
- [ ] Examples can be copy-pasted
- [ ] cURL commands work as-is

### Testing

- [ ] All endpoints can be tested via Swagger UI
- [ ] Authentication flow works
- [ ] Error scenarios are testable
- [ ] Rate limiting is documented
- [ ] CORS is properly configured

## Common Issues

### Issue: Swagger UI not loading

**Solution:**
1. Check that backend server is running
2. Verify `backend/docs/swagger-ui` directory exists
3. Check browser console for errors
4. Try accessing `/docs/swagger.yaml` directly

### Issue: 404 on API calls from Swagger UI

**Solution:**
1. Check the server URL in Swagger UI
2. Verify CORS is enabled
3. Check that routes are registered in router

### Issue: Authentication not working

**Solution:**
1. Get a fresh token from `/api/auth/login`
2. Click "Authorize" button in Swagger UI
3. Enter: `Bearer <your-token>`
4. Try the request again

### Issue: Rate limit errors

**Solution:**
1. Wait for the rate limit window to reset
2. Use different endpoints
3. Adjust rate limits in development

## Automated Testing

Create a test script to verify all endpoints:

```bash
#!/bin/bash
# test-api-docs.sh

BASE_URL="http://localhost:8080"
FAILED=0

# Test health endpoints
echo "Testing health endpoints..."
curl -s -o /dev/null -w "%{http_code}" $BASE_URL/health | grep -q "200" || FAILED=$((FAILED+1))
curl -s -o /dev/null -w "%{http_code}" $BASE_URL/health/db | grep -q "200" || FAILED=$((FAILED+1))

# Test auth endpoints
echo "Testing auth endpoints..."
REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test'$(date +%s)'@example.com","password":"SecurePass123!","firstName":"Test","lastName":"User","phone":"0812345678"}')

TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.accessToken')

if [ "$TOKEN" != "null" ]; then
  echo "✓ Registration successful"
else
  echo "✗ Registration failed"
  FAILED=$((FAILED+1))
fi

# Test room search
echo "Testing room search..."
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2" | grep -q "200" || FAILED=$((FAILED+1))

echo ""
if [ $FAILED -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ $FAILED tests failed"
  exit 1
fi
```

Run with:
```bash
chmod +x test-api-docs.sh
./test-api-docs.sh
```

## Next Steps

After verifying the documentation:

1. Share with frontend team
2. Update as API evolves
3. Add more examples
4. Create video tutorials
5. Generate client SDKs

## Support

For issues with the API documentation:
- Check `backend/docs/examples/` for more examples
- Review `backend/*_QUICK_REFERENCE.md` files
- See test files in `backend/internal/handlers/*_test.go`
