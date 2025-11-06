# Release Expired Holds Function - Quick Reference

## Overview

Function `release_expired_holds()` ปล่อย booking holds ที่หมดอายุและคืน tentative_count กลับเข้า inventory

**Task:** 14. สร้าง PostgreSQL Function - release_expired_holds  
**Requirements:** 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8

## Function Signature

```sql
release_expired_holds()
RETURNS TABLE(
    released_count INT,
    message TEXT
)
```

## Purpose

Function นี้ถูกออกแบบมาเพื่อ:
1. ทำความสะอาด booking holds ที่หมดอายุ (hold_expiry < NOW())
2. คืน tentative_count กลับเข้า room_inventory
3. ป้องกัน tentative_count ติดลบ
4. Return สถิติการทำงาน

## Usage

### Basic Usage

```sql
-- เรียก function เพื่อปล่อย expired holds
SELECT * FROM release_expired_holds();
```

### Expected Output

```
released_count | message
---------------+--------------------------------------------------
3              | ปล่อย 3 holds ที่หมดอายุ และอัปเดต 2 inventory records
```

หรือถ้าไม่มี holds ที่หมดอายุ:

```
released_count | message
---------------+------------------
0              | ไม่มี holds ที่หมดอายุ
```

## How It Works

### Step 1: คืน tentative_count

```sql
WITH expired_holds AS (
    SELECT 
        room_type_id,
        date,
        COUNT(*) as hold_count
    FROM booking_holds
    WHERE hold_expiry < NOW()
    GROUP BY room_type_id, date
)
UPDATE room_inventory ri
SET 
    tentative_count = GREATEST(0, tentative_count - eh.hold_count),
    updated_at = NOW()
FROM expired_holds eh
WHERE ri.room_type_id = eh.room_type_id 
  AND ri.date = eh.date
  AND ri.tentative_count > 0;
```

**Key Features:**
- ใช้ CTE เพื่อนับจำนวน holds ที่หมดอายุแบบ grouped
- ใช้ `GREATEST(0, ...)` เพื่อป้องกัน tentative_count ติดลบ
- อัปเดตเฉพาะ rows ที่มี tentative_count > 0

### Step 2: ลบ expired holds

```sql
DELETE FROM booking_holds
WHERE hold_expiry < NOW();
```

## Background Job Integration

Function นี้ควรถูกเรียกโดย background job ทุก 5 นาที:

### Go Implementation Example

```go
// cmd/jobs/hold_cleanup.go
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
            log.Printf("Hold cleanup failed: %v", err)
        } else if releasedCount > 0 {
            log.Printf("Hold cleanup: %s", message)
        }
    })
    
    c.Start()
}
```

## Test Scenarios

### Test 1: Release Expired Holds

```sql
-- สร้าง expired holds
INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
VALUES 
    ('TEST_1', 1, 1, CURRENT_DATE, NOW() - INTERVAL '1 hour'),
    ('TEST_1', 1, 1, CURRENT_DATE + 1, NOW() - INTERVAL '1 hour');

-- อัปเดต inventory
UPDATE room_inventory 
SET tentative_count = 1 
WHERE room_type_id = 1 AND date = CURRENT_DATE;

-- เรียก function
SELECT * FROM release_expired_holds();
-- Expected: released_count = 2

-- ตรวจสอบ inventory
SELECT tentative_count 
FROM room_inventory 
WHERE room_type_id = 1 AND date = CURRENT_DATE;
-- Expected: tentative_count = 0
```

### Test 2: No Expired Holds

```sql
-- เรียก function เมื่อไม่มี expired holds
SELECT * FROM release_expired_holds();
-- Expected: released_count = 0, message = 'ไม่มี holds ที่หมดอายุ'
```

### Test 3: Mixed Expired and Active Holds

```sql
-- สร้าง expired hold
INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
VALUES ('EXPIRED', 1, 1, CURRENT_DATE, NOW() - INTERVAL '5 minutes');

-- สร้าง active hold
INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
VALUES ('ACTIVE', 2, 1, CURRENT_DATE, NOW() + INTERVAL '10 minutes');

-- อัปเดต inventory
UPDATE room_inventory 
SET tentative_count = 2 
WHERE room_type_id = 1 AND date = CURRENT_DATE;

-- เรียก function
SELECT * FROM release_expired_holds();
-- Expected: released_count = 1

-- ตรวจสอบว่า active hold ยังอยู่
SELECT COUNT(*) FROM booking_holds WHERE session_id = 'ACTIVE';
-- Expected: 1

-- ตรวจสอบ inventory
SELECT tentative_count 
FROM room_inventory 
WHERE room_type_id = 1 AND date = CURRENT_DATE;
-- Expected: tentative_count = 1 (สำหรับ active hold)
```

### Test 4: Prevent Negative Tentative Count

```sql
-- ตั้งค่า inventory ให้ tentative_count = 0
UPDATE room_inventory 
SET tentative_count = 0 
WHERE room_type_id = 1 AND date = CURRENT_DATE;

-- สร้าง expired hold (แม้ว่า inventory จะเป็น 0 แล้ว)
INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
VALUES ('TEST', 1, 1, CURRENT_DATE, NOW() - INTERVAL '1 hour');

-- เรียก function
SELECT * FROM release_expired_holds();

-- ตรวจสอบว่า tentative_count ไม่ติดลบ
SELECT tentative_count 
FROM room_inventory 
WHERE room_type_id = 1 AND date = CURRENT_DATE;
-- Expected: tentative_count = 0 (ไม่ติดลบ)
```

