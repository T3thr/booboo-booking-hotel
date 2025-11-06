# Docker Setup Testing Guide

This document provides step-by-step instructions to test the Docker setup for the Hotel Booking System.

## Pre-Test Checklist

- [ ] Docker Desktop is installed and running
- [ ] Docker Compose is available
- [ ] Ports 3000, 8080, and 5432 are not in use
- [ ] At least 4GB RAM available
- [ ] At least 5GB disk space available

## Test 1: Configuration Validation

### Test Docker Compose Configuration
```bash
docker-compose config
```

**Expected Result**: Configuration should be parsed without errors (warnings about version are okay).

## Test 2: Build Images

### Build all images
```bash
docker-compose build
```

**Expected Results**:
- ✅ PostgreSQL image pulled successfully
- ✅ Backend image built successfully
- ✅ Frontend image built successfully
- ⏱️ Time: 5-10 minutes (first time)

### Verify images
```bash
docker images | grep hotel-booking
```

**Expected Output**: Should show 2 images (backend and frontend)

## Test 3: Start Services

### Start all containers
```bash
docker-compose up -d
```

**Expected Results**:
- ✅ Database container starts first
- ✅ Backend waits for database health check
- ✅ Frontend starts after backend
- ⏱️ Time: 30-60 seconds

### Check container status
```bash
docker-compose ps
```

**Expected Output**: All 3 containers should be "Up" and healthy

## Test 4: Service Health Checks

### Test Database Connection
```bash
docker exec hotel-booking-db psql -U postgres -d hotel_booking -c "SELECT version();"
```

**Expected Result**: PostgreSQL version information displayed

### Test Backend API
```bash
curl http://localhost:8080/health
```

**Expected Response**:
```json
{
  "status": "ok",
  "message": "Hotel Booking System API is running"
}
```

### Test Frontend
Open browser and navigate to: http://localhost:3000

**Expected Result**: Homepage displays with "ระบบจองโรงแรมและที่พัก" title

## Test 5: Hot Reload (Development)

### Test Backend Hot Reload

1. Edit `backend/cmd/server/main.go`
2. Change the health check message
3. Save the file
4. Check logs:
```bash
docker-compose logs -f backend
```

**Expected Result**: Air should detect changes and rebuild automatically

### Test Frontend Hot Reload

1. Edit `frontend/src/app/page.tsx`
2. Change some text
3. Save the file
4. Refresh browser

**Expected Result**: Changes should appear immediately

## Test 6: Logs and Monitoring

### View all logs
```bash
docker-compose logs -f
```

### View specific service logs
```bash
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db
```

**Expected Result**: Logs should stream in real-time

## Test 7: Database Operations

### Access PostgreSQL Shell
```bash
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking
```

### Run test query
```sql
SELECT current_database();
\q
```

**Expected Result**: Should show "hotel_booking" as current database

## Test 8: Network Connectivity

### Test Backend to Database
```bash
docker exec hotel-booking-backend ping -c 3 db
```

**Expected Result**: Successful ping responses

### Test Frontend to Backend
```bash
docker exec hotel-booking-frontend wget -O- http://backend:8080/health
```

**Expected Result**: Health check response received

## Test 9: Resource Usage

### Check resource consumption
```bash
docker stats --no-stream
```

**Expected Results**:
- Database: ~50-100MB RAM
- Backend: ~20-50MB RAM
- Frontend: ~100-200MB RAM

## Test 10: Stop and Restart

### Stop services
```bash
docker-compose down
```

**Expected Result**: All containers stop gracefully

### Restart services
```bash
docker-compose up -d
```

**Expected Result**: All services start successfully

## Test 11: Data Persistence

### Create test data
```bash
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "CREATE TABLE test (id SERIAL PRIMARY KEY, name VARCHAR(100));"
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "INSERT INTO test (name) VALUES ('Test Data');"
```

### Stop and restart
```bash
docker-compose down
docker-compose up -d
```

### Verify data persists
```bash
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "SELECT * FROM test;"
```

**Expected Result**: Test data should still exist

### Cleanup
```bash
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "DROP TABLE test;"
```

## Test 12: Makefile Commands

### Test make commands
```bash
make help
make ps
make logs-backend
make logs-frontend
make logs-db
```

**Expected Result**: All commands execute successfully

## Test 13: Clean Up

### Remove all containers and volumes
```bash
docker-compose down -v
```

**Expected Result**: All containers, networks, and volumes removed

### Verify cleanup
```bash
docker-compose ps
docker volume ls | grep hotel-booking
```

**Expected Result**: No containers or volumes should exist

## Troubleshooting Tests

### If Backend Fails to Start

1. Check logs:
```bash
docker-compose logs backend
```

2. Check if Go modules downloaded:
```bash
docker exec hotel-booking-backend ls -la /app
```

3. Rebuild:
```bash
docker-compose build --no-cache backend
docker-compose up -d backend
```

### If Frontend Fails to Start

1. Check logs:
```bash
docker-compose logs frontend
```

2. Check if node_modules installed:
```bash
docker exec hotel-booking-frontend ls -la /app/node_modules
```

3. Rebuild:
```bash
docker-compose build --no-cache frontend
docker-compose up -d frontend
```

### If Database Connection Fails

1. Check database health:
```bash
docker inspect hotel-booking-db | grep -A 10 Health
```

2. Check connection string:
```bash
docker exec hotel-booking-backend env | grep DATABASE_URL
```

3. Test connection manually:
```bash
docker exec hotel-booking-backend ping db
```

## Performance Tests

### Test Concurrent Requests
```bash
# Install Apache Bench (ab) if not available
# Windows: Download from Apache website
# Linux: sudo apt-get install apache2-utils
# Mac: brew install ab

# Test backend
ab -n 1000 -c 10 http://localhost:8080/health

# Test frontend
ab -n 100 -c 5 http://localhost:3000/
```

**Expected Results**:
- Backend: >500 requests/second
- Frontend: >50 requests/second

## Security Tests

### Test Port Exposure
```bash
netstat -an | grep LISTEN | grep -E "3000|8080|5432"
```

**Expected Result**: All three ports should be listening

### Test Environment Variables
```bash
docker exec hotel-booking-backend env | grep -E "JWT_SECRET|DATABASE_URL"
```

**Expected Result**: Secrets should be set (but not displayed in production)

## Test Results Summary

Create a checklist of all tests:

- [ ] Configuration validation passed
- [ ] Images built successfully
- [ ] All services started
- [ ] Database connection works
- [ ] Backend API responds
- [ ] Frontend loads
- [ ] Hot reload works (backend)
- [ ] Hot reload works (frontend)
- [ ] Logs accessible
- [ ] Database operations work
- [ ] Network connectivity verified
- [ ] Resource usage acceptable
- [ ] Stop/restart works
- [ ] Data persists
- [ ] Makefile commands work
- [ ] Clean up successful

## Next Steps After Testing

If all tests pass:
1. ✅ Docker setup is complete
2. ✅ Ready to run database migrations
3. ✅ Ready to start development
4. ✅ Proceed to Task 3 in tasks.md

If any tests fail:
1. Review error messages
2. Check DOCKER_SETUP.md troubleshooting section
3. Verify system requirements
4. Check Docker Desktop settings
5. Restart Docker Desktop and try again

---

**Note**: This testing guide ensures that the Docker setup is working correctly before proceeding with development.
