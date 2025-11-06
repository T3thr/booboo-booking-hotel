# Load Testing - Race Condition & Overbooking Prevention

This directory contains load tests for the hotel booking system, specifically designed to test race conditions, concurrent bookings, and database connection pool behavior.

## Overview

The load tests verify that the system:
1. **Prevents overbooking** when multiple users try to book the last available room simultaneously
2. **Handles race conditions** correctly using database-level locking
3. **Maintains database connection pool** stability under high load
4. **Ensures data integrity** even under stress conditions

## Prerequisites

### Install k6

**Windows (using Chocolatey):**
```cmd
choco install k6
```

**Windows (using Scoop):**
```cmd
scoop install k6
```

**macOS:**
```bash
brew install k6
```

**Linux:**
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

**Or download from:** https://k6.io/docs/getting-started/installation/

### System Requirements

- Backend API running on `http://localhost:8080` (or set `API_URL` environment variable)
- PostgreSQL database with test data
- At least 2GB RAM available for load testing
- Stable network connection

## Test Files

### 1. race-condition-test.js
Tests the system's ability to handle race conditions when multiple users try to book rooms simultaneously.

**What it tests:**
- 50+ concurrent users attempting bookings
- Proper inventory management (no overbooking)
- Database transaction handling
- Hold expiration mechanism

**Expected behavior:**
- Only available rooms should be booked
- No inventory violations (booked + tentative ≤ allotment)
- Failed bookings should fail gracefully
- System should remain stable

### 2. concurrent-booking-test.js
Specifically tests the "last room" scenario where 50 users try to book the same last available room.

**What it tests:**
- Exactly 50 users trying to book 1 room simultaneously
- Database-level locking (FOR UPDATE)
- Atomic inventory updates
- Proper error handling

**Expected behavior:**
- Exactly 1 booking should succeed
- 49 bookings should fail gracefully
- Zero inventory violations
- No database deadlocks

### 3. connection-pool-test.js
Stress tests the database connection pool under high load.

**What it tests:**
- High request rate (up to 150 req/s)
- Connection pool exhaustion scenarios
- Query performance under load
- Timeout handling

**Expected behavior:**
- Less than 5% error rate
- No connection pool errors
- Response times within acceptable limits
- Graceful degradation under extreme load

## Running the Tests

### Quick Start

```bash
cd load-tests

# Run all tests
npm run test:all

# Run individual tests
npm run test:race-condition
npm run test:concurrent-booking
npm run test:connection-pool
```

### Custom Test Runs

**Smoke test (quick validation):**
```bash
k6 run --vus 10 --duration 30s race-condition-test.js
```

**Stress test (high load):**
```bash
k6 run --vus 100 --duration 2m race-condition-test.js
```

**With custom API URL:**
```bash
k6 run -e API_URL=http://your-api:8080 race-condition-test.js
```

**With admin token (for test setup):**
```bash
k6 run -e API_URL=http://localhost:8080 -e ADMIN_TOKEN=your_token concurrent-booking-test.js
```

### Windows-Specific Commands

```cmd
cd load-tests

REM Run race condition test
k6 run race-condition-test.js

REM Run with environment variable
set API_URL=http://localhost:8080
k6 run race-condition-test.js

REM Run concurrent booking test
k6 run concurrent-booking-test.js

REM Run connection pool test
k6 run connection-pool-test.js
```

## Understanding the Results

### Key Metrics

**Successful Bookings:**
- Number of bookings that completed successfully
- Should be limited by actual room availability

**Failed Bookings:**
- Bookings that failed due to no availability
- This is EXPECTED and CORRECT behavior

**Overbookings/Inventory Violations:**
- **MUST BE ZERO** - Any value > 0 indicates a critical bug
- Indicates that booked + tentative exceeded allotment

**Response Times:**
- P95 should be < 2000ms for normal operations
- P99 should be < 5000ms under load

**Error Rate:**
- Should be < 10% for race condition tests
- Should be < 5% for connection pool tests

### Success Criteria

✅ **Test PASSES if:**
- Zero inventory violations
- No overbooking detected
- Failed bookings fail gracefully (not with errors)
- Response times within thresholds
- No database connection errors

❌ **Test FAILS if:**
- Any inventory violations occur
- Overbooking is detected
- High rate of database errors
- System becomes unresponsive

## Test Scenarios Explained

### Scenario 1: Race Condition Test
```
50 users → Search rooms → Create hold → Confirm booking
         ↓
    Some succeed, some fail (expected)
         ↓
    Verify: No overbooking occurred
```

### Scenario 2: Last Room Test
```
1 room available
50 users try to book it simultaneously
         ↓
    1 succeeds, 49 fail (expected)
         ↓
    Verify: Exactly 1 booking, no violations
```

### Scenario 3: Connection Pool Test
```
Ramp up to 150 requests/second
Test various endpoints
         ↓
    Monitor connection pool
         ↓
    Verify: No connection exhaustion
```

## Troubleshooting

### "Connection refused" errors
- Ensure backend is running: `docker-compose up backend`
- Check API_URL environment variable
- Verify port 8080 is accessible

### High failure rates
- Check database connection pool size in backend config
- Verify PostgreSQL has enough connections available
- Review backend logs for errors

### Slow response times
- Check database query performance
- Review indexes on frequently queried tables
- Monitor database CPU/memory usage

### Inventory violations detected
- **CRITICAL BUG** - Review database functions
- Check transaction isolation levels
- Verify FOR UPDATE locks are working
- Review booking hold and confirm logic

## Database Configuration

For optimal performance during load tests, ensure your PostgreSQL configuration includes:

```sql
-- Check current settings
SHOW max_connections;
SHOW shared_buffers;

-- Recommended settings for testing
-- max_connections = 100 (or higher)
-- shared_buffers = 256MB (or higher)
```

Backend connection pool should be configured appropriately:
```go
// backend/pkg/database/postgres.go
MaxOpenConns: 25,
MaxIdleConns: 10,
ConnMaxLifetime: 5 * time.Minute,
```

## Interpreting Results

### Example Good Result:
```
=== RACE CONDITION TEST SUMMARY ===
Successful Bookings: 15
Failed Bookings: 35
Overbookings Detected: 0
Total Booking Attempts: 50
✅ NO OVERBOOKING DETECTED - System passed race condition test!
```

### Example Bad Result:
```
=== RACE CONDITION TEST SUMMARY ===
Successful Bookings: 18
Failed Bookings: 32
Overbookings Detected: 3
Total Booking Attempts: 50
❌ OVERBOOKING DETECTED - System failed race condition test!
```

## Next Steps After Testing

1. **If tests pass:** System is ready for production load
2. **If tests fail:** 
   - Review database function implementations
   - Check transaction isolation levels
   - Verify locking mechanisms
   - Review concurrent access patterns

## Additional Resources

- [k6 Documentation](https://k6.io/docs/)
- [PostgreSQL Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [Database Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)

## Task Verification

This load testing suite verifies:
- ✅ Concurrent bookings (50+ users)
- ✅ Last room race condition
- ✅ No overbooking occurs
- ✅ Database connection pool stability
- ✅ Requirements 3.1-3.8, 4.1-4.9
