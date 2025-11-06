# Booking Flow Visual Diagram

## Complete User Journey

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         GUEST BOOKING FLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ STEP 1: ROOM SEARCH                                                     │
│ Route: /rooms/search                                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  Search Form                                             │          │
│  │  • Check-in Date                                         │          │
│  │  • Check-out Date                                        │          │
│  │  • Adults (1-10)                                         │          │
│  │  • Children (0-5)                                        │          │
│  │                                                          │          │
│  │  [Search Button]                                         │          │
│  └─────────────────────────────────────────────────────────┘          │
│                          ↓                                              │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  Search Results                                          │          │
│  │  ┌────────────────────────────────────────────────┐    │          │
│  │  │ Deluxe Room                    ฿3,000          │    │          │
│  │  │ • Max 2 guests                                  │    │          │
│  │  │ • 5 rooms available                             │    │          │
│  │  │ • WiFi, TV, AC                                  │    │          │
│  │  │                                                  │    │          │
│  │  │              [จองห้องนี้] ←─────────────────────┼────┼──┐      │
│  │  └────────────────────────────────────────────────┘    │  │      │
│  └─────────────────────────────────────────────────────────┘  │      │
│                                                                 │      │
│  Store in Booking Store:                                       │      │
│  • searchParams (dates, guests)                                │      │
│  • selectedRoomTypeId                                          │      │
│  • selectedRoomType (full object)                              │      │
└─────────────────────────────────────────────────────────────────┘      │
                                                                          │
                                                                          │
┌─────────────────────────────────────────────────────────────────────────┤
│ STEP 2: GUEST INFORMATION                                               │
│ Route: /booking/guest-info                                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  On Page Load:                                                          │
│  ┌──────────────────────────────────────────────────┐                 │
│  │ POST /api/bookings/hold                          │                 │
│  │ {                                                 │                 │
│  │   room_type_id: 1,                               │                 │
│  │   check_in_date: "2024-01-15",                   │                 │
│  │   check_out_date: "2024-01-17"                   │                 │
│  │ }                                                 │                 │
│  │                                                   │                 │
│  │ Response: { expiry: "2024-01-14T10:15:00Z" }    │                 │
│  └──────────────────────────────────────────────────┘                 │
│                          ↓                                              │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  ⏱️  14:58 remaining                                     │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  Guest 1 (Primary) (Adult)                               │          │
│  │  ┌──────────────────┐  ┌──────────────────┐            │          │
│  │  │ First Name *     │  │ Last Name *      │            │          │
│  │  │ [John          ] │  │ [Doe           ] │            │          │
│  │  └──────────────────┘  └──────────────────┘            │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  Guest 2 (Adult)                                         │          │
│  │  ┌──────────────────┐  ┌──────────────────┐            │          │
│  │  │ First Name *     │  │ Last Name *      │            │          │
│  │  │ [Jane          ] │  │ [Doe           ] │            │          │
│  │  └──────────────────┘  └──────────────────┘            │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  [Back to Search]  [Continue to Payment] ←──────────────────────┐     │
│                                                                   │     │
│  Store in Booking Store:                                         │     │
│  • holdExpiry (Date)                                             │     │
│  • guestInfo (Array of guests)                                   │     │
└───────────────────────────────────────────────────────────────────┘     │
                                                                          │
                                                                          │
