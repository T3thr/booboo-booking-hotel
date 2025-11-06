# Load Testing Quick Start Guide

## 5-Minute Setup

### Step 1: Install k6

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

### Step 2: Start the System

```bash
# From project root
docker-compose up -d
```

Wait for services to be ready (~30 seconds).

### Step 3: Run Tests

**Windows:**
```cmd
cd load-tests
run_load_tests.bat
```

**Unix/Linux/macOS:**
```bash
cd load-tests
chmod +x run_load_tests.sh
./run_load_tests.sh
```

### Step 4: Select Test

Choose from the menu:
- **Option 1**: Race Condition Test (recommended first test)
- **Option 2**: Concurrent Booking Test (tests last room scenario)
- **Option 3**: Connection Pool Test (stress test)
- **Option 4**: Run all tests
- **Option 5**: Quick smoke test (30 seconds)

## What to Look For

### ✅ Success Indicators

```
=== RACE CONDITION TEST SUMMARY ===
Successful Bookings: 15
Failed Bookings: 35
Overbookings Detected: 0          ← MUST BE 0
Total Booking Attempts: 50
✅ NO OVERBOOKING DETECTED - System passed race condition test!
```

### ❌ Failure Indicators

```
Overbookings Detected: 3           ← BAD! Should be 0
❌ OVERBOOKING DETECTED - System failed race condition test!
```

## Quick Test Commands

### Smoke Test (30 seconds)
```bash
k6 run --vus 10 --duration 30s race-condition-test.js
```

### Race Condition Test
```bash
k6 run race-condition-test.js
```

### Last Room Test
```bash
k6 run concurrent-booking-test.js
```

### Connection Pool Stress Test
```bash
k6 run connection-pool-test.js
```

## Troubleshooting

**"Connection refused"**
- Backend not running: `docker-compose up backend`
- Wrong port: Set `API_URL=http://localhost:8080`

**"k6 not found"**
- Install k6 (see Step 1)
- Restart terminal after installation

**High failure rates**
- Normal if rooms are fully booked
- Check database has test data
- Review backend logs

## Understanding Results

| Metric | Good | Bad |
|--------|------|-----|
| Overbookings | 0 | > 0 |
| Inventory Violations | 0 | > 0 |
| Error Rate | < 10% | > 20% |
| Response Time P95 | < 2s | > 5s |

## Next Steps

1. ✅ All tests pass → System ready for production
2. ❌ Tests fail → Review database functions and locking
3. ⚠️ High errors → Check connection pool configuration

## Full Documentation

See [README.md](./README.md) for complete documentation.