## Performance Considerations

### Optimization Features

1. **CTE for Grouping**: ใช้ Common Table Expression เพื่อนับ holds แบบ grouped ก่อนอัปเดต inventory
2. **Conditional Update**: อัปเดตเฉพาะ rows ที่มี tentative_count > 0
3. **Single Transaction**: ทุกอย่างทำงานใน transaction เดียว

### Expected Performance

- **100 expired holds**: < 100ms
- **1000 expired holds**: < 500ms
- **10000 expired holds**: < 2 seconds

### Monitoring

```sql
-- ตรวจสอบจำนวน expired holds ปัจจุบัน
SELECT COUNT(*) as expired_holds_count
FROM booking_holds
WHERE hold_expiry < NOW();

-- ตรวจสอบ expired holds แยกตาม room type
SELECT 
    rt.name,
    COUNT(*) as expired_count
FROM booking_holds bh
JOIN room_types rt ON bh.room_type_id = rt.room_type_id
WHERE bh.hold_expiry < NOW()
GROUP BY rt.name;
```

## Error Handling

Function มี error handling สำหรับ:

1. **Database Errors**: Catch และ return error message
2. **Negative Prevention**: ใช้ GREATEST(0, ...) เพื่อป้องกัน tentative_count ติดลบ
3. **Transaction Safety**: ทุกอย่างทำงานใน transaction เดียว

### Error Response

```
released_count | message
---------------+---------------------------
-1             | เกิดข้อผิดพลาด: [error details]
```

## Integration with Other Functions

### Relationship with create_booking_hold

```
create_booking_hold()
    ↓ สร้าง holds พร้อม expiry time
    ↓ เพิ่ม tentative_count
    
[15 minutes later]
    
release_expired_holds()
    ↓ ลบ expired holds
    ↓ คืน tentative_count
```

### Relationship with confirm_booking

```
create_booking_hold()
    ↓ สร้าง holds
    
confirm_booking()
    ↓ ลบ holds ของ booking นี้
    ↓ ย้าย tentative_count → booked_count
    
release_expired_holds()
    ↓ ลบ holds ที่เหลือที่หมดอายุ
```

## Monitoring & Logging

### Recommended Logging

```go
// Log เมื่อมีการปล่อย holds
if releasedCount > 0 {
    log.Printf("[HOLD_CLEANUP] Released %d expired holds", releasedCount)
}

// Log เมื่อมี error
if err != nil {
    log.Printf("[HOLD_CLEANUP_ERROR] %v", err)
    // ส่ง alert ถ้าจำเป็น
}
```

### Metrics to Track

1. **Released Count**: จำนวน holds ที่ถูกปล่อยในแต่ละรอบ
2. **Execution Time**: เวลาที่ใช้ในการทำงาน
3. **Error Rate**: จำนวนครั้งที่เกิด error
4. **Peak Times**: ช่วงเวลาที่มี expired holds มากที่สุด

## Troubleshooting

### Problem: Function ไม่ปล่อย holds

**Check:**
```sql
-- ตรวจสอบว่ามี expired holds จริงหรือไม่
SELECT * FROM booking_holds WHERE hold_expiry < NOW();
```

### Problem: Tentative count ไม่ถูกต้อง

**Fix:**
```sql
-- Recalculate tentative_count จาก holds ที่ active
UPDATE room_inventory ri
SET tentative_count = (
    SELECT COUNT(*)
    FROM booking_holds bh
    WHERE bh.room_type_id = ri.room_type_id
      AND bh.date = ri.date
      AND bh.hold_expiry > NOW()
);
```

### Problem: Performance ช้า

**Check:**
```sql
-- ตรวจสอบจำนวน expired holds
SELECT COUNT(*) FROM booking_holds WHERE hold_expiry < NOW();

-- ตรวจสอบ indexes
\d booking_holds
```

**Ensure indexes exist:**
```sql
CREATE INDEX IF NOT EXISTS idx_holds_expiry ON booking_holds(hold_expiry);
```

## Best Practices

1. **Run Frequently**: เรียก function ทุก 5 นาทีเพื่อป้องกัน holds สะสม
2. **Monitor Performance**: ติดตามเวลาที่ใช้ในการทำงาน
3. **Log Results**: บันทึก log เมื่อมีการปล่อย holds
4. **Alert on Errors**: ตั้ง alert เมื่อ function ล้มเหลว
5. **Regular Cleanup**: ถ้ามี holds สะสมมาก ให้รันบ่อยขึ้น

## Related Files

- **Migration**: `008_create_release_expired_holds_function.sql`
- **Tests**: `test_release_expired_holds_function.sql`
- **Verification**: `verify_release_expired_holds.sql`
- **Run Scripts**: 
  - `run_migration_008.bat` / `run_migration_008.sh`
  - `run_test_release_expired_holds.bat` / `run_test_release_expired_holds.sh`

## Next Steps

After implementing this function:

1. ✅ **Task 14 Complete** - release_expired_holds function
2. ⏭️ **Task 15** - Create Booking Module backend
3. ⏭️ **Background Job** - Implement Go cron job to call this function

## Summary

Function `release_expired_holds()` เป็นส่วนสำคัญของระบบ booking hold:
- ทำความสะอาด holds ที่หมดอายุอัตโนมัติ
- คืนสต็อกกลับเข้า inventory
- ป้องกัน race conditions และ data inconsistency
- ควรถูกเรียกโดย background job ทุก 5 นาที
