# Cancel Booking Function - Quick Reference

## Overview

The `cancel_booking` function handles the cancellation of bookings and returns inventory stock to the system. It supports both Confirmed and PendingPayment bookings with automatic refund calculation.

## Function Signature

```sql
cancel_booking(
    p_booking_id INT,
    p_cancellation_reason TEXT DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    refund_amount DECIMAL(10, 2),
    refund_percentage DECIMAL(5, 2)
)
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_booking_id` | INT | Yes | The ID of the booking to cancel |
| `p_cancellation_reason` | TEXT | No | Optional reason for cancellation |

## Return Values

| Column | Type | Description |
|--------|------|-------------|
| `success` | BOOLEAN | `TRUE` if cancellation succeeded, `FALSE` otherwise |
| `message` | TEXT | Success or error message |
| `refund_amount` | DECIMAL(10,2) | Amount to be refunded |
| `refund_percentage` | DECIMAL(5,2) | Percentage of total amount refunded |

## Refund Policy

The function calculates refunds based on days until check-in:

| Days Before Check-in | Refund Percentage |
|---------------------|-------------------|
| 7+ days | 100% |
| 3-6 days | 50% |
| 1-2 days | 25% |
| Same day or past | 0% |
| PendingPayment | 100% (no payment made) |

## Usage Examples

### Example 1: Cancel a Confirmed Booking

```sql
-- Cancel booking with reason
SELECT * FROM cancel_booking(
    p_booking_id := 123,
    p_cancellation_reason := 'Customer requested cancellation'
);

-- Expected output:
-- success | message                    | refund_amount | refund_percentage
-- --------|----------------------------|---------------|------------------
-- true    | ยกเลิกการจองสำเร็จ         | 6000.00       | 100.00
```

### Example 2: Cancel a PendingPayment Booking

```sql
-- Cancel pending booking
SELECT * FROM cancel_booking(123, 'Changed travel plans');

-- Expected output:
-- success | message                    | refund_amount | refund_percentage
-- --------|----------------------------|---------------|------------------
-- true    | ยกเลิกการจองสำเร็จ         | 6000.00       | 100.00
```

### Example 3: Attempt to Cancel CheckedIn Booking (Fails)

```sql
-- Try to cancel checked-in booking
SELECT * FROM cancel_booking(456);

-- Expected output:
-- success | message                                        | refund_amount | refund_percentage
-- --------|------------------------------------------------|---------------|------------------
-- false   | ไม่สามารถยกเลิกการจองที่มีสถานะ CheckedIn ได้ | 0.00          | 0.00
```

## Behavior by Booking Status

### PendingPayment
- ✅ Can be cancelled
- Returns `tentative_count` to inventory
- 100% refund (no payment made yet)

### Confirmed
- ✅ Can be cancelled
- Returns `booked_count` to inventory
- Refund based on days until check-in

### CheckedIn
- ❌ Cannot be cancelled
- Returns error message

### Completed
- ❌ Cannot be cancelled
- Returns error message

### Cancelled
- ❌ Already cancelled
- Returns error message

### NoShow
- ❌ Cannot be cancelled
- Returns error message

## What the Function Does

1. **Validates Booking**
   - Checks if booking exists
   - Verifies booking status allows cancellation
   - Locks booking row for update

2. **Calculates Refund**
   - Determines days until check-in
   - Applies refund policy based on timing
   - Uses policy snapshot from booking (not current policy)

3. **Returns Inventory**
   - For Confirmed: decrements `booked_count`
   - For PendingPayment: decrements `tentative_count`
   - Updates all nights in the booking

4. **Updates Booking**
   - Sets status to 'Cancelled'
   - Updates timestamp
   - Maintains audit trail

## Error Handling

The function handles these error cases:

| Error Case | Message | Success |
|------------|---------|---------|
| Booking not found | "ไม่พบการจองนี้" | FALSE |
| Already cancelled | "การจองนี้ถูกยกเลิกแล้ว" | FALSE |
| CheckedIn status | "ไม่สามารถยกเลิกการจองที่มีสถานะ CheckedIn ได้" | FALSE |
| Completed status | "ไม่สามารถยกเลิกการจองที่มีสถานะ Completed ได้" | FALSE |

## Transaction Safety

- ✅ Uses `FOR UPDATE` locking to prevent race conditions
- ✅ All operations are atomic (all-or-nothing)
- ✅ Inventory updates are consistent across all nights
- ✅ Rollback on any error

## Integration with Backend

### Go Example

```go
type CancelBookingResult struct {
    Success          bool
    Message          string
    RefundAmount     float64
    RefundPercentage float64
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
    
    return &result, nil
}
```

### API Response Example

```json
{
  "success": true,
  "message": "ยกเลิกการจองสำเร็จ (เหตุผล: Customer requested cancellation)",
  "refund_amount": 6000.00,
  "refund_percentage": 100.00,
  "booking_id": 123
}
```

## Testing

Run comprehensive tests:

```bash
# Windows
run_test_cancel_booking.bat

# Linux/Mac
./run_test_cancel_booking.sh
```

Quick verification:

```bash
psql -U postgres -d hotel_booking -f verify_cancel_booking.sql
```

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

## Related Functions

- `create_booking_hold` - Creates temporary booking holds
- `confirm_booking` - Confirms a pending booking
- `check_in` - Checks in a confirmed booking
- `check_out` - Checks out a guest

## Notes

- The refund policy is currently hardcoded in the function
- In production, you may want to parse the policy from `policy_description` or store it as separate columns
- The function logs warnings if inventory rows are missing (shouldn't happen in normal operation)
- Cancellation reasons are included in the success message but not stored separately (consider adding a cancellation_log table)

## See Also

- [CANCEL_BOOKING_FLOW.md](CANCEL_BOOKING_FLOW.md) - Detailed flow diagrams
- [test_cancel_booking_function.sql](test_cancel_booking_function.sql) - Comprehensive test suite
- [Requirements Document](../../.kiro/specs/hotel-reservation-system/requirements.md) - Requirement 6
