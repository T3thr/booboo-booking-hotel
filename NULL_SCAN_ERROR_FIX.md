# NULL Scan Error Fix - Final

## ปัญหา
```
Error: cannot scan NULL into *string
```

**สาเหตุ:** Query ดึงข้อมูลจาก database โดยไม่ใช้ COALESCE สำหรับ fields ที่อาจเป็น NULL

## Fields ที่เป็น NULL

1. `pp.notes` - payment_proofs table (ยังไม่มีข้อมูล)
2. `bg.email` - booking_guests table (อาจไม่กรอก)
3. `bg.phone` - booking_guests table (อาจไม่กรอก)
4. `bg.first_name` - booking_guests table (อาจไม่กรอก)
5. `bg.last_name` - booking_guests table (อาจไม่กรอก)

## การแก้ไข

### 1. เพิ่ม COALESCE ใน Query

```sql
-- เดิม (ERROR)
pp.notes,
bg.email as guest_email,
bg.phone as guest_phone,
CONCAT(bg.first_name, ' ', bg.last_name) as guest_name

-- ใหม่ (FIXED)
COALESCE(pp.notes, '') as notes,
COALESCE(bg.email, '') as guest_email,
COALESCE(bg.phone, '') as guest_phone,
CONCAT(COALESCE(bg.first_name, ''), ' ', COALESCE(bg.last_name, '')) as guest_name
```

### 2. เปลี่ยน Model Type

```go
// เดิม
Notes *string `json:"notes" db:"notes"`

// ใหม่
Notes string `json:"notes,omitempty" db:"notes"`
```

## Query ที่ถูกต้อง

```sql
SELECT 
    COALESCE(pp.payment_proof_id, 0) as payment_proof_id,
    b.booking_id,
    COALESCE(pp.proof_url, '') as proof_url,
    COALESCE(pp.status, 'pending') as status,
    COALESCE(pp.notes, '') as notes,
    COALESCE(pp.created_at, b.created_at) as created_at,
    COALESCE(pp.updated_at, b.updated_at) as updated_at,
    CONCAT(COALESCE(bg.first_name, ''), ' ', COALESCE(bg.last_name, '')) as guest_name,
    COALESCE(bg.email, '') as guest_email,
    COALESCE(bg.phone, '') as guest_phone,
    rt.name as room_type_name,
    bd.check_in_date,
    bd.check_out_date,
    b.total_amount,
    'bank_transfer' as payment_method
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id 
  AND bg.is_primary = true
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE b.status = 'PendingPayment'
ORDER BY b.created_at DESC
```

## Files Modified

### Backend
1. **`backend/internal/repository/payment_proof_repository.go`**
   - เพิ่ม COALESCE ทุก field ที่อาจเป็น NULL

2. **`backend/internal/models/payment_proof.go`**
   - เปลี่ยน `Notes *string` เป็น `Notes string`

## ผลลัพธ์

✅ ไม่มี NULL scan error
✅ แสดงข้อมูล booking ทั้งหมดที่ status = 'PendingPayment'
✅ แสดงข้อมูล guest จาก booking_guests (ข้อมูลที่กรอก)
✅ Backend ส่ง 200 OK

## การทดสอบ

1. เข้า Admin → Reception → จัดการการจอง → รอตรวจสอบการชำระเงิน
2. ควรเห็น booking ทั้งหมดที่รอ approve
3. แสดงข้อมูลครบ: ชื่อ, email, เบอร์โทร, ห้อง, วันที่, จำนวนเงิน
4. ไม่มี error ใดๆ

## Status

✅ Backend แก้ไขเสร็จ
✅ Build สำเร็จ
✅ Server ทำงานที่ port 8080
✅ ทดสอบแล้ว ได้ 200 OK
✅ พร้อมส่งลูกค้า 100%!
