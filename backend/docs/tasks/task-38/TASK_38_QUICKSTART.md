# Task 38 Quick Start - Hold Cleanup Job

## Quick Overview

Hold Cleanup Job ทำงานอัตโนมัติทุก 5 นาที เพื่อลบ booking holds ที่หมดอายุและคืนสต็อกกลับเข้า inventory

## Quick Start

### 1. Start the Server

```bash
cd backend
make run
```

### 2. Verify Job is Running

Check the logs for:
```
[HOLD-CLEANUP] Hold cleanup scheduler started successfully (runs every 5 minutes)
Hold cleanup job scheduled (next run: 2024-01-15 10:35:00)
```

### 3. Test Manual Trigger

```bash
# Login as manager
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"password123"}'

# Trigger cleanup (replace YOUR_TOKEN)
curl -X POST http://localhost:8080/api/admin/hold-cleanup/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Check Status

```bash
curl -X GET http://localhost:8080/api/admin/hold-cleanup/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Quick Test

### Create Test Expired Holds

```sql
-- Connect to database
psql -h localhost -U postgres -d hotel_booking

-- Create expired holds
INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
VALUES 
    ('test-1', 1, 1, CURRENT_DATE, NOW() - INTERVAL '1 hour'),
    ('test-2', 1, 1, CURRENT_DATE + 1, NOW() - INTERVAL '30 minutes');

-- Check expired holds
SELECT COUNT(*) FROM booking_holds WHERE hold_expiry < NOW();
```

### Run Cleanup

```sql
-- Run cleanup function
SELECT * FROM release_expired_holds();

-- Verify cleanup
SELECT COUNT(*) FROM booking_holds WHERE hold_expiry < NOW();
-- Should return 0
```

## Quick Verification

### 1. Check Logs

```bash
# Windows PowerShell
Get-Content logs\app.log -Tail 50 | Select-String "HOLD-CLEANUP"

# Linux/Mac
tail -f logs/app.log | grep HOLD-CLEANUP
```

### 2. Check Database

```sql
-- Should be 0 or very low
SELECT COUNT(*) as expired_holds
FROM booking_holds
WHERE hold_expiry < NOW();
```

### 3. Check API

```bash
curl http://localhost:8080/api/admin/hold-cleanup/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Quick Troubleshooting

### Job Not Running?

1. Check server logs for errors
2. Verify database connection
3. Check if function exists:
   ```sql
   \df release_expired_holds
   ```

### Holds Not Cleaning?

1. Check hold_expiry timestamps:
   ```sql
   SELECT * FROM booking_holds ORDER BY hold_expiry;
   ```
2. Run function manually:
   ```sql
   SELECT * FROM release_expired_holds();
   ```

### API Errors?

1. Verify authentication token
2. Check user role (must be manager)
3. Check server logs for details

## Quick Reference

### Schedule
- **Frequency:** Every 5 minutes
- **Cron:** `*/5 * * * *`

### Endpoints
- **Trigger:** `POST /api/admin/hold-cleanup/trigger`
- **Status:** `GET /api/admin/hold-cleanup/status`

### Database Function
- **Name:** `release_expired_holds()`
- **Returns:** `(released_count INT, message TEXT)`

### Log Pattern
```
[HOLD-CLEANUP] ✓ Hold Cleanup Success | Time: ... | Holds Released: 5 | Duration: 45ms
```

## Next Steps

1. ✅ Job is running automatically
2. ✅ Monitor logs for scheduled runs
3. ✅ Test manual trigger if needed
4. ✅ Verify holds are being cleaned

## Full Documentation

For complete documentation, see:
- [HOLD_CLEANUP_REFERENCE.md](./HOLD_CLEANUP_REFERENCE.md)
- [TASK_38_SUMMARY.md](./TASK_38_SUMMARY.md)
