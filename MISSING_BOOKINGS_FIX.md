# Missing Bookings Fix - Complete

## ปัญหา
แสดงแค่ 32 bookings แต่ใน database มี 61 bookings ที่ status = 'PendingPayment'

## สาเหตุ

### Query เดิม (ผิด)
```sql
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
```

**ปัญหา:**
- `JOIN booking_guests` กรองออก bookings ที่ไม่มี booking_guests
- Bookings เก่าที่สร้างก่อน migration 021 (เพิ่ม email/phone) ไม่มี booking_guests
- Bookings ที่มีปัญหาในการสร้าง guest info จะไม่แสดง

## การแก้ไข

### เปลี่ยนเป็น LEFT JOIN

```sql
FROM bookings b
LEFT JOIN booking_details bd ON b.booking_id = bd.booking_id
LEFT JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id 
  AND bg.is_primary = true
LEFT JOIN room_types rt ON bd.room_type_id = rt.room_type_id
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE b.status = 'PendingPayment'
```

**LEFT JOIN:**
- แสดงทุก bookings แม้ไม่มี booking_guests
- แสดงทุก bookings แม้ไม่มี booking_details
- ใช้ COALESCE เพื่อจัดการ NULL values

### จัดการ NULL Values

```sql
CONCAT(COALESCE(bg.first_name, 'Guest'), ' ', COALESCE(bg.last_name, '')) as guest_name,
COALESCE(bg.email, 'N/A') as guest_email,
COALESCE(bg.phone, 'N/A') as guest_phone,
COALESCE(rt.name, 'Unknown Room') as room_type_name,
COALESCE(bd.check_in_date, b.created_at::date) as check_in_date,
COALESCE(bd.check_out_date, b.created_at::date + 1) as check_out_date
```

## Scenarios ที่แก้ไข

### Scenario 1: Booking ไม่มี booking_guests
```
Booking #45: สร้างก่อน migration 021
- ไม่มี booking_guests record
- Query เดิม: ไม่แสดง (JOIN กรองออก)
- Query ใหม่: แสดง (LEFT JOIN + COALESCE)
- แสดงเป็น: "Guest" / "N/A" / "N/A"
```

### Scenario 2: Booking มี booking_guests
```
Booking #60: สร้างหลัง migration 021
- มี booking_guests record
- Query เดิม: แสดง
- Query ใหม่: แสดง (ข้อมูลจริง)
- แสดงเป็น: "John Doe" / "john@test.com" / "0812345678"
```

### Scenario 3: Booking ไม่มี booking_details
```
Booking #50: มีปัญหาในการสร้าง
- ไม่มี booking_details record
- Query เดิม: ไม่แสดง
- Query ใหม่: แสดง
- แสดงเป็น: "Unknown Room" / check_in = created_at
```

## ผลลัพธ์

### เดิม (JOIN)
```
Total bookings in DB: 61
Bookings shown: 32
Missing: 29 bookings
```

### ใหม่ (LEFT JOIN)
```
Total bookings in DB: 61
Bookings shown: 61
Missing: 0 bookings
```

## Files Modified

**File:** `backend/internal/repository/payment_proof_repository.go`

**Changes:**
1. เปลี่ยน `JOIN` เป็น `LEFT JOIN` ทุก table
2. เพิ่ม COALESCE สำหรับ fields ที่อาจเป็น NULL
3. ใช้ fallback values: "Guest", "N/A", "Unknown Room"

## การทดสอบ

### Test 1: Count Total
```sql
SELECT COUNT(*) FROM bookings WHERE status = 'PendingPayment';
-- Result: 61

-- API Response
GET /api/payment-proofs?status=pending
-- Result: 61 items
```

### Test 2: Booking ไม่มี Guest Info
```
Booking #45 (no booking_guests):
✅ แสดงใน list
✅ guest_name = "Guest"
✅ guest_email = "N/A"
✅ guest_phone = "N/A"
```

### Test 3: Booking มี Guest Info
```
Booking #60 (has booking_guests):
✅ แสดงใน list
✅ guest_name = "John Doe"
✅ guest_email = "john@test.com"
✅ guest_phone = "0812345678"
```

## Migration History

### Migration 021 (เพิ่ม email/phone)
```sql
ALTER TABLE booking_guests 
ADD COLUMN email VARCHAR(255),
ADD COLUMN phone VARCHAR(20);
```

**Impact:**
- Bookings ก่อน migration: ไม่มี email/phone
- Bookings หลัง migration: มี email/phone
- ต้องใช้ LEFT JOIN เพื่อแสดงทั้งสอง

## Status

✅ Backend แก้ไขเสร็จ
✅ Build สำเร็จ
✅ Server ทำงานที่ port 8080
✅ แสดงครบ 61/61 bookings
✅ จัดการ NULL values ถูกต้อง
✅ พร้อมส่งลูกค้า 100%!
