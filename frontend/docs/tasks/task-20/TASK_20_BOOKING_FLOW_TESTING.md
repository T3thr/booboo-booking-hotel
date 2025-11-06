# Task 20: Booking Flow Testing Guide

## Overview
This document provides testing instructions for the Guest Booking Flow implementation.

## Components Created

### 1. Countdown Timer Component
**File:** `src/components/countdown-timer.tsx`
- Displays remaining time for booking hold (15 minutes)
- Changes color based on time remaining (green → yellow → red)
- Calls `onExpire` callback when timer reaches zero

### 2. Guest Information Page
**File:** `src/app/(guest)/booking/guest-info/page.tsx`
- Collects guest information for all travelers
- Creates booking hold when page loads
- Validates all required fields
- Displays countdown timer
- Navigates to summary page on completion

### 3. Booking Summary & Payment Page
**File:** `src/app/(guest)/booking/summary/page.tsx`
- Shows booking details and guest information
- Mock payment form (card number, name, expiry, CVV)
- Displays price breakdown
- Optional voucher code input
- Creates booking and confirms payment
- Navigates to confirmation page on success

### 4. Booking Confirmation Page
**File:** `src/app/(guest)/booking/confirmation/[id]/page.tsx`
- Displays booking confirmation with success message
- Shows booking details and cancellation policy
- Provides important check-in/out information
- Links to view all bookings or book another room

### 5. My Bookings Page
**File:** `src/app/(guest)/bookings/page.tsx`
- Lists all user bookings
- Shows booking status with color coding
- Allows viewing booking details

### 6. Updated Booking Store
**File:** `src/store/useBookingStore.ts`
- Added `guestInfo` state
- Added `selectedRoomType` state
- Added `voucherCode` state
- Added corresponding setter functions

## Testing Instructions

### Prerequisites
1. Backend server running on `http://localhost:8080`
2. Database with test data (rooms, rate plans, etc.)
3. User account created and logged in

### Test Flow

#### Step 1: Search for Rooms
1. Navigate to `/rooms/search`
2. Enter search criteria:
   - Check-in date: Tomorrow
   - Check-out date: 2 days from now
   - Adults: 2
   - Children: 0
3. Click "Search"
4. Verify rooms are displayed with pricing

#### Step 2: Select a Room
1. Click "จองห้องนี้" (Book This Room) on any available room
2. Verify navigation to `/booking/guest-info`
3. Verify countdown timer appears (15:00)

#### Step 3: Enter Guest Information
1. Verify form shows correct number of guest fields (2 adults in this case)
2. Fill in guest information:
   - Guest 1 (Primary): First Name, Last Name
   - Guest 2: First Name, Last Name
3. Try submitting with empty fields - verify validation errors
4. Fill all required fields
5. Click "Continue to Payment"
6. Verify navigation to `/booking/summary`

#### Step 4: Review and Pay
1. Verify booking summary shows:
   - Room details (type, dates, guests, nights)
   - Guest information (all guests listed)
   - Price breakdown
2. Verify countdown timer is still running
3. Fill in mock payment details:
   - Card Number: 1234 5678 9012 3456
   - Cardholder Name: Test User
   - Expiry Date: 12/25
   - CVV: 123
4. (Optional) Enter voucher code
5. Click "Complete Booking"
6. Verify loading state appears
7. Wait for processing (2 second mock delay)
8. Verify navigation to confirmation page

#### Step 5: View Confirmation
1. Verify confirmation page shows:
   - Success message with green checkmark
   - Booking number
   - Booking status (Confirmed)
   - Room and date details
   - Total amount
   - Cancellation policy
   - Important information
2. Click "View My Bookings"
3. Verify navigation to `/bookings`

#### Step 6: View Bookings List
1. Verify booking appears in list
2. Verify status badge shows "Confirmed" in green
3. Click "View Details" or click on the card
4. Verify navigation back to confirmation page

### Edge Cases to Test

