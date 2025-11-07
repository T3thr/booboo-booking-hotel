# Task 23 Quick Start: Check-out Function

## Quick Installation

### 1. Run Migration (Choose your platform)

**Windows:**
```bash
cd database/migrations
run_migration_010.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_migration_010.sh
./run_migration_010.sh
```

### 2. Run Tests

**Windows:**
```bash
run_test_check_out.bat
```

**Linux/Mac:**
```bash
chmod +x run_test_check_out.sh
./run_test_check_out.sh
```

## Quick Usage

### Basic Check-out

```sql
-- Check out a booking
SELECT * FROM check_out(123);

-- Expected output:
-- success | message                              | total_amount | rooms_checked_out
-- --------|--------------------------------------|--------------|-----------------
-- TRUE    | เช็คเอาท์สำเร็จ - ห้อง: 101 (1 ห้อง) | 3000.00      | 1
```

### Check Multiple Rooms

```sql
-- Check out booking with multiple rooms
SELECT * FROM check_out(456);

-- Expected output:
-- success | message                                  | total_amount | rooms_checked_out
-- --------|------------------------------------------|--------------|-----------------
-- TRUE    | เช็คเอาท์สำเร็จ - ห้อง: 101, 102 (2 ห้อง) | 6000.00      | 2
```

## Quick Verification

### Check Function Exists

```sql
SELECT proname, pronargs 
FROM pg_proc 
WHERE proname = 'check_out';

-- Should return: check_out | 1
```

### Verify States After Check-out

```sql
-- Check booking status
SELECT booking_id, status 
FROM bookings 
WHERE booking_id = 123;
-- Should be: Completed

-- Check room assignments
SELECT status, check_out_datetime 
FROM room_assignments 
WHERE booking_detail_id IN (
    SELECT booking_detail_id 
    FROM booking_details 
    WHERE booking_id = 123
);
-- Should be: Completed, (timestamp)

-- Check room status
SELECT room_number, occupancy_status, housekeeping_status
FROM rooms
WHERE room_id IN (
    SELECT room_id 
    FROM room_assignments ra
    JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
    WHERE bd.booking_id = 123
);
-- Should be: Vacant, Dirty
```

## Quick Integration

### Go Backend Example

```go
// Handler
func (h *CheckOutHandler) CheckOut(c *gin.Context) {
    bookingID := c.Param("id")
    
    var result struct {
        Success         bool     `db:"success"`
        Message         string   `db:"message"`
        TotalAmount     *float64 `db:"total_amount"`
        RoomsCheckedOut int      `db:"rooms_checked_out"`
    }
    
    err := h.db.QueryRow(
        "SELECT * FROM check_out($1)", 
        bookingID,
    ).Scan(&result.Success, &result.Message, &result.TotalAmount, &result.RoomsCheckedOut)
    
    if err != nil || !result.Success {
        c.JSON(400, gin.H{"error": result.Message})
        return
    }
    
    c.JSON(200, gin.H{
        "message": result.Message,
        "total_amount": result.TotalAmount,
        "rooms_checked_out": result.RoomsCheckedOut,
    })
}

// Route
router.POST("/api/checkout/:id", authMiddleware, checkOutHandler.CheckOut)
```

### Frontend Example (React)

```typescript
// API call
const checkOut = async (bookingId: number) => {
    const response = await fetch(`/api/checkout/${bookingId}`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        }
    });
    
    const data = await response.json();
    
    if (data.success) {
        // Show receipt
        showReceipt(data.total_amount, data.rooms_checked_out);
        // Refresh room status
        refreshRoomStatus();
    }
};
```

## Quick Troubleshooting

### Error: "ไม่พบข้อมูลการจองนี้"
**Solution**: Verify booking_id exists
```sql
SELECT booking_id, status FROM bookings WHERE booking_id = ?;
```

### Error: "ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: Confirmed"
**Solution**: Check in first
```sql
-- Check current status
SELECT status FROM bookings WHERE booking_id = ?;

-- If Confirmed, need to check in first
SELECT * FROM check_in(booking_detail_id, room_id);
```

### Error: "ไม่พบห้องที่ active สำหรับการจองนี้"
**Solution**: Verify room assignments exist
```sql
SELECT * FROM room_assignments ra
JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
WHERE bd.booking_id = ? AND ra.status = 'Active';
```

## Quick Test Scenarios

### Scenario 1: Normal Check-out
```sql
-- 1. Create and confirm booking
-- 2. Check in
SELECT * FROM check_in(booking_detail_id, room_id);

-- 3. Check out
SELECT * FROM check_out(booking_id);

-- 4. Verify
SELECT status FROM bookings WHERE booking_id = ?;
-- Should be: Completed
```

### Scenario 2: Multiple Rooms
```sql
-- 1. Create booking with 2 rooms
-- 2. Check in both rooms
SELECT * FROM check_in(booking_detail_id_1, room_id_1);
SELECT * FROM check_in(booking_detail_id_2, room_id_2);

-- 3. Check out (closes both)
SELECT * FROM check_out(booking_id);

-- 4. Verify both rooms are Vacant + Dirty
SELECT room_number, occupancy_status, housekeeping_status
FROM rooms WHERE room_id IN (room_id_1, room_id_2);
```

## Quick Reference

### Function Parameters
- `p_booking_id` (INT) - The booking to check out

### Return Values
- `success` (BOOLEAN) - Operation success
- `message` (TEXT) - Result message
- `total_amount` (DECIMAL) - Booking total for receipt
- `rooms_checked_out` (INT) - Number of rooms

### Valid States
- **Before**: Booking = CheckedIn, Assignments = Active, Rooms = Occupied
- **After**: Booking = Completed, Assignments = Completed, Rooms = Vacant + Dirty

### Common Errors
| Error | Cause | Fix |
|-------|-------|-----|
| Booking not found | Invalid ID | Check booking_id |
| Not CheckedIn | Wrong status | Check in first |
| No active rooms | No assignments | Verify check-in |
| Already completed | Duplicate | Check booking status |

## Quick Links

- **Full Reference**: [CHECK_OUT_REFERENCE.md](CHECK_OUT_REFERENCE.md)
- **Task Summary**: [TASK_23_SUMMARY.md](TASK_23_SUMMARY.md)
- **Check-in Function**: [CHECK_IN_REFERENCE.md](CHECK_IN_REFERENCE.md)
- **Test Suite**: [test_check_out_function.sql](test_check_out_function.sql)

## Next Steps

1. ✅ Migration complete
2. ✅ Tests passing
3. ⏳ Integrate with backend (Task 25)
4. ⏳ Create frontend UI (Task 28)
5. ⏳ Implement receipt generation
6. ⏳ Add housekeeping notifications

## Need Help?

- Review full documentation: `CHECK_OUT_REFERENCE.md`
- Check test examples: `test_check_out_function.sql`
- Compare with check-in: `CHECK_IN_REFERENCE.md`
- Review requirements: `.kiro/specs/hotel-reservation-system/requirements.md` (9.1-9.7)
