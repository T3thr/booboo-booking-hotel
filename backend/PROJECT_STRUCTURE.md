# Backend Project Structure

## Visual Overview

```
backend/
│
├── 📁 cmd/                          # Application entry points
│   └── 📁 server/
│       └── 📄 main.go              # ⭐ Main application entry point
│                                    #    - Loads configuration
│                                    #    - Initializes database
│                                    #    - Sets up router
│                                    #    - Starts HTTP server
│                                    #    - Handles graceful shutdown
│
├── 📁 internal/                     # Private application code
│   │
│   ├── 📁 handlers/                # 🎯 HTTP Request Handlers
│   │   └── .gitkeep               #    (To be implemented in Task 8+)
│   │                               #    - Validate requests
│   │                               #    - Call services
│   │                               #    - Return responses
│   │
│   ├── 📁 middleware/              # 🛡️ HTTP Middleware
│   │   ├── 📄 cors.go             #    - CORS configuration
│   │   ├── 📄 logger.go           #    - Request logging
│   │   └── 📄 recovery.go         #    - Panic recovery
│   │
│   ├── 📁 models/                  # 📦 Data Models
│   │   └── .gitkeep               #    (To be implemented in Task 8+)
│   │                               #    - Domain entities
│   │                               #    - Validation tags
│   │
│   ├── 📁 repository/              # 💾 Database Access Layer
│   │   └── .gitkeep               #    (To be implemented in Task 8+)
│   │                               #    - SQL queries
│   │                               #    - Stored procedures
│   │
│   ├── 📁 router/                  # 🛣️ Route Configuration
│   │   └── 📄 router.go           #    - Route definitions
│   │                               #    - Middleware setup
│   │                               #    - Route groups
│   │
│   └── 📁 service/                 # 💼 Business Logic
│       └── .gitkeep               #    (To be implemented in Task 8+)
│                                   #    - Business rules
│                                   #    - Transactions
│
├── 📁 pkg/                         # 🔧 Shared/Reusable Packages
│   │
│   ├── 📁 config/                  # ⚙️ Configuration Management
│   │   ├── 📄 config.go           #    - Load environment variables
│   │   │                           #    - Validate configuration
│   │   │                           #    - Provide defaults
│   │   └── 📄 config_test.go      #    - Configuration tests
│   │
│   ├── 📁 database/                # 🗄️ Database Connection
│   │   └── 📄 postgres.go         #    - Connection pool setup
│   │                               #    - Health checks
│   │                               #    - Pool statistics
│   │
│   └── 📁 utils/                   # 🛠️ Utility Functions
│       └── 📄 response.go         #    - Response helpers
│                                   #    - Error formatting
│
├── 📄 .air.toml                    # Air hot reload config
├── 📄 .dockerignore                # Docker ignore patterns
├── 📄 .env.example                 # Environment variables template
├── 📄 .gitkeep                     # Git placeholder
├── 📄 Dockerfile                   # Production Docker image
├── 📄 Dockerfile.dev               # Development Docker image
├── 📄 go.mod                       # Go module definition
├── 📄 go.sum                       # Go module checksums
├── 📄 Makefile                     # Build commands
│
└── 📚 Documentation/
    ├── 📄 README.md                # Setup and usage guide
    ├── 📄 ARCHITECTURE.md          # Architecture details
    ├── 📄 QUICK_START.md           # Quick start guide
    └── 📄 PROJECT_STRUCTURE.md     # This file
```

## Request Flow

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP Request
       ▼
┌─────────────────────────────────────────┐
│         Gin Router (router.go)          │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│  Middleware Chain                       │
│  1. Recovery (panic handling)           │
│  2. Logger (request logging)            │
│  3. CORS (cross-origin)                 │
│  4. Auth (JWT validation) [optional]    │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│  Handler (handlers/)                    │
│  - Validate request                     │
│  - Parse input                          │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│  Service (service/)                     │
│  - Business logic                       │
│  - Orchestrate operations               │
│  - Manage transactions                  │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│  Repository (repository/)               │
│  - Execute SQL queries                  │
│  - Call stored procedures               │
│  - Map results to models                │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│  PostgreSQL Database                    │
│  - Tables                               │
│  - Functions                            │
│  - Constraints                          │
└─────────────────────────────────────────┘
```

## Layer Responsibilities

### 🎯 Handler Layer
**Location**: `internal/handlers/`  
**Purpose**: HTTP request/response handling  
**Responsibilities**:
- Receive HTTP requests
- Validate input data
- Call service layer
- Format responses
- Handle HTTP errors

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

### 💼 Service Layer
**Location**: `internal/service/`  
**Purpose**: Business logic implementation  
**Responsibilities**:
- Implement business rules
- Orchestrate operations
- Manage transactions
- Transform data
- Validate business constraints

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
    
    // Commit
    if err := tx.Commit(ctx); err != nil {
        return nil, err
    }
    
    return booking, nil
}
```