┌─────────────────────────────────────────────────────────────────────────┤
│ STEP 3: BOOKING SUMMARY & PAYMENT                                      │
│ Route: /booking/summary                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  ⏱️  12:34 remaining                                     │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  ┌──────────────────────────────┐  ┌──────────────────────┐          │
│  │ Room Details                 │  │ Price Summary        │          │
│  │ • Deluxe Room                │  │                      │          │
│  │ • Jan 15 - Jan 17            │  │ ฿1,500 × 2 nights   │          │
│  │ • 2 Adults                   │  │ = ฿3,000            │          │
│  │ • 2 nights                   │  │                      │          │
│  └──────────────────────────────┘  │ Discount: ฿0        │          │
│                                     │ ─────────────────    │          │
│  ┌──────────────────────────────┐  │ Total: ฿3,000       │          │
│  │ Guest Information            │  │                      │          │
│  │ • John Doe (Adult, Primary)  │  │ [Voucher Code]      │          │
│  │ • Jane Doe (Adult)           │  │                      │          │
│  └──────────────────────────────┘  │ [Complete Booking]  │          │
│                                     └──────────────────────┘          │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │ Payment Details (Mock)                                   │          │
│  │ ⚠️ This is a mock payment form                          │          │
│  │                                                          │          │
│  │ Card Number *                                            │          │
│  │ [1234 5678 9012 3456                                  ] │          │
│  │                                                          │          │
│  │ Cardholder Name *                                        │          │
│  │ [John Doe                                             ] │          │
│  │                                                          │          │
│  │ Expiry Date *        CVV *                               │          │
│  │ [12/25          ]    [***]                               │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  On Submit:                                                             │
│  1. Validate payment form                                               │
│  2. POST /api/bookings (create booking)                                │
│     Response: { booking_id: 456, status: "PendingPayment" }           │
│  3. Mock payment delay (2 seconds)                                     │
│  4. POST /api/bookings/456/confirm                                     │
│     Response: { status: "Confirmed" }                                  │
│  5. Clear booking store                                                │
│  6. Navigate to /booking/confirmation/456 ←────────────────────┐      │
└─────────────────────────────────────────────────────────────────┘      │
                                                                          │
                                                                          │
┌─────────────────────────────────────────────────────────────────────────┤
│ STEP 4: BOOKING CONFIRMATION                                            │
│ Route: /booking/confirmation/[id]                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  On Page Load:                                                          │
│  GET /api/bookings/456                                                 │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │              ✓ Booking Confirmed!                        │          │
│  │                                                          │          │
│  │  Your reservation has been successfully confirmed        │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  Booking Number: #456                                    │          │
│  │  Status: [Confirmed]                                     │          │
│  │                                                          │          │
│  │  Room Type: Deluxe Room                                  │          │
│  │  Check-in: Jan 15, 2024                                  │          │
│  │  Check-out: Jan 17, 2024                                 │          │
│  │  Duration: 2 nights                                      │          │
│  │  Guests: 2 guest(s)                                      │          │
│  │                                                          │          │
│  │  Total Amount: ฿3,000                                    │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  Cancellation Policy                                     │          │
│  │  Standard Cancellation                                   │          │
│  │  Free cancellation up to 24 hours before check-in       │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  ℹ️ Important Information                                │          │
│  │  • Confirmation email sent                               │          │
│  │  • Check-in from 2:00 PM                                 │          │
│  │  • Check-out until 12:00 PM                              │          │
│  │  • Bring valid ID and confirmation                       │          │
│  └─────────────────────────────────────────────────────────┘          │
│                                                                         │
│  [View My Bookings]  [Book Another Room]                               │
│           ↓                                                             │
└───────────┼─────────────────────────────────────────────────────────────┘
            │
            │
