# API Client และ React Query Setup - คู่มืออ้างอิง

## ภาพรวม

ระบบใช้ **TanStack Query (React Query)** สำหรับการจัดการ data fetching, caching และ state synchronization ร่วมกับ **Axios** สำหรับการเรียก API

## โครงสร้างไฟล์

```
frontend/src/
├── lib/
│   └── api.ts                    # API client และ endpoint definitions
├── hooks/
│   ├── index.ts                  # Export all hooks
│   ├── use-auth.ts              # Authentication hooks
│   ├── use-bookings.ts          # Booking management hooks
│   ├── use-rooms.ts             # Room search hooks
│   ├── use-checkin.ts           # Check-in/out hooks
│   ├── use-housekeeping.ts      # Housekeeping hooks
│   ├── use-pricing.ts           # Pricing management hooks
│   ├── use-inventory.ts         # Inventory management hooks
│   ├── use-reports.ts           # Reporting hooks
│   └── use-room-status.ts       # Room status dashboard hooks
└── components/
    ├── providers.tsx             # React Query Provider setup
    └── protected-route.tsx       # Route protection component
```

## การใช้งาน API Client

### 1. Basic API Calls

```typescript
import { api } from '@/lib/api';

// GET request
const data = await api.get('/endpoint');

// POST request
const result = await api.post('/endpoint', { data });

// PUT request
const updated = await api.put('/endpoint', { data });

// DELETE request
await api.delete('/endpoint');
```

### 2. Specific API Endpoints

```typescript
import { bookingApi, roomApi, checkinApi } from '@/lib/api';

// Booking operations
const bookings = await bookingApi.getAll();
const booking = await bookingApi.getById(123);
await bookingApi.createHold(holdData);
await bookingApi.confirm(bookingId);

// Room operations
const rooms = await roomApi.search({ check_in_date, check_out_date });
const roomTypes = await roomApi.getTypes();

// Check-in operations
await checkinApi.checkIn({ booking_detail_id, room_id });
await checkinApi.checkOut(bookingId);
```

## การใช้งาน React Query Hooks

### 1. Booking Hooks

```typescript
import { useBookings, useBooking, useCreateBooking, useCancelBooking } from '@/hooks';

function BookingList() {
  // Query: Get all bookings
  const { data: bookings, isLoading, error } = useBookings();
  
  // Query: Get single booking
  const { data: booking } = useBooking(bookingId);
  
  // Mutation: Create booking
  const createBooking = useCreateBooking();
  const handleCreate = () => {
    createBooking.mutate(bookingData, {
      onSuccess: (data) => {
        console.log('Booking created:', data);
      },
      onError: (error) => {
        console.error('Failed:', error);
      },
    });
  };
  
  // Mutation: Cancel booking
  const cancelBooking = useCancelBooking();
  const handleCancel = (id: number) => {
    cancelBooking.mutate(id);
  };
  
  return (
    <div>
      {isLoading && <p>Loading...</p>}
      {error && <p>Error: {error.message}</p>}
      {bookings?.map(booking => (
        <div key={booking.booking_id}>
          {booking.booking_id}
          <button onClick={() => handleCancel(booking.booking_id)}>
            Cancel
          </button>
        </div>
      ))}
    </div>
  );
}
```

### 2. Room Search Hooks

```typescript
import { useRoomSearch, useRoomTypes, useRoomPricing } from '@/hooks';

function RoomSearch() {
  const [searchParams, setSearchParams] = useState({
    check_in_date: '2025-01-01',
    check_out_date: '2025-01-05',
    adults: 2,
  });
  
  // Search available rooms
  const { data: availableRooms, isLoading } = useRoomSearch(searchParams);
  
  // Get all room types
  const { data: roomTypes } = useRoomTypes();
  
  // Get pricing for specific room
  const { data: pricing } = useRoomPricing(roomTypeId, {
    check_in_date: searchParams.check_in_date,
    check_out_date: searchParams.check_out_date,
  });
  
  return (
    <div>
      {availableRooms?.map(room => (
        <div key={room.room_type_id}>
          {room.name} - {room.total_price} บาท
        </div>
      ))}
    </div>
  );
}
```

### 3. Check-in/Check-out Hooks

