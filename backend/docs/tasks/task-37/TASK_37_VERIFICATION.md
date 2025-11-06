# Task 37: Night Audit - Verification Checklist

## Pre-Verification Setup

### 1. Ensure Server is Running
```bash
cd backend
go run cmd/server/main.go
```

**Expected Output:**
```
✓ Configuration loaded successfully
✓ Database connection established
✓ [NIGHT-AUDIT] Initializing night audit scheduler...
✓ [NIGHT-AUDIT] Night audit scheduler started successfully (runs daily at 02:00 AM)
✓ Night audit job scheduled (next run: YYYY-MM-DD 02:00:00)
✓ Starting server on 0.0.0.0:8080
```

### 2. Prepare Test Data
```sql
-- Create test rooms with occupied status but clean
UPDATE rooms 
SET occupancy_status = 'Occupied',
    housekeeping_status = 'Clean'
WHERE room_id IN (
    SELECT room_id FROM rooms LIMIT 5
);

-- Verify setup
SELECT room_id, room_number, occupancy_status, housekeeping_status
FROM rooms
WHERE occupancy_status = 'Occupied';
```

### 3. Get Manager Token
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "manager@hotel.com",
    "password": "password123"
  }'
```

Save the token for subsequent requests.

---

## Verification Checklist

### ✅ Core Functionality

#### 1. Job Initialization
- [ ] Server starts without errors
- [ ] Night audit scheduler initializes
- [ ] Log shows "Night audit scheduler started successfully"
- [ ] Next run time is displayed in logs

**Verification:**
```bash
# Check server logs
grep "NIGHT-AUDIT" server.log
```

#### 2. Scheduler Status
- [ ] Status endpoint is accessible
- [ ] Returns correct schedule information
- [ ] Shows next run time
- [ ] Indicates scheduler is running

**Test:**
```bash
curl -X GET http://localhost:8080/api/admin/night-audit/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
{
  "is_running": true,
  "next_run": "2024-01-16T02:00:00Z",
  "schedule": "Daily at 02:00 AM"
}
```

#### 3. Manual Trigger
- [ ] Trigger endpoint is accessible
- [ ] Executes night audit successfully
- [ ] Returns execution results
- [ ] Updates database correctly

**Test:**
```bash
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
{
  "message": "Night audit completed successfully",
  "timestamp": "2024-01-15T14:30:00Z",
  "rooms_updated": 5,
  "execution_time": "87ms"
}
```

#### 4. Database Updates
- [ ] Occupied rooms are updated to dirty
- [ ] Only occupied rooms are affected
- [ ] Vacant rooms remain unchanged
- [ ] Update is atomic (all or nothing)

**Verification:**
```sql
-- Check that occupied rooms are now dirty
SELECT COUNT(*) 
FROM rooms 
WHERE occupancy_status = 'Occupied' 
  AND housekeeping_status = 'Dirty';

-- Should match the number of occupied rooms
SELECT COUNT(*) 
FROM rooms 
WHERE occupancy_status = 'Occupied';

-- Verify vacant rooms are unchanged
SELECT COUNT(*) 
FROM rooms 
WHERE occupancy_status = 'Vacant' 
  AND housekeeping_status = 'Dirty';
-- Should be 0 or unchanged from before
```

---

### ✅ Error Handling

#### 5. Authentication Required
- [ ] Endpoints require authentication
- [ ] Returns 401 without token
- [ ] Returns 403 for non-manager roles

**Test:**
```bash
# Without token
curl -X POST http://localhost:8080/api/admin/night-audit/trigger

# Expected: 401 Unauthorized

# With guest token
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer GUEST_TOKEN"

# Expected: 403 Forbidden
```

#### 6. Database Error Handling
- [ ] Handles database connection errors
- [ ] Returns appropriate error messages
- [ ] Logs errors properly
- [ ] Doesn't crash the server

**Test:**
```bash
# Stop database temporarily and trigger
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected: 500 with error message
```

#### 7. Timeout Protection
- [ ] Query has timeout (30 seconds)
- [ ] Doesn't hang indefinitely
- [ ] Returns error on timeout

---

### ✅ Logging

#### 8. Log Entries
- [ ] Initialization logged
- [ ] Scheduled runs logged
- [ ] Manual triggers logged
- [ ] Execution results logged
- [ ] Errors logged with details

**Verification:**
```bash
# Check for all log types
grep "NIGHT-AUDIT" server.log

