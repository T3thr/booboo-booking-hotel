# Middleware Quick Reference

## Quick Start

### 1. Import Middleware
```go
import "github.com/hotel-booking-system/backend/internal/middleware"
```

### 2. Apply Global Middleware (in router setup)
```go
r.Use(middleware.Recovery())      // Panic recovery
r.Use(middleware.Logger())        // Request logging
r.Use(middleware.CORS(allowedOrigins))  // CORS handling
```

### 3. Protect Routes

#### Any Authenticated User
```go
protected := r.Group("/api/protected")
protected.Use(middleware.AuthMiddleware(jwtSecret))
{
    protected.GET("/profile", handler.GetProfile)
}
```

#### Specific Role Required
```go
managerRoutes := r.Group("/api/manager")
managerRoutes.Use(middleware.AuthMiddleware(jwtSecret))
managerRoutes.Use(middleware.RequireRole("manager"))
{
    managerRoutes.GET("/dashboard", handler.GetDashboard)
}
```

#### Multiple Roles (OR logic)
```go
staffRoutes := r.Group("/api/staff")
staffRoutes.Use(middleware.AuthMiddleware(jwtSecret))
staffRoutes.Use(middleware.RequireRole("receptionist", "manager"))
{
    staffRoutes.POST("/checkin", handler.CheckIn)
}
```

## Available Middleware

### AuthMiddleware(jwtSecret string)
- Validates JWT token from Authorization header
- Sets context: `user_id`, `user_email`, `user_role`
- Returns 401 if invalid/missing token

### RequireRole(roles ...string)
- Checks if user has one of the required roles
- Must be used after AuthMiddleware
- Returns 403 if insufficient permissions

### CORS(allowedOrigins []string)
- Handles CORS headers
- Supports wildcard: `[]string{"*"}`
- Handles OPTIONS preflight

### Logger()
- Logs all requests with timing
- Format: `[METHOD] STATUS | DURATION | IP | PATH`

### Recovery()
- Recovers from panics
- Returns 500 error
- Logs panic details

## User Roles

| Role | Description | Use Case |
|------|-------------|----------|
| `guest` | Hotel guests | Bookings, profile |
| `receptionist` | Front desk | Check-in/out, room management |
| `housekeeper` | Housekeeping | Room status updates |
| `manager` | Hotel manager | Reports, pricing, all features |

## Getting User Info in Handlers

```go
func MyHandler(c *gin.Context) {
    userID, _ := c.Get("user_id")
    userEmail, _ := c.Get("user_email")
    userRole, _ := c.Get("user_role")
    
    // Use the values
    id := userID.(int)
    email := userEmail.(string)
    role := userRole.(string)
}
```

## Common Patterns

### Public + Protected Routes
```go
// Public
r.GET("/api/rooms/search", handler.SearchRooms)

// Protected
protected := r.Group("/api/bookings")
protected.Use(middleware.AuthMiddleware(jwtSecret))
{
    protected.GET("/", handler.GetMyBookings)
    protected.POST("/", handler.CreateBooking)
}
```

### Nested Role Protection
```go
api := r.Group("/api")
api.Use(middleware.AuthMiddleware(jwtSecret))
{
    // All authenticated users
    api.GET("/profile", handler.GetProfile)
    
    // Manager only
    manager := api.Group("/manager")
    manager.Use(middleware.RequireRole("manager"))
    {
        manager.GET("/reports", handler.GetReports)
    }
}
```

### Multiple Middleware
```go
r.Use(
    middleware.Recovery(),
    middleware.Logger(),
    middleware.CORS(origins),
)
```

## Testing

### Create Test Token
```go
import "github.com/hotel-booking-system/backend/pkg/utils"

token, _ := utils.GenerateToken(1, "test@example.com", "guest", jwtSecret)
```

### Test Request
```go
req.Header.Set("Authorization", "Bearer " + token)
```

## Error Responses

### 401 Unauthorized
```json
{
  "success": false,
  "error": "No authorization header provided"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": "Insufficient permissions"
}
```

## Configuration

### Environment Variables
```env
JWT_SECRET=your-secret-key-here
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4000
```

### In Code
```go
cfg := config.Load()
r.Use(middleware.CORS(cfg.Server.CORS.AllowOrigins))
r.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
```

## Tips

1. **Always apply CORS before Auth** - OPTIONS requests should not require auth
2. **Use RequireRole after AuthMiddleware** - Role check needs user context
3. **Test with curl** - Easy way to verify middleware
4. **Check logs** - Logger middleware shows all requests
5. **Use groups** - Organize routes by permission level

## Example: Complete API Setup

```go
func Setup(cfg *config.Config, db *database.DB) *gin.Engine {
    r := gin.New()
    
    // Global middleware
    r.Use(middleware.Recovery())
    r.Use(middleware.Logger())
    r.Use(middleware.CORS(cfg.Server.CORS.AllowOrigins))
    
    // Public routes
    r.GET("/health", healthHandler)
    r.POST("/api/auth/login", authHandler.Login)
    r.POST("/api/auth/register", authHandler.Register)
    
    // Protected routes
    api := r.Group("/api")
    api.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
    {
        // All authenticated users
        api.GET("/profile", handler.GetProfile)
        
        // Guest routes
        guest := api.Group("/bookings")
        guest.Use(middleware.RequireRole("guest"))
        {
            guest.GET("/", handler.GetMyBookings)
            guest.POST("/", handler.CreateBooking)
        }
        
        // Staff routes
        staff := api.Group("/checkin")
        staff.Use(middleware.RequireRole("receptionist", "manager"))
        {
            staff.POST("/", handler.CheckIn)
            staff.POST("/checkout", handler.CheckOut)
        }
        
        // Manager routes
        manager := api.Group("/manager")
        manager.Use(middleware.RequireRole("manager"))
        {
            manager.GET("/reports", handler.GetReports)
            manager.PUT("/pricing", handler.UpdatePricing)
        }
    }
    
    return r
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No authorization header" | Add `Authorization: Bearer <token>` header |
| "Invalid token" | Check token is not expired, verify JWT secret |
| "Insufficient permissions" | User role doesn't match required roles |
| CORS error in browser | Add frontend origin to allowed origins |
| Panic not recovered | Make sure Recovery middleware is first |

## See Also

- `backend/internal/middleware/TESTING.md` - Detailed testing guide
- `backend/AUTH_QUICK_REFERENCE.md` - Authentication guide
- `backend/TESTING_AUTH.md` - Auth testing examples
