# Confirm Booking Function - คู่มืออ้างอิงฉบับสมบูรณ์

## สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [Function Signature](#function-signature)
3. [การทำงานแบบละเอียด](#การทำงานแบบละเอียด)
4. [ตัวอย่างการใช้งาน](#ตัวอย่างการใช้งาน)
5. [Error Handling](#error-handling)
6. [Performance](#performance)
7. [Best Practices](#best-practices)

## ภาพรวม

`confirm_booking` เป็น PostgreSQL function ที่ใช้สำหรับยืนยันการจองหลังจากผู้เข้าพักชำระเงินสำเร็จ Function นี้จะ:

- เปลี่ยนสถานะการจองจาก `PendingPayment` เป็น `Confirmed`
- ย้าย inventory จาก tentative ไป booked
- บันทึก snapshot ของนโยบายการยกเลิก
- บันทึกราคาแต่ละคืนใน booking_nightly_log
- ลบ booking holds ของ guest

## Function Signature

```sql
CREATE OR REPLACE FUNCTION confirm_booking(
    p_booking_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    booking_id INT
) LANGUAGE plpgsql
```

### Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| p_booking_id | INT | Yes | ID ของการจองที่ต้องการยืนยัน |

### Return Values

| Column | Type | Description |
|--------|------|-------------|
| success | BOOLEAN | TRUE = สำเร็จ, FALSE = ล้มเหลว |
| message | TEXT | ข้อความอธิบายผลลัพธ์ |
| booking_id | INT | ID ของการจองที่ยืนยัน (NULL ถ้าล้มเหลว) |

## การทำงานแบบละเอียด

### STEP 1: ตรวจสอบสถานะการจอง

```sql
SELECT b.status, b.guest_id INTO v_status, v_guest_id
FROM bookings b
WHERE b.booking_id = p_booking_id
FOR UPDATE; -- Lock booking record
```

**จุดประสงค์:**
- ดึงข้อมูลการจองและ lock record
- ป้องกัน concurrent modifications
- ตรวจสอบว่าการจองมีอยู่จริง

**Validations:**
- ถ้าไม่พบการจอง → Return error "ไม่พบการจองนี้"
- ถ้าสถานะไม่ใช่ 'PendingPayment' → Return error พร้อมสถานะปัจจุบัน

### STEP 2: อัปเดต Inventory แบบ Atomic

```sql
FOR v_detail IN 
    SELECT room_type_id, check_in_date, check_out_date
    FROM booking_details
    WHERE booking_id = p_booking_id
LOOP
    v_date := v_detail.check_in_date;
    
    WHILE v_date < v_detail.check_out_date LOOP
        -- Lock inventory row
        SELECT (allotment - booked_count - tentative_count) INTO v_available
        FROM room_inventory
        WHERE room_type_id = v_detail.room_type_id 
          AND date = v_date
        FOR UPDATE;
        
        -- Update inventory
        UPDATE room_inventory
        SET booked_count = booked_count + 1,
            tentative_count = GREATEST(tentative_count - 1, 0),
            updated_at = NOW()
        WHERE room_type_id = v_detail.room_type_id 
          AND date = v_date;
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
END LOOP;
```

**จุดประสงค์:**
- ย้าย inventory จาก tentative ไป booked
- ใช้ FOR UPDATE เพื่อ lock rows
- ป้องกัน race conditions

**การทำงาน:**
1. วนลูปทุก booking_detail (กรณีจองหลายห้อง)
2. สำหรับแต่ละห้อง วนลูปทุกวันในช่วงการจอง
3. Lock inventory row ของวันนั้น
4. อัปเดต booked_count +1, tentative_count -1

### STEP 3: บันทึก Nightly Log

```sql
-- ดึง rate_tier_id สำหรับวันนี้
SELECT pc.rate_tier_id INTO v_rate_tier_id
FROM pricing_calendar pc
WHERE pc.date = v_date;

-- ดึงราคาสำหรับวันนี้
SELECT rp.price INTO v_price
FROM rate_pricing rp
WHERE rp.rate_plan_id = v_detail.rate_plan_id
  AND rp.room_type_id = v_detail.room_type_id
  AND rp.rate_tier_id = v_rate_tier_id;

-- บันทึก nightly log
INSERT INTO booking_nightly_log (
    booking_detail_id,
    date,
    quoted_price
) VALUES (
    v_detail.booking_detail_id,
    v_date,
    v_price
);
```

**จุดประสงค์:**
- บันทึกราคาแต่ละคืน ณ เวลาที่จอง
- ป้องกันการเปลี่ยนแปลงราคาย้อนหลัง
- ใช้สำหรับ audit trail

**การทำงาน:**
1. ดึง rate_tier_id จาก pricing_calendar
2. ดึงราคาจาก rate_pricing ตาม rate_plan, room_type และ rate_tier
3. INSERT ลงใน booking_nightly_log

### STEP 4: บันทึก Policy Snapshot

```sql
SELECT cp.name, cp.description 
INTO v_policy_name, v_policy_description
FROM booking_details bd
JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
WHERE bd.booking_id = p_booking_id
LIMIT 1;

-- ถ้าไม่มีนโยบาย ให้ใช้ค่า default
IF v_policy_name IS NULL THEN
    v_policy_name := 'No Refund';
    v_policy_description := 'ไม่สามารถยกเลิกหรือคืนเงินได้';
END IF;
```

**จุดประสงค์:**
- บันทึก snapshot ของนโยบายการยกเลิก
- ป้องกันการเปลี่ยนแปลงนโยบายย้อนหลัง
- รักษาความเป็นธรรมกับลูกค้า

**การทำงาน:**
1. ดึงนโยบายจาก rate_plan ของ booking detail แรก
2. ถ้าไม่มีนโยบาย ใช้ค่า default "No Refund"
3. บันทึกลงใน bookings table

### STEP 5: อัปเดตสถานะการจอง

```sql
UPDATE bookings
SET status = 'Confirmed',
    policy_name = v_policy_name,
    policy_description = v_policy_description,
    updated_at = NOW()
WHERE booking_id = p_booking_id;
```

**จุดประสงค์:**
- เปลี่ยนสถานะเป็น 'Confirmed'
- บันทึก policy snapshot
- อัปเดต timestamp

### STEP 6: ลบ Booking Holds

```sql
IF v_guest_account_id IS NOT NULL THEN
    DELETE FROM booking_holds
    WHERE guest_account_id = v_guest_account_id;
END IF;
```

**จุดประสงค์:**
- ลบ holds ทั้งหมดของ guest นี้
- ทำให้ guest สามารถสร้าง hold ใหม่ได้
- ทำความสะอาดข้อมูล

## ตัวอย่างการใช้งาน

### 1. Basic Usage

```sql
-- ยืนยันการจอง ID 123
SELECT * FROM confirm_booking(123);

-- ผลลัพธ์:
-- success | message                                    | booking_id
-- --------+--------------------------------------------+-----------
-- true    | ยืนยันการจองสำเร็จ (Booking ID: 123, 3 คืน) | 123
```

### 2. ใช้ใน Transaction (Go)

```go
func (s *BookingService) ConfirmBooking(ctx context.Context, bookingID int) error {
    tx, err := s.db.Begin(ctx)
    if err != nil {
        return fmt.Errorf("begin transaction: %w", err)
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
        return fmt.Errorf("execute function: %w", err)
    }
    
    if !result.Success {
        return fmt.Errorf("confirm failed: %s", result.Message)
    }
    
    if err := tx.Commit(ctx); err != nil {
        return fmt.Errorf("commit transaction: %w", err)
    }
    
    // ส่งอีเมลยืนยัน (async)
    go s.emailService.SendConfirmation(ctx, bookingID)
    
    log.Printf("Booking %d confirmed successfully", bookingID)
    return nil
}
```

### 3. ใช้ใน Transaction (Node.js)

```javascript
async function confirmBooking(bookingId) {
    const client = await pool.connect();
    
    try {
        await client.query('BEGIN');
        
        const result = await client.query(
            'SELECT * FROM confirm_booking($1)',
            [bookingId]
        );
        
        const { success, message, booking_id } = result.rows[0];
        
        if (!success) {
            throw new Error(`Confirm failed: ${message}`);
        }
        
        await client.query('COMMIT');
        
        // ส่งอีเมลยืนยัน (async)
        sendConfirmationEmail(booking_id).catch(console.error);
        
        return { success: true, bookingId: booking_id };
        
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}
```

### 4. Batch Confirmation

```sql
-- ยืนยันหลายการจองพร้อมกัน
DO $
DECLARE
    v_booking_id INT;
    v_result RECORD;
BEGIN
    FOR v_booking_id IN 
        SELECT booking_id 
        FROM bookings 
        WHERE status = 'PendingPayment'
          AND created_at < NOW() - INTERVAL '1 hour'
        LIMIT 10
    LOOP
        SELECT * INTO v_result
        FROM confirm_booking(v_booking_id);
        
        IF v_result.success THEN
            RAISE NOTICE 'Confirmed booking %', v_booking_id;
        ELSE
            RAISE WARNING 'Failed to confirm booking %: %', 
                          v_booking_id, v_result.message;
        END IF;
    END LOOP;
END $;
```

## Error Handling

### Error Cases

| Error | Condition | Message |
|-------|-----------|---------|
| Booking Not Found | booking_id ไม่มีอยู่ | "ไม่พบการจองนี้" |
| Invalid Status | status != 'PendingPayment' | "ไม่สามารถยืนยันการจองได้ สถานะปัจจุบัน: {status}" |
| No Inventory | ไม่มี inventory record | "ไม่พบข้อมูล inventory สำหรับ {room_type} วันที่ {date}" |
| Unexpected Error | Exception อื่นๆ | "เกิดข้อผิดพลาดในการยืนยันการจอง: {error}" |

### Error Handling Pattern

```go
result, err := confirmBooking(ctx, bookingID)
if err != nil {
    // Database error
    log.Error("Database error", "error", err)
    return fmt.Errorf("database error: %w", err)
}

if !result.Success {
    // Business logic error
    switch {
    case strings.Contains(result.Message, "ไม่พบการจอง"):
        return ErrBookingNotFound
    case strings.Contains(result.Message, "สถานะปัจจุบัน"):
        return ErrInvalidStatus
    default:
        return fmt.Errorf("confirm failed: %s", result.Message)
    }
}

// Success
return nil
```

## Performance

### Expected Performance

| Scenario | Expected Time | Notes |
|----------|---------------|-------|
| Single room, 1 night | < 20ms | Fastest case |
| Single room, 7 nights | < 50ms | Linear with nights |
| Multiple rooms | < 100ms | Depends on room count |
| Concurrent confirms | Variable | Handled by locking |

### Performance Tips

1. **Use Connection Pooling**
   ```go
   pool, err := pgxpool.New(ctx, connString)
   // Reuse connections
   ```

2. **Monitor Slow Queries**
   ```sql
   -- Enable slow query logging
   ALTER DATABASE hotel_booking 
   SET log_min_duration_statement = 100;
   ```

3. **Add Indexes** (if needed)
   ```sql
   CREATE INDEX IF NOT EXISTS idx_bookings_status_created 
   ON bookings(status, created_at);
   ```

4. **Batch Operations**
   - Confirm multiple bookings in one transaction
   - Use prepared statements

### Monitoring Queries

```sql
-- ดูการจองที่ confirm ล่าสุด
SELECT 
    booking_id,
    status,
    updated_at - created_at as confirm_duration
FROM bookings
WHERE status = 'Confirmed'
ORDER BY updated_at DESC
LIMIT 10;

-- ดู inventory consistency
SELECT 
    room_type_id,
    date,
    allotment,
    booked_count,
    tentative_count,
    allotment - booked_count - tentative_count as available
FROM room_inventory
WHERE date >= CURRENT_DATE
  AND (booked_count + tentative_count > allotment)
LIMIT 10;
```

## Best Practices

### 1. Always Use Transactions

```go
// ✅ Good
tx, _ := db.Begin(ctx)
defer tx.Rollback(ctx)
result, _ := tx.QueryRow("SELECT * FROM confirm_booking($1)", id)
tx.Commit(ctx)

// ❌ Bad
db.QueryRow("SELECT * FROM confirm_booking($1)", id)
```

### 2. Handle All Error Cases

```go
// ✅ Good
if !result.Success {
    switch {
    case strings.Contains(result.Message, "ไม่พบ"):
        return ErrNotFound
    case strings.Contains(result.Message, "สถานะ"):
        return ErrInvalidStatus
    default:
        return fmt.Errorf("unknown error: %s", result.Message)
    }
}

// ❌ Bad
if !result.Success {
    return errors.New("failed")
}
```

### 3. Send Email Asynchronously

```go
// ✅ Good
if err := confirmBooking(ctx, id); err == nil {
    go sendEmail(id) // Don't block
}

// ❌ Bad
if err := confirmBooking(ctx, id); err == nil {
    sendEmail(id) // Blocks
}
```

### 4. Log Important Events

```go
// ✅ Good
log.Info("Booking confirmed",
    "booking_id", id,
    "guest_id", guestID,
    "total_amount", amount,
    "duration_ms", duration)

// ❌ Bad
log.Info("Booking confirmed")
```

### 5. Validate Before Calling

```go
// ✅ Good
if booking.Status != "PendingPayment" {
    return ErrInvalidStatus
}
if booking.PaymentStatus != "Completed" {
    return ErrPaymentNotCompleted
}
result := confirmBooking(ctx, booking.ID)

// ❌ Bad
result := confirmBooking(ctx, booking.ID)
// Let function handle all validation
```

## Troubleshooting

### Problem: Function ไม่ทำงาน

**Solution:**
```sql
-- ตรวจสอบว่า function มีอยู่
SELECT proname FROM pg_proc WHERE proname = 'confirm_booking';

-- ตรวจสอบ permissions
SELECT * FROM information_schema.routine_privileges 
WHERE routine_name = 'confirm_booking';
```

### Problem: Inventory ไม่ถูกต้อง

**Solution:**
```sql
-- ตรวจสอบ inventory consistency
SELECT 
    room_type_id,
    date,
    allotment,
    booked_count,
    tentative_count,
    allotment - booked_count - tentative_count as available
FROM room_inventory
WHERE booked_count + tentative_count > allotment;

-- รีเซ็ต inventory (ระวัง!)
UPDATE room_inventory
SET tentative_count = 0
WHERE date >= CURRENT_DATE;
```

### Problem: Policy ไม่ถูกบันทึก

**Solution:**
```sql
-- ตรวจสอบ policy data
SELECT 
    b.booking_id,
    b.policy_name,
    b.policy_description,
    cp.name as current_policy
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
WHERE b.status = 'Confirmed'
  AND (b.policy_name IS NULL OR b.policy_name = '');
```

---

**เอกสารนี้ครอบคลุม:**
- ✅ Function signature และ parameters
- ✅ การทำงานแบบละเอียดทุก step
- ✅ ตัวอย่างการใช้งานหลายภาษา
- ✅ Error handling patterns
- ✅ Performance tips และ monitoring
- ✅ Best practices
- ✅ Troubleshooting guide

**อัปเดตล่าสุด**: 2025-11-02
