# Task 23 Verification Checklist

## Pre-Installation Checklist

### Prerequisites
- [ ] PostgreSQL 15+ installed and running
- [ ] Database `hotel_booking` exists
- [ ] Previous migrations (001-009) completed
- [ ] Check-in function (Task 22) installed
- [ ] Database user has necessary permissions

### Required Tables
- [ ] `bookings` table exists
- [ ] `booking_details` table exists
- [ ] `room_assignments` table exists
- [ ] `rooms` table exists

## Installation Checklist

### Step 1: Run Migration
- [ ] Navigate to `database/migrations` directory
- [ ] Run `run_migration_010.bat` (Windows) or `run_migration_010.sh` (Linux/Mac)
- [ ] Migration completes without errors
- [ ] Verification script runs automatically
- [ ] Function `check_out` is created

### Step 2: Verify Function Creation
```sql
-- Run this query
SELECT proname, pronargs 
FROM pg_proc 
WHERE proname = 'check_out';

-- Expected result: check_out | 1
```
- [ ] Function exists in database
- [ ] Function has correct number of arguments (1)
- [ ] Function has documentation/comment

### Step 3: Run Test Suite
- [ ] Run `run_test_check_out.bat` (Windows) or `run_test_check_out.sh` (Linux/Mac)
- [ ] All 7 tests pass
- [ ] No errors in test output
- [ ] Test data cleaned up properly

## Functional Testing Checklist

### Test 1: Successful Check-out (Single Room)
```sql
-- Setup
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
VALUES (9999, 1, 3000.00, 'CheckedIn', 'Test', 'Test');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                             check_in_date, check_out_date, num_guests)
VALUES (9999, 9999, 1, 1, CURRENT_DATE - 1, CURRENT_DATE, 2);

INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status)
VALUES (9999, 1, NOW() - INTERVAL '1 day', 'Active');

-- Test
SELECT * FROM check_out(9999);

-- Verify
SELECT status FROM bookings WHERE booking_id = 9999;
-- Expected: Completed

SELECT status, check_out_datetime FROM room_assignments WHERE booking_detail_id = 9999;
-- Expected: Completed, (timestamp)

SELECT occupancy_status, housekeeping_status FROM rooms WHERE room_id = 1;
-- Expected: Vacant, Dirty

-- Cleanup
DELETE FROM room_assignments WHERE booking_detail_id = 9999;
DELETE FROM booking_details WHERE booking_detail_id = 9999;
DELETE FROM bookings WHERE booking_id = 9999;
```

- [ ] Check-out succeeds
- [ ] Booking status updated to Completed
- [ ] Room assignment closed with timestamp
- [ ] Room set to Vacant + Dirty
- [ ] Total amount returned correctly
- [ ] Rooms checked out count is 1

### Test 2: Multiple Rooms Check-out
```sql
-- Setup with 2 rooms
-- (Similar to Test 1 but with 2 booking_details and 2 room_assignments)

-- Test
SELECT * FROM check_out(booking_id);

-- Verify
-- Both rooms should be Vacant + Dirty
-- Both assignments should be Completed
-- Rooms checked out count should be 2
```

- [ ] Check-out succeeds for multiple rooms
- [ ] All room assignments closed
- [ ] All rooms set to Vacant + Dirty
- [ ] Correct room count returned

### Test 3: Error Handling
```sql
-- Test non-existent booking
SELECT * FROM check_out(99999);
-- Expected: success = FALSE, message about booking not found

-- Test non-CheckedIn booking
-- (Create booking with status = 'Confirmed')
SELECT * FROM check_out(booking_id);
-- Expected: success = FALSE, message about wrong status

-- Test booking without active assignments
-- (Create CheckedIn booking but no room_assignments)
SELECT * FROM check_out(booking_id);
-- Expected: success = FALSE, message about no active rooms
```

- [ ] Non-existent booking rejected
- [ ] Non-CheckedIn booking rejected
- [ ] Booking without assignments rejected
- [ ] Error messages are clear and helpful

### Test 4: Duplicate Check-out Prevention
```sql
-- Check out once (should succeed)
SELECT * FROM check_out(booking_id);

-- Try to check out again (should fail)
SELECT * FROM check_out(booking_id);
-- Expected: success = FALSE, status is Completed
```

- [ ] First check-out succeeds
- [ ] Second check-out rejected
- [ ] Appropriate error message

## Data Integrity Checklist

### Booking Status
- [ ] Status changes from CheckedIn to Completed
- [ ] updated_at timestamp is set
- [ ] No other fields modified
- [ ] Status cannot be changed back

### Room Assignments
- [ ] All active assignments closed
- [ ] check_out_datetime set to NOW()
- [ ] Status changed to Completed
- [ ] No orphaned active assignments

### Room Status
- [ ] occupancy_status changed to Vacant
- [ ] housekeeping_status changed to Dirty
- [ ] Room ready for housekeeping
- [ ] Room appears in housekeeping task list

