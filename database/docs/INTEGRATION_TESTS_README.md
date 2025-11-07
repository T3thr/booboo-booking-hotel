# Integration Tests for PostgreSQL Functions

## Overview

This directory contains comprehensive integration tests for all critical PostgreSQL functions in the hotel booking system. These tests ensure data integrity, transaction safety, and proper constraint enforcement.

## Test Coverage

### Test Suite 1: create_booking_hold
- ✅ Successful hold creation
- ✅ Hold creation with no availability
- ✅ Race condition handling (concurrent holds)
- ✅ Tentative count updates
- ✅ Hold expiry tracking

### Test Suite 2: confirm_booking
- ✅ Successful booking confirmation
- ✅ Invalid status handling
- ✅ Inventory updates (booked_count, tentative_count)
- ✅ Hold cleanup after confirmation
- ✅ Booking status transitions

### Test Suite 3: check_in
- ✅ Successful check-in
- ✅ Room not ready (dirty room)
- ✅ Room occupied
- ✅ Room assignment creation
- ✅ Room status updates

### Test Suite 4: check_out
- ✅ Successful check-out
- ✅ Invalid status handling
- ✅ Room assignment completion
- ✅ Room status updates (Vacant + Dirty)
- ✅ Booking completion

### Test Suite 5: Rollback Scenarios
- ✅ Foreign key constraint violations
- ✅ Inventory constraint violations
- ✅ Transaction rollback integrity
- ✅ No partial updates on failure

### Test Suite 6: Constraint Violations
- ✅ Inventory constraint (booked + tentative <= allotment)
- ✅ Date constraint (check_out > check_in)
- ✅ Status constraint (valid enum values)
- ✅ Foreign key constraints

### Test Suite 7: Complex Integration Scenarios
- ✅ Full booking flow (hold → confirm → check-in → check-out)
- ✅ Multi-step transaction integrity
- ✅ State consistency across operations

## Running the Tests

### Prerequisites

1. PostgreSQL 15+ installed and running
2. Database `hotel_booking` created
3. All migrations applied (001-011)
4. Test data seeded

### Windows

```cmd
cd database\tests
run_integration_tests.bat
```

### Linux/Mac

```bash
cd database/tests
chmod +x run_integration_tests.sh
./run_integration_tests.sh
```

### Manual Execution

```bash
psql -U postgres -d hotel_booking -f integration_tests.sql
```

## Test Structure

Each test function follows this pattern:

```sql
CREATE OR REPLACE FUNCTION test.test_name()
RETURNS void AS $$
DECLARE
    -- Variables
BEGIN
    -- Setup: Prepare test data
    
    -- Test: Execute the function being tested
    
    -- Assert: Verify expected outcomes
    
    RAISE NOTICE 'Test completed';
END;
$$ LANGUAGE plpgsql;
```

## Helper Functions

### assert_equals
Compares two values for equality:
```sql
PERFORM test.assert_equals('test name', expected_value, actual_value);
```

### assert_true
Verifies a boolean condition:
```sql
PERFORM test.assert_true('test name', condition);
```

## Test Data Requirements

The tests assume the following data exists:
- At least 1 guest with guest_id = 1
- At least 1 guest_account with guest_account_id = 1
- At least 2 room types (room_type_id = 1, 2)
- At least 10 rooms per room type
- At least 1 rate plan (rate_plan_id = 1)
- Room inventory for the next 90 days
- Pricing calendar configured

## Expected Output

Successful test run will show:
```
NOTICE:  === TEST SUITE 1: create_booking_hold ===
NOTICE:  TEST PASSED: create_booking_hold returns success
NOTICE:  TEST PASSED: tentative_count increased by 1
NOTICE:  TEST PASSED: booking_holds record created
...
NOTICE:  ============================================================
NOTICE:  ALL INTEGRATION TESTS COMPLETED
NOTICE:  ============================================================
```

## Troubleshooting

### Test Failures

If tests fail, check:
1. All migrations are applied
2. Test data is properly seeded
3. Database constraints are in place
4. Functions are created correctly

### Common Issues

**Issue**: Foreign key violation
- **Solution**: Ensure guest and room type data exists

**Issue**: Inventory constraint violation
- **Solution**: Reset inventory data with proper allotment values

**Issue**: Function not found
- **Solution**: Run all migration scripts (005-011)

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Integration Tests
  run: |
    psql -U postgres -d hotel_booking_test -f database/tests/integration_tests.sql
```

## Test Isolation

Each test run:
1. Creates a temporary `test` schema
2. Runs all tests in isolation
3. Cleans up the test schema
4. Does not affect production data

## Performance

- Total test execution time: ~5-10 seconds
- Individual test time: <1 second
- Database operations: ~100-150 queries

## Maintenance

When adding new functions:
1. Create test functions following the naming convention
2. Add to `run_all_tests()` function
3. Document in this README
4. Update test coverage metrics

## Related Documentation

- [Booking Hold Reference](../migrations/BOOKING_HOLD_REFERENCE.md)
- [Confirm Booking Reference](../migrations/CONFIRM_BOOKING_REFERENCE.md)
- [Check-in Reference](../migrations/CHECK_IN_REFERENCE.md)
- [Check-out Reference](../migrations/CHECK_OUT_REFERENCE.md)

## Requirements Coverage

These integration tests satisfy:
- ✅ Requirement 3.1-3.8: Booking hold functionality
- ✅ Requirement 4.1-4.9: Booking confirmation
- ✅ Requirement 7.1-7.8: Check-in process
- ✅ Requirement 9.1-9.7: Check-out process
- ✅ All quality assurance requirements
