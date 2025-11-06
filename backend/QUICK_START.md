# Backend Quick Start Guide

## Prerequisites

- Go 1.21+ installed
- PostgreSQL running (via Docker or local)
- Database migrations completed (Tasks 3-6)

## Quick Setup (5 minutes)

### 1. Install Dependencies
```bash
cd backend
go mod download
```

### 2. Configure Environment
```bash
cp .env.example .env
```

Edit `.env`:
```env
DB_PASSWORD=postgres123
JWT_SECRET=your-secret-key-here
```

### 3. Start Database
```bash
# From project root
docker-compose up -d postgres
```

### 4. Run Server
```bash
go run cmd/server/main.go
```

Server will start on http://localhost:8080

## Verify Installation

### Test Health Endpoint
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "ok",
  "message": "Hotel Booking System API is running"
}
```

### Test Database Connection
```bash
curl http://localhost:8080/health/db
```

Expected response:
```json
{
  "status": "ok",
  "total_conns": 10,
  "idle_conns": 5,
  "acquired_conns": 5,
  "constructing_conns": 0
}
```

## Development Mode (Hot Reload)

### Install Air
```bash
go install github.com/cosmtrek/air@latest
```

### Run with Hot Reload
```bash
air
```

Changes to `.go` files will automatically reload the server.

## Project Structure

```
backend/
├── cmd/server/main.go          # Start here - application entry point
├── internal/
│   ├── router/router.go        # Route definitions
│   ├── middleware/             # CORS, logging, auth
│   ├── handlers/               # HTTP handlers (to be implemented)
│   ├── service/                # Business logic (to be implemented)
│   └── repository/             # Database access (to be implemented)
├── pkg/
│   ├── config/config.go        # Configuration management
│   ├── database/postgres.go   # Database connection pool
│   └── utils/response.go       # Response helpers
└── .env                        # Your configuration
```

## Available Endpoints

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/health` | Health check | ✅ Working |
| GET | `/health/db` | Database health | ✅ Working |
| GET | `/api/` | API info | ✅ Working |
| POST | `/api/auth/register` | Register user | 🔜 Task 8 |
| POST | `/api/auth/login` | Login | 🔜 Task 8 |
| GET | `/api/rooms/search` | Search rooms | 🔜 Task 10 |
| POST | `/api/bookings/hold` | Hold booking | 🔜 Task 15 |

## Common Commands

```bash
# Run tests
go test ./...

# Format code
go fmt ./...

# Build binary
go build -o bin/server ./cmd/server

# Run binary
./bin/server
```

## Troubleshooting

### Port 8080 already in use
Change `PORT` in `.env` file:
```env
PORT=8081
```

### Database connection failed
1. Check if PostgreSQL is running:
   ```bash
   docker-compose ps
   ```

2. Verify database credentials in `.env`

3. Test connection manually:
   ```bash
   psql -h localhost -U postgres -d hotel_booking
   ```

### Go not found
Install Go from https://go.dev/dl/

## Next Steps

1. ✅ **Task 7 Complete**: Project structure ready
2. 🔜 **Task 8**: Implement authentication (register/login)
3. 🔜 **Task 9**: Add authentication middleware
4. 🔜 **Task 10**: Implement room search

## Need Help?

- See `README.md` for detailed documentation
- See `ARCHITECTURE.md` for architecture details
- Check `TASK_7_COMPLETION.md` for implementation summary

## Quick Test Script

Save as `test.sh`:
```bash
#!/bin/bash
echo "Testing health endpoint..."
curl -s http://localhost:8080/health | jq

echo -e "\nTesting database health..."
curl -s http://localhost:8080/health/db | jq

echo -e "\nTesting API info..."
curl -s http://localhost:8080/api/ | jq
```

Run:
```bash
chmod +x test.sh
./test.sh
```

## Development Workflow

1. Make changes to code
2. Server auto-reloads (if using Air)
3. Test with curl or Postman
4. Run tests: `go test ./...`
5. Commit changes

Happy coding! 🚀
