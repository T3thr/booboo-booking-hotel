# Authentication Module - Quick Reference

## Quick Start

### 1. Start the Server
```bash
cd backend
go run cmd/server/main.go
```

### 2. Register a User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "0812345678",
    "password": "password123"
  }'
```

### 3. Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### 4. Use the Token
```bash
# Save the accessToken from login response
TOKEN="your_access_token_here"

# Get profile
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN"

# Update profile
curl -X PUT http://localhost:8080/api/auth/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "first_name": "John",
    "last_name": "Smith",
    "phone": "0898765432"
  }'
```

## Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | No | Register new guest |
| POST | `/api/auth/login` | No | Login and get token |
| GET | `/api/auth/me` | Yes | Get current user profile |
| PUT | `/api/auth/profile` | Yes | Update user profile |

## Code Structure

```
backend/
├── internal/
│   ├── models/
│   │   └── guest.go              # Data models
│   ├── repository/
│   │   └── auth_repository.go    # Database operations
│   ├── service/
│   │   └── auth_service.go       # Business logic
│   ├── handlers/
│   │   └── auth_handler.go       # HTTP handlers
│   └── middleware/
│       └── auth.go               # JWT middleware
└── pkg/
    └── utils/
        ├── jwt.go                # JWT utilities
        └── password.go           # Password hashing
```

## Using Authentication in New Handlers

### Protect a Route
```go
// In router.go
protected := api.Group("/bookings")
protected.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
{
    protected.GET("/", bookingHandler.GetMyBookings)
    protected.POST("/", bookingHandler.CreateBooking)
}
```

### Get User ID in Handler
```go
func (h *BookingHandler) GetMyBookings(c *gin.Context) {
    userID, exists := c.Get("user_id")
    if !exists {
        utils.ErrorResponse(c, 401, "Unauthorized")
        return
    }
    
    bookings, err := h.service.GetBookingsByGuestID(c.Request.Context(), userID.(int))
    // ...
}
```

### Require Specific Role
```go
// In router.go
manager := api.Group("/manager")
manager.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
manager.Use(middleware.RequireRole("manager"))
{
    manager.GET("/reports", reportHandler.GetReports)
}
```

## Common Errors

### 401 Unauthorized
- Missing Authorization header
- Invalid token format
- Expired token
- Wrong JWT secret

**Fix:** Ensure token is sent as `Authorization: Bearer <token>`

### 400 Bad Request
- Invalid email format
- Password too short
- Missing required fields

**Fix:** Check request body matches model validation

### 409 Conflict
- Email already registered

**Fix:** Use different email or login instead

## Environment Variables

Required in `.env`:
```env
JWT_SECRET=your-secret-key-change-in-production
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=hotel_booking
```

## Testing

### Run Unit Tests
```bash
go test -v ./pkg/utils/...
```

### Test Registration Flow
```bash
# 1. Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","last_name":"User","email":"test@test.com","phone":"0811111111","password":"test1234"}'

# 2. Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test1234"}'

# 3. Get Profile (use token from step 2)
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Database Queries

### Check Registered Users
```sql
SELECT g.guest_id, g.first_name, g.last_name, g.email, ga.last_login
FROM guests g
JOIN guest_accounts ga ON g.guest_id = ga.guest_id
ORDER BY g.created_at DESC;
```

### Verify Password is Hashed
```sql
SELECT guest_id, hashed_password
FROM guest_accounts
LIMIT 1;
-- Should start with $2a$ or $2b$
```

## Security Notes

- ✅ Passwords are hashed with bcrypt (cost 10)
- ✅ JWT tokens expire after 24 hours
- ✅ Passwords never exposed in API responses
- ✅ Email uniqueness enforced at database level
- ✅ Input validation on all endpoints
- ✅ Context-aware database operations

## Next Steps

1. ✅ Task 8: Authentication Module - **COMPLETE**
2. ✅ Task 9: Authentication Middleware - **COMPLETE** (included in Task 8)
3. 🔜 Task 10: Room Search Module
4. 🔜 Task 15: Booking Module

## Need Help?

- See `TESTING_AUTH.md` for detailed testing guide
- See `TASK_8_COMPLETION.md` for implementation details
- See `ARCHITECTURE.md` for system architecture
- Check logs for error details
