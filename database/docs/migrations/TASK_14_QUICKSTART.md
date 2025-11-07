# Task 14 Quick Start - Release Expired Holds Function

## 🎯 Goal

สร้าง PostgreSQL function สำหรับปล่อย booking holds ที่หมดอายุและคืน tentative_count กลับเข้า inventory

## 📋 Prerequisites

- ✅ Task 11 complete (create_booking_hold function)
- ✅ PostgreSQL database running
- ✅ Tables: booking_holds, room_inventory

## 🚀 Quick Start (3 Steps)

### Step 1: Run Migration

**Windows:**
```cmd
cd database/migrations
run_migration_008.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_migration_008.sh
./run_migration_008.sh
```

### Step 2: Verify Function

```cmd
psql -h localhost -U postgres -d hotel_booking -f verify_release_expired_holds.sql
```

### Step 3: Run Tests

**Windows:**
```cmd
run_test_release_expired_holds.bat
```

**Linux/Mac:**
```bash
chmod +x run_test_release_expired_holds.sh
./run_test_release_expired_holds.sh
```

## ✅ Expected Results

### Migration Output

```
=== Release Expired Holds Function Created Successfully ===
Function: release_expired_holds
Purpose: ปล่อย booking holds ที่หมดอายุและคืนสต็อก
Features:
  - Atomic inventory updates
  - Grouped hold counting with CTE
  - Prevents negative tentative_count
  - Returns statistics
Usage: Should be called by background job every 5 minutes
==============================================================
```

### Test Output

```
=== Starting Release Expired Holds Function Tests ===

--- Test 1: Release Expired Holds ---
✓ Test 1 PASSED: Released 3 expired holds
✓ Inventory restored correctly for CURRENT_DATE
✓ Expired holds deleted successfully

--- Test 2: No Expired Holds ---
✓ Test 2 PASSED: No holds to release

--- Test 3: Mixed Expired and Active Holds ---
✓ Test 3 PASSED: Released only expired holds
✓ Active holds preserved correctly
✓ Inventory correctly shows 1 tentative (active hold)

--- Test 4: Prevent Negative Tentative Count ---
✓ Test 4 PASSED: Tentative count = 0 (not negative)

--- Test 5: Performance Test (100 Expired Holds) ---
✓ Test 5 PASSED: Released all 100 holds
✓ Performance acceptable (< 1 second)

=== All Tests Completed ===
```

## 🧪 Manual Testing

### Test 1: Basic Usage

```sql
-- สร้าง expired hold
INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
VALUES ('TEST', 1, 1, CURRENT_DATE, NOW() - INTERVAL '1 hour');

-- อัปเดต inventory
UPDATE room_inventory 
SET tentative_count = 1 
WHERE room_type_id = 1 AND date = CURRENT_DATE;

-- เรียก function
SELECT * FROM release_expired_holds();

-- ตรวจสอบผลลัพธ์
SELECT tentative_count FROM room_inventory 
WHERE room_type_id = 1 AND date = CURRENT_DATE;
-- Expected: 0
```

### Test 2: Check Current Expired Holds

```sql
-- ดูจำนวน expired holds ปัจจุบัน
SELECT COUNT(*) as expired_count
FROM booking_holds
WHERE hold_expiry < NOW();

-- ดูรายละเอียด expired holds
SELECT 
    bh.*,
    rt.name as room_type_name,
    NOW() - bh.hold_expiry as expired_duration
FROM booking_holds bh
JOIN room_types rt ON bh.room_type_id = rt.room_type_id
WHERE bh.hold_expiry < NOW()
ORDER BY bh.hold_expiry;
```

## 📊 Function Details

### Signature

```sql
release_expired_holds()
RETURNS TABLE(
    released_count INT,
    message TEXT
)
```

### Usage

```sql
-- เรียก function
SELECT * FROM release_expired_holds();

-- ผลลัพธ์
released_count | message
---------------+--------------------------------------------------
3              | ปล่อย 3 holds ที่หมดอายุ และอัปเดต 2 inventory records
```

