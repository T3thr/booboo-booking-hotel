# Task 37: Night Audit - Quick Start Guide

## What is Night Audit?

The night audit is an automated background job that runs every day at 02:00 AM to update the housekeeping status of all occupied rooms to "Dirty". This ensures that housekeeping staff know which rooms need cleaning at the start of each day.

## Quick Setup

### 1. Dependencies

The night audit job is automatically started when the server starts. No additional setup required!

**Required dependency** (already added):
```go
github.com/robfig/cron/v3 v3.0.1
```

### 2. Start the Server

```bash
cd backend
go run cmd/server/main.go
```

**Expected output:**
```
[NIGHT-AUDIT] Initializing night audit scheduler...
[NIGHT-AUDIT] Night audit scheduler started successfully (runs daily at 02:00 AM)
Night audit job scheduled (next run: 2024-01-16 02:00:00)
```

## Quick Test

### Option 1: Using PowerShell Script

```powershell
cd backend
.\test_night_audit.ps1
```

### Option 2: Using curl

```bash
# 1. Login as manager
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "manager@hotel.com",
    "password": "password123"
  }'

# Copy the token from response

# 2. Check status
curl -X GET http://localhost:8080/api/admin/night-audit/status \
  -H "Authorization: Bearer YOUR_TOKEN"

# 3. Trigger manually
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Option 3: Using Postman

1. **Login**: POST `http://localhost:8080/api/auth/login`
   ```json
   {
     "email": "manager@hotel.com",
     "password": "password123"
   }
   ```

2. **Get Status**: GET `http://localhost:8080/api/admin/night-audit/status`
   - Add header: `Authorization: Bearer YOUR_TOKEN`

3. **Trigger**: POST `http://localhost:8080/api/admin/night-audit/trigger`
   - Add header: `Authorization: Bearer YOUR_TOKEN`

## Verify It Works

### 1. Setup Test Data

```sql
-- Connect to your database and run:
UPDATE rooms 
SET occupancy_status = 'Occupied',
    housekeeping_status = 'Clean'
WHERE room_id IN (1, 2, 3);
```

### 2. Trigger Night Audit

Use any of the methods above to trigger the night audit.

### 3. Check Results

```sql
-- All occupied rooms should now be dirty
SELECT room_id, room_number, occupancy_status, housekeeping_status
FROM rooms
WHERE occupancy_status = 'Occupied';
```

**Expected result**: All occupied rooms have `housekeeping_status = 'Dirty'`

## API Endpoints

### Get Status
```
GET /api/admin/night-audit/status
Authorization: Bearer {manager_token}
```

**Response:**
```json
{
  "is_running": true,
  "next_run": "2024-01-16T02:00:00Z",
  "schedule": "Daily at 02:00 AM"
}
```

### Trigger Manually
```
POST /api/admin/night-audit/trigger
Authorization: Bearer {manager_token}
```

**Response:**
```json
{
  "message": "Night audit completed successfully",
  "timestamp": "2024-01-15T14:30:00Z",
  "rooms_updated": 5,
  "execution_time": "87ms"
}
```

## What Happens During Night Audit?

1. **Identifies Occupied Rooms**: Finds all rooms with `occupancy_status = 'Occupied'`
2. **Updates Status**: Changes their `housekeeping_status` to `'Dirty'`
3. **Logs Results**: Records how many rooms were updated
4. **Returns Summary**: Provides execution details

## Schedule

- **Runs**: Daily at 02:00 AM
- **Cron Expression**: `0 2 * * *`
- **Automatic**: Starts with server, no manual intervention needed

## Logs

Check server logs for night audit activity:

```
[NIGHT-AUDIT] 2024-01-15 02:00:00 Starting scheduled night audit...
[NIGHT-AUDIT] 2024-01-15 02:00:00 Executing night audit process...
[NIGHT-AUDIT] 2024-01-15 02:00:00 Night audit completed successfully: 15 rooms updated in 125ms
[NIGHT-AUDIT] 2024-01-15 02:00:00 Updated room IDs: [101, 102, 103, ...]
```

## Troubleshooting

### Job Not Running?

**Check logs:**
```bash
# Look for [NIGHT-AUDIT] entries
grep "NIGHT-AUDIT" server.log
```

**Check status via API:**
```bash
curl -X GET http://localhost:8080/api/admin/night-audit/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### No Rooms Updated?

**Verify occupied rooms exist:**
```sql
SELECT COUNT(*) FROM rooms WHERE occupancy_status = 'Occupied';
```

**Check if already dirty:**
```sql
SELECT COUNT(*) FROM rooms 
WHERE occupancy_status = 'Occupied' 
  AND housekeeping_status != 'Dirty';
```

### Database Error?

**Check connection:**
```bash
curl http://localhost:8080/health/db
```

**Review logs:**
```bash
grep "ERROR" server.log | grep "NIGHT-AUDIT"
```

## Common Use Cases

### 1. Testing Before Production
```bash
# Trigger manually to test
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Emergency Cleanup
If the scheduled job fails, trigger manually:
```bash
curl -X POST http://localhost:8080/api/admin/night-audit/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Monitoring
Check next run time:
```bash
curl -X GET http://localhost:8080/api/admin/night-audit/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Requirements Satisfied

✅ **18.1**: Runs automatically at 02:00 AM daily  
✅ **18.2**: Updates occupied rooms to dirty status  
✅ **18.3**: Scheduled execution (cron)  
✅ **18.4**: Error handling with timeouts  
✅ **18.5**: Comprehensive logging  
✅ **18.6**: Alert mechanism (logs errors)  

## Next Steps

1. ✅ Night audit is working
2. ⏭️ Implement Task 38: Hold Cleanup Job
3. 📊 Monitor execution in production
4. 🔔 Set up email alerts (optional)

## Need Help?

- 📖 Full documentation: `NIGHT_AUDIT_REFERENCE.md`
- 📝 Implementation details: `TASK_37_SUMMARY.md`
- 🧪 Test script: `test_night_audit.ps1`

## Quick Reference

| Action | Command |
|--------|---------|
| Start server | `go run cmd/server/main.go` |
| Run tests | `.\test_night_audit.ps1` |
| Check status | `GET /api/admin/night-audit/status` |
| Trigger manually | `POST /api/admin/night-audit/trigger` |
| View logs | `grep "NIGHT-AUDIT" server.log` |

---

**That's it!** The night audit job is now running and will automatically update room statuses every day at 02:00 AM. 🎉
