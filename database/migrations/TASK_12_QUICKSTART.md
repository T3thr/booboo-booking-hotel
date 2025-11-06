# Task 12 Quick Start Guide - confirm_booking Function

## 🚀 Quick Start (5 นาที)

### 1. รัน Migration

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_migration_006.sh
./run_migration_006.sh
```

**Windows:**
```cmd
cd database\migrations
run_migration_006.bat
```

### 2. รัน Tests

**Linux/Mac:**
```bash
chmod +x run_test_confirm_booking.sh
./run_test_confirm_booking.sh
```

**Windows:**
```cmd
run_test_confirm_booking.bat
```

### 3. Verify

```bash
psql -h localhost -U postgres -d hotel_booking -f verify_confirm_booking.sql
```

---

## 📖 การใช้งานพื้นฐาน

### ยืนยันการจอง

```sql
-- ยืนยันการจอง ID 123
SELECT * FROM confirm_booking(123);

-- ผลลัพธ์:
-- success | message                                    | booking_id
-- --------+--------------------------------------------+-----------
-- true    | ยืนยันการจองสำเร็จ (Booking ID: 123, 3 คืน) | 123
```

### ตรวจสอบผลลัพธ์

```sql
-- ดูการจองที่ confirm แล้ว
SELECT 
    booking_id,
    status,
    policy_name,
    total_amount,
    updated_at
FROM bookings
WHERE booking_id = 123;

-- ดู nightly log
SELECT 
    date,
    quoted_price
FROM booking_nightly_log bnl
JOIN booking_details bd ON bnl.booking_detail_id = bd.booking_detail_id
WHERE bd.booking_id = 123
ORDER BY date;

-- ดู inventory
SELECT 
    date,
    allotment,
    booked_count,
    tentative_count,
    allotment - booked_count - tentative_count as available
FROM room_inventory
WHERE room_type_id = 1
  AND date >= CURRENT_DATE
ORDER BY date
LIMIT 7;
```

---

## 🔧 Integration (Go)

```go
func (s *BookingService) ConfirmBooking(ctx context.Context, bookingID int) error {
    tx, err := s.db.Begin(ctx)
    if err != nil {
        return err
    }
    defer tx.Rollback(ctx)
    
    var result struct {
        Success   bool
        Message   string
        BookingID *int
    }
    
    err = tx.QueryRow(
        ctx,
        "SELECT * FROM confirm_booking($1)",
        bookingID,
    ).Scan(&result.Success, &result.Message, &result.BookingID)
    
    if err != nil {
        return err
    }
    
    if !result.Success {
        return fmt.Errorf("confirm failed: %s", result.Message)
    }
    
    if err := tx.Commit(ctx); err != nil {
        return err
    }
    
    // ส่งอีเมล (async)
    go s.emailService.SendConfirmation(ctx, bookingID)
    
    return nil
}
```

---

## 📁 ไฟล์ที่เกี่ยวข้อง

### Migration & Tests
- `006_create_confirm_booking_function.sql` - Function definition
- `test_confirm_booking_function.sql` - Test suite (7 tests)
- `verify_confirm_booking.sql` - Verification script

### Helper Scripts
- `run_migration_006.sh` / `.bat` - รัน migration
- `run_test_confirm_booking.sh` / `.bat` - รัน tests

### Documentation
- `TASK_12_SUMMARY.md` - สรุปภาพรวม
- `CONFIRM_BOOKING_REFERENCE.md` - คู่มืออ้างอิงฉบับสมบูรณ์
- `CONFIRM_BOOKING_FLOW.md` - แผนภาพและ flow
- `TASK_12_QUICKSTART.md` - คู่มือนี้
- `TASK_12_COMPLETION.md` - รายงานการเสร็จสิ้น

---

## ✅ Checklist

- [ ] รัน migration สำเร็จ
- [ ] Tests ทั้งหมด pass (7/7)
- [ ] Verify function exists
- [ ] ทดสอบ confirm booking จริง
- [ ] ตรวจสอบ inventory อัปเดตถูกต้อง
- [ ] ตรวจสอบ policy snapshot บันทึกแล้ว
- [ ] ตรวจสอบ nightly log ถูกสร้าง
- [ ] ตรวจสอบ holds ถูกลบ

---

## 🐛 Troubleshooting

### Function ไม่ทำงาน

```sql
-- ตรวจสอบว่า function มีอยู่
SELECT proname FROM pg_proc WHERE proname = 'confirm_booking';

-- ดู function definition
\df+ confirm_booking
```

### Inventory ไม่ถูกต้อง

```sql
-- ตรวจสอบ inventory violations
SELECT * FROM room_inventory
WHERE booked_count + tentative_count > allotment;

-- รีเซ็ต tentative_count (ระวัง!)
UPDATE room_inventory
SET tentative_count = 0
WHERE date >= CURRENT_DATE;
```

### Policy ไม่ถูกบันทึก

```sql
-- ตรวจสอบ confirmed bookings ที่ไม่มี policy
SELECT booking_id, status, policy_name
FROM bookings
WHERE status = 'Confirmed'
  AND (policy_name IS NULL OR policy_name = '');
```

---

## 📊 Monitoring

### Key Metrics

```sql
-- Confirmation rate (24 ชั่วโมงล่าสุด)
SELECT 
    COUNT(*) FILTER (WHERE status = 'Confirmed') * 100.0 / COUNT(*) as rate
FROM bookings
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Average confirmation time
SELECT 
    AVG(updated_at - created_at) as avg_time
FROM bookings
WHERE status = 'Confirmed'
  AND updated_at >= NOW() - INTERVAL '24 hours';

-- Recent confirmations
SELECT 
    booking_id,
    guest_id,
    total_amount,
    updated_at - created_at as duration
FROM bookings
WHERE status = 'Confirmed'
ORDER BY updated_at DESC
LIMIT 10;
```

---

## 🎯 Next Steps

1. ✅ Task 12 Complete
2. ⏭️ Task 13: สร้าง cancel_booking function
3. ⏭️ Task 14: สร้าง release_expired_holds function
4. ⏭️ Task 15: Integrate กับ Go backend

---

## 📚 เอกสารเพิ่มเติม

- **สรุปภาพรวม**: `TASK_12_SUMMARY.md`
- **คู่มืออ้างอิง**: `CONFIRM_BOOKING_REFERENCE.md`
- **Flow Diagrams**: `CONFIRM_BOOKING_FLOW.md`
- **Completion Report**: `TASK_12_COMPLETION.md`

---

## 💡 Tips

1. **Always use transactions** เมื่อเรียก function
2. **Validate payment** ก่อนเรียก confirm_booking
3. **Send email asynchronously** เพื่อไม่ block
4. **Monitor confirmation rate** เพื่อตรวจจับปัญหา
5. **Log all confirmations** สำหรับ audit trail

---

**สถานะ**: ✅ Ready to use  
**Version**: 1.0  
**Last Updated**: 2025-11-02

**🎉 Happy Coding!**
