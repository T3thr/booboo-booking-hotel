# Hotel Booking System - Backend API

Go-based REST API server for the Hotel Booking System.

## Prerequisites

- Go 1.21 or higher
- PostgreSQL 15+
- Make (optional, for using Makefile commands)

## Project Structure

```
backend/
├── cmd/
│   └── server/
│       └── main.go              # Application entry point
├── internal/
│   ├── handlers/                # HTTP request handlers
│   ├── middleware/              # HTTP middleware (auth, cors, logger, etc.)
│   │   ├── cors.go
│   │   ├── logger.go
│   │   └── recovery.go
│   ├── models/                  # Data models
│   ├── repository/              # Database access layer
│   ├── router/                  # Router setup
│   │   └── router.go
│   └── service/                 # Business logic layer
├── pkg/
│   ├── config/                  # Configuration management
│   │   └── config.go
│   ├── database/                # Database connection pool
│   │   └── postgres.go
│   └── utils/                   # Utility functions
│       └── response.go
├── .env.example                 # Example environment variables
├── go.mod                       # Go module definition
└── go.sum                       # Go module checksums
```

## Setup

### 1. Install Dependencies

```bash
go mod download
```

### 2. Configure Environment Variables

Copy the example environment file and update with your settings:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Server Configuration
PORT=8080
GIN_MODE=debug

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=hotel_booking
DB_SSLMODE=disable

# JWT Configuration
JWT_SECRET=your-secret-key-change-in-production

# CORS Configuration
FRONTEND_URL=http://localhost:3000
```

### 3. Ensure Database is Running

Make sure PostgreSQL is running and the database is created:

```bash
# Using docker-compose from project root
docker-compose up -d postgres

# Or manually create database
psql -U postgres -c "CREATE DATABASE hotel_booking;"
```

### 4. Run Migrations

Run the database migrations from the project root:

```bash
# Windows
database\migrations\run_migration_001.bat
database\migrations\run_migration_002.bat
database\migrations\run_migration_003.bat
database\migrations\run_migration_004.bat

# Linux/Mac
./database/migrations/run_migration_001.sh
./database/migrations/run_migration_002.sh
./database/migrations/run_migration_003.sh
./database/migrations/run_migration_004.sh
```

## Running the Server

### Development Mode (with hot reload)

Using Air for hot reload:

```bash
air
```

### Standard Go Run

```bash
go run cmd/server/main.go
```

### Build and Run

```bash
# Build
go build -o bin/server ./cmd/server

# Run
./bin/server
```

## API Endpoints

### Health Checks

- `GET /health` - Basic health check
- `GET /health/db` - Database health check with connection pool stats

### API Routes

- `GET /api/` - API version info

### Placeholder Routes (to be implemented)

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/rooms/search` - Search available rooms
- `GET /api/rooms/types` - Get room types
- `POST /api/bookings/hold` - Create booking hold
- `POST /api/bookings` - Create booking

## Testing

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with verbose output
go test -v ./...
```

## Code Quality

```bash
# Format code
go fmt ./...

# Run linter (requires golangci-lint)
golangci-lint run

# Check for common mistakes
go vet ./...
```

## Docker

### Build Docker Image

```bash
docker build -t hotel-booking-backend .
```

### Run with Docker Compose

From project root:

```bash
docker-compose up backend
```

## Architecture

### Layers

1. **Handler Layer** (`internal/handlers/`)
   - Handles HTTP requests and responses
   - Validates input
   - Calls service layer

2. **Service Layer** (`internal/service/`)
   - Contains business logic
   - Orchestrates operations
   - Calls repository layer

3. **Repository Layer** (`internal/repository/`)
   - Database access
   - Executes queries and stored procedures
   - Returns data models

4. **Middleware** (`internal/middleware/`)
   - CORS handling
   - Authentication/Authorization
   - Logging
   - Error recovery

### Database Connection Pool

The application uses pgx v5 with connection pooling:

- Max connections: 25
- Min connections: 5
- Max connection lifetime: 1 hour
- Max connection idle time: 30 minutes
- Health check period: 1 minute

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 8080 |
| GIN_MODE | Gin mode (debug/release) | debug |
| DB_HOST | Database host | localhost |
| DB_PORT | Database port | 5432 |
| DB_USER | Database user | postgres |
| DB_PASSWORD | Database password | (required) |
| DB_NAME | Database name | hotel_booking |
| DB_SSLMODE | SSL mode | disable |
| JWT_SECRET | JWT signing secret | (required) |
| FRONTEND_URL | Frontend URL for CORS | http://localhost:3000 |

## Troubleshooting

### Database Connection Issues

1. Check if PostgreSQL is running
2. Verify database credentials in `.env`
3. Ensure database exists
4. Check firewall settings

### Port Already in Use

Change the PORT in `.env` file or kill the process using the port:

```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8080 | xargs kill -9
```

## Next Steps

- Implement authentication handlers (Task 8)
- Implement authentication middleware (Task 9)
- Implement room search module (Task 10)
- Implement booking management (Task 15)

## License

Proprietary - Hotel Booking System Project


## 📋 Latest Updates - Task 15: Booking Module

### ✅ Complete Booking System Implemented

The booking module provides a full-featured reservation system with:
- Temporary holds (15-minute reservation)
- Complete booking creation with guest details
- Payment confirmation
- Cancellation with refund calculation
- Booking history and details

### Quick Documentation Links

- **[TASK_15_INDEX.md](TASK_15_INDEX.md)** - Documentation index and navigation
- **[TASK_15_SUMMARY.md](TASK_15_SUMMARY.md)** - Quick overview and getting started
- **[TEST_BOOKING_MODULE.md](TEST_BOOKING_MODULE.md)** - Complete testing guide
- **[BOOKING_QUICK_REFERENCE.md](BOOKING_QUICK_REFERENCE.md)** - API reference
- **[BOOKING_MODULE_POSTMAN.json](BOOKING_MODULE_POSTMAN.json)** - Postman collection

### New API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/bookings/hold` | POST | No | Create 15-min temporary hold |
| `/api/bookings` | POST | Yes | Create booking with details |
| `/api/bookings/:id/confirm` | POST | Yes | Confirm and process payment |
| `/api/bookings/:id/cancel` | POST | Yes | Cancel with refund |
| `/api/bookings` | GET | Yes | List user's bookings |
| `/api/bookings/:id` | GET | Yes | Get booking details |

### Quick Test

```bash
# Start server
go run cmd/server/main.go

# Register user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","last_name":"User","email":"test@example.com","phone":"1234567890","password":"password123"}'

# Login (save the token)
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Create booking hold
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test-123","room_type_id":1,"check_in":"2025-12-01","check_out":"2025-12-03"}'
```

### Implementation Files

- `internal/models/booking.go` - Booking data models
- `internal/repository/booking_repository.go` - Database operations
- `internal/service/booking_service.go` - Business logic
- `internal/handlers/booking_handler.go` - HTTP handlers
- `internal/router/router.go` - Route registration (updated)

### Requirements Covered

✅ Requirement 3.1-3.8: Booking Hold  
✅ Requirement 4.1-4.9: Payment & Confirmation  
✅ Requirement 5.1-5.7: Booking History  
✅ Requirement 6.1-6.9: Cancellation  

### Next Steps

1. Test the booking module using the Postman collection
2. Verify all endpoints work correctly
3. Proceed to Task 16: Frontend Setup (Next.js)
