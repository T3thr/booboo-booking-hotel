# Booking Flow Quick Reference

## Overview
Complete guest booking flow from room search to confirmation.

## Flow Diagram

```
┌─────────────────┐
│  Room Search    │
│  /rooms/search  │
└────────┬────────┘
         │ Click "จองห้องนี้"
         ↓
┌─────────────────────────┐
│  Guest Information      │
│  /booking/guest-info    │
│  • Creates hold (15min) │
│  • Countdown timer      │
│  • Guest details form   │
└────────┬────────────────┘
         │ Continue to Payment
         ↓
┌─────────────────────────┐
│  Booking Summary        │
│  /booking/summary       │
│  • Review details       │
│  • Mock payment form    │
│  • Voucher code         │
│  • Price breakdown      │
└────────┬────────────────┘
         │ Complete Booking
         ↓
┌─────────────────────────┐
│  Confirmation           │
│  /booking/confirmation  │
│  • Success message      │
│  • Booking details      │
│  • Policy info          │
└────────┬────────────────┘
         │ View My Bookings
         ↓
┌─────────────────────────┐
│  Bookings List          │
│  /bookings              │
│  • All bookings         │
│  • Status badges        │
└─────────────────────────┘
```

## Pages

### 1. Room Search (`/rooms/search`)
**Purpose**: Search and select available rooms

**Actions**:
- Enter search criteria (dates, guests)
- View available rooms with pricing
- Click "จองห้องนี้" to start booking

**State Stored**:
- `searchParams`: Check-in/out dates, adults, children
- `selectedRoomTypeId`: Selected room type ID
- `selectedRoomType`: Full room type object

### 2. Guest Information (`/booking/guest-info`)
**Purpose**: Collect guest details and create hold

**Features**:
- Countdown timer (15:00)
- Dynamic guest forms (adults + children)
- Primary guest designation
- Form validation

**API Calls**:
- `POST /api/bookings/hold` (on page load)

**State Stored**:
- `holdExpiry`: Hold expiration timestamp
- `guestInfo`: Array of guest details

**Validation**:
- First name required
- Last name required

### 3. Booking Summary (`/booking/summary`)
**Purpose**: Review booking and process payment

**Sections**:
1. **Room Details**
   - Room type, dates, guests, nights
   
2. **Guest Information**
   - List of all guests with types
   
3. **Payment Details** (Mock)
   - Card number (16 digits)
   - Cardholder name
   - Expiry date (MM/YY)
   - CVV (3 digits)
   
4. **Price Summary**
   - Nightly rate × nights
   - Discount (if voucher)
   - Total amount
   - Voucher code input

**API Calls**:
1. `POST /api/bookings` (create booking)
2. `POST /api/bookings/:id/confirm` (confirm booking)

**State Stored**:
- `voucherCode`: Optional voucher code

**Validation**:
- Valid card number (16 digits)
- Cardholder name required
- Valid expiry format (MM/YY)
- Valid CVV (3 digits)

### 4. Confirmation (`/booking/confirmation/[id]`)
**Purpose**: Show booking confirmation

**Features**:
- Success message with checkmark
- Booking number
- Status badge
- Complete booking details
- Cancellation policy
- Important information
- Action buttons

**API Calls**:
- `GET /api/bookings/:id`

### 5. Bookings List (`/bookings`)
**Purpose**: View all user bookings

**Features**:
- List of all bookings
- Status badges with colors
- Quick booking details
- Click to view full details
- Empty state

**API Calls**:
- `GET /api/bookings`

## Components

### CountdownTimer
**File**: `src/components/countdown-timer.tsx`

**Props**:
```typescript
interface CountdownTimerProps {
  expiryDate: Date;
  onExpire?: () => void;
}
```

**Features**:
- Real-time countdown (MM:SS)
- Color coding:
  - Blue: > 5 minutes
  - Yellow: 2-5 minutes
  - Red: < 2 minutes
- Expiration callback

**Usage**:
```tsx
<CountdownTimer 
  expiryDate={holdExpiry} 
  onExpire={handleExpire} 
/>
```