┌───────────┼─────────────────────────────────────────────────────────────┐
│ STEP 5: BOOKINGS LIST                                                   │
│ Route: /bookings                                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  GET /api/bookings                                                     │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────┐          │
│  │  Booking #456                    [Confirmed]             │          │
│  │  Deluxe Room                                             │          │
│  │                                                          │          │
│  │  Check-in: Jan 15    Guests: 2    Total: ฿3,000        │          │
│  │  Check-out: Jan 17                                       │          │
│  │                                                          │          │
│  │                              [View Details] ─────────────┼──┐      │
│  └─────────────────────────────────────────────────────────┘  │      │
│                                                                 │      │
│  ┌─────────────────────────────────────────────────────────┐  │      │
│  │  Booking #455                    [Completed]             │  │      │
│  │  Standard Room                                           │  │      │
│  │                                                          │  │      │
│  │  Check-in: Jan 10    Guests: 1    Total: ฿2,000        │  │      │
│  │  Check-out: Jan 12                                       │  │      │
│  │                                                          │  │      │
│  │                              [View Details]              │  │      │
│  └─────────────────────────────────────────────────────────┘  │      │
│                                                                 │      │
│  Click on card or "View Details" → /booking/confirmation/456 ──┘      │
└─────────────────────────────────────────────────────────────────────────┘
```

## State Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      BOOKING STORE STATE FLOW                           │
└─────────────────────────────────────────────────────────────────────────┘

Initial State:
┌──────────────────────────────────────┐
│ searchParams: null                   │
│ selectedRoomTypeId: null             │
│ selectedRoomType: null               │
│ holdExpiry: null                     │
│ guestInfo: null                      │
│ voucherCode: null                    │
└──────────────────────────────────────┘
                ↓
        [User searches rooms]
                ↓
After Room Search:
┌──────────────────────────────────────┐
│ searchParams: {                      │
│   check_in_date: "2024-01-15",      │
│   check_out_date: "2024-01-17",     │
│   adults: 2,                         │
│   children: 0                        │
│ }                                    │
│ selectedRoomTypeId: null             │
│ selectedRoomType: null               │
│ holdExpiry: null                     │
│ guestInfo: null                      │
│ voucherCode: null                    │
└──────────────────────────────────────┘
                ↓
      [User selects room]
                ↓
After Room Selection:
┌──────────────────────────────────────┐
│ searchParams: { ... }                │
│ selectedRoomTypeId: 1                │
│ selectedRoomType: {                  │
│   room_type_id: 1,                   │
│   name: "Deluxe Room",               │
│   base_price: 1500,                  │
│   ...                                │
│ }                                    │
│ holdExpiry: null                     │
│ guestInfo: null                      │
│ voucherCode: null                    │
└──────────────────────────────────────┘
                ↓
    [Navigate to guest-info]
    [Hold created via API]
                ↓
After Hold Creation:
┌──────────────────────────────────────┐
│ searchParams: { ... }                │
│ selectedRoomTypeId: 1                │
│ selectedRoomType: { ... }            │
│ holdExpiry: Date(2024-01-14 10:15)  │
│ guestInfo: null                      │
│ voucherCode: null                    │
└──────────────────────────────────────┘
                ↓
   [User fills guest info]
                ↓
After Guest Info:
┌──────────────────────────────────────┐
│ searchParams: { ... }                │
│ selectedRoomTypeId: 1                │
│ selectedRoomType: { ... }            │
│ holdExpiry: Date(...)                │
│ guestInfo: [                         │
│   {                                  │
│     first_name: "John",              │
│     last_name: "Doe",                │
│     type: "Adult",                   │
│     is_primary: true                 │
│   },                                 │
│   { ... }                            │
│ ]                                    │
│ voucherCode: null                    │
└──────────────────────────────────────┘
                ↓
   [Navigate to summary]
   [User enters voucher]
                ↓
After Voucher Entry:
┌──────────────────────────────────────┐
│ searchParams: { ... }                │
│ selectedRoomTypeId: 1                │
│ selectedRoomType: { ... }            │
│ holdExpiry: Date(...)                │
│ guestInfo: [ ... ]                   │
│ voucherCode: "SAVE10"                │
└──────────────────────────────────────┘
                ↓
  [User completes payment]
  [Booking confirmed]
                ↓
After Booking Complete:
┌──────────────────────────────────────┐
│ searchParams: null                   │
│ selectedRoomTypeId: null             │
│ selectedRoomType: null               │
│ holdExpiry: null                     │
│ guestInfo: null                      │
│ voucherCode: null                    │
└──────────────────────────────────────┘
        (State cleared)
```

## API Call Sequence

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         API CALL SEQUENCE                               │
└─────────────────────────────────────────────────────────────────────────┘

1. Room Search
   ┌──────────────────────────────────────────────────────────┐
   │ GET /api/rooms/search?checkIn=...&checkOut=...&guests=2 │
   │                                                          │
   │ Response: {                                              │
   │   room_types: [                                          │
   │     {                                                    │
   │       room_type_id: 1,                                   │
   │       name: "Deluxe Room",                               │
   │       available_rooms: 5,                                │
   │       total_price: 3000,                                 │
   │       ...                                                │
   │     }                                                    │
   │   ]                                                      │
   │ }                                                        │
   └──────────────────────────────────────────────────────────┘
                          ↓
2. Create Hold (on guest-info page load)
   ┌──────────────────────────────────────────────────────────┐
   │ POST /api/bookings/hold                                  │
   │                                                          │
   │ Request: {                                               │
   │   room_type_id: 1,                                       │
   │   check_in_date: "2024-01-15",                          │
   │   check_out_date: "2024-01-17"                          │
   │ }                                                        │
   │                                                          │
   │ Response: {                                              │
   │   hold_id: 123,                                          │
   │   expiry: "2024-01-14T10:15:00Z",                       │
   │   message: "Hold created successfully"                   │
   │ }                                                        │
   └──────────────────────────────────────────────────────────┘
                          ↓
