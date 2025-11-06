# Check-in/Check-out Module - Quick Reference

## Overview

This module handles check-in, check-out, room moves, and no-show management for the hotel booking system. All endpoints require receptionist role authentication.

## API Endpoints

### 1. Check-in

**Endpoint:** `POST /api/checkin`

**Authentication:** Required (Receptionist role)

**Request Body:**
```json
{
  "booking_detail_id": 1,
  "room_id": 101
}
```

**Response:**
```json
{
  "success": true,
  "message": "Check-in สำเร็จ",
  "room_number": "101"
}
```

**Description:** Checks in a guest to a specific room. The room must be vacant and clean/inspected.

---

### 2. Check-out

**Endpoint:** `POST /api/checkout`

**Authentication:** Required (Receptionist role)

**Request Body:**
```json
{
  "booking_id": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "Check-out สำเร็จ",
  "total_amount": 3000.00
}
```

**Description:** Checks out a guest and marks all assigned rooms as dirty.

---

### 3. Move Room

**Endpoint:** `POST /api/checkin/move-room`

**Authentication:** Required (Receptionist role)

**Request Body:**
```json
{
  "room_assignment_id": 1,
  "new_room_id": 102,
  "reason": "Air conditioning issue"
}
```

**Response:**
```json
{
  "success": true,
  "message": "ย้ายห้องสำเร็จ",
  "new_room_number": "102"
}
```

**Description:** Moves a guest from their current room to a new room. The old room is marked as dirty.

---

### 4. Mark No-Show

**Endpoint:** `POST /api/bookings/:id/no-show`

**Authentication:** Required (Receptionist role)

**Request Body:**
```json
{
  "notes": "Guest did not arrive by end of check-in day"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking marked as no-show successfully"
}
```

**Description:** Marks a confirmed booking as no-show when the guest doesn't arrive.

---

### 5. Get Arrivals

**Endpoint:** `GET /api/checkin/arrivals?date=2024-01-15`

**Authentication:** Required (Receptionist role)

**Query Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to today.

**Response:**
```json
{
  "arrivals": [
    {
      "booking_id": 1,
      "booking_detail_id": 1,
      "guest_name": "John Doe",
      "room_type_name": "Deluxe Room",
      "check_in_date": "2024-01-15T00:00:00Z",
      "check_out_date": "2024-01-17T00:00:00Z",
      "num_guests": 2,
      "status": "Confirmed",
      "room_number": null
    }
  ],
  "count": 1
}
```

**Description:** Retrieves all bookings arriving on a specific date.

---

### 6. Get Departures

**Endpoint:** `GET /api/checkout/departures?date=2024-01-15`

**Authentication:** Required (Receptionist role)

**Query Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to today.

**Response:**
```json
{
  "departures": [
    {
      "booking_id": 1,
      "guest_name": "John Doe",
      "room_number": "101",
      "check_out_date": "2024-01-15T00:00:00Z",
      "total_amount": 3000.00,
      "status": "CheckedIn"
    }
  ],
  "count": 1
}
```

**Description:** Retrieves all bookings departing on a specific date.

---

### 7. Get Available Rooms for Check-in

**Endpoint:** `GET /api/checkin/available-rooms/:roomTypeId`

**Authentication:** Required (Receptionist role)

**Path Parameters:**
- `roomTypeId`: The room type ID

**Response:**
```json
{
  "rooms": [
    {
      "room_id": 1,
      "room_number": "101",
      "occupancy_status": "Vacant",
      "housekeeping_status": "Inspected"
    },
    {
      "room_id": 2,
      "room_number": "102",
      "occupancy_status": "Vacant",
      "housekeeping_status": "Clean"
    }
  ],
  "count": 2
}
```

**Description:** Retrieves all vacant and clean/inspected rooms for a specific room type. Inspected rooms are listed first.

---

## PostgreSQL Functions Used

### 1. check_in(booking_detail_id, room_id)

Performs atomic check-in operation:
- Validates room is vacant and clean/inspected
- Updates booking status to 'CheckedIn'
- Creates room assignment
- Updates room occupancy status to 'Occupied'

### 2. check_out(booking_id)

Performs atomic check-out operation:
- Updates booking status to 'Completed'
- Closes all active room assignments
- Updates rooms to vacant and dirty

### 3. move_room(room_assignment_id, new_room_id)