# Should see:
# - Initializing night audit scheduler...
# - Night audit scheduler started successfully
# - Starting scheduled night audit... (at 02:00 AM)
# - Executing night audit process...
# - Night audit completed successfully: X rooms updated
# - ✓ Night Audit Success | ...
```

#### 9. Log Format
- [ ] Includes timestamp
- [ ] Includes [NIGHT-AUDIT] prefix
- [ ] Includes execution details
- [ ] Includes room IDs updated
- [ ] Includes execution time

**Example:**
```
[NIGHT-AUDIT] 2024-01-15 02:00:00 Starting scheduled night audit...
[NIGHT-AUDIT] 2024-01-15 02:00:00 Night audit completed successfully: 15 rooms updated in 125ms
[NIGHT-AUDIT] 2024-01-15 02:00:00 Updated room IDs: [101, 102, 103, ...]
```

---

### ✅ Scheduling

#### 10. Cron Schedule
- [ ] Scheduled for 02:00 AM daily
- [ ] Cron expression is correct: `0 2 * * *`
- [ ] Next run time is accurate
- [ ] Runs automatically at scheduled time

**Verification:**
```bash
# Check next run time
curl -X GET http://localhost:8080/api/admin/night-audit/status \
  -H "Authorization: Bearer YOUR_TOKEN"

# Verify next_run is tomorrow at 02:00 AM
```

#### 11. Graceful Shutdown
- [ ] Stops cleanly on server shutdown
- [ ] Logs shutdown message
- [ ] Doesn't leave hanging processes

**Test:**
```bash
# Start server
go run cmd/server/main.go

# Stop with Ctrl+C
# Check logs for:
# [NIGHT-AUDIT] Stopping night audit scheduler...
# [NIGHT-AUDIT] Night audit scheduler stopped
```

---

### ✅ Edge Cases

#### 12. No Rooms to Update
- [ ] Handles case with no occupied rooms
- [ ] Returns success with 0 rooms updated
- [ ] Doesn't throw errors

**Test:**
```sql
-- Make all rooms vacant
UPDATE rooms SET occupancy_status = 'Vacant';
```

```bash
# Trigger night audit
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected: Success with rooms_updated: 0
```

#### 13. All Rooms Already Dirty
- [ ] Handles case where all occupied rooms are already dirty
- [ ] Returns success with 0 rooms updated
- [ ] Doesn't update unnecessarily

**Test:**
```sql
-- Make all occupied rooms dirty
UPDATE rooms 
SET housekeeping_status = 'Dirty' 
WHERE occupancy_status = 'Occupied';
```

```bash
# Trigger night audit
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected: Success with rooms_updated: 0
```

#### 14. Large Number of Rooms
- [ ] Handles 100+ rooms efficiently
- [ ] Completes within reasonable time (< 5 seconds)
- [ ] Doesn't timeout

**Test:**
```sql
-- Create many occupied rooms
UPDATE rooms 
SET occupancy_status = 'Occupied',
    housekeeping_status = 'Clean'
WHERE room_id <= 100;
```

```bash
# Trigger and check execution time
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"

# Verify execution_time is reasonable
```

---

### ✅ Integration

#### 15. Router Integration
- [ ] Routes are registered correctly
- [ ] Admin group exists
- [ ] Middleware applied correctly
- [ ] Endpoints accessible

**Test:**
```bash
# Test both endpoints
curl -X GET http://localhost:8080/api/admin/night-audit/status \
  -H "Authorization: Bearer YOUR_TOKEN"

curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### 16. Server Lifecycle
- [ ] Job starts with server
- [ ] Job stops with server
- [ ] No memory leaks
- [ ] No goroutine leaks

**Test:**
```bash
# Start and stop server multiple times
for i in {1..5}; do
  go run cmd/server/main.go &
  PID=$!
  sleep 5
  kill $PID
  sleep 2
done

# Check for any issues in logs
```

---

### ✅ Documentation

#### 17. Code Documentation
- [ ] Functions have comments
- [ ] Structs are documented
- [ ] Complex logic explained
- [ ] Examples provided

