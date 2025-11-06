# Task 26: Housekeeping Module - Quick Start Guide

## Overview

This guide will help you quickly set up and test the Housekeeping Module.

## Prerequisites

1. ✅ Backend server running
2. ✅ PostgreSQL database with schema
3. ✅ Housekeeper account created

## Step 1: Create Housekeeper Account

If you don't have a housekeeper account, create one:

```sql
-- 1. Insert guest
INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('House', 'Keeper', 'housekeeper@hotel.com', '1234567890')
ON CONFLICT (email) DO NOTHING;

-- 2. Get the guest_id
SELECT guest_id FROM guests WHERE email = 'housekeeper@hotel.com';

-- 3. Insert guest account with housekeeper role
-- Note: Replace 'YOUR_HASHED_PASSWORD' with actual bcrypt hash of 'password123'
INSERT INTO guest_accounts (guest_id, hashed_password, role)
VALUES (
    (SELECT guest_id FROM guests WHERE email = 'housekeeper@hotel.com'),
    '$2a$10$YourBcryptHashHere',
    'housekeeper'
)
ON CONFLICT (guest_id) DO NOTHING;
```

## Step 2: Ensure Rooms Have Various Statuses

```sql
-- Set some rooms to different statuses for testing
UPDATE rooms SET housekeeping_status = 'Dirty' WHERE room_id IN (1, 2, 3);
UPDATE rooms SET housekeeping_status = 'Cleaning' WHERE room_id IN (4, 5);
UPDATE rooms SET housekeeping_status = 'Clean' WHERE room_id IN (6, 7);
UPDATE rooms SET housekeeping_status = 'Inspected' WHERE room_id IN (8, 9, 10);
```

## Step 3: Start Backend Server

```bash
cd backend
go run cmd/server/main.go
```

Or if using Air for hot reload:

```bash
cd backend
air
```

Server should start on `http://localhost:8080`

## Step 4: Run Quick Test

### Option A: Use PowerShell Test Script (Recommended)

```powershell
cd backend
.\test_housekeeping_module.ps1
```

This will automatically test all endpoints and show results.

### Option B: Manual Testing with cURL

#### 1. Login as Housekeeper

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "housekeeper@hotel.com",
    "password": "password123"
  }'
```

Save the token from the response.

#### 2. Get Housekeeping Tasks

```bash
curl -X GET http://localhost:8080/api/housekeeping/tasks \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### 3. Update Room Status

```bash
curl -X PUT http://localhost:8080/api/housekeeping/rooms/1/status \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"status": "Cleaning"}'
```

#### 4. Complete Cleaning

```bash
curl -X PUT http://localhost:8080/api/housekeeping/rooms/1/status \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"status": "Clean"}'
```

#### 5. Inspect Room

```bash
curl -X POST http://localhost:8080/api/housekeeping/rooms/1/inspect \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "approved": true,
    "notes": "Room looks great!"
  }'
```

## Step 5: Verify Results

Check the database to verify status changes:

```sql
SELECT 
    room_id,
    room_number,
    occupancy_status,
    housekeeping_status
FROM rooms
WHERE room_id = 1;
```

## Common Workflows

### Workflow 1: Daily Cleaning

```bash
# 1. Get tasks
curl -X GET http://localhost:8080/api/housekeeping/tasks \
  -H "Authorization: Bearer $TOKEN"

# 2. Start cleaning
curl -X PUT http://localhost:8080/api/housekeeping/rooms/1/status \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "Cleaning"}'

# 3. Finish cleaning
curl -X PUT http://localhost:8080/api/housekeeping/rooms/1/status \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "Clean"}'

# 4. Supervisor inspects
curl -X POST http://localhost:8080/api/housekeeping/rooms/1/inspect \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"approved": true, "notes": "Perfect!"}'
```

### Workflow 2: Maintenance Issue

```bash
# Report maintenance
curl -X POST http://localhost:8080/api/housekeeping/rooms/1/maintenance \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description": "AC not working"}'
```

## Troubleshooting

### Issue: "unauthorized" error

**Solution:** Make sure you're including the Bearer token in the Authorization header:
```
Authorization: Bearer YOUR_TOKEN_HERE
```

### Issue: "insufficient permissions" error

**Solution:** Make sure the user has role "housekeeper". Check with:
```sql
SELECT g.email, ga.role 
FROM guests g 
JOIN guest_accounts ga ON g.guest_id = ga.guest_id 
WHERE g.email = 'housekeeper@hotel.com';
```

### Issue: "invalid status transition" error

**Solution:** Check the current status and ensure the transition is valid:
- Dirty → Cleaning, MaintenanceRequired, OutOfService
- Cleaning → Clean, Dirty, MaintenanceRequired
- Clean → Inspected, Dirty, MaintenanceRequired
- etc.

### Issue: "room not found" error

**Solution:** Verify the room exists:
```sql
SELECT * FROM rooms WHERE room_id = 1;
```

## API Endpoints Summary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/housekeeping/tasks` | GET | Get all tasks |
| `/api/housekeeping/rooms/:id/status` | PUT | Update status |
| `/api/housekeeping/inspection` | GET | Get rooms for inspection |
| `/api/housekeeping/rooms/:id/inspect` | POST | Inspect room |
| `/api/housekeeping/rooms/:id/maintenance` | POST | Report maintenance |

## Next Steps

1. ✅ Test all endpoints
2. ✅ Verify status transitions
3. ✅ Test with multiple rooms
4. ✅ Integrate with frontend
5. ✅ Test with real users

## Additional Resources

- **Full Documentation:** `HOUSEKEEPING_MODULE_REFERENCE.md`
- **Verification Checklist:** `TASK_26_VERIFICATION.md`
- **Implementation Summary:** `TASK_26_SUMMARY.md`
- **Test Script:** `test_housekeeping_module.ps1`

## Support

If you encounter any issues:
1. Check the logs in the backend console
2. Verify database connection
3. Check JWT secret configuration
4. Review the verification checklist
5. Run the test script for automated testing

---

**Happy Housekeeping! 🧹✨**
