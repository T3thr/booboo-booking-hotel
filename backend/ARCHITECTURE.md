# Backend Architecture Documentation

## Overview

The Hotel Booking System backend is built using Go with a clean architecture pattern, separating concerns into distinct layers. This document describes the architecture, design decisions, and implementation details.

## Technology Stack

- **Language**: Go 1.21+
- **Web Framework**: Gin
- **Database**: PostgreSQL 15+ with pgx v5 driver
- **Authentication**: JWT (golang-jwt/jwt)
- **Password Hashing**: bcrypt
- **Configuration**: Environment variables with godotenv
- **Hot Reload**: Air (development)

## Architecture Layers

### 1. Handler Layer (`internal/handlers/`)

**Responsibility**: HTTP request/response handling

- Receives HTTP requests
- Validates request data
- Calls appropriate service methods
- Formats and returns HTTP responses
- Handles HTTP-specific errors

**Example**:
```go
func (h *AuthHandler) Login(c *gin.Context) {
    var req LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.ErrorResponse(c, 400, "Invalid request")
        return
    }
    
    user, err := h.authService.Authenticate(req.Email, req.Password)
    if err != nil {
        utils.ErrorResponse(c, 401, "Invalid credentials")
        return
    }
    
    utils.SuccessResponse(c, 200, user)
}
```

### 2. Service Layer (`internal/service/`)

**Responsibility**: Business logic implementation

- Implements business rules
- Orchestrates operations across repositories
- Handles transactions
- Performs data transformations
- Contains domain logic

**Example**:
```go
func (s *BookingService) CreateBooking(ctx context.Context, req CreateBookingRequest) (*Booking, error) {
    // Validate business rules
    if err := s.validateBooking(req); err != nil {
        return nil, err
    }
    
    // Start transaction
    tx, err := s.db.Pool.Begin(ctx)
    if err != nil {
        return nil, err
    }
    defer tx.Rollback(ctx)
    
    // Create booking
    booking, err := s.repo.CreateBooking(ctx, tx, req)
    if err != nil {
        return nil, err
    }
    
    // Commit transaction
    if err := tx.Commit(ctx); err != nil {
        return nil, err
    }
    
    return booking, nil
}
```

### 3. Repository Layer (`internal/repository/`)

**Responsibility**: Data access

- Executes SQL queries
- Calls stored procedures
- Maps database rows to models
- Handles database-specific errors
- No business logic

**Example**:
```go
func (r *BookingRepository) CreateBooking(ctx context.Context, tx pgx.Tx, booking *Booking) error {
    query := `
        INSERT INTO bookings (guest_id, total_amount, status)
        VALUES ($1, $2, $3)
        RETURNING booking_id, created_at
    `
    
    return tx.QueryRow(ctx, query, 
        booking.GuestID, 
        booking.TotalAmount, 
        booking.Status,
    ).Scan(&booking.ID, &booking.CreatedAt)
}
```

### 4. Model Layer (`internal/models/`)

**Responsibility**: Data structures

- Defines domain entities
- Contains validation tags
- Includes JSON serialization tags
- No business logic

**Example**:
```go
type Booking struct {
    ID          int       `json:"booking_id" db:"booking_id"`
    GuestID     int       `json:"guest_id" db:"guest_id"`
    TotalAmount float64   `json:"total_amount" db:"total_amount"`
    Status      string    `json:"status" db:"status"`
    CreatedAt   time.Time `json:"created_at" db:"created_at"`
}
```

### 5. Middleware Layer (`internal/middleware/`)

**Responsibility**: Request/response processing

- Authentication/Authorization
- CORS handling
- Logging
- Error recovery
- Rate limiting (future)

**Example**:
```go
func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := extractToken(c)
        claims, err := validateToken(token)
        if err != nil {
            c.AbortWithStatusJSON(401, gin.H{"error": "Unauthorized"})
            return
        }
        c.Set("user_id", claims.UserID)
        c.Next()
    }
}
```

## Package Structure

### `pkg/` - Shared Packages

Reusable packages that could be used by other applications:

- **`pkg/config/`**: Configuration management
- **`pkg/database/`**: Database connection pool
- **`pkg/utils/`**: Utility functions

### `internal/` - Application-Specific Code

Code specific to this application:

- **`internal/handlers/`**: HTTP handlers
- **`internal/service/`**: Business logic
- **`internal/repository/`**: Data access
- **`internal/models/`**: Domain models
- **`internal/middleware/`**: HTTP middleware
- **`internal/router/`**: Route configuration

### `cmd/` - Application Entry Points

- **`cmd/server/`**: Main API server
- **`cmd/jobs/`**: Background jobs (future)

## Database Connection Pool

### Configuration

```go
poolConfig.MaxConns = 25              // Maximum connections
poolConfig.MinConns = 5               // Minimum idle connections
poolConfig.MaxConnLifetime = 1h       // Connection lifetime
poolConfig.MaxConnIdleTime = 30m      // Idle timeout
poolConfig.HealthCheckPeriod = 1m     // Health check interval
```

### Usage