**Verification:**
```bash
# Check for godoc comments
grep -A 2 "^//" backend/internal/jobs/night_audit.go
```

#### 18. User Documentation
- [ ] NIGHT_AUDIT_REFERENCE.md exists
- [ ] TASK_37_QUICKSTART.md exists
- [ ] TASK_37_SUMMARY.md exists
- [ ] TASK_37_VERIFICATION.md exists (this file)
- [ ] test_night_audit.ps1 exists

---

### ✅ Testing

#### 19. Unit Tests
- [ ] Test file exists
- [ ] Tests compile
- [ ] Tests cover main functionality
- [ ] Tests can be run

**Test:**
```bash
cd backend
go test ./internal/jobs -v
```

#### 20. Integration Tests
- [ ] Test script exists
- [ ] Script runs successfully
- [ ] All test cases pass
- [ ] Results are verified

**Test:**
```powershell
cd backend
.\test_night_audit.ps1
```

---

### ✅ Requirements Compliance

#### 21. Requirement 18.1
- [ ] Night audit runs automatically at scheduled time
- [ ] Scheduled for 02:00 AM daily
- [ ] Starts with server

#### 22. Requirement 18.2
- [ ] Updates occupied rooms to dirty status
- [ ] Only affects occupied rooms
- [ ] Updates housekeeping_status column

#### 23. Requirement 18.3
- [ ] Scheduled execution implemented
- [ ] Uses cron scheduler
- [ ] Runs daily

#### 24. Requirement 18.4
- [ ] Error handling implemented
- [ ] Database errors caught
- [ ] Timeout protection added
- [ ] Graceful failure

#### 25. Requirement 18.5
- [ ] Logging implemented
- [ ] Detailed execution logs
- [ ] Error logs
- [ ] Success logs

#### 26. Requirement 18.6
- [ ] Alert mechanism ready
- [ ] Errors logged for monitoring
- [ ] Can be extended to email alerts

---

## Final Verification

### Run Complete Test Suite

```powershell
# 1. Start server
cd backend
go run cmd/server/main.go

# 2. In another terminal, run tests
.\test_night_audit.ps1

# 3. Verify all tests pass
```

### Manual Verification Steps

1. **Check Server Logs:**
   ```bash
   grep "NIGHT-AUDIT" server.log | tail -20
   ```

2. **Verify Database State:**
   ```sql
   SELECT 
       occupancy_status,
       housekeeping_status,
       COUNT(*) as count
   FROM rooms
   GROUP BY occupancy_status, housekeeping_status
   ORDER BY occupancy_status, housekeeping_status;
   ```

3. **Test API Endpoints:**
   - Get status
   - Trigger manually
   - Verify response format

4. **Check Next Run Time:**
   - Should be tomorrow at 02:00 AM
   - Verify timezone is correct

---

## Sign-Off Checklist

- [ ] All core functionality tests pass
- [ ] All error handling tests pass
- [ ] All logging tests pass
- [ ] All scheduling tests pass
- [ ] All edge cases handled
- [ ] All integration tests pass
- [ ] All documentation complete
- [ ] All unit tests pass
- [ ] All requirements satisfied
- [ ] Code reviewed
- [ ] Ready for production

---

## Test Results Summary

| Category | Tests | Passed | Failed |
|----------|-------|--------|--------|
| Core Functionality | 4 | __ | __ |
| Error Handling | 3 | __ | __ |
| Logging | 2 | __ | __ |
| Scheduling | 2 | __ | __ |
| Edge Cases | 3 | __ | __ |
| Integration | 2 | __ | __ |
| Documentation | 2 | __ | __ |
| Testing | 2 | __ | __ |
| Requirements | 6 | __ | __ |
| **TOTAL** | **26** | **__** | **__** |

---

## Notes

_Add any observations, issues, or recommendations here:_

---

## Verified By

- **Name:** _______________
- **Date:** _______________
- **Signature:** _______________

---

## Status

- [ ] ✅ All tests passed - Ready for production
- [ ] ⚠️ Minor issues found - Needs fixes
- [ ] ❌ Major issues found - Requires rework

---

**Task 37 Verification Complete!** 🎉
