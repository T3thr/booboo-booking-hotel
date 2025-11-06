# Move Room Function - Quick Reference

## Overview

The `move_room` function allows receptionists to move a guest from one room to another during their stay. This is useful for handling maintenance issues, guest complaints, or room upgrades.

## Function Signature

```sql
move_room(
    p_room_assignment_id BIGINT,
    p_new_room_id INT,
    p_reason TEXT DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    new_assignment_id BIGINT
)
```

## Parameters

- `p_room_assignment_id` (BIGINT): The ID of the current active room assignment
- `p_new_room_id` (INT): The ID of the new room to move to
- `p_reason` (TEXT, optional): Reason for the room move (for logging)

## Return Values

- `success` (BOOLEAN): Whether the move was successful
- `message` (TEXT): Success or error message
- `new_assignment_id` (BIGINT): ID of the new room assignment (NULL if failed)

## Business Rules

### Validations

1. **Assignment must exist and be Active**
   - The room assignment must exist in the database
   - Status must be 'Active' (not 'Moved' or 'Completed')

2. **Cannot move to the same room**
   - The new room must be different from the current room

3. **New room must be available**
   - Occupancy status must be 'Vacant'
   - Housekeeping status must be 'Clean' or 'Inspected'

4. **Room type consideration**
   - The function allows moving to any room type
   - A notice is logged if moving to a different room type

### Atomic Operations

The function performs these operations atomically (all-or-nothing):

1. Close old assignment (status = 'Moved', set check_out_datetime)
2. Create new assignment (status = 'Active')
3. Update old room (Vacant + Dirty)
4. Update new room (Occupied)

## Usage Examples

### Example 1: Basic Room Move

```sql
-- Move guest from current room to room 205
SELECT * FROM move_room(
    12345,  -- room_assignment_id
    205     -- new_room_id
);
```

**Expected Result:**
```
success | message                                                    | new_assignment_id
--------|------------------------------------------------------------|-----------------
true    | ย้ายห้องสำเร็จ - จากห้อง 201 ไปห้อง 205 (Assignment ID: 12346) | 12346
```

### Example 2: Room Move with Reason

```sql
-- Move guest due to maintenance issue
SELECT * FROM move_room(
    12345,
    205,
    'Air conditioning malfunction in room 201'
);
```

### Example 3: Find Active Assignment for a Booking

```sql
-- First, find the active assignment
SELECT ra.room_assignment_id, r.room_number
FROM room_assignments ra
JOIN rooms r ON ra.room_id = r.room_id
WHERE ra.booking_detail_id = 100
  AND ra.status = 'Active';

-- Then move the room
SELECT * FROM move_room(
    <room_assignment_id>,
    <new_room_id>
);
```

## Error Scenarios

### 1. Assignment Not Found

```sql
SELECT * FROM move_room(999999, 205);
```

**Result:**
```
success | message                              | new_assignment_id
--------|--------------------------------------|-----------------
false   | ไม่พบข้อมูล room assignment นี้     | NULL
```

### 2. Assignment Not Active

```sql
-- Trying to move a completed assignment
SELECT * FROM move_room(12345, 205);
```

**Result:**
```
success | message                                                          | new_assignment_id
--------|------------------------------------------------------------------|-----------------
false   | ไม่สามารถย้ายห้องได้ สถานะ assignment ปัจจุบัน: Completed (ต้องเป็น Active) | NULL
```

### 3. Moving to Same Room

```sql
-- Current room is 201, trying to move to 201
SELECT * FROM move_room(12345, 201);
```

**Result:**
```
success | message                                    | new_assignment_id
--------|--------------------------------------------|-----------------
false   | ไม่สามารถย้ายไปห้องเดิม (ห้อง 201)        | NULL
```

### 4. New Room Not Available

```sql
-- Room 205 is occupied
SELECT * FROM move_room(12345, 205);
```

**Result:**
```
success | message                              | new_assignment_id
--------|--------------------------------------|-----------------
false   | ห้อง 205 ไม่ว่าง (สถานะ: Occupied)   | NULL
```

### 5. New Room Not Clean

