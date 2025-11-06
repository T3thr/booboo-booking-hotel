# Hold Cleanup Job - Quick Reference

## Overview

Hold Cleanup Job เป็น background job ที่ทำงานทุก 5 นาที เพื่อลบ booking holds ที่หมดอายุและคืนสต็อกกลับเข้า inventory

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Hold Cleanup Job                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │   Scheduler  │─────▶│   Run Job    │                     │
│  │ (Every 5min) │      │              │                     │
│  └──────────────┘      └──────┬───────┘                     │
│                               │                              │
│                               ▼                              │
│                    ┌──────────────────┐                     │
│                    │  Call Database   │                     │
│                    │    Function      │                     │
│                    │ release_expired_ │                     │
│                    │     holds()      │                     │
│                    └──────┬───────────┘                     │
│                           │                                  │
│                           ▼                                  │
│              ┌────────────────────────┐                     │
│              │  1. Find expired holds │                     │
│              │  2. Return tentative   │                     │
│              │     count to inventory │                     │
│              │  3. Delete holds       │                     │
│              └────────────────────────┘                     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Automatic Cleanup
- Runs every 5 minutes automatically
- No manual intervention required
- Ensures expired holds don't block inventory

### 2. Atomic Operations
- Uses database transactions
- All-or-nothing execution
- Prevents data inconsistency

### 3. Error Handling
- Comprehensive error logging
- Graceful failure handling
- Detailed error messages

### 4. Monitoring
- Structured logging
- Execution time tracking
- Success/failure statistics

## Implementation Details

### Job Structure

```go
type HoldCleanupJob struct {
    db     *sql.DB
    cron   *cron.Cron
    logger *log.Logger
}

type HoldCleanupResult struct {
    Timestamp        time.Time
    HoldsReleased    int
    InventoryUpdated int
    Success          bool
    ErrorMessage     string
    ExecutionTime    time.Duration
}
```

### Schedule Configuration

```go
// Cron expression: */5 * * * *
// Runs every 5 minutes
_, err := j.cron.AddFunc("*/5 * * * *", func() {
    result := j.Run()
    j.logResult(result)
})
```

### Database Function Call

```go
query := `SELECT * FROM release_expired_holds()`
err := j.db.QueryRowContext(ctx, query).Scan(&releasedCount, &message)
```

## API Endpoints

### 1. Manual Trigger

**Endpoint:** `POST /api/admin/hold-cleanup/trigger`

**Authentication:** Required (Manager role)

**Request:**
```bash
curl -X POST http://localhost:8080/api/admin/hold-cleanup/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "holds_released": 5,
  "timestamp": "2024-01-15T10:30:00Z",
  "execution_time": "45.2ms",
  "message": "Hold cleanup executed successfully"
}
```

### 2. Get Status

**Endpoint:** `GET /api/admin/hold-cleanup/status`

**Authentication:** Required (Manager role)

**Request:**
```bash
curl -X GET http://localhost:8080/api/admin/hold-cleanup/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "is_running": true,
  "next_run_time": "2024-01-15T10:35:00Z",
  "schedule": "Every 5 minutes"
}
```

## Database Function

### release_expired_holds()

**Purpose:** ปล่อย booking holds ที่หมดอายุและคืนสต็อกกลับเข้า inventory

**Returns:**
- `released_count` (INT): จำนวน holds ที่ถูกปล่อย
- `message` (TEXT): ข้อความอธิบายผลลัพธ์

**Logic:**
1. หา holds ที่ `hold_expiry < NOW()`
2. คืน `tentative_count` กลับเข้า `room_inventory`
3. ลบ holds ที่หมดอายุ
4. Return สถิติ

**Example:**
```sql
SELECT * FROM release_expired_holds();

-- Result:
-- released_count | message
-- 5              | ปล่อย 5 holds ที่หมดอายุ และอัปเดต 3 inventory records
```

## Logging

### Log Format

```
[HOLD-CLEANUP] 2024/01/15 10:30:00 Starting scheduled hold cleanup...
[HOLD-CLEANUP] 2024/01/15 10:30:00 Executing hold cleanup process...
[HOLD-CLEANUP] 2024/01/15 10:30:00 Hold cleanup completed successfully: ปล่อย 5 holds ที่หมดอายุ และอัปเดต 3 inventory records (Duration: 45.2ms)
[HOLD-CLEANUP] 2024/01/15 10:30:00 ✓ Hold Cleanup Success | Time: 2024-01-15 10:30:00 | Holds Released: 5 | Duration: 45.2ms
```

