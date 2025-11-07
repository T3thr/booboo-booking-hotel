# Task 12: สร้าง PostgreSQL Function - confirm_booking

## ภาพรวม (Overview)

Task นี้สร้าง PostgreSQL function `confirm_booking` สำหรับยืนยันการจองและเปลี่ยนสถานะจาก `PendingPayment` เป็น `Confirmed` พร้อมกับอัปเดต inventory และบันทึกข้อมูลที่จำเป็นทั้งหมดแบบ atomic

## Requirements ที่เกี่ยวข้อง

- **4.1**: เมื่อผู้เข้าพักชำระเงินสำเร็จ ระบบต้องเรียก SP_ConfirmBooking ภายใน transaction เดียวกัน
- **4.2**: อัปเดต Bookings.Status = 'Confirmed', RoomInventory (BookedCount +1, TentativeCount -1) แบบ atomic
- **4.3**: บันทึก snapshot ของนโยบายการยกเลิก (PolicyName, PolicyDescription)
- **4.4**: บันทึกข้อมูลใน BookingNightlyLog พร้อม QuotedPrice สำหรับทุกคืน
- **4.5**: ถ้าการชำระเงินล้มเหลว ไม่เรียก SP_ConfirmBooking
- **4.6**: ส่งอีเมลยืนยันพร้อมรายละเอียดการจอง
- **4.7**: คำนวณ TotalAmount รวมส่วนลดจากคูปอง (ถ้ามี)
- **4.8**: เพิ่ม Vouchers.CurrentUses แบบ atomic (ถ้ามีคูปอง)
- **4.9**: แสดงรายละเอียดการจองทั้งหมดรวมนโยบายการยกเลิก

## ไฟล์ที่สร้าง

### 1. Migration File
- **ไฟล์**: `006_create_confirm_booking_function.sql`
- **จุดประสงค์**: สร้าง PostgreSQL function `confirm_booking`
- **ขนาด**: ~250 บรรทัด

### 2. Test File
- **ไฟล์**: `test_confirm_booking_function.sql`
- **จุดประสงค์**: ทดสอบ function ครอบคลุมทุก scenarios
- **Test Cases**: 7 tests

### 3. Helper Scripts
- `run_migration_006.sh` / `run_migration_006.bat` - รัน migration
- `run_test_confirm_booking.sh` / `run_test_confirm_booking.bat` - รัน tests
- `verify_confirm_booking.sql` - ตรวจสอบ function

### 4. Documentation
- `TASK_12_SUMMARY.md` (ไฟล์นี้) - สรุปภาพรวม
- `CONFIRM_BOOKING_REFERENCE.md` - คู่มืออ้างอิง
- `CONFIRM_BOOKING_FLOW.md` - อธิบาย flow

## Function Signature

```sql
CREATE OR REPLACE FUNCTION confirm_booking(
    p_booking_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    booking_id INT
)
```

### Parameters
- `p_booking_id` (INT): ID ของการจองที่ต้องการยืนยัน

### Return Values
- `success` (BOOLEAN): TRUE ถ้าสำเร็จ, FALSE ถ้าล้มเหลว
- `message` (TEXT): ข้อความอธิบายผลลัพธ์
- `booking_id` (INT): ID ของการจองที่ยืนยัน (NULL ถ้าล้มเหลว)

## การทำงานของ Function

### Step 1: ตรวจสอบสถานะการจอง
- ดึงข้อมูลการจองและ lock record ด้วย `FOR UPDATE`
- ตรวจสอบว่าสถานะเป็น `PendingPayment`
- ถ้าไม่ใช่ให้ return error

### Step 2: อัปเดต Inventory แบบ Atomic
- วนลูปทุก booking_detail
- สำหรับแต่ละวันในช่วงการจอง:
  - Lock inventory row ด้วย `FOR UPDATE`
  - ตรวจสอบห้องว่าง
  - อัปเดต: `booked_count = booked_count + 1`
  - อัปเดต: `tentative_count = GREATEST(tentative_count - 1, 0)`

### Step 3: บันทึก Nightly Log
- สำหรับแต่ละวัน:
  - ดึง rate_tier_id จาก pricing_calendar
  - ดึงราคาจาก rate_pricing
  - INSERT ลงใน booking_nightly_log

### Step 4: บันทึก Policy Snapshot
- ดึงนโยบายการยกเลิกจาก rate_plan
- บันทึก policy_name และ policy_description ลงใน bookings table
- ทำให้การจองไม่ได้รับผลกระทบจากการเปลี่ยนแปลงนโยบายในอนาคต

### Step 5: อัปเดตสถานะการจอง
- UPDATE bookings SET status = 'Confirmed'
- UPDATE policy_name และ policy_description
- UPDATE updated_at = NOW()

### Step 6: ลบ Booking Holds
- ลบ booking_holds ทั้งหมดของ guest นี้
- ทำให้ guest สามารถสร้าง hold ใหม่ได้

### Step 7: Return Success
- Return ผลลัพธ์พร้อมข้อความสำเร็จ

## Test Cases

### TEST 1: Basic Confirm Booking ✓
- สร้าง booking ใหม่และ confirm
- ตรวจสอบสถานะเปลี่ยนเป็น 'Confirmed'
- ตรวจสอบ inventory อัปเดตถูกต้อง
- ตรวจสอบ nightly log ถูกสร้าง
- ตรวจสอบ holds ถูกลบ

### TEST 2: Confirm Already Confirmed Booking ✓
- พยายาม confirm booking ที่ confirmed แล้ว
- ควรล้มเหลวพร้อมข้อความ error