### 💾 Repository Layer
**Location**: `internal/repository/`  
**Purpose**: Database access  
**Responsibilities**:
- Execute SQL queries
- Call stored procedures
- Map database rows to models
- Handle database errors
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

### 📦 Model Layer
**Location**: `internal/models/`  
**Purpose**: Data structures  
**Responsibilities**:
- Define domain entities
- Validation tags
- JSON serialization
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

### 🛡️ Middleware Layer
**Location**: `internal/middleware/`  
**Purpose**: Request/response processing  
**Responsibilities**:
- Authentication
- Authorization
- CORS handling
- Logging
- Error recovery
- Rate limiting

## Configuration Flow

```
┌─────────────────┐
│  .env file      │
│  (development)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Environment Variables  │
│  (production)           │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  config.Load()          │
│  - Parse variables      │
│  - Apply defaults       │
│  - Validate             │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Config struct          │
│  - Server config        │
│  - Database config      │
│  - JWT config           │
└─────────────────────────┘
```

## Database Connection Pool

```
┌──────────────────────────────────────┐
│  Application                         │
│  ┌────────────────────────────────┐  │
│  │  Handler 1  ──┐                │  │
│  │  Handler 2  ──┤                │  │
│  │  Handler 3  ──┤                │  │
│  │  Handler 4  ──┤                │  │
│  │  Handler 5  ──┤                │  │
│  └───────────────┼────────────────┘  │
│                  │                    │
│                  ▼                    │
│  ┌────────────────────────────────┐  │
│  │  Connection Pool               │  │
│  │  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐    │  │
│  │  │C1│ │C2│ │C3│ │C4│ │C5│    │  │
│  │  └──┘ └──┘ └──┘ └──┘ └──┘    │  │
│  │  Max: 25 | Min: 5             │  │
│  └────────────────┬───────────────┘  │
└───────────────────┼──────────────────┘
                    │
                    ▼
         ┌──────────────────┐
         │  PostgreSQL DB   │
         └──────────────────┘
```

## Dependency Injection

```
main.go
  │
  ├─► config.Load()
  │     └─► Config
  │
  ├─► database.New(config)
  │     └─► DB (connection pool)
  │
  └─► router.Setup(config, db)
        │
        ├─► Middleware setup
        │
        └─► Handler initialization
              │
              ├─► Service initialization
              │     │
              │     └─► Repository initialization
              │           │
              │           └─► Uses DB pool
              │
              └─► Routes registration
```

## File Naming Conventions

- **Handlers**: `{entity}_handler.go` (e.g., `auth_handler.go`)
- **Services**: `{entity}_service.go` (e.g., `booking_service.go`)
- **Repositories**: `{entity}_repository.go` (e.g., `room_repository.go`)
- **Models**: `{entity}.go` (e.g., `booking.go`)
- **Tests**: `{filename}_test.go` (e.g., `config_test.go`)

## Package Import Paths

```go
import (
    // Standard library
    "context"
    "fmt"
    
    // Third-party
    "github.com/gin-gonic/gin"
    "github.com/jackc/pgx/v5"
    
    // Internal packages
    "github.com/hotel-booking-system/backend/internal/handlers"
    "github.com/hotel-booking-system/backend/internal/service"
    "github.com/hotel-booking-system/backend/pkg/config"
    "github.com/hotel-booking-system/backend/pkg/database"
)
```

## Current Status

### ✅ Completed (Task 7)
- Project structure
- Configuration management
- Database connection pool
- Router setup
- Middleware (CORS, Logger, Recovery)
- Health check endpoints
- Documentation

### 🔜 To Be Implemented
- **Task 8**: Authentication handlers
- **Task 9**: Authentication middleware
- **Task 10**: Room search handlers
- **Task 15**: Booking handlers

## Quick Reference

### Start Server
```bash
go run cmd/server/main.go
```

### Test Endpoints
```bash
curl http://localhost:8080/health
curl http://localhost:8080/health/db
curl http://localhost:8080/api/
```

### Run Tests
```bash
go test ./...
```

### Format Code
```bash
go fmt ./...
```

## Key Files to Know

1. **`cmd/server/main.go`** - Application entry point
2. **`internal/router/router.go`** - Route definitions
3. **`pkg/config/config.go`** - Configuration
4. **`pkg/database/postgres.go`** - Database pool
5. **`.env`** - Your configuration

## Next Steps

1. Review the structure
2. Understand the flow
3. Start implementing Task 8 (Authentication)
4. Follow the layer pattern for new features

---

**Legend**:
- 📁 Folder
- 📄 File
- ⭐ Important file
- 🎯 Handler layer
- 💼 Service layer
- 💾 Repository layer
- 📦 Model layer
- 🛡️ Middleware
- ⚙️ Configuration
- 🗄️ Database
- 🛠️ Utilities
- 📚 Documentation
