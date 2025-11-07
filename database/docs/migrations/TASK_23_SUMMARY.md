# Task 23 Summary: Check-out Function

## Overview

Task 23 implements the PostgreSQL function for guest check-out, completing the check-in/check-out cycle. This function handles the entire check-out process atomically, including closing room assignments, updating booking status, and preparing rooms for housekeeping.

## What Was Implemented

### 1. PostgreSQL Function: `check_out`

**Purpose**: Process guest check-out and prepare rooms for housekeeping

**Key Features**:
- ✅ Validates booking status (must be CheckedIn)
- ✅ Closes all active room assignments
- ✅ Updates booking status to Completed
- ✅ Sets rooms to Vacant + Dirty
- ✅ Supports multiple room bookings
- ✅ Returns total amount for receipt
- ✅ Atomic transaction handling
- ✅ Comprehensive error handling

### 2. Function Signature

```sql
check_out(
    p_booking_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    total_amount DECIMAL(10, 2),
    rooms_checked_out INT
)
```

### 3. State Transitions

**Before Check-out**:
```
Booking: CheckedIn
Room Assignments: Active
Rooms: Occupied + (any housekeeping status)
```

**After Check-out**:
```
Booking: Completed
Room Assignments: Completed (with check_out_datetime)
Rooms: Vacant + Dirty
```

## Files Created

### Migration Files
1. **010_create_check_out_function.sql** - Main migration file
2. **test_check_out_function.sql** - Comprehensive test suite
3. **verify_check_out.sql** - Verification script

### Run Scripts
4. **run_migration_010.bat** - Windows migration runner
5. **run_migration_010.sh** - Linux/Mac migration runner
6. **run_test_check_out.bat** - Windows test runner
7. **run_test_check_out.sh** - Linux/Mac test runner

### Documentation
8. **CHECK_OUT_REFERENCE.md** - Complete function reference
9. **TASK_23_SUMMARY.md** - This summary document
10. **TASK_23_QUICKSTART.md** - Quick start guide

## Test Coverage

The test suite includes 7 comprehensive tests:

1. ✅ **Test 1**: Successful check-out - single room (Happy Path)
2. ✅ **Test 2**: Successful check-out - multiple rooms
3. ✅ **Test 3**: Reject non-CheckedIn booking
4. ✅ **Test 4**: Reject non-existent booking
5. ✅ **Test 5**: Reject booking without active assignments
6. ✅ **Test 6**: Reject duplicate check-out (already Completed)
7. ✅ **Test 7**: Verify rooms set to Dirty for housekeeping

## Key Validations

### Booking Validations
- ✓ Booking must exist
- ✓ Booking status must be 'CheckedIn'
- ✓ At least one active room assignment must exist

### State Updates
- ✓ All active room assignments closed atomically
- ✓ Booking status updated to 'Completed'
- ✓ All rooms set to 'Vacant' + 'Dirty'
- ✓ Check-out datetime recorded

## Requirements Satisfied

This implementation satisfies all requirements from 9.1 to 9.7:

- **9.1**: ✅ Booking status validation (CheckedIn required)
- **9.2**: ✅ Room assignment closure with timestamp
- **9.3**: ✅ Booking status update to Completed
- **9.4**: ✅ Room status update to Vacant + Dirty
- **9.5**: ✅ Multiple room support
- **9.6**: ✅ Atomic transaction handling
- **9.7**: ✅ Housekeeping notification (via Dirty status)

## Integration Points

### Backend Integration
```go
// Example Go handler
func (h *CheckOutHandler) CheckOut(c *gin.Context) {
    var req struct {
        BookingID int `json:"booking_id"`
    }
    
    // Call check_out function
    result := h.db.QueryRow("SELECT * FROM check_out($1)", req.BookingID)
    
    // Handle result
    // Send receipt email
    // Notify housekeeping
}
```

### Frontend Integration
- Receptionist dashboard: Check-out button
- Display total amount for receipt
- Show rooms that were checked out
- Trigger receipt generation
- Update room status display

