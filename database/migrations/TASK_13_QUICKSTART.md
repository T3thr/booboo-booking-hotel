# Task 13 Quick Start - Cancel Booking Function

## What Was Implemented

✅ PostgreSQL function `cancel_booking` for canceling bookings
✅ Handles both Confirmed and PendingPayment bookings
✅ Returns inventory stock (booked_count or tentative_count)
✅ Calculates refund based on days until check-in
✅ Prevents cancellation of CheckedIn/Completed bookings
✅ Comprehensive test suite
✅ Documentation and reference guides

## Quick Start (5 minutes)

### Step 1: Run the Migration (1 min)

**Windows:**
```cmd
cd database\migrations
run_migration_007.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_migration_007.sh
./run_migration_007.sh
```

### Step 2: Run Tests (2 min)

**Windows:**
```cmd
run_test_cancel_booking.bat
```

**Linux/Mac:**
```bash
chmod +x run_test_cancel_booking.sh
./run_test_cancel_booking.sh
```

### Step 3: Verify Function (1 min)

```bash
psql -U postgres -d hotel_booking -f verify_cancel_booking.sql
```

### Step 4: Try It Out (1 min)

```sql
-- Connect to database
psql -U postgres -d hotel_booking

-- Test with non-existent booking (safe test)
SELECT * FROM cancel_booking(99999, 'Test cancellation');

-- Expected output:
-- success | message              | refund_amount | refund_percentage
-- --------|----------------------|---------------|------------------
-- false   | ไม่พบการจองนี้       | 0.00          | 0.00
```

## Function Usage

### Basic Syntax

```sql
SELECT * FROM cancel_booking(
    p_booking_id := <booking_id>,
    p_cancellation_reason := '<optional reason>'
);
```

### Example 1: Cancel with Reason

```sql
SELECT * FROM cancel_booking(123, 'Customer requested cancellation');
```

### Example 2: Cancel without Reason

```sql
SELECT * FROM cancel_booking(456);
```

## Refund Policy

| Days Before Check-in | Refund % |
|---------------------|----------|
| 7+ days | 100% |
| 3-6 days | 50% |
| 1-2 days | 25% |
| Same day or past | 0% |
| PendingPayment | 100% |

## What Gets Cancelled

### ✅ Can Cancel
- **PendingPayment** - Returns tentative_count, 100% refund
- **Confirmed** - Returns booked_count, refund based on timing

### ❌ Cannot Cancel
- **CheckedIn** - Guest already checked in
- **Completed** - Stay completed
- **Cancelled** - Already cancelled
- **NoShow** - Guest didn't show up

## Files Created

```
database/migrations/
├── 007_create_cancel_booking_function.sql    # Main migration
├── test_cancel_booking_function.sql          # Comprehensive tests
├── verify_cancel_booking.sql                 # Quick verification
├── run_migration_007.bat                     # Windows migration script
├── run_migration_007.sh                      # Linux/Mac migration script
├── run_test_cancel_booking.bat              # Windows test script
├── run_test_cancel_booking.sh               # Linux/Mac test script
├── CANCEL_BOOKING_REFERENCE.md              # Quick reference guide
├── CANCEL_BOOKING_FLOW.md                   # Detailed flow diagrams
└── TASK_13_QUICKSTART.md                    # This file
```

## Test Coverage

The test suite covers:

1. ✅ Cancel PendingPayment booking (100% refund)
2. ✅ Cancel Confirmed booking 7+ days before (100% refund)
3. ✅ Cancel Confirmed booking 3-6 days before (50% refund)
4. ✅ Cancel Confirmed booking 1-2 days before (25% refund)
5. ✅ Reject CheckedIn booking cancellation
6. ✅ Reject Completed booking cancellation
7. ✅ Handle non-existent booking
8. ✅ Cancel multi-night booking

## Integration Example (Go)

```go
type CancelBookingResult struct {
    Success          bool    `json:"success"`
    Message          string  `json:"message"`
    RefundAmount     float64 `json:"refund_amount"`
    RefundPercentage float64 `json:"refund_percentage"`
}

func (r *BookingRepository) CancelBooking(bookingID int, reason string) (*CancelBookingResult, error) {
    var result CancelBookingResult
    
    query := `
        SELECT success, message, refund_amount, refund_percentage
        FROM cancel_booking($1, $2)
    `
    
    err := r.db.QueryRow(query, bookingID, reason).Scan(
        &result.Success,
        &result.Message,
        &result.RefundAmount,
        &result.RefundPercentage,
    )
    
    if err != nil {
        return nil, err
    }
    
    if !result.Success {
        return &result, fmt.Errorf("cancellation failed: %s", result.Message)
    }
    
    return &result, nil
}
```

## API Endpoint Example

```go
// POST /api/bookings/:id/cancel
func (h *BookingHandler) CancelBooking(c *gin.Context) {
    bookingID, _ := strconv.Atoi(c.Param("id"))
    
    var req struct {
        Reason string `json:"reason"`
    }
    c.ShouldBindJSON(&req)
    
    result, err := h.bookingService.CancelBooking(bookingID, req.Reason)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    if !result.Success {
        c.JSON(http.StatusBadRequest, gin.H{"error": result.Message})
        return
    }
    
    // Send cancellation email here
    
    c.JSON(http.StatusOK, result)
}
```

## Common Issues & Solutions

### Issue 1: Function Not Found
```
ERROR: function cancel_booking does not exist
```
**Solution:** Run the migration script first
```bash
run_migration_007.bat  # or .sh
```

### Issue 2: Permission Denied
```
ERROR: permission denied for table bookings
```
**Solution:** Ensure your database user has proper permissions
```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO your_user;
```

### Issue 3: Inventory Not Updated
```
Inventory counts don't change after cancellation
```
**Solution:** Check if inventory rows exist for the booking dates
```sql
SELECT * FROM room_inventory 
WHERE room_type_id = <type_id> 
  AND date BETWEEN <check_in> AND <check_out>;
```

## Next Steps

After completing this task:

1. ✅ Task 13 complete - cancel_booking function created
2. ⏭️ Task 14 - Create release_expired_holds function
3. ⏭️ Task 15 - Create Booking Module in Go backend

## Requirements Satisfied

- ✅ 6.1: Calls cancel function for Confirmed bookings
- ✅ 6.2: Returns booked_count atomically
- ✅ 6.3: Calls cancel function for PendingPayment bookings
- ✅ 6.4: Returns tentative_count atomically
- ✅ 6.5: Uses policy snapshot from booking
- ✅ 6.6: Calculates refund based on days before check-in
- ✅ 6.7: Returns refund information
- ✅ 6.8: Rejects CheckedIn/Completed cancellations
- ✅ 6.9: Provides cancellation confirmation

## Documentation

- **Quick Reference:** [CANCEL_BOOKING_REFERENCE.md](CANCEL_BOOKING_REFERENCE.md)
- **Flow Diagrams:** [CANCEL_BOOKING_FLOW.md](CANCEL_BOOKING_FLOW.md)
- **Test Suite:** [test_cancel_booking_function.sql](test_cancel_booking_function.sql)
- **Requirements:** [requirements.md](../../.kiro/specs/hotel-reservation-system/requirements.md) - Section 6

## Support

If you encounter issues:
1. Check the test output for specific errors
2. Review the flow diagrams in CANCEL_BOOKING_FLOW.md
3. Verify prerequisites (previous migrations completed)
4. Check PostgreSQL logs for detailed error messages

---

**Status:** ✅ Task 13 Complete - Ready for Integration