```typescript
import { useCheckIn, useCheckOut, useArrivals, useDepartures } from '@/hooks';

function CheckInDesk() {
  const today = new Date().toISOString().split('T')[0];
  
  // Get today's arrivals (auto-refreshes every 30s)
  const { data: arrivals } = useArrivals(today);
  
  // Get today's departures
  const { data: departures } = useDepartures(today);
  
  // Check-in mutation
  const checkIn = useCheckIn();
  const handleCheckIn = (bookingDetailId: number, roomId: number) => {
    checkIn.mutate(
      { booking_detail_id: bookingDetailId, room_id: roomId },
      {
        onSuccess: () => {
          alert('Check-in successful!');
        },
      }
    );
  };
  
  // Check-out mutation
  const checkOut = useCheckOut();
  const handleCheckOut = (bookingId: number) => {
    checkOut.mutate(bookingId);
  };
  
  return (
    <div>
      <h2>Arrivals Today</h2>
      {arrivals?.map(arrival => (
        <div key={arrival.booking_id}>
          {arrival.guest?.first_name}
          <button onClick={() => handleCheckIn(arrival.booking_detail_id, selectedRoomId)}>
            Check In
          </button>
        </div>
      ))}
    </div>
  );
}
```

### 4. Housekeeping Hooks

```typescript
import { useHousekeepingTasks, useUpdateRoomStatus } from '@/hooks';

function HousekeepingDashboard() {
  // Get tasks (auto-refreshes every 30s)
  const { data: tasks } = useHousekeepingTasks();
  
  // Update room status
  const updateStatus = useUpdateRoomStatus();
  
  const handleStatusChange = (roomId: number, newStatus: string) => {
    updateStatus.mutate(
      { roomId, status: newStatus },
      {
        onSuccess: () => {
          console.log('Status updated');
        },
      }
    );
  };
  
  return (
    <div>
      {tasks?.map(task => (
        <div key={task.room_id}>
          Room {task.room_number} - {task.housekeeping_status}
          <button onClick={() => handleStatusChange(task.room_id, 'Cleaning')}>
            Start Cleaning
          </button>
          <button onClick={() => handleStatusChange(task.room_id, 'Clean')}>
            Mark Clean
          </button>
        </div>
      ))}
    </div>
  );
}
```

### 5. Pricing & Inventory Hooks

```typescript
import { useRateTiers, usePricingCalendar, useInventory } from '@/hooks';

function PricingManagement() {
  // Get rate tiers
  const { data: tiers } = useRateTiers();
  
  // Get pricing calendar
  const { data: calendar } = usePricingCalendar({
    start_date: '2025-01-01',
    end_date: '2025-12-31',
  });
  
  // Get inventory
  const { data: inventory } = useInventory({
    room_type_id: 1,
    start_date: '2025-01-01',
    end_date: '2025-01-31',
  });
  
  return (
    <div>
      <h2>Rate Tiers</h2>
      {tiers?.map(tier => (
        <div key={tier.rate_tier_id}>{tier.name}</div>
      ))}
    </div>
  );
}
```

### 6. Room Status Dashboard

```typescript
import { useRoomStatus, useRoomStatusSummary } from '@/hooks';

function RoomStatusDashboard() {
  // Get all rooms with status (auto-refreshes every 30s)
  const { data: rooms } = useRoomStatus();
  
  // Get summary statistics
  const { data: summary } = useRoomStatusSummary();
  
  return (
    <div>
      <div className="summary">
        <div>Total Rooms: {summary?.total}</div>
        <div>Occupied: {summary?.occupied}</div>
        <div>Vacant & Clean: {summary?.vacant_clean}</div>
      </div>
      
      <div className="room-grid">
        {rooms?.map(room => (
          <div
            key={room.room_id}
            className={`room-card ${room.occupancy_status} ${room.housekeeping_status}`}
          >
            {room.room_number}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Protected Routes

### 1. Basic Usage

```typescript
import { ProtectedRoute } from '@/components/protected-route';

