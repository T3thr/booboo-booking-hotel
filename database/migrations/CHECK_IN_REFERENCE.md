# Check-in Function Reference

## Overview

The `check_in` function handles the guest check-in process, validating room availability and status, creating room assignments, and updating booking and room statuses atomically.

## Function Signature

```sql
check_in(
    p_booking_detail_id INT,
    p_room_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    room_assignment_id BIGINT
)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `p_booking_detail_id` | INT | The booking detail ID to check in |
| `p_room_id` | INT | The physical room ID to assign |

## Return Values

| Column | Type | Description |
|--------|------|-------------|
| `success` | BOOLEAN | `TRUE` if check-in successful, `FALSE` otherwise |
| `message` | TEXT | Success message or error description |
| `room_assignment_id` | BIGINT | ID of created room assignment (NULL on failure) |

## Validation Rules

The function performs the following validations in order:

### 1. Booking Detail Validation
- ✓ Booking detail must exist
- ✓ No active room assignment already exists for this booking detail

### 2. Booking Status Validation
- ✓ Booking status must be `'Confirmed'` or `'CheckedIn'`
- ✗ Rejects: `'PendingPayment'`, `'Cancelled'`, `'Completed'`, `'NoShow'`

### 3. Room Validation
- ✓ Room must exist
- ✓ Room type must match the booked room type
- ✓ Room occupancy status must be `'Vacant'`
- ✓ Room housekeeping status must be `'Clean'` or `'Inspected'`
- ✗ Rejects: Occupied rooms, Dirty rooms, rooms under Maintenance

### 4. Duplicate Check-in Prevention
- ✓ Prevents checking in the same booking detail twice
- ✓ Checks for existing active room assignments

## State Changes

### Successful Check-in

**Before:**
```
Booking: status = 'Confirmed'
Room: occupancy_status = 'Vacant', housekeeping_status = 'Clean'/'Inspected'
Room Assignment: (none)
```

**After:**
```
Booking: status = 'CheckedIn'
Room: occupancy_status = 'Occupied', housekeeping_status = (unchanged)
Room Assignment: status = 'Active', check_in_datetime = NOW()
```

## Usage Examples

### Example 1: Successful Check-in

```sql
-- Check in booking detail 123 to room 456
SELECT * FROM check_in(123, 456);

-- Expected result:
-- success | message                                    | room_assignment_id
-- --------|--------------------------------------------|-----------------
-- TRUE    | เช็คอินสำเร็จ - ห้อง 101 (Assignment ID: 789) | 789
```

### Example 2: Room Not Ready

```sql
-- Try to check in to a dirty room
SELECT * FROM check_in(123, 456);

-- Expected result:
-- success | message                                           | room_assignment_id
-- --------|---------------------------------------------------|-----------------
-- FALSE   | ห้อง 101 ยังไม่พร้อมสำหรับเช็คอิน (สถานะการทำความสะอาด: Dirty) | NULL
```

### Example 3: Room Occupied

```sql
-- Try to check in to an occupied room
SELECT * FROM check_in(123, 456);

-- Expected result:
-- success | message                        | room_assignment_id
-- --------|--------------------------------|-----------------
-- FALSE   | ห้อง 101 ไม่ว่าง (สถานะ: Occupied) | NULL
```

### Example 4: Wrong Room Type

```sql
-- Try to check in to a room of different type
SELECT * FROM check_in(123, 456);

-- Expected result:
-- success | message                                    | room_assignment_id
-- --------|--------------------------------------------|-----------------
-- FALSE   | ห้องนี้ไม่ตรงกับประเภทห้องที่จอง (ห้อง: 2, จอง: 1) | NULL
```

## Integration with Backend

### Go Handler Example

```go
func (h *CheckInHandler) CheckIn(c *gin.Context) {
    var req struct {
        BookingDetailID int `json:"booking_detail_id" binding:"required"`
        RoomID          int `json:"room_id" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    var result struct {
        Success           bool   `db:"success"`
        Message           string `db:"message"`
        RoomAssignmentID  *int64 `db:"room_assignment_id"`
    }
    
    err := h.db.QueryRow(
        "SELECT * FROM check_in($1, $2)",
        req.BookingDetailID,
        req.RoomID,
    ).Scan(&result.Success, &result.Message, &result.RoomAssignmentID)
    
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
        return
    }
    
    if !result.Success {
        c.JSON(http.StatusBadRequest, gin.H{"error": result.Message})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": result.Message,
        "room_assignment_id": result.RoomAssignmentID,
    })
}
```

## Error Handling

The function uses PostgreSQL's transaction mechanism to ensure atomicity:

- All validations are performed before any data modifications
- If any validation fails, no changes are made to the database
- Row-level locks (`FOR UPDATE`) prevent race conditions
- Exceptions are caught and returned as error messages

## Common Error Messages

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `ไม่พบข้อมูลการจองนี้` | Invalid booking_detail_id | Verify booking detail exists |
| `การจองนี้ได้ทำการเช็คอินแล้ว` | Duplicate check-in attempt | Check room_assignments table |
| `ไม่สามารถเช็คอินได้ สถานะการจองปัจจุบัน: PendingPayment` | Booking not confirmed | Confirm booking first |
| `ไม่พบห้องนี้ในระบบ` | Invalid room_id | Verify room exists |
| `ห้องนี้ไม่ตรงกับประเภทห้องที่จอง` | Room type mismatch | Select correct room type |
| `ห้อง X ไม่ว่าง (สถานะ: Occupied)` | Room occupied | Select different room |
| `ห้อง X ยังไม่พร้อมสำหรับเช็คอิน (สถานะการทำความสะอาด: Dirty)` | Room not clean | Wait for housekeeping |

## Performance Considerations

### Indexes Used
- `idx_booking_details_booking` - Fast booking detail lookup
- `idx_rooms_status` - Fast room status filtering
- `idx_room_assignments_active` - Fast duplicate check-in detection

### Locking Strategy
- Uses `FOR UPDATE` on booking and room records
- Prevents concurrent check-ins to the same room
- Prevents race conditions in status updates

### Transaction Scope
- Entire check-in process is atomic
- Either all changes succeed or all are rolled back
- No partial check-ins possible

## Testing

Run the test suite:

```bash
# Windows
database/migrations/run_test_check_in.bat

# Linux/Mac
database/migrations/run_test_check_in.sh
```

Test coverage includes:
1. ✓ Successful check-in (Happy Path)
2. ✓ Reject occupied room
3. ✓ Reject dirty room
4. ✓ Reject non-confirmed booking
5. ✓ Reject wrong room type
6. ✓ Reject duplicate check-in

## Related Functions

- `confirm_booking()` - Must be called before check-in
- `check_out()` - Completes the stay
- `move_room()` - Moves guest to different room during stay

## Requirements Satisfied

This function satisfies the following requirements:

- **7.1**: Room status validation (Vacant + Clean/Inspected)
- **7.2**: Booking status validation (Confirmed)
- **7.3**: Room assignment creation
- **7.4**: Atomic status updates
- **7.5**: Duplicate check-in prevention
- **7.6**: Room type matching
- **7.7**: Error handling and rollback
- **7.8**: Audit trail through room_assignments

## Migration Files

- **Migration**: `009_create_check_in_function.sql`
- **Tests**: `test_check_in_function.sql`
- **Verification**: `verify_check_in.sql`
- **Run Scripts**: 
  - `run_migration_009.bat` / `run_migration_009.sh`
  - `run_test_check_in.bat` / `run_test_check_in.sh`