### Log Levels

- **INFO:** Normal operations
- **ERROR:** Failures and exceptions
- **WARNING:** Non-critical issues

## Testing

### Unit Tests

```bash
# Run all hold cleanup tests
go test ./internal/jobs/hold_cleanup_test.go ./internal/jobs/hold_cleanup.go -v

# Run specific test
go test ./internal/jobs -run TestHoldCleanupJob_Run_Success -v

# Run with coverage
go test ./internal/jobs -cover
```

### Integration Test

```bash
# Run PowerShell test script
.\test_hold_cleanup.ps1
```

### Manual Testing

1. **Create expired holds:**
```sql
INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
VALUES ('test-session', 1, 1, CURRENT_DATE, NOW() - INTERVAL '1 hour');
```

2. **Trigger cleanup:**
```bash
curl -X POST http://localhost:8080/api/admin/hold-cleanup/trigger \
  -H "Authorization: Bearer YOUR_TOKEN"
```

3. **Verify cleanup:**
```sql
SELECT COUNT(*) FROM booking_holds WHERE hold_expiry < NOW();
-- Should return 0
```

## Monitoring

### Health Checks

1. **Check if job is running:**
```bash
curl http://localhost:8080/api/admin/hold-cleanup/status
```

2. **Check logs:**
```bash
# Look for scheduled runs
grep "HOLD-CLEANUP" logs/app.log

# Check for errors
grep "HOLD-CLEANUP.*ERROR" logs/app.log
```

3. **Monitor database:**
```sql
-- Check for expired holds
SELECT COUNT(*) as expired_holds
FROM booking_holds
WHERE hold_expiry < NOW();

-- Should be 0 or very low if job is working
```

### Performance Metrics

- **Execution Time:** Typically < 100ms
- **Frequency:** Every 5 minutes
- **Impact:** Minimal (runs during low activity)

## Troubleshooting

### Issue: Job not running

**Symptoms:**
- No logs from HOLD-CLEANUP
- Expired holds accumulating

**Solutions:**
1. Check if server is running
2. Verify job initialization in main.go
3. Check for startup errors

### Issue: Database errors

**Symptoms:**
- Error logs: "failed to execute hold cleanup"
- Function returns -1

**Solutions:**
1. Verify database connection
2. Check if function exists: `\df release_expired_holds`
3. Verify permissions

### Issue: Holds not being cleaned

**Symptoms:**
- Job runs successfully
- But holds remain in database

**Solutions:**
1. Check hold_expiry timestamps
2. Verify function logic
3. Check for database locks

## Configuration

### Environment Variables

```env
# Database connection (required)
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=hotel_booking

# Server settings
SERVER_PORT=8080
GIN_MODE=release
```

### Cron Schedule

To change the schedule, modify the cron expression in `hold_cleanup.go`:

```go
// Current: Every 5 minutes
"*/5 * * * *"

// Examples:
"*/10 * * * *"  // Every 10 minutes
"0 * * * *"     // Every hour
"*/1 * * * *"   // Every minute (for testing)
```

## Best Practices

### 1. Monitoring
- Set up alerts for cleanup failures
- Monitor execution time trends
- Track holds released per run

### 2. Performance
- Keep hold expiry time reasonable (15 minutes)
- Ensure database indexes are optimized
- Monitor database connection pool

### 3. Error Handling
- Log all errors with context
- Implement retry logic if needed
- Alert on consecutive failures

### 4. Testing
- Test with various hold counts
- Test error scenarios
- Verify inventory consistency

## Related Components

- **Night Audit Job:** Similar background job pattern
- **Booking Hold Function:** Creates the holds
- **Room Inventory:** Receives returned stock
- **Booking Service:** Uses holds for reservations

## Requirements Satisfied

This implementation satisfies requirements **3.1-3.8**:

- ✅ 3.1: Hold creation with expiry
- ✅ 3.2: Atomic inventory updates
- ✅ 3.3: Tentative count management
- ✅ 3.4: Hold expiry validation
- ✅ 3.5: Automatic cleanup
- ✅ 3.6: Session tracking
- ✅ 3.7: Concurrent hold handling
- ✅ 3.8: Countdown timer support

## References

- [Night Audit Reference](./NIGHT_AUDIT_REFERENCE.md)
- [Booking Hold Function](../database/migrations/005_create_booking_hold_function.sql)
- [Release Expired Holds Function](../database/migrations/008_create_release_expired_holds_function.sql)
- [Booking Module Reference](./BOOKING_MODULE_REFERENCE.md)
