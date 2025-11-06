# Inventory Management Module - Quick Reference

## Overview

The Inventory Management Module allows hotel managers to view and manage room inventory (allotment) for different room types across dates. It includes validation to prevent reducing inventory below existing bookings.

## Key Features

- View inventory for all room types or specific room type
- View inventory for specific dates
- Update inventory for single dates
- Bulk update inventory for date ranges
- Automatic validation against existing bookings
- Prevents overbooking by enforcing: `allotment >= booked_count + tentative_count`

## API Endpoints

### 1. Get All Inventory

**Endpoint:** `GET /api/inventory`

**Query Parameters:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format
- `room_type_id` (optional): Filter by specific room type

**Authentication:** Required (Manager role)

**Example Request:**
```bash
curl -X GET "http://localhost:8080/api/inventory?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "success": true,
  "data": [
    {
      "room_type_id": 1,
      "room_type_name": "Standard Room",
      "date": "2024-01-01T00:00:00Z",
      "allotment": 10,
      "booked_count": 5,
      "tentative_count": 2,
      "available": 3,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### 2. Get Inventory for Specific Room Type

**Endpoint:** `GET /api/inventory?room_type_id={id}&start_date={date}&end_date={date}`

**Query Parameters:**
- `room_type_id` (required): Room type ID
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (required): End date in YYYY-MM-DD format

**Authentication:** Required (Manager role)

**Example Request:**
```bash
curl -X GET "http://localhost:8080/api/inventory?room_type_id=1&start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Get Inventory for Specific Date

**Endpoint:** `GET /api/inventory/:roomTypeId/:date`

**Path Parameters:**
- `roomTypeId`: Room type ID
- `date`: Date in YYYY-MM-DD format

**Authentication:** Required (Manager role)

**Example Request:**
```bash
curl -X GET "http://localhost:8080/api/inventory/1/2024-01-15" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "room_type_id": 1,
    "date": "2024-01-15T00:00:00Z",
    "allotment": 10,
    "booked_count": 5,
    "tentative_count": 2,
    "available": 3,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-10T00:00:00Z"
  }
}
```

### 4. Update Inventory (Single Date)

**Endpoint:** `PUT /api/inventory`

**Authentication:** Required (Manager role)

**Request Body:**
```json
{
  "room_type_id": 1,
  "date": "2024-01-15",
  "allotment": 15
}
```

**Validation Rules:**
- `allotment` must be >= 0
- `allotment` must be >= `booked_count + tentative_count`
- `room_type_id` must exist
- `date` must be valid format (YYYY-MM-DD)

**Example Request:**
```bash
curl -X PUT "http://localhost:8080/api/inventory" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "date": "2024-01-15",
    "allotment": 15
  }'
```

**Success Response:**
```json
{
  "success": true,
  "message": "Inventory updated successfully"
}
```

**Error Response (Validation Failed):**
```json
{
  "success": false,
  "error": "Failed to update inventory",
  "details": "cannot reduce allotment to 10, current bookings: 12 (booked: 8, tentative: 4)"
}
```

### 5. Bulk Update Inventory

**Endpoint:** `POST /api/inventory/bulk`

**Authentication:** Required (Manager role)

**Request Body:**
```json
{
  "room_type_id": 1,
  "start_date": "2024-01-01",
  "end_date": "2024-01-31",
  "allotment": 20
}
```

**Validation Rules:**
- Same as single update, but applied to all dates in range
- Date range cannot exceed 1 year
- `end_date` must be after `start_date`

**Example Request:**
```bash
curl -X POST "http://localhost:8080/api/inventory/bulk" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "start_date": "2024-01-01",
    "end_date": "2024-01-31",
    "allotment": 20
  }'
```

**Success Response:**
```json
{
  "success": true,
  "message": "Inventory bulk updated successfully"
}
```

**Error Response (Validation Failed):**
```json
{
  "success": false,
  "error": "Cannot update inventory for some dates due to existing bookings",
  "validation_errors": [
    {
      "date": "2024-01-15",
      "message": "Cannot reduce allotment to 10. Current bookings: 12 (booked: 8, tentative: 4)"
    },
    {
      "date": "2024-01-20",
      "message": "Cannot reduce allotment to 10. Current bookings: 15 (booked: 10, tentative: 5)"
    }
  ]
}
```

## Data Model

### RoomInventory

```go
type RoomInventory struct {
    RoomTypeID     int       `json:"room_type_id"`
    Date           time.Time `json:"date"`
    Allotment      int       `json:"allotment"`
    BookedCount    int       `json:"booked_count"`
    TentativeCount int       `json:"tentative_count"`
    Available      int       `json:"available"` // Calculated: allotment - booked_count - tentative_count
    CreatedAt      time.Time `json:"created_at"`
    UpdatedAt      time.Time `json:"updated_at"`
}
```

### RoomInventoryWithDetails

