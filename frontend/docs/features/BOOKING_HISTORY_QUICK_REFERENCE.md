# Booking History - Quick Reference Guide

## Overview
The Booking History page allows guests to view, manage, and cancel their hotel reservations.

## Page Location
- **URL**: `/bookings`
- **Component**: `frontend/src/app/(guest)/bookings/page.tsx`
- **Layout**: Guest layout with authentication required

## Key Features

### 1. Booking List Display
```typescript
// Each booking card shows:
- Booking ID (e.g., "Booking #123")
- Status badge (Confirmed, CheckedIn, Completed, Cancelled, etc.)
- Room type name
- Check-in date
- Check-out date
- Number of guests
- Total amount
```

### 2. Status Filtering
```typescript
const filters = [
  'all',        // Show all bookings
  'upcoming',   // Confirmed + CheckedIn
  'Completed',  // Completed bookings
  'Cancelled'   // Cancelled bookings
];
```

### 3. Expandable Details
Click "Show More" to reveal:
- Room details (duration, description)
- Guest information (names, primary guest)
- Cancellation policy
- Estimated refund (for cancellable bookings)
- Nightly rate breakdown

### 4. Cancel Booking
```typescript
// Cancellable statuses
const canCancel = ['Confirmed', 'PendingPayment'];

// Non-cancellable statuses
const cannotCancel = ['CheckedIn', 'Completed', 'Cancelled', 'NoShow'];
```

## Component Structure

### State Management
```typescript
const [statusFilter, setStatusFilter] = useState<string>('all');
const [expandedBooking, setExpandedBooking] = useState<number | null>(null);
const [cancellingBooking, setCancellingBooking] = useState<number | null>(null);
```

### API Hooks
```typescript
import { useBookings, useCancelBooking } from '@/hooks/use-bookings';

const { data: bookings, isLoading, error } = useBookings();
const cancelBooking = useCancelBooking();
```

## Refund Calculation

### Algorithm
```typescript
const calculateRefund = (booking: Booking) => {
  // 1. Get check-in date
  const checkInDate = new Date(booking.booking_details[0].check_in_date);
  
  // 2. Calculate days until check-in
  const today = new Date();
  const daysUntilCheckIn = Math.ceil(
    (checkInDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
  );
  
  // 3. Parse refund percentage from policy description
  const match = booking.policy_description.match(/(\d+)%\s+refund/i);
  const refundPercentage = match ? parseInt(match[1]) : 0;
  
  // 4. Calculate refund amount
  const refundAmount = (booking.total_amount * refundPercentage) / 100;
  
  return { percentage: refundPercentage, amount: refundAmount, daysUntilCheckIn };
};
```

### Example Policy Descriptions
```
"Cancel 7 days before check-in for 100% refund"
"Cancel 3 days before check-in for 50% refund"
"Non-refundable - 0% refund"
```

## Status Color Coding

```typescript
const getStatusColor = (status: string) => {
  switch (status) {
    case 'Confirmed':
      return 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400';
    case 'CheckedIn':
      return 'bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400';
    case 'Completed':
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/20 dark:text-gray-400';
    case 'Cancelled':
      return 'bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400';
    case 'PendingPayment':
      return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/20 dark:text-yellow-400';
    case 'NoShow':
      return 'bg-orange-100 text-orange-700 dark:bg-orange-900/20 dark:text-orange-400';
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-900/20 dark:text-gray-400';
  }
};
```

## Cancel Booking Flow

### Step 1: User Clicks Cancel
```typescript
<Button onClick={() => setCancellingBooking(booking.booking_id)}>
  Cancel Booking
</Button>
```

### Step 2: Confirmation Dialog
```typescript
{cancellingBooking && (
  <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
    <Card className="max-w-md w-full p-6">
      <h2>Cancel Booking?</h2>
      <p>Are you sure you want to cancel this booking?</p>
      {/* Show refund amount */}
      <div className="flex gap-3">
        <Button onClick={() => setCancellingBooking(null)}>Keep Booking</Button>
        <Button onClick={() => handleCancelBooking(cancellingBooking)}>Yes, Cancel</Button>
      </div>
    </Card>
  </div>
)}
```

### Step 3: API Call
```typescript
const handleCancelBooking = async (bookingId: number) => {
  try {
    await cancelBooking.mutateAsync(bookingId);
    setCancellingBooking(null);
    alert('Booking cancelled successfully');
  } catch (error) {
    alert(error instanceof Error ? error.message : 'Failed to cancel booking');
  }
};
```

### Step 4: Backend Processing
```
POST /api/bookings/:id/cancel

Backend will:
1. Verify booking status (must be Confirmed or PendingPayment)
2. Call appropriate stored procedure:
   - SP_CancelConfirmedBooking (for Confirmed)
   - SP_CancelPendingBooking (for PendingPayment)
3. Update booking status to 'Cancelled'
4. Return inventory (booked_count or tentative_count)
5. Calculate refund based on saved policy
6. Send cancellation confirmation email
```

## Data Flow

