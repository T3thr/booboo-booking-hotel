# Housekeeping Module - Quick Reference

## Overview

The Housekeeping Module provides endpoints for housekeepers and supervisors to manage room cleaning tasks, update room statuses, inspect cleaned rooms, and report maintenance issues.

## Authentication

All housekeeping endpoints require:
- Valid JWT token in Authorization header
- User role: `housekeeper`

```
Authorization: Bearer <token>
```

## Endpoints

### 1. Get Housekeeping Tasks

Retrieves all rooms that need cleaning or inspection, sorted by priority.

**Endpoint:** `GET /api/housekeeping/tasks`

**Response:**
```json
{
  "success": true,
  "data": {
    "tasks": [
      {
        "room_id": 101,
        "room_number": "101",
        "room_type_id": 1,
        "room_type_name": "Standard Room",
        "occupancy_status": "Vacant",
        "housekeeping_status": "Dirty",
        "priority": 1,
        "last_updated": "2025-11-03T10:30:00Z",
        "estimated_time": 25
      }
    ],
    "total_tasks": 15,
    "summary": {
      "dirty": 8,
      "cleaning": 3,
      "clean": 4,
      "inspected": 20,
      "maintenance_required": 2
    }
  }
}
```

**Priority Levels:**
- 1: Vacant + Dirty (highest priority - ready for next guest)
- 2: Occupied + Dirty (daily cleaning)
- 3: Cleaning (in progress)
- 4: Clean (ready for inspection)

### 2. Update Room Status

Updates the housekeeping status of a specific room.

**Endpoint:** `PUT /api/housekeeping/rooms/:id/status`

**Request Body:**
```json
{
  "status": "Cleaning"
}
```

**Valid Statuses:**
- `Dirty` - Room needs cleaning
- `Cleaning` - Cleaning in progress
- `Clean` - Cleaning completed, ready for inspection
- `Inspected` - Approved by supervisor
- `MaintenanceRequired` - Needs maintenance
- `OutOfService` - Room unavailable

**Valid Status Transitions:**
```
Dirty → Cleaning, MaintenanceRequired, OutOfService
Cleaning → Clean, Dirty, MaintenanceRequired
Clean → Inspected, Dirty, MaintenanceRequired
Inspected → Dirty, MaintenanceRequired, OutOfService
MaintenanceRequired → Dirty, OutOfService
OutOfService → Dirty
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Room status updated successfully",
    "room_id": 101,
    "status": "Cleaning"
  }
}
```

### 3. Get Rooms for Inspection

Retrieves all rooms that are in "Clean" status and ready for supervisor inspection.

**Endpoint:** `GET /api/housekeeping/inspection`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "room_id": 102,
      "room_number": "102",
      "room_type_id": 1,
      "room_type_name": "Standard Room",
      "occupancy_status": "Vacant",
      "housekeeping_status": "Clean",
      "priority": 4,
      "last_updated": "2025-11-03T11:00:00Z",
      "estimated_time": 5
    }
  ]
}
```

### 4. Inspect Room

Allows supervisor to approve or reject a cleaned room.

**Endpoint:** `POST /api/housekeeping/rooms/:id/inspect`

**Request Body:**
```json
{
  "approved": true,
  "notes": "Room looks great, approved for guest check-in"
}
```

**Behavior:**
- If `approved: true` → Status changes to "Inspected"
- If `approved: false` → Status changes back to "Dirty"

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Room inspection completed",
    "room_id": 102,
    "status": "approved"
  }
}
```

### 5. Report Maintenance Issue

Reports a maintenance issue for a room and marks it as requiring maintenance.

**Endpoint:** `POST /api/housekeeping/rooms/:id/maintenance`

**Request Body:**
```json
{
  "description": "Air conditioning not working properly"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Maintenance issue reported successfully",
    "room_id": 101,
    "description": "Air conditioning not working properly"
  }
}
```

## Typical Workflows

### Workflow 1: Daily Room Cleaning

1. Housekeeper logs in
2. Gets task list: `GET /api/housekeeping/tasks`
3. Starts cleaning room: `PUT /api/housekeeping/rooms/101/status` with `{"status": "Cleaning"}`
4. Completes cleaning: `PUT /api/housekeeping/rooms/101/status` with `{"status": "Clean"}`
5. Supervisor inspects: `POST /api/housekeeping/rooms/101/inspect` with `{"approved": true}`
6. Room is now "Inspected" and ready for check-in

### Workflow 2: Maintenance Issue

1. Housekeeper finds issue during cleaning
2. Reports maintenance: `POST /api/housekeeping/rooms/101/maintenance` with description
3. Room status automatically changes to "MaintenanceRequired"
4. After maintenance is fixed, status can be changed back to "Dirty"

### Workflow 3: Failed Inspection

1. Supervisor inspects room: `POST /api/housekeeping/rooms/102/inspect` with `{"approved": false, "notes": "Bathroom needs more attention"}`
2. Room status changes back to "Dirty"
3. Housekeeper sees room back in task list
4. Housekeeper re-cleans the room

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "invalid housekeeping status"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": "unauthorized"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": "insufficient permissions"
}
```

### 404 Not Found
```json
{
  "success": false,
  "error": "Room not found"
}
```

## Testing

Run the test script to verify all endpoints:

```powershell
# PowerShell
.\test_housekeeping_module.ps1
```

```bash
# Bash (if converted)
./test_housekeeping_module.sh
```

## Requirements Covered

This module implements the following requirements:

**Requirement 10: การจัดการสถานะการทำความสะอาดห้อง**
- 10.1: Display task list for housekeepers
- 10.2: Update room status (Dirty → Cleaning)
- 10.3: Update room status (Cleaning → Clean)
- 10.4: Report maintenance issues
- 10.5: Real-time status updates
- 10.6: Timestamp logging
- 10.7: Estimated cleaning time display

**Requirement 11: การตรวจสอบห้องโดยหัวหน้าแม่บ้าน**
- 11.1: Display rooms ready for inspection
- 11.2: Approve room (Clean → Inspected)
- 11.3: Reject room (Clean → Dirty)
- 11.4: Prioritize inspected rooms for check-in
- 11.5: Display inspected rooms first
- 11.6: Record rejection reason

## Integration Points

### With Check-in Module
- Inspected rooms are prioritized for check-in
- Check-in handler queries rooms with status "Inspected" or "Clean"

### With Night Audit
- Night audit automatically sets Occupied rooms to Dirty
- Runs daily at 02:00 AM

### With Room Status Dashboard
- Real-time status updates reflect immediately
- Receptionist dashboard shows current housekeeping status

## Database Schema

### Rooms Table
```sql
CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    room_type_id INT NOT NULL,
    room_number VARCHAR(10) UNIQUE NOT NULL,
    occupancy_status VARCHAR(20) NOT NULL DEFAULT 'Vacant',
    housekeeping_status VARCHAR(50) NOT NULL DEFAULT 'Dirty',
    CONSTRAINT chk_occupancy CHECK (occupancy_status IN ('Vacant', 'Occupied')),
    CONSTRAINT chk_housekeeping CHECK (housekeeping_status IN 
        ('Dirty', 'Cleaning', 'Clean', 'Inspected', 'MaintenanceRequired', 'OutOfService'))
);
```

## Notes

- All status updates are atomic and immediate
- Status transitions are validated to prevent invalid states
- Priority is calculated based on occupancy and housekeeping status
- Estimated cleaning time varies by room type (Suite: 45min, Deluxe: 35min, Standard: 25min)
- Maintenance issues should be tracked in a separate system (future enhancement)