### What It Does

1. **Find Expired Holds**: หา holds ที่ hold_expiry < NOW()
2. **Return Inventory**: คืน tentative_count กลับเข้า room_inventory
3. **Delete Holds**: ลบ expired holds ออกจากระบบ
4. **Return Stats**: Return จำนวน holds ที่ถูกปล่อย

## 🔄 Background Job Integration

Function นี้ควรถูกเรียกโดย background job ทุก 5 นาที:

### Go Example

```go
// cmd/jobs/hold_cleanup.go
package main

import (
    "database/sql"
    "log"
    "github.com/robfig/cron/v3"
)

func RunHoldCleanup(db *sql.DB) {
    c := cron.New()
    
    // ทุก 5 นาที
    c.AddFunc("*/5 * * * *", func() {
        var releasedCount int
        var message string
        
        err := db.QueryRow(`
            SELECT released_count, message 
            FROM release_expired_holds()
        `).Scan(&releasedCount, &message)
        
        if err != nil {
            log.Printf("[HOLD_CLEANUP_ERROR] %v", err)
        } else if releasedCount > 0 {
            log.Printf("[HOLD_CLEANUP] %s", message)
        }
    })
    
    c.Start()
    log.Println("Hold cleanup job started (runs every 5 minutes)")
}
```

## 🐛 Troubleshooting

### Problem: Function not found

**Solution:**
```bash
# Re-run migration
cd database/migrations
./run_migration_008.sh
```

### Problem: Permission denied

**Solution:**
```sql
-- Grant execute permission
GRANT EXECUTE ON FUNCTION release_expired_holds TO hotel_app_user;
```

### Problem: Tentative count incorrect

**Solution:**
```sql
-- Recalculate tentative_count
UPDATE room_inventory ri
SET tentative_count = (
    SELECT COUNT(*)
    FROM booking_holds bh
    WHERE bh.room_type_id = ri.room_type_id
      AND bh.date = ri.date
      AND bh.hold_expiry > NOW()
);
```

## 📚 Related Documentation

- **Full Reference**: `RELEASE_EXPIRED_HOLDS_REFERENCE.md`
- **Migration File**: `008_create_release_expired_holds_function.sql`
- **Test File**: `test_release_expired_holds_function.sql`
- **Verification**: `verify_release_expired_holds.sql`

## ✅ Task Completion Checklist

- [ ] Migration 008 executed successfully
- [ ] Function verified (verify_release_expired_holds.sql)
- [ ] All tests passed (5/5 tests)
- [ ] Manual testing completed
- [ ] Function documented
- [ ] Ready for background job integration

## 🎉 Success Criteria

Task 14 is complete when:

1. ✅ Function `release_expired_holds()` exists
2. ✅ Function executes without errors
3. ✅ All 5 tests pass
4. ✅ Expired holds are released correctly
5. ✅ Inventory is restored correctly
6. ✅ Active holds are preserved
7. ✅ Tentative count never goes negative

## ⏭️ Next Steps

After completing Task 14:

1. **Task 15**: Create Booking Module backend
   - Integrate with Go API
   - Create booking endpoints
   - Connect to PostgreSQL functions

2. **Background Job**: Implement cron job
   - Call release_expired_holds() every 5 minutes
   - Add logging and monitoring
   - Set up alerts for failures

## 🔗 Quick Links

- [Task 11 - create_booking_hold](TASK_11_QUICKSTART.md)
- [Task 12 - confirm_booking](TASK_12_QUICKSTART.md)
- [Task 13 - cancel_booking](TASK_13_QUICKSTART.md)
- [Booking Hold Flow](BOOKING_HOLD_FLOW.md)

---

**Task 14 Status**: ✅ Ready to implement  
**Estimated Time**: 30 minutes  
**Difficulty**: Easy
