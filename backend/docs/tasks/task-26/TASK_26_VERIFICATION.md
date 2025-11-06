# Task 26: Housekeeping Module - Verification Checklist

## Pre-Verification Setup

### 1. Database Setup
Ensure the following tables exist and have data:
- [ ] `rooms` table with sample rooms
- [ ] `room_types` table with room types
- [ ] Rooms have various housekeeping statuses (Dirty, Cleaning, Clean, etc.)

### 2. User Account Setup
Create a housekeeper account if it doesn't exist:

```sql
-- Insert guest
INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('House', 'Keeper', 'housekeeper@hotel.com', '1234567890')
ON CONFLICT (email) DO NOTHING;

-- Insert guest account with housekeeper role
INSERT INTO guest_accounts (guest_id, hashed_password, role)
SELECT guest_id, '$2a$10$YourHashedPasswordHere', 'housekeeper'
FROM guests WHERE email = 'housekeeper@hotel.com'
ON CONFLICT (guest_id) DO NOTHING;
```

Note: Generate hashed password using bcrypt with password: `password123`

### 3. Backend Server
- [ ] Backend server is running on `http://localhost:8080`
- [ ] Database connection is working
- [ ] JWT secret is configured in `.env`

## Code Verification

### 1. File Structure
Verify all files are created:
- [ ] `backend/internal/models/housekeeping.go`
- [ ] `backend/internal/repository/housekeeping_repository.go`
- [ ] `backend/internal/service/housekeeping_service.go`
- [ ] `backend/internal/handlers/housekeeping_handler.go`
- [ ] `backend/test_housekeeping_module.ps1`
- [ ] `backend/HOUSEKEEPING_MODULE_REFERENCE.md`
- [ ] `backend/TASK_26_SUMMARY.md`

### 2. Router Integration
Verify `backend/internal/router/router.go` includes:
- [ ] `housekeepingRepo := repository.NewHousekeepingRepository(db)`
- [ ] `housekeepingService := service.NewHousekeepingService(housekeepingRepo)`
- [ ] `housekeepingHandler := handlers.NewHousekeepingHandler(housekeepingService)`
- [ ] Housekeeping route group with authentication and role middleware

### 3. Compilation
Build the backend to ensure no syntax errors:

```bash
cd backend
go build -o bin/server ./cmd/server
```

Expected: No compilation errors

## Functional Testing

### Test 1: Authentication
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "housekeeper@hotel.com",
    "password": "password123"
  }'
```

Expected:
- [ ] Status: 200 OK
- [ ] Response contains `token` field
- [ ] Response contains `role: "housekeeper"`

### Test 2: Get Housekeeping Tasks
```bash
curl -X GET http://localhost:8080/api/housekeeping/tasks \
  -H "Authorization: Bearer <token>"
```

Expected:
- [ ] Status: 200 OK
- [ ] Response contains `tasks` array
- [ ] Response contains `total_tasks` count
- [ ] Response contains `summary` object with status counts
- [ ] Tasks are sorted by priority

### Test 3: Update Room Status
```bash
curl -X PUT http://localhost:8080/api/housekeeping/rooms/1/status \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "Cleaning"}'
```

Expected:
- [ ] Status: 200 OK
- [ ] Response confirms status update
- [ ] Database reflects new status

### Test 4: Invalid Status Transition
```bash
curl -X PUT http://localhost:8080/api/housekeeping/rooms/1/status \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "InvalidStatus"}'
```

Expected:
- [ ] Status: 400 Bad Request
- [ ] Error message about invalid status

### Test 5: Get Rooms for Inspection
```bash
curl -X GET http://localhost:8080/api/housekeeping/inspection \
  -H "Authorization: Bearer <token>"
```

Expected:
- [ ] Status: 200 OK
- [ ] Response contains only rooms with status "Clean"
- [ ] Rooms are sorted by room number

### Test 6: Inspect Room (Approve)
```bash
curl -X POST http://localhost:8080/api/housekeeping/rooms/1/inspect \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "approved": true,
    "notes": "Room looks great"
  }'
```

Expected:
- [ ] Status: 200 OK
- [ ] Room status changes to "Inspected"
- [ ] Response confirms approval

### Test 7: Inspect Room (Reject)
```bash
curl -X POST http://localhost:8080/api/housekeeping/rooms/2/inspect \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "approved": false,
    "notes": "Needs more attention"
  }'