```go
type RoomInventoryWithDetails struct {
    RoomTypeID     int       `json:"room_type_id"`
    RoomTypeName   string    `json:"room_type_name"`
    Date           time.Time `json:"date"`
    Allotment      int       `json:"allotment"`
    BookedCount    int       `json:"booked_count"`
    TentativeCount int       `json:"tentative_count"`
    Available      int       `json:"available"`
    CreatedAt      time.Time `json:"created_at"`
    UpdatedAt      time.Time `json:"updated_at"`
}
```

## Business Rules

### Inventory Constraint

The system enforces the following constraint at the database level:

```sql
CONSTRAINT chk_inventory CHECK (booked_count + tentative_count <= allotment)
```

This ensures that:
1. You cannot reduce allotment below current bookings
2. The booking system cannot create bookings that exceed allotment
3. Data integrity is maintained at all times

### Validation Flow

When updating inventory:

1. **Single Update:**
   - Check if new allotment >= current (booked_count + tentative_count)
   - If valid, update the record
   - If invalid, return error with current booking counts

2. **Bulk Update:**
   - Check all dates in range for validation
   - Collect all dates that would violate the constraint
   - If any violations found, return all validation errors without updating
   - If all valid, update all dates in range

## Common Use Cases

### 1. View Current Inventory Status

```bash
# Get inventory for next 30 days
START_DATE=$(date +%Y-%m-%d)
END_DATE=$(date -d "+30 days" +%Y-%m-%d)

curl -X GET "http://localhost:8080/api/inventory?start_date=$START_DATE&end_date=$END_DATE" \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Increase Allotment for High Season

```bash
# Bulk update for December (high season)
curl -X POST "http://localhost:8080/api/inventory/bulk" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "start_date": "2024-12-01",
    "end_date": "2024-12-31",
    "allotment": 25
  }'
```

### 3. Reduce Allotment for Maintenance

```bash
# Reduce allotment for specific dates
curl -X PUT "http://localhost:8080/api/inventory" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "date": "2024-06-15",
    "allotment": 5
  }'
```

### 4. Check Specific Date Before Booking

```bash
# Check availability for specific date
curl -X GET "http://localhost:8080/api/inventory/1/2024-06-15" \
  -H "Authorization: Bearer $TOKEN"
```

## Error Handling

### Common Errors

1. **Invalid Date Format**
   ```json
   {
     "success": false,
     "error": "Failed to retrieve inventory",
     "details": "invalid start date format: parsing time \"2024-13-01\" as \"2006-01-02\": month out of range"
   }
   ```

2. **Invalid Room Type**
   ```json
   {
     "success": false,
     "error": "Failed to update inventory",
     "details": "invalid room type ID: sql: no rows in result set"
   }
   ```

3. **Allotment Below Bookings**
   ```json
   {
     "success": false,
     "error": "Failed to update inventory",
     "details": "cannot reduce allotment to 5, current bookings: 8 (booked: 6, tentative: 2)"
   }
   ```

4. **Date Range Too Large**
   ```json
   {
     "success": false,
     "error": "Failed to retrieve inventory",
     "details": "date range cannot exceed 1 year"
   }
   ```

5. **Unauthorized Access**
   ```json
   {
     "success": false,
     "error": "Insufficient permissions"
   }
   ```

## Testing

Run the test script:

```powershell
# PowerShell
.\test_inventory_module.ps1
```

```bash
# Bash (if converted)
./test_inventory_module.sh
```

## Integration with Other Modules

### Booking Module
- Booking creation checks inventory availability
- Confirmed bookings increment `booked_count`
- Pending bookings increment `tentative_count`
- Cancelled bookings decrement respective counts

### Room Search Module
- Uses inventory data to determine room availability
- Filters out room types with no available inventory

### Pricing Module
- Inventory data can be displayed alongside pricing calendar
- Helps managers make pricing decisions based on availability

## Database Schema

```sql
CREATE TABLE room_inventory (
    room_type_id INT REFERENCES room_types(room_type_id),
    date DATE,
    allotment INT NOT NULL,
    booked_count INT NOT NULL DEFAULT 0,
    tentative_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (room_type_id, date),
    CONSTRAINT chk_inventory CHECK (booked_count + tentative_count <= allotment)
);

CREATE INDEX idx_inventory_date ON room_inventory(date);
```

## Best Practices

1. **Always validate before bulk updates** - Check a sample date first
2. **Use date ranges wisely** - Don't query more than necessary
3. **Monitor validation errors** - They indicate booking pressure
4. **Coordinate with pricing** - Adjust inventory with pricing tiers
5. **Plan ahead** - Set inventory for future dates in advance
6. **Regular audits** - Verify inventory matches actual room availability

## Requirements Covered

This module implements the following requirements from the specification:

- **13.1**: Manager can access inventory management interface
- **13.2**: System displays inventory for all room types for 365 days
- **13.3**: Manager can update allotment for specific dates
- **13.4**: System validates allotment >= (booked_count + tentative_count)
- **13.5**: System rejects updates that violate constraint with error message
- **13.6**: Manager can bulk update allotment for date ranges
- **13.7**: System displays inventory calendar with heatmap visualization (frontend)