### Housekeeping Integration
- Rooms automatically appear in housekeeping task list
- Status: Vacant + Dirty
- Priority based on upcoming arrivals
- Workflow: Dirty → Cleaning → Clean → Inspected

## Usage Example

```sql
-- Check out booking 123
SELECT * FROM check_out(123);

-- Result:
-- success | message                              | total_amount | rooms_checked_out
-- --------|--------------------------------------|--------------|-----------------
-- TRUE    | เช็คเอาท์สำเร็จ - ห้อง: 101 (1 ห้อง) | 3000.00      | 1
```

## Error Handling

The function provides clear error messages:

| Scenario | Error Message |
|----------|---------------|
| Invalid booking | `ไม่พบข้อมูลการจองนี้` |
| Not checked in | `ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: Confirmed` |
| No active rooms | `ไม่พบห้องที่ active สำหรับการจองนี้` |
| Already completed | `ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: Completed` |

## Performance Considerations

### Locking Strategy
- Uses `FOR UPDATE` on booking record
- Uses `FOR UPDATE OF` on room assignments and rooms
- Prevents concurrent check-outs
- Ensures data consistency

### Atomic Operations
- All room assignments closed together
- All room statuses updated together
- Either all succeed or all rollback
- No partial check-outs possible

## Next Steps

### Immediate
1. ✅ Run migration: `run_migration_010.bat` or `.sh`
2. ✅ Run tests: `run_test_check_out.bat` or `.sh`
3. ✅ Verify installation: `verify_check_out.sql`

### Backend (Task 25)
1. Create Go handler for `/api/checkout` endpoint
2. Implement receipt generation
3. Add housekeeping notification
4. Create check-out service layer

### Frontend (Task 28)
1. Create receptionist check-out interface
2. Display booking summary
3. Show total amount
4. Generate and display receipt
5. Update room status dashboard

## Related Tasks

- **Task 22**: ✅ Check-in function (prerequisite)
- **Task 24**: ⏳ Move room function (next)
- **Task 25**: ⏳ Check-in/out module backend
- **Task 28**: ⏳ Receptionist check-in/out interface

## Testing Instructions

### Run Migration
```bash
# Windows
cd database/migrations
run_migration_010.bat

# Linux/Mac
cd database/migrations
chmod +x run_migration_010.sh
./run_migration_010.sh
```

### Run Tests
```bash
# Windows
run_test_check_out.bat

# Linux/Mac
chmod +x run_test_check_out.sh
./run_test_check_out.sh
```

### Manual Testing
```sql
-- 1. Create test booking and check in
-- 2. Check out
SELECT * FROM check_out(booking_id);

-- 3. Verify states
SELECT status FROM bookings WHERE booking_id = ?;
SELECT status FROM room_assignments WHERE booking_detail_id = ?;
SELECT occupancy_status, housekeeping_status FROM rooms WHERE room_id = ?;
```

## Documentation

- **Complete Reference**: [CHECK_OUT_REFERENCE.md](CHECK_OUT_REFERENCE.md)
- **Quick Start**: [TASK_23_QUICKSTART.md](TASK_23_QUICKSTART.md)
- **Check-in Reference**: [CHECK_IN_REFERENCE.md](CHECK_IN_REFERENCE.md)

## Success Criteria

All success criteria have been met:

- ✅ Function created and documented
- ✅ All validations implemented
- ✅ Atomic transaction handling
- ✅ Multiple room support
- ✅ Comprehensive test coverage (7 tests)
- ✅ Error handling and messages
- ✅ Housekeeping integration
- ✅ Documentation complete

## Conclusion

Task 23 is **COMPLETE**. The check-out function is fully implemented, tested, and documented. It provides a robust, atomic solution for processing guest check-outs while maintaining data integrity and preparing rooms for housekeeping.

The function is ready for backend integration (Task 25) and frontend implementation (Task 28).
