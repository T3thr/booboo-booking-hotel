# Task 11 Quick Start Guide

## 🚀 Quick Start

### Step 1: Start Database

```bash
# Make sure Docker Desktop is running, then:
docker-compose up -d db

# Wait for database to be ready (about 10 seconds)
docker-compose logs -f db
# Press Ctrl+C when you see "database system is ready to accept connections"
```

### Step 2: Run Migration

```bash
cd database/migrations

# Windows
run_migration_005.bat

# Linux/Mac
chmod +x run_migration_005.sh
./run_migration_005.sh
```

### Step 3: Run Tests

```bash
# Windows
run_test_booking_hold.bat

# Linux/Mac
chmod +x run_test_booking_hold.sh
./run_test_booking_hold.sh
```

### Step 4: Verify

```bash
# Connect to database
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking

# Run verification
\i /docker-entrypoint-initdb.d/verify_booking_hold.sql

# Exit
\q
```

## 📝 What Was Created

### 1. Main Function
- **File**: `005_create_booking_hold_function.sql`
- **Function**: `create_booking_hold()`
- **Purpose**: Create temporary room reservations (holds) for 15 minutes

### 2. Test Suite
- **File**: `test_booking_hold_function.sql`
- **Tests**: 7 comprehensive test cases
- **Coverage**: Success cases, failure cases, race conditions

### 3. Documentation
- **File**: `BOOKING_HOLD_REFERENCE.md`
- **Contents**: Complete reference guide with examples

### 4. Summary
- **File**: `TASK_11_SUMMARY.md`
- **Contents**: Implementation details and integration guide

## 🎯 Key Features

### Atomic Operations
```sql
-- Uses FOR UPDATE to lock rows
SELECT ... FROM room_inventory WHERE ... FOR UPDATE;
```

### Auto-Release Conflicting Holds
```sql
-- Automatically releases old holds that overlap with new dates
-- No manual cleanup needed!
```

### Race Condition Protection
```sql
-- Only one transaction can modify inventory at a time
-- Prevents overbooking even with concurrent requests
```

### 15-Minute Expiry
```sql
-- Holds automatically expire after 15 minutes
-- Background job cleans up expired holds
```

## 📊 Usage Example

```sql
-- Create a hold for 3 nights
SELECT * FROM create_booking_hold(
    'session-123',              -- Session ID
    42,                         -- Guest account ID
    1,                          -- Room type ID (Standard Room)
    '2025-01-15',              -- Check-in
    '2025-01-18'               -- Check-out (3 nights)
);

-- Result:
-- success | message                                    | hold_expiry
-- --------|--------------------------------------------|-----------------------
-- TRUE    | สร้าง hold สำเร็จสำหรับ Standard Room... | 2025-01-15 14:45:00
```

## 🧪 Test Results

When you run the tests, you should see:

```
=== TEST 1: Basic Hold Creation ===
✓ TEST 1 PASSED

=== TEST 2: Replace Existing Hold ===
✓ TEST 2 PASSED

=== TEST 3: No Availability ===
✓ TEST 3 PASSED

=== TEST 4: Invalid Date Range ===
✓ TEST 4 PASSED (all sub-tests)

=== TEST 5: Invalid Room Type ===
✓ TEST 5 PASSED

=== TEST 6: Concurrent Holds (Simulated) ===
✓ TEST 6 PASSED

=== TEST 7: Hold Expiry Time ===
✓ TEST 7 PASSED

=== ALL TESTS COMPLETED ===
All tests passed successfully!
```

## 🔧 Troubleshooting

### Database Not Running
```bash
# Start database
docker-compose up -d db

# Check status
docker-compose ps
```

### Migration Already Run
```bash
# It's safe to run again - function will be replaced
run_migration_005.bat
```

### Tests Failing
```bash
# Make sure previous migrations are run
run_migration_001.bat
run_migration_002.bat
run_migration_003.bat
run_migration_004.bat
run_migration_005.bat

# Then run tests
run_test_booking_hold.bat
```

### Check Function Exists
```sql
-- Connect to database
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking

-- Check function
\df create_booking_hold

-- Should show:
-- Schema | Name                | Result data type | Argument data types
-- -------|---------------------|------------------|--------------------
-- public | create_booking_hold | TABLE(...)       | p_session_id varchar...
```

## 📚 Next Steps

1. ✅ **Task 11 Complete**: Booking hold function created
2. ⏭️ **Task 12**: Create `confirm_booking` function
3. ⏭️ **Task 13**: Create `cancel_booking` function
4. ⏭️ **Task 14**: Create `release_expired_holds` function

## 🔗 Related Files

- **Requirements**: `.kiro/specs/hotel-reservation-system/requirements.md` (Requirement 3)
- **Design**: `.kiro/specs/hotel-reservation-system/design.md` (Booking Module)
- **Tasks**: `.kiro/specs/hotel-reservation-system/tasks.md` (Task 11)
- **Reference**: `BOOKING_HOLD_REFERENCE.md` (Complete guide)
- **Summary**: `TASK_11_SUMMARY.md` (Implementation details)

## 💡 Tips

1. **Always use the function** - Never update `room_inventory` directly
2. **Check success field** - Always check the `success` boolean in result
3. **Handle failures gracefully** - Show user-friendly error messages
4. **Display countdown** - Show remaining time to user (frontend)
5. **Run cleanup regularly** - Schedule `release_expired_holds()` every 5 minutes

## 🎉 Success!

If all tests pass, you're ready to integrate this function with the Go backend!

See `TASK_11_SUMMARY.md` for integration examples.
