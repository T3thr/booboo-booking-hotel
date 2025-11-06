# Middleware Testing Guide

This document describes the middleware components and how to test them.

## Middleware Components

### 1. AuthMiddleware
Validates JWT tokens and sets user context.

**Features:**
- Validates Authorization header format
- Verifies JWT token signature and expiration
- Sets user_id, user_email, and user_role in context
- Returns 401 for invalid/missing tokens

**Usage:**
```go
r.Use(middleware.AuthMiddleware(jwtSecret))
```

### 2. RequireRole
Checks if the authenticated user has one of the required roles.

**Features:**
- Checks user_role from context
- Supports multiple roles (OR logic)
- Returns 403 for insufficient permissions

**Usage:**
```go
// Single role
r.Use(middleware.RequireRole("manager"))

// Multiple roles (user needs one of them)
r.Use(middleware.RequireRole("manager", "receptionist"))
```

**Supported Roles:**
- `guest` - Regular hotel guests
- `receptionist` - Front desk staff
- `housekeeper` - Housekeeping staff
- `manager` - Hotel managers

### 3. CORS
Handles Cross-Origin Resource Sharing.

**Features:**
- Validates origin against allowed list
- Supports wildcard (*) for all origins
- Handles OPTIONS preflight requests
- Sets appropriate CORS headers

**Usage:**
```go
r.Use(middleware.CORS([]string{"http://localhost:3000", "http://localhost:4000"}))

// Allow all origins
r.Use(middleware.CORS([]string{"*"}))
```

## Running Tests

### Run all middleware tests:
```bash
cd backend
go test ./internal/middleware/... -v
```

### Run specific test file:
```bash
go test ./internal/middleware/auth_test.go -v
go test ./internal/middleware/cors_test.go -v
go test ./internal/middleware/integration_test.go -v
```

### Run with coverage:
```bash
go test ./internal/middleware/... -cover
go test ./internal/middleware/... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

## Test Coverage

### auth_test.go
- ✅ Valid token authentication
- ✅ Missing authorization header
- ✅ Invalid header format
- ✅ Invalid token
- ✅ Expired token
- ✅ Context values are set correctly
- ✅ RequireRole with single role
- ✅ RequireRole with multiple roles
- ✅ RequireRole with insufficient permissions
- ✅ RequireRole with missing role in context
- ✅ RequireRole with invalid role type

### cors_test.go
- ✅ Allowed origin - exact match
- ✅ Allowed origin - wildcard
- ✅ Not allowed origin
- ✅ Multiple allowed origins
- ✅ OPTIONS preflight request
- ✅ No origin header
- ✅ All HTTP methods (GET, POST, PUT, DELETE, PATCH, OPTIONS)
- ✅ Allowed headers validation
- ✅ Empty allowed origins

### integration_test.go
- ✅ Complete authentication flow for all roles
- ✅ Role-based access control
- ✅ Multi-role routes
- ✅ Middleware chain (CORS + Auth + Role)
- ✅ Public and protected routes
- ✅ OPTIONS preflight with auth

## Example Protected Routes

### Guest Routes
```go
guestRoutes := api.Group("/bookings")
guestRoutes.Use(middleware.AuthMiddleware(jwtSecret))
guestRoutes.Use(middleware.RequireRole("guest"))
{
    guestRoutes.GET("/", handler.GetMyBookings)
    guestRoutes.POST("/", handler.CreateBooking)
}
```

### Receptionist Routes
```go
receptionRoutes := api.Group("/checkin")
receptionRoutes.Use(middleware.AuthMiddleware(jwtSecret))
receptionRoutes.Use(middleware.RequireRole("receptionist", "manager"))
{
    receptionRoutes.POST("/", handler.CheckIn)
    receptionRoutes.POST("/checkout", handler.CheckOut)
}
```

### Housekeeper Routes
```go
housekeepingRoutes := api.Group("/housekeeping")
housekeepingRoutes.Use(middleware.AuthMiddleware(jwtSecret))
housekeepingRoutes.Use(middleware.RequireRole("housekeeper"))
{
    housekeepingRoutes.GET("/tasks", handler.GetTasks)
    housekeepingRoutes.PUT("/rooms/:id/status", handler.UpdateRoomStatus)
}
```

### Manager Routes
```go
managerRoutes := api.Group("/manager")
managerRoutes.Use(middleware.AuthMiddleware(jwtSecret))
managerRoutes.Use(middleware.RequireRole("manager"))
{
    managerRoutes.GET("/reports", handler.GetReports)
    managerRoutes.PUT("/pricing", handler.UpdatePricing)
}
```

## Testing with curl

### Get token:
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Access protected route:
```bash
curl -X GET http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Test CORS:
```bash
curl -X OPTIONS http://localhost:8080/api/auth/me \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

## Common Issues

### 1. "No authorization header provided"
- Make sure to include the Authorization header
- Format: `Authorization: Bearer <token>`

### 2. "Invalid authorization header format"
- Check that the header starts with "Bearer "
- Make sure there's a space after "Bearer"

### 3. "Invalid or expired token"
- Token may have expired (default: 24 hours)
- Token may be signed with wrong secret
- Token may be malformed

### 4. "Insufficient permissions"
- User role doesn't match required roles
- Check that the user has the correct role in the database

### 5. CORS errors in browser
- Check that frontend origin is in allowed origins list
- Make sure CORS middleware is applied before other middleware
- Verify OPTIONS requests are handled correctly

## Security Best Practices

1. **Always use HTTPS in production**
2. **Keep JWT secret secure** - use environment variables
3. **Set appropriate token expiration** - balance security and UX
4. **Validate all inputs** - even after authentication
5. **Use role-based access control** - principle of least privilege
6. **Log authentication failures** - for security monitoring
7. **Implement rate limiting** - prevent brute force attacks
8. **Rotate JWT secrets periodically** - in production