### Transaction Integrity
- [ ] All changes are atomic
- [ ] Rollback works on error
- [ ] No partial check-outs
- [ ] Database constraints enforced

## Performance Checklist

### Locking
- [ ] Booking record locked during check-out
- [ ] Room assignments locked
- [ ] Rooms locked
- [ ] No deadlocks occur

### Query Performance
- [ ] Check-out completes in < 1 second
- [ ] Multiple rooms handled efficiently
- [ ] Indexes used appropriately
- [ ] No full table scans

### Concurrent Operations
```sql
-- Test concurrent check-outs (different bookings)
-- Should both succeed

-- Test concurrent check-out of same booking
-- Only one should succeed
```

- [ ] Concurrent check-outs of different bookings work
- [ ] Concurrent check-out of same booking prevented
- [ ] No race conditions

## Integration Checklist

### Backend Integration (Task 25)
- [ ] Go handler created
- [ ] Endpoint `/api/checkout/:id` works
- [ ] Authentication required
- [ ] Authorization checked (receptionist role)
- [ ] Receipt generation triggered
- [ ] Housekeeping notification sent

### Frontend Integration (Task 28)
- [ ] Check-out button visible
- [ ] Booking summary displayed
- [ ] Total amount shown
- [ ] Receipt displayed/downloadable
- [ ] Room status updated in real-time
- [ ] Success message shown

### Housekeeping Integration
- [ ] Rooms appear in housekeeping task list
- [ ] Status shows as Dirty
- [ ] Priority based on next arrival
- [ ] Workflow: Dirty → Cleaning → Clean → Inspected

## Documentation Checklist

### Code Documentation
- [ ] Function has SQL comment
- [ ] Parameters documented
- [ ] Return values documented
- [ ] Error cases documented

### User Documentation
- [ ] CHECK_OUT_REFERENCE.md complete
- [ ] TASK_23_QUICKSTART.md complete
- [ ] TASK_23_SUMMARY.md complete
- [ ] Usage examples provided
- [ ] Error messages explained

### Technical Documentation
- [ ] Migration script documented
- [ ] Test cases documented
- [ ] Integration guide provided
- [ ] Troubleshooting guide included

## Security Checklist

### Access Control
- [ ] Function can be executed by backend user
- [ ] Appropriate permissions granted
- [ ] No SQL injection vulnerabilities
- [ ] Input validation performed

### Data Protection
- [ ] Sensitive data not logged
- [ ] Transactions protect data integrity
- [ ] Rollback on error
- [ ] Audit trail maintained

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Code reviewed
- [ ] Migration tested on staging

### Deployment
- [ ] Backup database
- [ ] Run migration
- [ ] Verify function created
- [ ] Run smoke tests
- [ ] Monitor for errors

### Post-Deployment
- [ ] Function working in production
- [ ] No errors in logs
- [ ] Performance acceptable
- [ ] Users can check out successfully

## Rollback Checklist

### If Issues Occur
```sql
-- Drop function
DROP FUNCTION IF EXISTS check_out(INT);

-- Verify removal
SELECT proname FROM pg_proc WHERE proname = 'check_out';
-- Should return no rows
```

- [ ] Rollback procedure documented
- [ ] Function can be dropped safely
- [ ] No dependent objects
- [ ] Can re-run migration

## Sign-off Checklist

### Developer Sign-off
- [ ] All code written and tested
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Code committed to repository

### QA Sign-off
- [ ] All test scenarios executed
- [ ] Edge cases tested
- [ ] Performance acceptable
- [ ] No critical bugs

### Technical Lead Sign-off
- [ ] Code reviewed
- [ ] Architecture approved
- [ ] Security reviewed
- [ ] Ready for deployment

## Final Verification

### Quick Smoke Test
```sql
-- 1. Check function exists
SELECT proname FROM pg_proc WHERE proname = 'check_out';

-- 2. Test with non-existent booking (should fail gracefully)
SELECT * FROM check_out(99999);

-- 3. Verify error message is clear
-- Expected: success = FALSE, message = 'ไม่พบข้อมูลการจองนี้'
```

- [ ] Function exists
- [ ] Handles errors gracefully
- [ ] Returns appropriate messages
- [ ] Ready for production use

## Status Summary

- **Implementation**: ✅ Complete
- **Unit Tests**: ✅ Complete (7/7 passing)
- **Integration Tests**: ⏳ Pending (Task 25)
- **Documentation**: ✅ Complete
- **Code Review**: ⏳ Pending
- **Deployment**: ⏳ Pending

## Notes

### Known Issues
- None

### Future Enhancements
- Add support for partial check-out (some rooms only)
- Add late check-out fee calculation
- Add automatic email receipt sending
- Add integration with payment gateway for refunds

### Dependencies
- Requires Task 22 (check-in function) to be complete
- Required by Task 25 (backend integration)
- Required by Task 28 (frontend integration)

---

**Verification Date**: _____________
**Verified By**: _____________
**Status**: ⏳ Pending Verification

**Notes**:
_____________________________________________
_____________________________________________
_____________________________________________