function GuestDashboard() {
  return (
    <ProtectedRoute requiredRole="guest">
      <div>Guest Dashboard Content</div>
    </ProtectedRoute>
  );
}
```

### 2. Multiple Roles

```typescript
function StaffDashboard() {
  return (
    <ProtectedRoute requiredRole={['receptionist', 'manager']}>
      <div>Staff Dashboard Content</div>
    </ProtectedRoute>
  );
}
```

### 3. Custom Fallback

```typescript
function AdminPanel() {
  return (
    <ProtectedRoute
      requiredRole="manager"
      fallback={<div>Loading admin panel...</div>}
      redirectTo="/auth/signin"
    >
      <div>Admin Panel Content</div>
    </ProtectedRoute>
  );
}
```

### 4. HOC Pattern

```typescript
import { withProtectedRoute } from '@/components/protected-route';

function ManagerDashboard() {
  return <div>Manager Dashboard</div>;
}

export default withProtectedRoute(ManagerDashboard, {
  requiredRole: 'manager',
});
```

## Query Configuration

### Global Configuration (in providers.tsx)

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,        // 1 minute
      gcTime: 5 * 60 * 1000,       // 5 minutes
      refetchOnWindowFocus: false,
      refetchOnReconnect: true,
      retry: 2,
    },
  },
});
```

### Per-Query Configuration

```typescript
const { data } = useBookings({
  staleTime: 5 * 60 * 1000,  // Override to 5 minutes
  refetchInterval: 30000,     // Auto-refetch every 30 seconds
  enabled: isReady,           // Conditional fetching
});
```

## Error Handling

### Global Error Handling

Errors are automatically handled by the API client interceptor:
- 401: Redirects to sign-in page
- Other errors: Formatted and returned to the component

### Component-Level Error Handling

```typescript
const { data, error, isError } = useBookings();

if (isError) {
  return <div>Error: {error.message}</div>;
}
```

### Mutation Error Handling

```typescript
const createBooking = useCreateBooking();

createBooking.mutate(data, {
  onError: (error) => {
    toast.error(error.message);
  },
  onSuccess: (data) => {
    toast.success('Booking created!');
  },
});
```

## Cache Invalidation

Mutations automatically invalidate related queries:

```typescript
// When a booking is created, these queries are invalidated:
// - ['bookings']
// - ['inventory']

// When a room status is updated, these queries are invalidated:
// - ['housekeeping', 'tasks']
// - ['rooms']
// - ['roomStatus']
```

## Best Practices

1. **Use specific hooks** instead of direct API calls in components
2. **Enable queries conditionally** when dependent data is ready
3. **Use optimistic updates** for better UX (can be added to mutations)
4. **Handle loading and error states** in all components
5. **Leverage auto-refetch** for real-time data (arrivals, room status)
6. **Use query keys consistently** for proper cache management

## ตัวอย่างการใช้งานจริง

### Complete Booking Flow

```typescript
function BookingFlow() {
  const [step, setStep] = useState(1);
  const [selectedRoom, setSelectedRoom] = useState(null);
  
  // Step 1: Search rooms
  const { data: rooms } = useRoomSearch(searchParams);
  
  // Step 2: Create hold
  const createHold = useCreateBookingHold();
  const handleSelectRoom = (room) => {
    setSelectedRoom(room);
    createHold.mutate(holdData, {
      onSuccess: () => setStep(2),
    });
  };
  
  // Step 3: Create booking
  const createBooking = useCreateBooking();
  const handleConfirm = () => {
    createBooking.mutate(bookingData, {
      onSuccess: () => setStep(3),
    });
  };
  
  return (
    <div>
      {step === 1 && <RoomSelection rooms={rooms} onSelect={handleSelectRoom} />}
      {step === 2 && <GuestInfo onConfirm={handleConfirm} />}
      {step === 3 && <Confirmation />}
    </div>
  );
}
```

## สรุป

ระบบ API Client และ React Query Setup นี้ให้:
- ✅ Type-safe API calls
- ✅ Automatic caching และ refetching
- ✅ Optimistic updates
- ✅ Error handling
- ✅ Loading states
- ✅ Real-time data synchronization
- ✅ Protected routes with role-based access
- ✅ Easy-to-use custom hooks

สำหรับข้อมูลเพิ่มเติม ดูที่:
- [TanStack Query Docs](https://tanstack.com/query/latest)
- [NextAuth.js Docs](https://next-auth.js.org/)
- [Axios Docs](https://axios-http.com/)
