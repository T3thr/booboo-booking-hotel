# Task 19: Guest Room Search - Quick Start Guide

## Overview
This task implements the room search functionality for guests, including:
- Search form with date and guest selection
- Room cards displaying available rooms with pricing
- Integration with backend `/api/rooms/search` endpoint
- Responsive design with Tailwind CSS

## Files Created

### Components
1. **`frontend/src/components/room-search-form.tsx`**
   - Search form with check-in, check-out, adults, and children inputs
   - Client-side validation
   - Date validation (check-out must be after check-in)

2. **`frontend/src/components/room-card.tsx`**
   - Displays room information (name, description, max occupancy)
   - Shows amenities as tags
   - Displays pricing breakdown (nightly rate, total price)
   - Book button with availability check

3. **`frontend/src/app/(guest)/rooms/search/page.tsx`**
   - Main search page
   - Handles search state and results
   - Shows loading, error, and empty states
   - Integrates search form and room cards

4. **`frontend/src/app/(guest)/layout.tsx`**
   - Guest navigation layout
   - Header with links to search and bookings
   - Footer

## Files Modified

1. **`frontend/src/lib/api.ts`**
   - Updated `roomApi.search()` to transform frontend params to backend format
   - Maps `check_in_date` → `checkIn`, `check_out_date` → `checkOut`
   - Combines `adults` + `children` → `guests`

2. **`frontend/src/hooks/use-rooms.ts`**
   - Updated `useRoomSearch()` to extract `room_types` array from response

3. **`frontend/src/types/index.ts`**
   - Added `RoomSearchResponse` interface
   - Updated `RoomSearchResult` to match backend response
   - Added optional fields to `RoomType`

## API Integration

### Backend Endpoint
```
GET /api/rooms/search?checkIn=YYYY-MM-DD&checkOut=YYYY-MM-DD&guests=N
```

### Request Parameters
- `checkIn` (string, required): Check-in date in YYYY-MM-DD format
- `checkOut` (string, required): Check-out date in YYYY-MM-DD format
- `guests` (number, required): Total number of guests (adults + children)

### Response Structure
```json
{
  "room_types": [
    {
      "room_type_id": 1,
      "name": "Deluxe Room",
      "description": "Spacious room with city view",
      "max_occupancy": 2,
      "default_allotment": 10,
      "amenities": [
        { "amenity_id": 1, "name": "WiFi" },
        { "amenity_id": 2, "name": "Air Conditioning" }
      ],
      "available_rooms": 5,
      "total_price": 3000.00,
      "nightly_prices": [
        { "date": "2025-01-15", "price": 1500.00 },
        { "date": "2025-01-16", "price": 1500.00 }
      ]
    }
  ],
  "check_in": "2025-01-15",
  "check_out": "2025-01-17",
  "guests": 2,
  "total_nights": 2
}
```

## Testing the Implementation

### 1. Start the Backend Server
```bash
cd backend
make run
# or
go run cmd/server/main.go
```

### 2. Start the Frontend Server
```bash
cd frontend
npm run dev
# or
bun dev
```

### 3. Access the Room Search Page
Navigate to: `http://localhost:3000/rooms/search`

### 4. Test Search Functionality

#### Test Case 1: Valid Search
1. Select check-in date (today or future)
2. Select check-out date (after check-in)
3. Enter number of adults (e.g., 2)
4. Enter number of children (e.g., 0)
5. Click "ค้นหาห้องพัก"
6. **Expected**: Room cards appear with available rooms

#### Test Case 2: No Results
1. Select dates far in the future with no inventory
2. Click search
3. **Expected**: "ไม่พบห้องว่าง" message appears

#### Test Case 3: Validation Errors
1. Select check-out date before check-in date
2. **Expected**: Error message "วันเช็คเอาท์ต้องหลังวันเช็คอิน"

#### Test Case 4: Booking Flow
1. Search for rooms
2. Click "จองห้องนี้" on a room card
3. **Expected**: Redirected to booking page (to be implemented in Task 20)

### 5. Manual API Testing

Test the backend endpoint directly:
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-02-01&checkOut=2025-02-03&guests=2"
```

## Features Implemented

### ✅ Search Form
- Date inputs with validation
- Guest count inputs (adults and children)
- Form validation (dates, guest counts)
- Loading state during search

### ✅ Room Cards
- Room image display (with placeholder if no image)
- Room name and description
- Max occupancy indicator
- Available rooms count
- Amenities display as tags
- Pricing breakdown:
  - Average nightly rate
  - Total price
  - Expandable nightly price details
- Book button (disabled when no rooms available)

### ✅ Search Results
- Loading spinner during search
- Error handling with user-friendly messages
- Empty state when no results
- Initial state before first search
- Results count display

### ✅ Responsive Design
- Mobile-friendly layout
- Grid layout for search form (1 column on mobile, 4 on desktop)
- Card layout adapts to screen size
- Touch-friendly buttons and inputs

## Requirements Coverage

This implementation covers the following requirements from the spec:

### Requirement 2.1-2.8: Room Search and Availability
- ✅ 2.1: Search form with check-in, check-out, and guest count
- ✅ 2.2: Display "ไม่มีห้องว่าง" when no availability
- ✅ 2.3: Display room type details (name, description, max occupancy, amenities, images, price)
- ✅ 2.4: Query room inventory for availability
- ✅ 2.5: Validate check-out date is after check-in
- ✅ 2.6: Calculate total price from nightly rates
- ✅ 2.7: Show nightly price breakdown when prices vary
- ✅ 2.8: Filter rooms by max occupancy

## Next Steps

### Task 20: Booking Flow
The next task will implement:
- Guest information form
- Payment summary page
- Booking hold creation
- Countdown timer for hold expiry
- Booking confirmation

### Future Enhancements
- Room image gallery (multiple images)
- Advanced filters (price range, amenities)
- Sort options (price, rating, availability)
- Room comparison feature
- Save favorite rooms
- Share search results

## Troubleshooting

### Issue: "Failed to search rooms"
**Solution**: Ensure backend is running and database has seed data

### Issue: No rooms displayed
**Solution**: Check if room inventory has been seeded for the selected dates

### Issue: Images not showing
**Solution**: Backend returns `image_url` field, ensure it's populated or use placeholder

### Issue: Prices showing as 0
**Solution**: Ensure pricing calendar and rate pricing tables are populated

## Database Requirements

For the search to work, ensure these tables have data:
1. `room_types` - Room type definitions
2. `amenities` - Available amenities
3. `room_type_amenities` - Room type to amenity mappings
4. `room_inventory` - Daily inventory for each room type
5. `rate_tiers` - Pricing tiers (e.g., Low, Standard, High)
6. `pricing_calendar` - Tier assignments for each date
7. `rate_plans` - Rate plan definitions
8. `rate_pricing` - Prices for each room type, rate plan, and tier combination

## Code Quality

- ✅ TypeScript for type safety
- ✅ Proper error handling
- ✅ Loading states
- ✅ Responsive design
- ✅ Accessibility (semantic HTML, labels)
- ✅ Clean component structure
- ✅ Reusable components
- ✅ Consistent styling with Tailwind CSS