```go
// Query
rows, err := db.Pool.Query(ctx, "SELECT * FROM bookings WHERE guest_id = $1", guestID)

// QueryRow
var count int
err := db.Pool.QueryRow(ctx, "SELECT COUNT(*) FROM bookings").Scan(&count)

// Exec
_, err := db.Pool.Exec(ctx, "UPDATE bookings SET status = $1 WHERE booking_id = $2", status, id)
```

## Error Handling

### Error Types

1. **Validation Errors**: 400 Bad Request
2. **Authentication Errors**: 401 Unauthorized
3. **Authorization Errors**: 403 Forbidden
4. **Not Found Errors**: 404 Not Found
5. **Business Logic Errors**: 422 Unprocessable Entity
6. **Server Errors**: 500 Internal Server Error

### Error Response Format

```json
{
  "success": false,
  "error": "Error message",
  "details": {} // Optional
}
```

## Authentication Flow

1. User sends credentials to `/api/auth/login`
2. Server validates credentials
3. Server generates JWT token
4. Client stores token
5. Client sends token in `Authorization: Bearer <token>` header
6. Middleware validates token
7. Request proceeds with user context

## Transaction Management

### Pattern

```go
func (s *Service) OperationWithTransaction(ctx context.Context) error {
    tx, err := s.db.Pool.Begin(ctx)
    if err != nil {
        return err
    }
    defer tx.Rollback(ctx) // Rollback if not committed
    
    // Perform operations
    if err := s.repo.Operation1(ctx, tx); err != nil {
        return err
    }
    
    if err := s.repo.Operation2(ctx, tx); err != nil {
        return err
    }
    
    // Commit transaction
    return tx.Commit(ctx)
}
```

## Configuration Management

### Environment Variables

All configuration is loaded from environment variables:

```go
cfg, err := config.Load()
```

### Configuration Structure

```go
type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    JWT      JWTConfig
}
```

## Middleware Chain

Request flow through middleware:

1. **Recovery**: Catches panics
2. **Logger**: Logs requests
3. **CORS**: Handles CORS headers
4. **Auth** (protected routes): Validates JWT
5. **Handler**: Processes request

## API Response Patterns

### Success Response

```go
utils.SuccessResponse(c, 200, data)
```

Output:
```json
{
  "success": true,
  "data": { ... }
}
```

### Error Response

```go
utils.ErrorResponse(c, 400, "Invalid input")
```

Output:
```json
{
  "success": false,
  "error": "Invalid input"
}
```

## Testing Strategy

### Unit Tests

- Test individual functions
- Mock dependencies
- Focus on business logic

### Integration Tests

- Test database operations
- Use test database
- Test stored procedures

### End-to-End Tests

- Test complete API flows
- Use test environment
- Verify business scenarios

## Security Considerations

1. **Password Hashing**: bcrypt with cost 10
2. **JWT Tokens**: HS256 algorithm, 24-hour expiry
3. **SQL Injection**: Parameterized queries only
4. **CORS**: Whitelist specific origins
5. **Rate Limiting**: To be implemented
6. **Input Validation**: Gin binding validation

## Performance Optimizations

1. **Connection Pooling**: Reuse database connections
2. **Prepared Statements**: Cache query plans
3. **Indexes**: Database indexes on frequently queried columns
4. **Caching**: To be implemented (Redis)
5. **Pagination**: Limit result sets

## Deployment

### Build

```bash
go build -o bin/server ./cmd/server
```

### Docker

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o server ./cmd/server

FROM alpine:latest
COPY --from=builder /app/server /server
CMD ["/server"]
```

### Environment

- Development: `GIN_MODE=debug`
- Production: `GIN_MODE=release`

## Monitoring

### Health Checks

- `/health`: Basic health check
- `/health/db`: Database health with pool stats

### Logging

- Request/response logging
- Error logging
- Performance metrics

## Future Enhancements

1. **Caching Layer**: Redis for frequently accessed data
2. **Rate Limiting**: Prevent abuse
3. **API Documentation**: Swagger/OpenAPI
4. **Metrics**: Prometheus integration
5. **Tracing**: Distributed tracing
6. **Background Jobs**: Cron jobs for night audit, etc.

## Development Workflow

1. Create feature branch
2. Implement handler → service → repository
3. Write tests
4. Run tests and linter
5. Create pull request
6. Code review
7. Merge to main

## Code Style Guidelines

1. Use `gofmt` for formatting
2. Follow Go naming conventions
3. Write descriptive comments
4. Keep functions small and focused
5. Handle all errors explicitly
6. Use context for cancellation
7. Avoid global variables

## Dependencies

### Core

- `github.com/gin-gonic/gin`: Web framework
- `github.com/jackc/pgx/v5`: PostgreSQL driver
- `github.com/golang-jwt/jwt/v5`: JWT handling
- `golang.org/x/crypto`: Password hashing

### Utilities

- `github.com/joho/godotenv`: Environment variables
- `github.com/gin-contrib/cors`: CORS middleware

### Development

- `github.com/cosmtrek/air`: Hot reload
- `github.com/golangci/golangci-lint`: Linting

## References

- [Gin Documentation](https://gin-gonic.com/docs/)
- [pgx Documentation](https://pkg.go.dev/github.com/jackc/pgx/v5)
- [Go Best Practices](https://golang.org/doc/effective_go)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