## State Management

### Booking Store (`useBookingStore`)
**File**: `src/store/useBookingStore.ts`

**State**:
```typescript
{
  searchParams: RoomSearchParams | null;
  selectedRoomTypeId: number | null;
  selectedRoomType: any | null;
  holdExpiry: Date | null;
  guestInfo: GuestInfo[] | null;
  voucherCode: string | null;
}
```

**Actions**:
- `setSearchParams(params)`
- `setSelectedRoomType(id, roomType)`
- `setHoldExpiry(expiry)`
- `setGuestInfo(guests)`
- `setVoucherCode(code)`
- `clearBooking()`

**Usage**:
```tsx
const { 
  searchParams, 
  selectedRoomTypeId,
  setSearchParams,
  clearBooking 
} = useBookingStore();
```

## API Endpoints

### 1. Create Hold
```
POST /api/bookings/hold
```

**Request**:
```json
{
  "room_type_id": 1,
  "check_in_date": "2024-01-15",
  "check_out_date": "2024-01-17"
}
```

**Response**:
```json
{
  "hold_id": 123,
  "expiry": "2024-01-14T10:15:00Z",
  "message": "Hold created successfully"
}
```

### 2. Create Booking
```
POST /api/bookings
```

**Request**:
```json
{
  "room_type_id": 1,
  "rate_plan_id": 1,
  "check_in_date": "2024-01-15",
  "check_out_date": "2024-01-17",
  "num_guests": 2,
  "guests": [
    {
      "first_name": "John",
      "last_name": "Doe",
      "type": "Adult",
      "is_primary": true
    }
  ],
  "voucher_code": "SAVE10"
}
```

**Response**:
```json
{
  "booking_id": 456,
  "status": "PendingPayment",
  "total_amount": 3000.00
}
```

### 3. Confirm Booking
```
POST /api/bookings/:id/confirm
```

**Response**:
```json
{
  "booking_id": 456,
  "status": "Confirmed",
  "message": "Booking confirmed successfully"
}
```

### 4. Get Booking
```
GET /api/bookings/:id
```

**Response**:
```json
{
  "booking_id": 456,
  "guest_id": 1,
  "total_amount": 3000.00,
  "status": "Confirmed",
  "policy_name": "Standard Cancellation",
  "policy_description": "Free cancellation up to 24 hours before check-in",
  "booking_details": [
    {
      "room_type_id": 1,
      "check_in_date": "2024-01-15",
      "check_out_date": "2024-01-17",
      "num_guests": 2,
      "room_type": {
        "name": "Deluxe Room",
        "description": "Spacious room with city view"
      }
    }
  ]
}
```

### 5. List Bookings
```
GET /api/bookings
```

**Response**:
```json
[
  {
    "booking_id": 456,
    "status": "Confirmed",
    "total_amount": 3000.00,
    "created_at": "2024-01-14T10:00:00Z",
    "booking_details": [...]
  }
]
```

## Hooks

### useBookings
**File**: `src/hooks/use-bookings.ts`

**Available Hooks**:
```typescript
// Query hooks
useBookings(params?)          // List all bookings
useBooking(id)                // Get single booking

// Mutation hooks
useCreateBookingHold()        // Create hold
useCreateBooking()            // Create booking
useConfirmBooking()           // Confirm booking
useCancelBooking()            // Cancel booking
```

**Usage**:
```tsx
const { data: bookings, isLoading } = useBookings();
const createHold = useCreateBookingHold();
const createBooking = useCreateBooking();

// Create hold
createHold.mutate(holdData, {
  onSuccess: (data) => {
    setHoldExpiry(new Date(data.expiry));
  }
});

// Create booking
createBooking.mutate(bookingData, {
  onSuccess: (data) => {
    setBookingId(data.booking_id);
  }
});
```

## Error Handling

### Hold Creation Failed
```tsx
createHold.mutate(holdData, {
  onError: (error) => {
    alert('Failed to reserve room: ' + error.message);
    router.push('/rooms/search');
  }
});
```