#### Timer Expiration
1. Start booking flow
2. Wait for timer to reach 0:00
3. Verify alert appears: "Your reservation has expired"
4. Verify redirect to search page
5. Verify booking store is cleared

#### Missing Data
1. Try accessing `/booking/guest-info` directly without search params
2. Verify redirect to `/rooms/search`
3. Try accessing `/booking/summary` without guest info
4. Verify redirect to `/rooms/search`

#### Payment Validation
1. On summary page, try submitting with:
   - Invalid card number (less than 16 digits)
   - Empty cardholder name
   - Invalid expiry date format
   - Invalid CVV (not 3 digits)
2. Verify validation errors appear
3. Verify form doesn't submit

#### API Errors
1. Stop backend server
2. Try to create booking
3. Verify error message appears
4. Verify user stays on summary page

### Backend API Endpoints Used

1. **POST /api/bookings/hold**
   - Creates temporary hold on room inventory
   - Called when guest-info page loads
   - Returns hold expiry time

2. **POST /api/bookings**
   - Creates booking record
   - Called when payment is submitted
   - Returns booking ID

3. **POST /api/bookings/:id/confirm**
   - Confirms booking and processes payment
   - Moves inventory from tentative to booked
   - Returns confirmed booking

4. **GET /api/bookings/:id**
   - Retrieves booking details
   - Called on confirmation page
   - Returns full booking with details

5. **GET /api/bookings**
   - Lists all user bookings
   - Called on bookings list page
   - Returns array of bookings

## Expected Behavior

### Booking Hold
- Hold is created when guest-info page loads
- Hold expires after 15 minutes
- Timer shows remaining time
- Expired holds are cleaned up by backend job

### State Management
- Search params stored in booking store
- Selected room type stored with full details
- Guest information persisted between pages
- Store cleared after successful booking

### Navigation Flow
```
Search → Guest Info → Summary → Confirmation → Bookings List
   ↓         ↓           ↓
  Back     Back       Back
```

### Payment Processing
1. Validate payment form
2. Create booking (status: PendingPayment)
3. Mock payment delay (2 seconds)
4. Confirm booking (status: Confirmed)
5. Clear booking store
6. Navigate to confirmation

## Known Limitations

1. **Mock Payment**: Payment is simulated, no real payment gateway integration
2. **Pricing**: Uses mock pricing from room type, should fetch from backend
3. **Voucher**: Voucher validation not fully implemented
4. **Email**: Confirmation email not sent (backend feature)
5. **Room Assignment**: Room number not assigned until check-in

## Requirements Coverage

This implementation covers the following requirements:

### Requirement 3.1-3.8: Booking Hold
- ✅ Create temporary hold on room selection
- ✅ Display countdown timer
- ✅ Atomic inventory update
- ✅ Automatic hold expiration
- ✅ Session tracking

### Requirement 4.1-4.9: Payment & Confirmation
- ✅ Secure payment form (mock)
- ✅ Booking creation
- ✅ Booking confirmation
- ✅ Policy snapshot
- ✅ Nightly log creation
- ✅ Confirmation email (backend)
- ✅ Voucher application
- ✅ Total calculation

## Next Steps

After testing, the following enhancements can be made:

1. Add real payment gateway integration
2. Implement voucher validation with backend
3. Add booking modification/cancellation from bookings list
4. Add filters and search to bookings list
5. Add booking details modal/drawer
6. Implement print/download receipt
7. Add booking reminders
8. Add special requests field

## Troubleshooting

### Timer not appearing
- Check if `holdExpiry` is set in booking store
- Verify hold creation API call succeeds
- Check browser console for errors

### Navigation issues
- Verify all required data is in booking store
- Check useEffect dependencies
- Verify router.push paths are correct

### API errors
- Check backend server is running
- Verify API endpoints match backend routes
- Check network tab for request/response
- Verify authentication token is valid

### State not persisting
- Check booking store implementation
- Verify setter functions are called
- Use React DevTools to inspect store state
