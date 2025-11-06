# Task 18 Quick Start Guide

## 🚀 Quick Start: Using API Client and Hooks

### 1. Import Hooks (Easiest Way)

```typescript
// Import from single entry point
import { 
  useRoomTypes,
  useBookings,
  useCheckIn,
  useHousekeepingTasks 
} from '@/hooks';
```

### 2. Use in Component

```typescript
'use client';

import { useRoomTypes } from '@/hooks';

export default function RoomList() {
  const { data: rooms, isLoading, error } = useRoomTypes();

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      {rooms?.map(room => (
        <div key={room.room_type_id}>{room.name}</div>
      ))}
    </div>
  );
}
```

### 3. Protect Routes

```typescript
import { ProtectedRoute } from '@/components/protected-route';

export default function GuestDashboard() {
  return (
    <ProtectedRoute requiredRole="guest">
      <div>Guest Dashboard Content</div>
    </ProtectedRoute>
  );
}
```

### 4. Use Mutations

```typescript
import { useCreateBooking } from '@/hooks';

export default function BookingForm() {
  const createBooking = useCreateBooking();

  const handleSubmit = (data) => {
    createBooking.mutate(data, {
      onSuccess: () => {
        alert('Booking created!');
      },
      onError: (error) => {
        alert(`Error: ${error.message}`);
      },
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* form fields */}
      <button 
        type="submit" 
        disabled={createBooking.isPending}
      >
        {createBooking.isPending ? 'Creating...' : 'Create Booking'}
      </button>
    </form>
  );
}
```

## 📚 Available Hooks by Module

### Bookings
```typescript
import { 
  useBookings,           // Get all bookings
  useBooking,            // Get single booking
  useCreateBookingHold,  // Create hold
  useCreateBooking,      // Create booking
  useConfirmBooking,     // Confirm booking
  useCancelBooking       // Cancel booking
} from '@/hooks';
```

### Rooms
```typescript
import { 
  useRoomSearch,    // Search available rooms
  useRoomTypes,     // Get all room types
  useRoomType,      // Get single room type
  useRoomPricing    // Get pricing
} from '@/hooks';
```

### Check-in/out
```typescript
import { 
  useArrivals,      // Today's arrivals
  useDepartures,    // Today's departures
  useCheckIn,       // Check-in guest
  useCheckOut,      // Check-out guest
  useMoveRoom,      // Move to different room
  useNoShow         // Mark as no-show
} from '@/hooks';
```

### Housekeeping
```typescript
import { 
  useHousekeepingTasks,   // Get cleaning tasks
  useUpdateRoomStatus,    // Update room status
  useInspectRoom,         // Inspect room
  useReportMaintenance    // Report issue
} from '@/hooks';
```

### Pricing & Inventory
```typescript
import { 
  useRateTiers,              // Get rate tiers
  usePricingCalendar,        // Get calendar
  useRatePricing,            // Get pricing matrix
  useInventory,              // Get inventory
  useUpdateInventory         // Update allotment
} from '@/hooks';
```

### Reports
```typescript
import { 
  useOccupancyReport,   // Occupancy report
  useRevenueReport,     // Revenue report
  useVoucherReport      // Voucher report
} from '@/hooks';
```

### Room Status
```typescript
import { 
  useRoomStatus,          // All rooms status
  useRoomsByStatus,       // Filter by status
  useRoomStatusSummary    // Summary stats
} from '@/hooks';
```

## 🔒 Protected Route Patterns

### Basic Protection
```typescript
<ProtectedRoute>
  <YourComponent />
</ProtectedRoute>
```

### Role-Based Protection
```typescript
<ProtectedRoute requiredRole="manager">
  <ManagerDashboard />
</ProtectedRoute>
```

### Multiple Roles
```typescript
<ProtectedRoute requiredRole={['receptionist', 'manager']}>
  <StaffDashboard />
</ProtectedRoute>
```

### HOC Pattern
```typescript
const ProtectedDashboard = withProtectedRoute(Dashboard, {
  requiredRole: 'manager'
});

export default ProtectedDashboard;
```

## 🎯 Common Patterns

### 1. Search with Parameters
```typescript
const [params, setParams] = useState({
  check_in_date: '2025-01-01',
  check_out_date: '2025-01-05',
  adults: 2,
});

const { data: rooms } = useRoomSearch(params);
```

### 2. Conditional Fetching
```typescript
const { data } = useBooking(bookingId, {
  enabled: !!bookingId  // Only fetch if bookingId exists
});
```

### 3. Auto-Refresh Data
```typescript
// Automatically refetches every 30 seconds
const { data: tasks } = useHousekeepingTasks();
```

### 4. Optimistic Updates
```typescript
const updateStatus = useUpdateRoomStatus();

updateStatus.mutate(
  { roomId, status: 'Clean' },
  {
    onMutate: async (newData) => {
      // Optimistically update UI before server responds
      // (can be implemented if needed)
    },
    onSuccess: () => {
      // Confirmed by server
    },
  }
);
```

## 🧪 Testing

### Test Page
Visit: `http://localhost:3000/test-api`

### Manual Test in Component
```typescript
'use client';

import { useRoomTypes } from '@/hooks';

export default function TestPage() {
  const { data, isLoading, error } = useRoomTypes();

  return (
    <div className="p-8">
      <h1>API Test</h1>
      {isLoading && <p>Loading...</p>}
      {error && <p>Error: {error.message}</p>}
      {data && <pre>{JSON.stringify(data, null, 2)}</pre>}
    </div>
  );
}
```

## 📖 Full Documentation

For complete documentation, see:
- `frontend/API_CLIENT_REFERENCE.md` - Comprehensive guide
- `frontend/TASK_18_VERIFICATION.md` - Verification checklist
- `frontend/TASK_18_COMPLETION.md` - Implementation summary

## 🔧 Configuration

### API Base URL
Set in `.env.local`:
```bash
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

### Query Client Options
Configured in `frontend/src/components/providers.tsx`:
- staleTime: 60 seconds
- gcTime: 5 minutes
- Auto-retry: 2 times (except 401, 403, 404)

## ⚡ Tips

1. **Always handle loading and error states**
2. **Use TypeScript for type safety**
3. **Leverage auto-refetch for real-time data**
4. **Use query keys consistently**
5. **Let mutations handle cache invalidation**
6. **Protect routes based on user roles**
7. **Check the DevTools in development**

## 🎉 You're Ready!

The API client and hooks are fully set up. Start building your UI components using these hooks!

Next: **Task 19 - สร้างหน้า Guest - Room Search**