### Booking Creation Failed
```tsx
try {
  const booking = await createBooking.mutateAsync(data);
} catch (error) {
  alert('Booking failed: ' + error.message);
  setIsProcessing(false);
}
```

### Hold Expired
```tsx
const handleExpire = () => {
  alert('Your reservation has expired. Please search again.');
  clearBooking();
  router.push('/rooms/search');
};
```

## Validation

### Guest Information
```typescript
const validateForm = (): boolean => {
  const newErrors: Record<string, string> = {};

  guests.forEach((guest, index) => {
    if (!guest.first_name.trim()) {
      newErrors[`guest_${index}_first_name`] = 'First name is required';
    }
    if (!guest.last_name.trim()) {
      newErrors[`guest_${index}_last_name`] = 'Last name is required';
    }
  });

  setErrors(newErrors);
  return Object.keys(newErrors).length === 0;
};
```

### Payment Details
```typescript
const validatePayment = (): boolean => {
  const newErrors: Record<string, string> = {};

  if (!cardNumber || cardNumber.replace(/\s/g, '').length !== 16) {
    newErrors.cardNumber = 'Please enter a valid 16-digit card number';
  }
  if (!cardName.trim()) {
    newErrors.cardName = 'Cardholder name is required';
  }
  if (!expiryDate || !/^\d{2}\/\d{2}$/.test(expiryDate)) {
    newErrors.expiryDate = 'Please enter expiry date as MM/YY';
  }
  if (!cvv || cvv.length !== 3) {
    newErrors.cvv = 'Please enter a valid 3-digit CVV';
  }

  setErrors(newErrors);
  return Object.keys(newErrors).length === 0;
};
```

## Navigation Guards

### Check Required Data
```tsx
useEffect(() => {
  if (!searchParams || !selectedRoomTypeId || !guestInfo) {
    router.push('/rooms/search');
  }
}, [searchParams, selectedRoomTypeId, guestInfo, router]);
```

## Styling

### Status Badge Colors
```typescript
const getStatusColor = (status: string) => {
  switch (status) {
    case 'Confirmed':
      return 'bg-green-100 text-green-700';
    case 'CheckedIn':
      return 'bg-blue-100 text-blue-700';
    case 'Completed':
      return 'bg-gray-100 text-gray-700';
    case 'Cancelled':
      return 'bg-red-100 text-red-700';
    case 'PendingPayment':
      return 'bg-yellow-100 text-yellow-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};
```

### Timer Colors
```typescript
const isLowTime = minutes < 5;
const isVeryLowTime = minutes < 2;

className={
  isVeryLowTime ? 'bg-red-100 text-red-700' :
  isLowTime ? 'bg-yellow-100 text-yellow-700' :
  'bg-blue-100 text-blue-700'
}
```

## Testing Checklist

- [ ] Search for rooms
- [ ] Select a room
- [ ] Timer appears and counts down
- [ ] Fill guest information
- [ ] Validation works
- [ ] Navigate to summary
- [ ] Review details are correct
- [ ] Fill payment details
- [ ] Payment validation works
- [ ] Booking creates successfully
- [ ] Confirmation page shows
- [ ] Booking appears in list
- [ ] Timer expiration works
- [ ] Back navigation works
- [ ] Error handling works

## Common Issues

### Timer not showing
- Check if hold was created successfully
- Verify `holdExpiry` is set in store
- Check API response format

### Navigation not working
- Verify all required data is in store
- Check useEffect dependencies
- Verify router.push paths

### API errors
- Check backend is running
- Verify authentication token
- Check network tab for details
- Verify request payload format

### State not persisting
- Check store implementation
- Verify setter functions called
- Use React DevTools to inspect

## Tips

1. **Always check store state** before navigation
2. **Clear store** after successful booking
3. **Handle timer expiration** gracefully
4. **Validate on both client and server**
5. **Show loading states** during API calls
6. **Provide clear error messages**
7. **Test with different guest counts**
8. **Test timer expiration scenarios**