```sql
-- Room 205 is dirty
SELECT * FROM move_room(12345, 205);
```

**Result:**
```
success | message                                                              | new_assignment_id
--------|----------------------------------------------------------------------|-----------------
false   | ห้อง 205 ยังไม่พร้อมสำหรับการย้าย (สถานะการทำความสะอาด: Dirty)      | NULL
```

## Integration with Backend

### Go Handler Example

```go
func (h *CheckInHandler) MoveRoom(c *gin.Context) {
    var req struct {
        AssignmentID int64  `json:"assignment_id" binding:"required"`
        NewRoomID    int    `json:"new_room_id" binding:"required"`
        Reason       string `json:"reason"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    result, err := h.checkinService.MoveRoom(
        req.AssignmentID,
        req.NewRoomID,
        req.Reason,
    )
    
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    if !result.Success {
        c.JSON(http.StatusBadRequest, gin.H{"error": result.Message})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": result.Message,
        "new_assignment_id": result.NewAssignmentID,
    })
}
```

### Repository Example

```go
func (r *CheckInRepository) MoveRoom(assignmentID int64, newRoomID int, reason string) (*MoveRoomResult, error) {
    var result MoveRoomResult
    
    query := `
        SELECT success, message, new_assignment_id
        FROM move_room($1, $2, $3)
    `
    
    err := r.db.QueryRow(
        context.Background(),
        query,
        assignmentID,
        newRoomID,
        reason,
    ).Scan(&result.Success, &result.Message, &result.NewAssignmentID)
    
    if err != nil {
        return nil, err
    }
    
    return &result, nil
}
```

## Audit Trail

The function maintains a complete audit trail:

1. **Old Assignment Record**
   - Status changed to 'Moved'
   - check_out_datetime set to NOW()
   - Original room_id preserved

2. **New Assignment Record**
   - New record created with status 'Active'
   - check_in_datetime set to NOW()
   - Links to same booking_detail_id

3. **Room Status Changes**
   - Old room: Vacant + Dirty (ready for housekeeping)
   - New room: Occupied (guest moved in)

## Workflow Integration

### Typical Room Move Workflow

1. **Receptionist identifies need to move**
   - Guest complaint
   - Maintenance issue
   - Room upgrade

2. **Find available rooms**
   ```sql
   SELECT room_id, room_number, room_type_id
   FROM rooms
   WHERE occupancy_status = 'Vacant'
     AND housekeeping_status IN ('Clean', 'Inspected')
   ORDER BY room_type_id, room_number;
   ```

3. **Execute room move**
   ```sql
   SELECT * FROM move_room(
       <assignment_id>,
       <new_room_id>,
       <reason>
   );
   ```

4. **Notify housekeeping**
   - Old room needs cleaning
   - System automatically sets old room to 'Dirty'

5. **Inform guest**
   - Provide new room key
   - Assist with moving belongings

## Testing

Run the test suite:

```bash
# Windows
run_test_move_room.bat

# Linux/Mac
./run_test_move_room.sh
```

The test suite covers:
- ✓ Successful room move
- ✓ Prevention of moving to same room
- ✓ Prevention of moving to occupied room
- ✓ Prevention of moving to dirty room
- ✓ Prevention of moving non-active assignment
- ✓ Prevention of moving non-existent assignment

## Related Functions

- `check_in()` - Initial room assignment
- `check_out()` - Complete stay and release room
- Room status management functions

## Requirements Mapping

This function implements requirements:
- 8.1: Display available rooms of same or higher type
- 8.2: Call SP_MoveRoom with assignment ID and new room ID
- 8.3: Close old assignment and create new one atomically
- 8.4: Update both room statuses
- 8.5: Maintain complete audit trail
- 8.6: Reject if new room not available or clean
- 8.7: Log reason and notify housekeeping

## Notes

- The function uses row-level locking (FOR UPDATE) to prevent race conditions
- All operations are atomic - either all succeed or all rollback
- The old room is automatically marked as 'Dirty' for housekeeping
- Room type changes are allowed but logged with a notice
- The reason parameter is optional but recommended for audit purposes
