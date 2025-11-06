# Booking Hold Function - Quick Reference

## Overview

The `create_booking_hold` function creates a temporary room reservation (hold) for 15 minutes while the guest completes their booking and payment. This prevents race conditions where multiple users try to book the last available room simultaneously.

## Function Signature

```sql
create_booking_hold(
    p_session_id VARCHAR(255),      -- Session ID for tracking
    p_guest_account_id INT,         -- Guest account ID
    p_room_type_id INT,             -- Room type to hold
    p_check_in DATE,                -- Check-in date
    p_check_out DATE                -- Check-out date
) RETURNS TABLE(
    success BOOLEAN,                -- TRUE if hold created successfully
    message TEXT,                   -- Success/error message
    hold_expiry TIMESTAMP           -- When the hold expires (NULL on failure)
)
```

## Features

### 1. **Atomic Operations**
- Uses `FOR UPDATE` row-level locking to prevent race conditions
- All inventory updates are atomic within a transaction
- Automatically rolls back if any step fails

### 2. **Auto-Release Conflicting Holds**
- Automatically releases old holds for the same guest that overlap with new dates
- Prevents guests from having multiple conflicting holds

### 3. **Comprehensive Validation**
- Check-out must be after check-in
- Cannot book past dates
- Maximum 30 nights per booking
- Validates room type exists
- Checks inventory availability for all nights

### 4. **Race Condition Protection**
- Row-level locking ensures only one transaction can modify inventory at a time
- Prevents overbooking even with concurrent requests

## Usage Examples

### Example 1: Basic Hold Creation

```sql
-- Create a hold for Standard Room, 3 nights
SELECT * FROM create_booking_hold(
    'session-abc123',           -- Session ID
    42,                         -- Guest account ID
    1,                          -- Room type ID (Standard Room)
    '2025-01-15',              -- Check-in
    '2025-01-18'               -- Check-out (3 nights)
);

-- Expected result:
-- success | message                                          | hold_expiry
-- --------|--------------------------------------------------|------------------------
-- TRUE    | สร้าง hold สำเร็จสำหรับ Standard Room (3 คืน)... | 2025-01-10 14:45:00
```

### Example 2: Replace Existing Hold

```sql
-- Guest already has a hold for Jan 15-18
-- Now wants to change to Jan 16-20
SELECT * FROM create_booking_hold(
    'session-xyz789',
    42,                         -- Same guest
    1,
    '2025-01-16',              -- New dates (overlaps with old hold)
    '2025-01-20'
);

-- The function will:
-- 1. Release the old hold (Jan 15-18)
-- 2. Create new hold (Jan 16-20)
-- 3. Return success
```

### Example 3: No Availability (Failure)

```sql
-- Try to book when rooms are full
SELECT * FROM create_booking_hold(
    'session-def456',
    43,
    1,
    '2025-12-31',              -- New Year's Eve (likely full)
    '2026-01-02'
);

-- Expected result:
-- success | message                                          | hold_expiry
-- --------|--------------------------------------------------|-------------
-- FALSE   | ห้อง Standard Room ไม่ว่างสำหรับวันที่ 2025-12-31... | NULL
```

## How It Works

### Step-by-Step Process

1. **Input Validation**
   - Validates date range (check-out > check-in)
   - Checks for past dates
   - Validates maximum 30 nights
   - Verifies room type exists

2. **Release Conflicting Holds**
   - Finds existing holds for the same guest that overlap with new dates
   - Decreases `tentative_count` in inventory
   - Deletes old hold records

3. **Check Availability & Lock Rows**
   - For each night in the date range:
     - Locks the inventory row with `FOR UPDATE`
     - Checks if `(allotment - booked_count - tentative_count) > 0`
     - If any night is unavailable, rolls back entire transaction

4. **Update Inventory**
   - Increases `tentative_count` by 1 for each night
   - Updates `updated_at` timestamp

5. **Create Hold Records**
   - Inserts one record per night into `booking_holds`
   - Sets `hold_expiry` to NOW() + 15 minutes

6. **Return Result**
   - Returns success status, message, and expiry time

## Database Schema

### booking_holds Table

```sql
CREATE TABLE booking_holds (
    hold_id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    guest_account_id INT REFERENCES guest_accounts(guest_account_id),
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id),
    date DATE NOT NULL,
    hold_expiry TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### room_inventory Table

```sql
CREATE TABLE room_inventory (
    room_type_id INT NOT NULL,
    date DATE NOT NULL,
    allotment INT NOT NULL,              -- Total rooms available for sale
    booked_count INT NOT NULL DEFAULT 0, -- Confirmed bookings
    tentative_count INT NOT NULL DEFAULT 0, -- Active holds
    PRIMARY KEY (room_type_id, date),
    CONSTRAINT chk_inventory_capacity 
        CHECK (booked_count + tentative_count <= allotment)
);
```

## Error Handling

### Common Error Messages

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `วันเช็คเอาท์ต้องอยู่หลังวันเช็คอิน` | Check-out date is before or equal to check-in | Fix date range |
| `ไม่สามารถจองย้อนหลังได้` | Check-in date is in the past | Use future dates |
| `ไม่สามารถจองเกิน 30 คืนได้` | Date range exceeds 30 nights | Reduce number of nights |
| `ไม่พบประเภทห้องที่เลือก` | Invalid room_type_id | Use valid room type |
| `ห้อง X ไม่ว่างสำหรับวันที่ Y` | No availability for that date | Choose different dates or room type |
| `ไม่พบข้อมูล inventory สำหรับ...` | Missing inventory record | Ensure inventory is initialized |

## Testing

### Run Migration

```bash
# Windows
run_migration_005.bat

