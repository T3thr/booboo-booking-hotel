# Task 42: Load Testing - Race Conditions

## Quick Links

- **[Quick Start Guide](./QUICKSTART.md)** - Get started in 5 minutes
- **[Complete Documentation](./README.md)** - Full load testing guide
- **[Verification Checklist](./TASK_42_VERIFICATION_CHECKLIST.md)** - Test verification steps
- **[Completion Summary](./TASK_42_COMPLETION_SUMMARY.md)** - Task overview and results

## What This Task Accomplishes

This task implements comprehensive load testing to verify that the hotel booking system:

1. ✅ **Prevents Overbooking** - No room can be booked beyond its capacity
2. ✅ **Handles Race Conditions** - Multiple users booking simultaneously works correctly
3. ✅ **Maintains Data Integrity** - Database constraints enforced under load
4. ✅ **Scales Properly** - Connection pool handles high request rates

## Test Suite Overview

### 1. Race Condition Test
- **File:** `race-condition-test.js`
- **Purpose:** Test 50+ concurrent users booking rooms
- **Duration:** ~2 minutes
- **Critical Check:** Zero overbookings detected

### 2. Concurrent Booking Test
- **File:** `concurrent-booking-test.js`
- **Purpose:** Test 50 users trying to book the last room
- **Duration:** ~2 minutes
- **Critical Check:** Only 1 booking succeeds, 49 fail gracefully

### 3. Connection Pool Test
- **File:** `connection-pool-test.js`
- **Purpose:** Stress test database connections
- **Duration:** ~3 minutes
- **Critical Check:** No connection pool exhaustion

## Quick Commands

### Run All Tests
```bash
cd load-tests
./run_load_tests.sh    # Unix/Linux/macOS
run_load_tests.bat     # Windows
```

### Run Individual Tests
```bash
# Race condition test
k6 run race-condition-test.js

# Last room test
k6 run concurrent-booking-test.js

# Connection pool test
k6 run connection-pool-test.js
```

### Quick Smoke Test
```bash
k6 run --vus 10 --duration 30s race-condition-test.js
```

## Success Criteria

### ✅ Tests Pass If:
- Overbookings Detected = **0**
- Inventory Violations = **0**
- Error Rate < **10%**
- Response Time P95 < **2 seconds**
- No database deadlocks

### ❌ Tests Fail If:
- Any overbooking detected
- Any inventory violations
- Database connection errors
- System crashes or hangs

## File Structure

```
load-tests/
├── race-condition-test.js          # Main race condition test
├── concurrent-booking-test.js      # Last room scenario test
├── connection-pool-test.js         # Connection pool stress test
├── package.json                    # NPM scripts
├── run_load_tests.bat             # Windows test runner
├── run_load_tests.sh              # Unix/Linux/macOS test runner
├── README.md                       # Complete documentation
├── QUICKSTART.md                   # 5-minute setup guide
├── TASK_42_INDEX.md               # This file
├── TASK_42_VERIFICATION_CHECKLIST.md  # Verification steps
└── TASK_42_COMPLETION_SUMMARY.md  # Task completion details
```

## Requirements Verified

This task verifies the following requirements:

### Requirements 3.1-3.8 (Booking Hold)
- Concurrent hold creation
- Atomic inventory updates
- Race condition prevention
- Hold expiration handling

### Requirements 4.1-4.9 (Booking Confirmation)
- Concurrent booking confirmation
- Inventory integrity
- Transaction handling
- No overbooking

## Installation

### Install k6

**Windows:**
```cmd
choco install k6
```

**macOS:**
```bash
brew install k6
```

**Linux:**
```bash
# See https://k6.io/docs/getting-started/installation/
```

## Running Tests

### Step 1: Start the System
```bash
docker-compose up -d
```

### Step 2: Run Tests
```bash
cd load-tests
./run_load_tests.sh  # or run_load_tests.bat on Windows
```

### Step 3: Review Results
Check the output for:
- Successful Bookings count
- Failed Bookings count
- **Overbookings Detected (MUST BE 0)**
- **Inventory Violations (MUST BE 0)**

## Expected Results

### Good Result
```
=== RACE CONDITION TEST SUMMARY ===
Successful Bookings: 15
Failed Bookings: 35
Overbookings Detected: 0          ← MUST BE 0
✅ NO OVERBOOKING DETECTED - System passed!
```

### Bad Result
```
=== RACE CONDITION TEST SUMMARY ===
Overbookings Detected: 3          ← BAD!
❌ OVERBOOKING DETECTED - System failed!
```

## Troubleshooting

### "k6 not found"
- Install k6 (see Installation section)
- Restart terminal after installation

### "Connection refused"
- Start backend: `docker-compose up backend`
- Check API URL: `http://localhost:8080`

### High failure rates
- Normal if rooms are fully booked
- Check database has test data
- Review backend logs

## Next Steps

1. ✅ Run smoke test (30 seconds)
2. ✅ Run full race condition test
3. ✅ Run concurrent booking test
4. ✅ Run connection pool test
5. ✅ Verify zero overbookings
6. ✅ Review performance metrics

## Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - Fast setup and basic usage
- **[README.md](./README.md)** - Complete guide with examples
- **[TASK_42_VERIFICATION_CHECKLIST.md](./TASK_42_VERIFICATION_CHECKLIST.md)** - Detailed verification
- **[TASK_42_COMPLETION_SUMMARY.md](./TASK_42_COMPLETION_SUMMARY.md)** - Implementation details

## Support

For issues or questions:
1. Check the [README.md](./README.md) troubleshooting section
2. Review the [QUICKSTART.md](./QUICKSTART.md) guide
3. Verify prerequisites are met
4. Check backend logs for errors

---

**Task Status:** ✅ COMPLETE  
**Last Updated:** 2025-11-03