```

Expected:
- [ ] Status: 200 OK
- [ ] Room status changes back to "Dirty"
- [ ] Response confirms rejection

### Test 8: Report Maintenance
```bash
curl -X POST http://localhost:8080/api/housekeeping/rooms/1/maintenance \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Air conditioning not working"
  }'
```

Expected:
- [ ] Status: 200 OK
- [ ] Room status changes to "MaintenanceRequired"
- [ ] Response confirms maintenance report

### Test 9: Unauthorized Access (No Token)
```bash
curl -X GET http://localhost:8080/api/housekeeping/tasks
```

Expected:
- [ ] Status: 401 Unauthorized
- [ ] Error message about missing authentication

### Test 10: Forbidden Access (Wrong Role)
Login as guest user and try to access housekeeping endpoint:

```bash
curl -X GET http://localhost:8080/api/housekeeping/tasks \
  -H "Authorization: Bearer <guest_token>"
```

Expected:
- [ ] Status: 403 Forbidden
- [ ] Error message about insufficient permissions

## Automated Testing

Run the PowerShell test script:

```powershell
cd backend
.\test_housekeeping_module.ps1
```

Expected Results:
- [ ] All 8 tests pass
- [ ] Login successful
- [ ] Tasks retrieved
- [ ] Status updated
- [ ] Inspection workflow works
- [ ] Maintenance reporting works
- [ ] Invalid status rejected
- [ ] Authorization enforced

## Integration Testing

### With Check-in Module
1. [ ] Mark a room as "Inspected"
2. [ ] Try to check in a guest
3. [ ] Verify "Inspected" rooms are prioritized

### With Room Status Dashboard
1. [ ] Update room status via housekeeping endpoint
2. [ ] Check receptionist dashboard
3. [ ] Verify status is reflected immediately

### With Night Audit
1. [ ] Set a room to "Occupied"
2. [ ] Run night audit (or wait for scheduled run)
3. [ ] Verify room status changes to "Dirty"

## Performance Testing

### Load Test
Test concurrent status updates:

```bash
# Run 10 concurrent requests
for i in {1..10}; do
  curl -X PUT http://localhost:8080/api/housekeeping/rooms/$i/status \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"status": "Cleaning"}' &
done
wait
```

Expected:
- [ ] All requests complete successfully
- [ ] No race conditions
- [ ] All status updates are atomic

## Requirements Verification

### Requirement 10: การจัดการสถานะการทำความสะอาดห้อง
- [ ] 10.1: Task list displays correctly with all required fields
- [ ] 10.2: Can update status from Dirty to Cleaning
- [ ] 10.3: Can update status from Cleaning to Clean
- [ ] 10.4: Can report maintenance issues
- [ ] 10.5: Status updates are immediate (real-time)
- [ ] 10.6: Timestamps are recorded correctly
- [ ] 10.7: Estimated time is displayed based on room type

### Requirement 11: การตรวจสอบห้องโดยหัวหน้าแม่บ้าน
- [ ] 11.1: Inspection queue shows only Clean rooms
- [ ] 11.2: Can approve room (Clean → Inspected)
- [ ] 11.3: Can reject room (Clean → Dirty)
- [ ] 11.4: Inspected rooms are prioritized for check-in
- [ ] 11.5: Inspected rooms appear first in available rooms list
- [ ] 11.6: Rejection notes are recorded

## Security Verification

- [ ] All endpoints require authentication
- [ ] All endpoints require housekeeper role
- [ ] JWT tokens are validated correctly
- [ ] Invalid tokens are rejected
- [ ] SQL injection is prevented (parameterized queries)
- [ ] Input validation works correctly

## Documentation Verification

- [ ] API endpoints are documented
- [ ] Request/response examples are provided
- [ ] Status transition rules are documented
- [ ] Workflows are explained
- [ ] Error responses are documented
- [ ] Integration points are described

## Final Checklist

- [ ] All code files created
- [ ] Router integration complete
- [ ] Code compiles without errors
- [ ] All functional tests pass
- [ ] All integration tests pass
- [ ] All requirements verified
- [ ] Security measures in place
- [ ] Documentation complete
- [ ] Test script works
- [ ] Ready for production

## Sign-off

- [ ] Developer: Code implemented and tested
- [ ] Reviewer: Code reviewed and approved
- [ ] QA: All tests passed
- [ ] Product Owner: Requirements met

## Notes

Add any additional notes or observations during verification:

---

**Verification Date:** _____________

**Verified By:** _____________

**Status:** [ ] PASSED [ ] FAILED [ ] NEEDS REVISION

**Issues Found:**
1. 
2. 
3. 

**Resolution:**
1. 
2. 
3.
