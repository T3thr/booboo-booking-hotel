# Integration Tests - Quick Start Guide

## Prerequisites

✅ PostgreSQL 15+ installed  
✅ Database `hotel_booking` created  
✅ All migrations applied (001-011)  
✅ Test data seeded  

## Run Tests (3 Easy Steps)

### Step 1: Navigate to Tests Directory

```bash
cd database/tests
```

### Step 2: Run the Tests

**Windows:**
```cmd
run_integration_tests.bat
```

**Linux/Mac:**
```bash
chmod +x run_integration_tests.sh
./run_integration_tests.sh
```

**Manual:**
```bash
psql -U postgres -d hotel_booking -f integration_tests.sql
```

### Step 3: Check Results

Look for this output:
```
NOTICE:  ============================================================
NOTICE:  ALL INTEGRATION TESTS COMPLETED
NOTICE:  ============================================================
```

## What Gets Tested?

- ✅ Booking hold creation
- ✅ Booking confirmation
- ✅ Check-in process
- ✅ Check-out process
- ✅ Transaction rollbacks
- ✅ Constraint violations
- ✅ End-to-end flows

## Troubleshooting

### Tests Fail?

1. **Check migrations**: Ensure all migrations (001-011) are applied
2. **Check data**: Verify test data exists (guests, rooms, etc.)
3. **Check connection**: Ensure PostgreSQL is running
4. **Check logs**: Review PostgreSQL logs for errors

### Common Errors

**"Function not found"**
```bash
# Solution: Run migrations
cd database/migrations
./run_migration_005.sh  # And 006-011
```

**"Foreign key violation"**
```bash
# Solution: Seed test data
psql -U postgres -d hotel_booking -f database/migrations/seed_data.sql
```

**"Connection refused"**
```bash
# Solution: Start PostgreSQL
# Windows: Start PostgreSQL service
# Linux: sudo systemctl start postgresql
```

## Need More Info?

- 📖 [Full Documentation](INTEGRATION_TESTS_README.md)
- ⚡ [Quick Reference](INTEGRATION_TESTS_QUICK_REFERENCE.md)
- ✅ [Verification Checklist](TASK_40_VERIFICATION_CHECKLIST.md)

## That's It!

You're now running comprehensive integration tests for the hotel booking system's PostgreSQL functions. 🎉