Performs atomic room move operation:
- Closes old room assignment
- Creates new room assignment
- Updates old room to vacant and dirty
- Updates new room to occupied

---

## Error Handling

All endpoints return appropriate HTTP status codes:

- `200 OK`: Successful operation
- `400 Bad Request`: Invalid input or business rule violation
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Insufficient permissions (not a receptionist)
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

Error response format:
```json
{
  "error": "Error message description"
}
```

---

## Business Rules

### Check-in Rules:
1. Room must be vacant
2. Room must be clean or inspected
3. Booking must be in 'Confirmed' status
4. Check-in date must match or be past

### Check-out Rules:
1. Booking must be in 'CheckedIn' status
2. All assigned rooms are marked as dirty after check-out

### Room Move Rules:
1. New room must be vacant and clean/inspected
2. New room must be same or higher room type
3. Old room is automatically marked as dirty

### No-Show Rules:
1. Booking must be in 'Confirmed' status
2. Can only be marked after check-in date has passed
3. Inventory is not automatically released (manager decision)

---

## Testing with cURL

### Check-in Example:
```bash
curl -X POST http://localhost:8080/api/checkin \
  -H "Authorization: Bearer YOUR_RECEPTIONIST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking_detail_id": 1,
    "room_id": 101
  }'
```

### Check-out Example:
```bash
curl -X POST http://localhost:8080/api/checkout \
  -H "Authorization: Bearer YOUR_RECEPTIONIST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": 1
  }'
```

### Get Arrivals Example:
```bash
curl -X GET "http://localhost:8080/api/checkin/arrivals?date=2024-01-15" \
  -H "Authorization: Bearer YOUR_RECEPTIONIST_TOKEN"
```

### Move Room Example:
```bash
curl -X POST http://localhost:8080/api/checkin/move-room \
  -H "Authorization: Bearer YOUR_RECEPTIONIST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_assignment_id": 1,
    "new_room_id": 102,
    "reason": "Air conditioning issue"
  }'
```

---

## Integration with Frontend

The frontend should:

1. **Check-in Flow:**
   - Display arrivals list
   - Show available rooms for selected room type
   - Allow receptionist to select room and confirm check-in
   - Display room number and welcome message

2. **Check-out Flow:**
   - Display departures list
   - Show bill summary
   - Confirm check-out
   - Print receipt

3. **Room Move Flow:**
   - Display current room assignment
   - Show available rooms for move
   - Allow reason input
   - Confirm move and notify housekeeping

4. **No-Show Management:**
   - Display overdue arrivals
   - Allow marking as no-show with notes
   - Track no-show patterns for reporting

---

## Database Schema Reference

### Key Tables:
- `bookings`: Main booking records
- `booking_details`: Individual room bookings
- `room_assignments`: Room assignment history
- `rooms`: Room inventory with status

### Status Values:

**Booking Status:**
- `Confirmed`: Booking confirmed, awaiting check-in
- `CheckedIn`: Guest has checked in
- `Completed`: Guest has checked out
- `NoShow`: Guest did not arrive

**Occupancy Status:**
- `Vacant`: Room is empty
- `Occupied`: Room has a guest

**Housekeeping Status:**
- `Dirty`: Needs cleaning
- `Cleaning`: Being cleaned
- `Clean`: Cleaned, not inspected
- `Inspected`: Cleaned and inspected (ready for check-in)
- `MaintenanceRequired`: Needs maintenance
- `OutOfService`: Not available

---

## Performance Considerations

1. **Indexes:** Ensure indexes exist on:
   - `booking_details.check_in_date`
   - `booking_details.check_out_date`
   - `room_assignments.status`
   - `rooms.occupancy_status`
   - `rooms.housekeeping_status`

2. **Transactions:** All operations use PostgreSQL functions with proper transaction handling

3. **Concurrency:** PostgreSQL row-level locking prevents race conditions

---

## Security

1. **Authentication:** All endpoints require valid JWT token
2. **Authorization:** All endpoints require 'receptionist' role
3. **Input Validation:** All inputs are validated before processing
4. **SQL Injection:** Protected by using parameterized queries
5. **Audit Trail:** All operations are logged in room_assignments table

---

## Future Enhancements

1. Early check-in/late check-out handling
2. Room preference tracking
3. Automatic room assignment based on preferences
4. Integration with key card systems
5. SMS/Email notifications for check-in/out
6. Digital check-in kiosks
7. Mobile check-in/out