3. Create Booking (on payment submit)
   ┌──────────────────────────────────────────────────────────┐
   │ POST /api/bookings                                       │
   │                                                          │
   │ Request: {                                               │
   │   room_type_id: 1,                                       │
   │   rate_plan_id: 1,                                       │
   │   check_in_date: "2024-01-15",                          │
   │   check_out_date: "2024-01-17",                         │
   │   num_guests: 2,                                         │
   │   guests: [                                              │
   │     {                                                    │
   │       first_name: "John",                                │
   │       last_name: "Doe",                                  │
   │       type: "Adult",                                     │
   │       is_primary: true                                   │
   │     },                                                   │
   │     { ... }                                              │
   │   ],                                                     │
   │   voucher_code: "SAVE10"                                 │
   │ }                                                        │
   │                                                          │
   │ Response: {                                              │
   │   booking_id: 456,                                       │
   │   status: "PendingPayment",                              │
   │   total_amount: 3000.00                                  │
   │ }                                                        │
   └──────────────────────────────────────────────────────────┘
                          ↓
4. Confirm Booking (after mock payment)
   ┌──────────────────────────────────────────────────────────┐
   │ POST /api/bookings/456/confirm                           │
   │                                                          │
   │ Response: {                                              │
   │   booking_id: 456,                                       │
   │   status: "Confirmed",                                   │
   │   message: "Booking confirmed successfully"              │
   │ }                                                        │
   └──────────────────────────────────────────────────────────┘
                          ↓
5. Get Booking Details (on confirmation page)
   ┌──────────────────────────────────────────────────────────┐
   │ GET /api/bookings/456                                    │
   │                                                          │
   │ Response: {                                              │
   │   booking_id: 456,                                       │
   │   guest_id: 1,                                           │
   │   total_amount: 3000.00,                                 │
   │   status: "Confirmed",                                   │
   │   policy_name: "Standard Cancellation",                  │
   │   policy_description: "...",                             │
   │   booking_details: [ ... ]                               │
   │ }                                                        │
   └──────────────────────────────────────────────────────────┘
                          ↓
6. List Bookings (on bookings page)
   ┌──────────────────────────────────────────────────────────┐
   │ GET /api/bookings                                        │
   │                                                          │
   │ Response: [                                              │
   │   {                                                      │
   │     booking_id: 456,                                     │
   │     status: "Confirmed",                                 │
   │     total_amount: 3000.00,                               │
   │     booking_details: [ ... ]                             │
   │   },                                                     │
   │   { ... }                                                │
   │ ]                                                        │
   └──────────────────────────────────────────────────────────┘
```

## Timer Behavior Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      COUNTDOWN TIMER BEHAVIOR                           │
└─────────────────────────────────────────────────────────────────────────┘

Hold Created: 15:00 remaining
┌────────────────────────────────────┐
│  ⏱️  15:00 remaining                │  Color: Blue
│  (Normal state)                    │  Background: bg-blue-100
└────────────────────────────────────┘

Time passes...

10:00 remaining
┌────────────────────────────────────┐
│  ⏱️  10:00 remaining                │  Color: Blue
│  (Still normal)                    │  Background: bg-blue-100
└────────────────────────────────────┘

Time passes...

04:59 remaining
┌────────────────────────────────────┐
│  ⏱️  04:59 remaining                │  Color: Yellow
│  (Low time warning)                │  Background: bg-yellow-100
└────────────────────────────────────┘

Time passes...

01:59 remaining
┌────────────────────────────────────┐
│  ⏱️  01:59 remaining                │  Color: Red
│  (Very low time - urgent!)         │  Background: bg-red-100
└────────────────────────────────────┘

Time passes...

00:00 remaining
┌────────────────────────────────────┐
│  ⏱️  00:00 remaining                │  Color: Red
│  (Expired!)                        │  Background: bg-red-100
└────────────────────────────────────┘
                ↓
        onExpire() called
                ↓
┌────────────────────────────────────┐
│  Alert: "Your reservation has      │
│  expired. Please search again."    │
└────────────────────────────────────┘
                ↓
        Clear booking store
                ↓
    Redirect to /rooms/search
```

This visual diagram provides a complete overview of the booking flow, state management, API calls, and timer behavior for easy reference and understanding.
