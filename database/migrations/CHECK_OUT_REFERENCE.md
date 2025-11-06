# Check-out Function Reference

## Overview

The `check_out` function handles the guest check-out process, closing room assignments, updating booking and room statuses atomically, and preparing rooms for housekeeping.

## Function Signature

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

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `p_booking_id` | INT | The booking ID to check out |

## Return Values

| Column | Type | Description |
|--------|------|-------------|
| `success` | BOOLEAN | `TRUE` if check-out successful, `FALSE` otherwise |
| `message` | TEXT | Success message or error description |
| `total_amount` | DECIMAL(10, 2) | Total amount of the booking (for receipt) |
| `rooms_checked_out` | INT | Number of rooms checked out |

## Validation Rules

The function performs the following validations in order:

### 1. Booking Validation
- ✓ Booking must exist
- ✓ Booking status must be `'CheckedIn'`
- ✗ Rejects: `'Confirmed'`, `'PendingPayment'`, `'Cancelled'`, `'Completed'`, `'NoShow'`

### 2. Room Assignment Validation
- ✓ At least one active room assignment must exist
- ✗ Rejects: Bookings with no active assignments

### 3. Multiple Rooms Support
- ✓ Handles bookings with multiple room assignments
- ✓ Closes all active assignments atomically
- ✓ Updates all assigned rooms

## State Changes

### Successful Check-out

**Before:**
```
Booking: status = 'CheckedIn'
Room Assignment(s): status = 'Active', check_out_datetime = NULL
Room(s): occupancy_status = 'Occupied', housekeeping_status = (any)
```

**After:**
```
Booking: status = 'Completed'
Room Assignment(s): status = 'Completed', check_out_datetime = NOW()
Room(s): occupancy_status = 'Vacant', housekeeping_status = 'Dirty'
```

## Usage Examples

### Example 1: Successful Check-out (Single Room)

```sql
-- Check out booking 123
SELECT * FROM check_out(123);

-- Expected result:
-- success | message                                    | total_amount | rooms_checked_out
-- --------|--------------------------------------------|--------------|-----------------
-- TRUE    | เช็คเอาท์สำเร็จ - ห้อง: 101 (1 ห้อง)        | 3000.00      | 1
```

### Example 2: Successful Check-out (Multiple Rooms)

```sql
-- Check out booking with 2 rooms
SELECT * FROM check_out(456);

-- Expected result:
-- success | message                                    | total_amount | rooms_checked_out
-- --------|--------------------------------------------|--------------|-----------------
-- TRUE    | เช็คเอาท์สำเร็จ - ห้อง: 101, 102 (2 ห้อง)   | 6000.00      | 2
```

### Example 3: Booking Not Checked In

```sql
-- Try to check out a confirmed but not checked-in booking
SELECT * FROM check_out(789);

-- Expected result:
-- success | message                                           | total_amount | rooms_checked_out
-- --------|---------------------------------------------------|--------------|-----------------
-- FALSE   | ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: Confirmed | NULL         | 0
```

### Example 4: Booking Already Completed

```sql
-- Try to check out an already completed booking
SELECT * FROM check_out(123);

-- Expected result:
-- success | message                                           | total_amount | rooms_checked_out
-- --------|---------------------------------------------------|--------------|-----------------
-- FALSE   | ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: Completed | NULL         | 0
```

## Integration with Backend

### Go Handler Example

```go
func (h *CheckOutHandler) CheckOut(c *gin.Context) {
    var req struct {
        BookingID int `json:"booking_id" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    var result struct {
        Success         bool    `db:"success"`
        Message         string  `db:"message"`
        TotalAmount     *float64 `db:"total_amount"`
        RoomsCheckedOut int     `db:"rooms_checked_out"`
    }
    
    err := h.db.QueryRow(
        "SELECT * FROM check_out($1)",
        req.BookingID,
    ).Scan(&result.Success, &result.Message, &result.TotalAmount, &result.RoomsCheckedOut)
    
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
        return
    }
    
    if !result.Success {
        c.JSON(http.StatusBadRequest, gin.H{"error": result.Message})
        return
    }
    
    // Send receipt email
    go h.emailService.SendReceipt(req.BookingID, *result.TotalAmount)
    
    // Notify housekeeping
    go h.notificationService.NotifyHousekeeping(req.BookingID)
    
    c.JSON(http.StatusOK, gin.H{
        "message": result.Message,
        "total_amount": result.TotalAmount,
        "rooms_checked_out": result.RoomsCheckedOut,
    })
}
```

## Error Handling

The function uses PostgreSQL's transaction mechanism to ensure atomicity:

- All validations are performed before any data modifications
- If any validation fails, no changes are made to the database
- Row-level locks (`FOR UPDATE`) prevent race conditions
- All room assignments are closed atomically
- All room statuses are updated atomically
- Exceptions are caught and returned as error messages

## Common Error Messages

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `ไม่พบข้อมูลการจองนี้` | Invalid booking_id | Verify booking exists |
| `ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: Confirmed` | Booking not checked in | Check in first |
| `ไม่พบห้องที่ active สำหรับการจองนี้` | No active room assignments | Verify check-in was completed |
| `ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: Completed` | Already checked out | Duplicate check-out attempt |

## Housekeeping Integration

After successful check-out:

1. **Room Status**: All rooms are set to `housekeeping_status = 'Dirty'`
2. **Occupancy**: All rooms are set to `occupancy_status = 'Vacant'`
3. **Notification**: Backend should notify housekeeping department
4. **Task List**: Rooms appear in housekeeper's task list

### Housekeeping Workflow

```
Check-out → Room: Vacant + Dirty
         ↓