### Loading Bookings
```
User navigates to /bookings
  ↓
useBookings() hook fetches data
  ↓
GET /api/bookings
  ↓
Backend queries database
  ↓
Returns bookings with details, guests, nightly logs
  ↓
Frontend displays in cards
```

### Cancelling Booking
```
User clicks "Cancel Booking"
  ↓
Confirmation dialog shows
  ↓
User confirms cancellation
  ↓
useCancelBooking() mutation
  ↓
POST /api/bookings/:id/cancel
  ↓
Backend calls stored procedure
  ↓
Database updates atomically
  ↓
Success response
  ↓
Frontend invalidates queries
  ↓
Booking list refreshes
  ↓
Status shows "Cancelled"
```

## Error Handling

### Loading Errors
```typescript
if (error) {
  return (
    <Card className="p-8 text-center">
      <h1>Error Loading Bookings</h1>
      <p>{error.message}</p>
      <Button onClick={() => window.location.reload()}>Try Again</Button>
    </Card>
  );
}
```

### Cancellation Errors
```typescript
try {
  await cancelBooking.mutateAsync(bookingId);
} catch (error) {
  // Show error message to user
  alert(error instanceof Error ? error.message : 'Failed to cancel booking');
}
```

### Common Error Scenarios
1. **Network Error**: "Failed to connect to server"
2. **Unauthorized**: Redirects to login page
3. **Invalid Status**: "This booking cannot be cancelled"
4. **Already Cancelled**: "Booking is already cancelled"
5. **Database Error**: "An error occurred while processing your request"

## UI Components Used

### From UI Library
- `Button` - Actions and filters
- `Card` - Booking containers
- `Loading` - Loading state

### Custom Components
- Status badges (inline)
- Confirmation dialog (inline)
- Refund calculator (inline)

## Responsive Design

### Mobile (< 640px)
- Single column layout
- Stacked buttons
- Full-width cards
- Simplified grid (2 columns)

### Tablet (640px - 1024px)
- Two column grid for booking info
- Side-by-side buttons
- Expanded cards

### Desktop (> 1024px)
- Four column grid for booking info
- Horizontal button layout
- Maximum width container (4xl)

## Accessibility Features

1. **Semantic HTML**: Proper heading hierarchy (h1, h2, h3)
2. **ARIA Labels**: Buttons have descriptive text
3. **Keyboard Navigation**: All interactive elements are keyboard accessible
4. **Color Contrast**: Meets WCAG AA standards
5. **Focus Indicators**: Visible focus states on all interactive elements
6. **Screen Reader Support**: Meaningful text for all actions

## Performance Considerations

1. **React Query Caching**: Bookings are cached to reduce API calls
2. **Optimistic Updates**: UI updates immediately on cancel
3. **Lazy Loading**: Only expanded details are rendered
4. **Memoization**: Status colors and calculations are memoized
5. **Debouncing**: Filter changes are debounced

## Testing Tips

### Unit Tests
```typescript
// Test status filtering
test('filters bookings by status', () => {
  // Arrange: Set up bookings with different statuses
  // Act: Click filter button
  // Assert: Verify correct bookings are shown
});

// Test refund calculation
test('calculates refund correctly', () => {
  // Arrange: Create booking with policy
  // Act: Call calculateRefund
  // Assert: Verify percentage and amount
});
```

### Integration Tests
```typescript
// Test cancel flow
test('cancels booking successfully', async () => {
  // Arrange: Mock API response
  // Act: Click cancel, confirm
  // Assert: Verify API called, status updated
});
```

### E2E Tests
```typescript
// Test full user journey
test('user can view and cancel booking', async () => {
  // 1. Login as guest
  // 2. Navigate to bookings
  // 3. Find confirmed booking
  // 4. Click cancel
  // 5. Confirm cancellation
  // 6. Verify success message
  // 7. Verify status changed
});
```

## Troubleshooting

### Issue: Bookings not loading
**Solution**: Check network tab, verify API endpoint, check authentication

### Issue: Cancel button not showing
**Solution**: Verify booking status is Confirmed or PendingPayment

### Issue: Refund calculation wrong
**Solution**: Check policy description format, verify regex pattern

### Issue: Dialog not closing
**Solution**: Verify state management, check event handlers

### Issue: Status not updating after cancel
**Solution**: Check React Query invalidation, verify mutation success

## Related Files

- `frontend/src/app/(guest)/bookings/page.tsx` - Main component
- `frontend/src/app/(guest)/booking/confirmation/[id]/page.tsx` - Details page
- `frontend/src/hooks/use-bookings.ts` - API hooks
- `frontend/src/lib/api.ts` - API client
- `frontend/src/types/index.ts` - TypeScript types
- `backend/internal/handlers/booking_handler.go` - Backend handler
- `database/migrations/007_create_cancel_booking_function.sql` - Database function

## Summary

The Booking History page provides a comprehensive interface for guests to:
- ✅ View all their bookings
- ✅ Filter by status
- ✅ See detailed information
- ✅ Cancel bookings with refund calculation
- ✅ View cancellation policies
- ✅ Navigate to full details

All features are implemented with proper error handling, responsive design, and accessibility support.
