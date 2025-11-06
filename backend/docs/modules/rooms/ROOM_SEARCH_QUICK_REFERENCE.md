# Room Search Module - Quick Reference

## Overview
The Room Search Module provides endpoints for searching available rooms, viewing room types, and calculating pricing.

## Endpoints

### 1. Search Available Rooms
Search for rooms based on dates and guest count.

**Endpoint:** `GET /api/rooms/search`

**Query Parameters:**
- `checkIn` (required): Check-in date in YYYY-MM-DD format
- `checkOut` (required): Check-out date in YYYY-MM-DD format
- `guests` (required): Number of guests (minimum 1)

**Example Request:**
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "description": "Comfortable room with modern amenities",
        "max_occupancy": 2,
        "default_allotment": 10,
        "amenities": [
          {
            "amenity_id": 1,
            "name": "WiFi"
          },
          {
            "amenity_id": 2,
            "name": "Air Conditioning"
          }
        ],
        "total_price": 4000.00,
        "price_per_night": 1000.00,
        "nightly_prices": [
          {
            "date": "2025-12-01",
            "price": 1000.00
          },
          {
            "date": "2025-12-02",
            "price": 1000.00
          },
          {
            "date": "2025-12-03",
            "price": 1000.00
          },
          {
            "date": "2025-12-04",
            "price": 1000.00
          }
        ]
      }
    ],
    "check_in": "2025-12-01",
    "check_out": "2025-12-05",
    "guests": 2,
    "total_nights": 4
  }
}
```

**No Rooms Available Response (200):**
```json
{
  "success": true,
  "data": {
    "room_types": [],
    "check_in": "2025-12-01",
    "check_out": "2025-12-05",
    "guests": 2,
    "total_nights": 4,
    "alternative_dates": [
      "2025-11-28",
      "2025-11-29",
      "2025-11-30",
      "2025-12-02",
      "2025-12-03",
      "2025-12-04"
    ]
  }
}
```

**Error Responses:**
- `400`: Invalid parameters or date validation failed
- `500`: Server error

---

### 2. Get All Room Types
Retrieve all room types with their amenities.

**Endpoint:** `GET /api/rooms/types`

**Example Request:**
```bash
curl "http://localhost:8080/api/rooms/types"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "room_type_id": 1,
      "name": "Standard Room",
      "description": "Comfortable room with modern amenities",
      "max_occupancy": 2,
      "default_allotment": 10,
      "amenities": [
        {
          "amenity_id": 1,
          "name": "WiFi"
        },
        {
          "amenity_id": 2,
          "name": "Air Conditioning"
        }
      ]
    },
    {
      "room_type_id": 2,
      "name": "Deluxe Room",
      "description": "Spacious room with premium amenities",
      "max_occupancy": 3,
      "default_allotment": 5,
      "amenities": [
        {
          "amenity_id": 1,
          "name": "WiFi"
        },
        {
          "amenity_id": 2,
          "name": "Air Conditioning"
        },
        {
          "amenity_id": 3,
          "name": "Mini Bar"
        }
      ]
    }
  ]
}
```

---

### 3. Get Room Type Details
Get detailed information about a specific room type including all physical rooms.

**Endpoint:** `GET /api/rooms/types/:id`

**Path Parameters:**
- `id` (required): Room type ID

**Example Request:**
```bash
curl "http://localhost:8080/api/rooms/types/1"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "room_type_id": 1,
    "name": "Standard Room",
    "description": "Comfortable room with modern amenities",
    "max_occupancy": 2,
    "default_allotment": 10,
    "amenities": [
      {
        "amenity_id": 1,
        "name": "WiFi"
      },
      {
        "amenity_id": 2,
        "name": "Air Conditioning"
      }
    ],
    "rooms": [
      {
        "room_id": 1,
        "room_type_id": 1,
        "room_number": "101",
        "occupancy_status": "Vacant",
        "housekeeping_status": "Clean"
      },
      {
        "room_id": 2,
        "room_type_id": 1,
        "room_number": "102",
        "occupancy_status": "Occupied",
        "housekeeping_status": "Dirty"
      }
    ]
  }
}
```

**Error Responses:**
- `400`: Invalid room type ID
- `404`: Room type not found
- `500`: Server error

---

### 4. Get Room Type Pricing
Calculate pricing for a specific room type and date range.

**Endpoint:** `GET /api/rooms/types/:id/pricing`

**Path Parameters:**
- `id` (required): Room type ID

**Query Parameters:**
- `checkIn` (required): Check-in date in YYYY-MM-DD format
- `checkOut` (required): Check-out date in YYYY-MM-DD format

**Example Request:**
```bash
curl "http://localhost:8080/api/rooms/types/1/pricing?checkIn=2025-12-01&checkOut=2025-12-05"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "room_type_id": 1,
    "name": "Standard Room",
    "description": "Comfortable room with modern amenities",
    "max_occupancy": 2,
    "default_allotment": 10,
    "total_price": 4500.00,
    "price_per_night": 1125.00,
    "nightly_prices": [
      {
        "date": "2025-12-01",
        "price": 1000.00
      },
      {
        "date": "2025-12-02",
        "price": 1000.00
      },
      {
        "date": "2025-12-03",
        "price": 1500.00
      },
      {
        "date": "2025-12-04",
        "price": 1000.00
      }
    ]
  }
}
```

**Error Responses:**
- `400`: Invalid parameters or date validation failed
- `404`: Room type not found
- `500`: Server error

---

## Common Error Messages

### Thai Error Messages
- `"รูปแบบวันที่ check-in ไม่ถูกต้อง"` - Invalid check-in date format
- `"รูปแบบวันที่ check-out ไม่ถูกต้อง"` - Invalid check-out date format
- `"วันที่ check-out ต้องอยู่หลังวันที่ check-in"` - Check-out must be after check-in
- `"วันที่ check-in ต้องไม่อยู่ในอดีต"` - Check-in date cannot be in the past

### English Error Messages
- `"Invalid room type ID"` - Room type ID is not a valid integer
- `"Room type not found"` - Room type with given ID does not exist
- `"checkIn and checkOut are required"` - Missing required query parameters
- `"Failed to search rooms"` - Database or server error
- `"Failed to get room types"` - Database or server error

---

## Business Logic

### Availability Check
1. Generates date series from check-in to check-out (excluding check-out date)
2. For each date, checks: `(allotment - booked_count - tentative_count) > 0`
3. Uses `default_allotment` if no inventory record exists
4. Only returns room types available for ALL nights
5. Filters by `max_occupancy >= guests`

### Price Calculation
1. Retrieves rate tier for each date from `pricing_calendar`
2. Looks up price in `rate_pricing` table using:
   - Room type ID
   - Rate plan ID (default)
   - Rate tier ID (from calendar)
3. Sums all nightly prices for total
4. Calculates average price per night

### Alternative Dates
When no rooms are available:
- Suggests 3 days before check-in (if not in past)
- Suggests 3 days after check-in
- Returns dates in YYYY-MM-DD format

---

## Database Dependencies

### Required Tables
- `room_types` - Room type definitions
- `rooms` - Physical rooms
- `amenities` - Available amenities
- `room_type_amenities` - Room type to amenity mapping
- `room_inventory` - Daily availability tracking
- `rate_plans` - Rate plan definitions
- `rate_tiers` - Rate tier definitions (e.g., Low, Standard, High)
- `pricing_calendar` - Date to rate tier mapping
- `rate_pricing` - Price matrix (room type × rate plan × rate tier)

### Data Requirements
For pricing to work:
1. At least one rate plan must exist
2. Rate tiers must be defined
3. Pricing calendar must have entries for search dates
4. Rate pricing must have prices for room types

If pricing data is missing:
- Search returns rooms without pricing information
- Pricing endpoint may return 0 prices

---

## Testing Examples

### Test 1: Basic Search
```bash
# Search for 2 guests, 4 nights
curl "http://localhost:8080/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2"
```

### Test 2: Invalid Date Order
```bash
# Check-out before check-in (should fail)
curl "http://localhost:8080/api/rooms/search?checkIn=2025-12-05&checkOut=2025-12-01&guests=2"
```

### Test 3: Past Date
```bash
# Check-in in the past (should fail)
curl "http://localhost:8080/api/rooms/search?checkIn=2024-01-01&checkOut=2024-01-05&guests=2"
```

### Test 4: Large Group
```bash
# Search for 5 guests (only returns rooms with max_occupancy >= 5)
curl "http://localhost:8080/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=5"
```

### Test 5: Get All Room Types
```bash
curl "http://localhost:8080/api/rooms/types"
```

### Test 6: Get Specific Room Type
```bash
curl "http://localhost:8080/api/rooms/types/1"
```

### Test 7: Get Pricing
```bash
curl "http://localhost:8080/api/rooms/types/1/pricing?checkIn=2025-12-01&checkOut=2025-12-05"
```

---

## Integration Notes

### Frontend Integration
When integrating with frontend:
1. Use the search endpoint for the main search page
2. Display room types with amenities and pricing
3. Show nightly price breakdown on hover/expand
4. If no rooms available, show alternative dates
5. Use room type details endpoint for detailed view
6. Use pricing endpoint to recalculate when dates change

### Booking Flow Integration
1. After user selects a room from search results
2. Store: room_type_id, check_in, check_out, guests
3. Pass to booking hold endpoint (Task 15)
4. Use nightly prices for booking confirmation

---

## Performance Considerations

### Optimization Tips
1. Search query uses indexes on:
   - `room_inventory(room_type_id, date)`
   - `room_types(max_occupancy)`
2. Consider caching room types (rarely change)
3. Consider caching pricing calendar (changes daily at most)
4. Use connection pooling for database

### Expected Response Times
- Search: < 200ms (with proper indexes)
- Get all room types: < 100ms
- Get room type details: < 150ms
- Get pricing: < 150ms

---

## Security Notes

- All endpoints are public (no authentication required)
- Input validation prevents SQL injection
- Date parsing prevents invalid formats
- Integer parsing prevents invalid IDs
- No sensitive data exposed in responses

---

## Future Enhancements

Potential improvements:
1. Add filtering (by amenities, price range)
2. Add sorting (by price, name, occupancy)
3. Add pagination for large result sets
4. Add room images
5. Add room availability calendar view
6. Add special offers/promotions
7. Add room comparison feature
8. Add reviews and ratings