Housekeeper sees room in task list
         ↓
Housekeeper: Cleaning
         ↓
Housekeeper: Clean
         ↓
Supervisor: Inspected
         ↓
Ready for next check-in
```

## Performance Considerations

### Indexes Used
- `idx_bookings_pk` - Fast booking lookup
- `idx_booking_details_booking` - Fast booking details lookup
- `idx_room_assignments_booking_detail` - Fast assignment lookup
- `idx_rooms_pk` - Fast room updates

### Locking Strategy
- Uses `FOR UPDATE` on booking record
- Uses `FOR UPDATE OF` on room assignments and rooms
- Prevents concurrent check-outs of the same booking
- Prevents race conditions in status updates

### Transaction Scope
- Entire check-out process is atomic
- Either all changes succeed or all are rolled back
- No partial check-outs possible
- All rooms updated together

## Testing

Run the test suite:

```bash
# Windows
database/migrations/run_test_check_out.bat

# Linux/Mac
database/migrations/run_test_check_out.sh
```

Test coverage includes:
1. ✓ Successful check-out - single room
2. ✓ Successful check-out - multiple rooms
3. ✓ Reject non-CheckedIn booking
4. ✓ Reject non-existent booking
5. ✓ Reject booking without active assignments
6. ✓ Reject duplicate check-out
7. ✓ Verify rooms set to Dirty for housekeeping

## Related Functions

- `check_in()` - Must be called before check-out
- `move_room()` - Can be called during stay
- `cancel_booking()` - Alternative to check-out for cancellations

## Requirements Satisfied

This function satisfies the following requirements:

- **9.1**: Booking status validation (CheckedIn)
- **9.2**: Room assignment closure
- **9.3**: Booking status update to Completed
- **9.4**: Room status update to Vacant + Dirty
- **9.5**: Multiple room support
- **9.6**: Atomic transaction handling
- **9.7**: Housekeeping notification (via Dirty status)

## Business Rules

### Check-out Time
- Standard check-out time: 12:00 PM
- Late check-out: May incur additional charges (handled by backend)
- Early check-out: No refund (per cancellation policy)

### Receipt Generation
- Backend should generate receipt after successful check-out
- Include: Booking ID, dates, room numbers, total amount
- Send via email to guest

### Housekeeping Priority
- Rooms with upcoming arrivals get priority
- Rooms set to Dirty immediately after check-out
- Housekeeping dashboard shows all Dirty rooms

## Migration Files

- **Migration**: `010_create_check_out_function.sql`
- **Tests**: `test_check_out_function.sql`
- **Verification**: `verify_check_out.sql`
- **Run Scripts**: 
  - `run_migration_010.bat` / `run_migration_010.sh`
  - `run_test_check_out.bat` / `run_test_check_out.sh`

## Next Steps

After implementing this function:

1. **Backend Integration**: Create Go handler for check-out endpoint
2. **Frontend UI**: Create receptionist check-out interface
3. **Receipt Generation**: Implement receipt email service
4. **Housekeeping Integration**: Update housekeeping task list
5. **Reporting**: Include check-out data in daily reports

## See Also

- [Check-in Function Reference](CHECK_IN_REFERENCE.md)
- [Move Room Function Reference](MOVE_ROOM_REFERENCE.md)
- [Booking Flow Diagram](BOOKING_FLOW_DIAGRAM.md)
- [Room Status Management](ROOM_STATUS_REFERENCE.md)