# Linux/Mac
chmod +x run_migration_005.sh
./run_migration_005.sh
```

### Run Tests

```bash
# Windows
run_test_booking_hold.bat

# Linux/Mac
chmod +x run_test_booking_hold.sh
./run_test_booking_hold.sh
```

### Test Coverage

The test suite includes:

1. ✅ **Basic Hold Creation** - Normal success case
2. ✅ **Replace Existing Hold** - Auto-release overlapping holds
3. ✅ **No Availability** - Proper failure when rooms are full
4. ✅ **Invalid Date Range** - Validation errors
5. ✅ **Invalid Room Type** - Non-existent room type
6. ✅ **Concurrent Holds** - Race condition protection
7. ✅ **Hold Expiry Time** - Correct 15-minute expiry

## Integration with Backend

### Go Example

```go
type BookingHoldResult struct {
    Success     bool      `db:"success"`
    Message     string    `db:"message"`
    HoldExpiry  *time.Time `db:"hold_expiry"`
}

func (r *BookingRepository) CreateHold(
    sessionID string,
    guestAccountID int,
    roomTypeID int,
    checkIn, checkOut time.Time,
) (*BookingHoldResult, error) {
    var result BookingHoldResult
    
    err := r.db.QueryRow(`
        SELECT success, message, hold_expiry
        FROM create_booking_hold($1, $2, $3, $4, $5)
    `, sessionID, guestAccountID, roomTypeID, checkIn, checkOut).
        Scan(&result.Success, &result.Message, &result.HoldExpiry)
    
    if err != nil {
        return nil, err
    }
    
    return &result, nil
}
```

## Performance Considerations

### Indexes

The following indexes optimize hold operations:

```sql
-- Fast lookup by expiry (for cleanup job)
CREATE INDEX idx_booking_holds_expiry ON booking_holds(hold_expiry);

-- Fast lookup by session
CREATE INDEX idx_booking_holds_session ON booking_holds(session_id);

-- Fast lookup by guest
CREATE INDEX idx_booking_holds_guest ON booking_holds(guest_account_id);

-- Fast lookup by room and date
CREATE INDEX idx_booking_holds_room_date ON booking_holds(room_type_id, date);
```

### Lock Duration

- Row locks are held only during the transaction
- Typical transaction time: < 100ms
- Locks are automatically released on commit/rollback

## Related Functions

### release_expired_holds()

Background job function that cleans up expired holds:

```sql
-- Run every 5 minutes via cron job
SELECT release_expired_holds();
```

This function:
- Finds all holds where `hold_expiry < NOW()`
- Decreases `tentative_count` in inventory
- Deletes expired hold records

## Requirements Mapping

This function satisfies the following requirements:

- **3.1**: Call SP_CreateBookingHold to reserve inventory
- **3.2**: Update RoomInventory SET TentativeCount atomically
- **3.3**: Rollback if TentativeCount + BookedCount exceeds Allotment
- **3.4**: Set HoldExpiry to 15 minutes from now
- **3.5**: Background job releases expired holds (separate function)
- **3.6**: Record in BookingHolds with SessionID
- **3.7**: Auto-release conflicting holds for same guest
- **3.8**: Display countdown timer (frontend responsibility)

## Troubleshooting

### Issue: "ห้องไม่ว่าง" but rooms appear available

**Possible causes:**
1. Another transaction is holding the room
2. `tentative_count` not properly cleaned up
3. Inventory data is stale

**Solutions:**
1. Run `SELECT release_expired_holds();` to clean up
2. Check current holds: `SELECT * FROM booking_holds WHERE hold_expiry > NOW();`
3. Verify inventory: `SELECT * FROM room_inventory WHERE date = 'YYYY-MM-DD';`

### Issue: Holds not expiring

**Cause:** Background cleanup job not running

**Solution:** Ensure the cleanup job is scheduled:
```sql
-- Manual cleanup
SELECT release_expired_holds();

-- Check for expired holds
SELECT COUNT(*) FROM booking_holds WHERE hold_expiry < NOW();
```

### Issue: Race condition still occurring

**Cause:** Not using the function correctly (bypassing it)

**Solution:** Always use `create_booking_hold()` function, never update inventory directly

## Best Practices

1. **Always use the function** - Never update `room_inventory` directly
2. **Handle failures gracefully** - Check `success` field in result
3. **Show countdown timer** - Display remaining time to user
4. **Clean up on navigation** - Release holds when user leaves booking flow
5. **Monitor hold duration** - Alert if holds are taking too long
6. **Run cleanup regularly** - Schedule `release_expired_holds()` every 5 minutes

## See Also

- [Requirements Document](../../.kiro/specs/hotel-reservation-system/requirements.md) - Requirement 3
- [Design Document](../../.kiro/specs/hotel-reservation-system/design.md) - Booking Module
- [Tasks Document](../../.kiro/specs/hotel-reservation-system/tasks.md) - Task 11