### TEST 3: Confirm Non-existent Booking ✓
- พยายาม confirm booking ที่ไม่มีอยู่
- ควรล้มเหลวพร้อมข้อความ error

### TEST 4: Confirm Booking with Multiple Rooms ✓
- สร้าง booking ที่มีหลายห้อง
- Confirm และตรวจสอบว่าทุกห้องถูก process
- ตรวจสอบ nightly log สำหรับทุกห้อง

### TEST 5: Verify Policy Snapshot ✓
- Confirm booking และตรวจสอบว่านโยบายถูกบันทึก
- ตรวจสอบว่า policy_name และ policy_description ไม่เป็น NULL

### TEST 6: Verify Nightly Pricing ✓
- Confirm booking และตรวจสอบราคาแต่ละคืน
- แสดงรายละเอียดราคาทุกคืน
- ตรวจสอบว่าราคาไม่เป็นลบ

### TEST 7: Concurrent Confirm ✓
- จำลอง race condition
- ตรวจสอบว่า locking ทำงานถูกต้อง

## การใช้งาน

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

### 3. Verify Function

```bash
psql -h localhost -U postgres -d hotel_booking -f verify_confirm_booking.sql
```

### 4. ใช้งานใน Application

```sql
-- ยืนยันการจอง
SELECT * FROM confirm_booking(123);

-- ตัวอย่างผลลัพธ์:
-- success | message                                    | booking_id
-- --------+--------------------------------------------+-----------
-- true    | ยืนยันการจองสำเร็จ (Booking ID: 123, 3 คืน) | 123
```

## Features หลัก

### 1. Atomic Operations
- ใช้ `FOR UPDATE` เพื่อ lock rows
- ทุก operation อยู่ใน transaction เดียว
- Rollback ทั้งหมดถ้ามี error

### 2. Data Integrity
- ตรวจสอบสถานะก่อน confirm
- ตรวจสอบห้องว่างก่อนอัปเดต inventory
- บันทึก snapshot ของนโยบาย

### 3. Comprehensive Logging
- บันทึกราคาแต่ละคืนใน booking_nightly_log
- บันทึก policy snapshot
- บันทึก timestamp ทุกการเปลี่ยนแปลง

### 4. Error Handling
- ตรวจสอบ input parameters
- Handle ทุก error case
- Return ข้อความ error ที่ชัดเจน

### 5. Performance
- ใช้ row-level locking
- Minimize lock duration
- Efficient query execution

## ข้อควรระวัง

### 1. Transaction Management
- Function ต้องถูกเรียกภายใน transaction
- Backend ต้อง handle transaction commit/rollback

### 2. Booking Holds
- Function จะลบ holds ทั้งหมดของ guest
- ต้องแน่ใจว่า hold ยังไม่หมดอายุ

### 3. Pricing Data
- ต้องมี pricing_calendar และ rate_pricing ครบถ้วน
- ถ้าไม่มีราคาจะใช้ 0 (ควร validate ก่อน)

### 4. Policy Snapshot
- Policy ถูกบันทึกเพียงครั้งเดียว
- การเปลี่ยนแปลงนโยบายในอนาคตไม่กระทบการจองเก่า

## Integration กับ Backend

### Go Example

```go
func (s *BookingService) ConfirmBooking(bookingID int) error {
    tx, err := s.db.Begin(context.Background())
    if err != nil {
        return err
    }
    defer tx.Rollback(context.Background())
    
    var result struct {
        Success   bool
        Message   string
        BookingID *int
    }
    
    err = tx.QueryRow(
        context.Background(),
        "SELECT * FROM confirm_booking($1)",
        bookingID,
    ).Scan(&result.Success, &result.Message, &result.BookingID)
    
    if err != nil {
        return err
    }
    
    if !result.Success {
        return fmt.Errorf("confirm failed: %s", result.Message)
    }
    
    if err := tx.Commit(context.Background()); err != nil {
        return err
    }
    
    // ส่งอีเมลยืนยัน
    go s.sendConfirmationEmail(bookingID)
    
    return nil
}
```

## Performance Considerations

### Expected Performance
- **Single booking**: < 50ms
- **Multiple rooms**: < 100ms
- **Concurrent bookings**: Handled by row-level locking

### Optimization Tips
1. ใช้ connection pooling
2. Monitor slow queries
3. Add indexes ถ้าจำเป็น
4. Cache pricing data ถ้าเป็นไปได้

## Monitoring

### Metrics to Track
- Confirmation success rate
- Average confirmation time
- Failed confirmations (by reason)
- Inventory consistency

### Logging
- Log ทุกการ confirm (success และ failure)
- Log inventory changes
- Log policy snapshots

## Next Steps

1. ✅ สร้าง function และ tests
2. ⏭️ Integrate กับ Go backend (Task 15)
3. ⏭️ สร้าง cancel_booking function (Task 13)
4. ⏭️ สร้าง release_expired_holds function (Task 14)
5. ⏭️ ทดสอบ end-to-end booking flow

## Related Tasks

- **Task 11**: create_booking_hold (prerequisite)
- **Task 13**: cancel_booking (next)
- **Task 14**: release_expired_holds (next)
- **Task 15**: Booking Module - Backend (integration)

## References

- Design Document: `.kiro/specs/hotel-reservation-system/design.md`
- Requirements: `.kiro/specs/hotel-reservation-system/requirements.md`
- Database Schema: `database/migrations/004_create_bookings_tables.sql`
- Booking Hold Function: `database/migrations/005_create_booking_hold_function.sql`

---

**สถานะ**: ✅ Complete
**วันที่สร้าง**: 2025-11-02
**ผู้สร้าง**: Theerapat Pooraya
