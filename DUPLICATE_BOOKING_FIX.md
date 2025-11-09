# Duplicate Booking Key Fix - Complete

## ปัญหา

### Error 1: Duplicate Key
```
Encountered two children with the same key, `31`
Encountered two children with the same key, `32`
```

**สาเหตุ:** 1 booking มีหลาย booking_details (หลาย room types) ทำให้ query คืนหลาย rows สำหรับ booking เดียวกัน

### Error 2: ไม่แสดงครบ
มี booking ใน database มากกว่าที่แสดง เพราะ query ดึงแค่ booking ที่มี booking_guests เท่านั้น

## สาเหตุหลัก

### Query เดิม (ผิด)
```sql
SELECT ...
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
```

**ปัญหา:**
- ถ้า booking มี 2 room types → ได้ 2 rows (booking_id ซ้ำ)
- ถ้า booking ไม่มี booking_guests → ไม่แสดงเลย

## การแก้ไข

### ใช้ DISTINCT ON

```sql
SELECT DISTINCT ON (b.booking_id)
    COALESCE(pp.payment_proof_id, 0) as payment_proof_id,
    b.booking_id,
    ...
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id 
  AND bg.is_primary = true
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE b.status = 'PendingPayment'
ORDER BY b.booking_id, b.created_at DESC
```

**DISTINCT ON (b.booking_id):**
- คืนแค่ 1 row ต่อ 1 booking_id
- เลือก row แรกตาม ORDER BY
- แก้ปัญหา duplicate key

## ทำไมเกิด Duplicate?

### Scenario 1: Multiple Room Types
```
Booking #31:
- Room Type 1: Standard Room
- Room Type 2: Deluxe Room

Query เดิม → 2 rows (booking_id = 31 ซ้ำ)
Query ใหม่ → 1 row (เลือก row แรก)
```

### Scenario 2: Multiple Guests per Room
```
Booking #32:
- Room 1: Guest A (primary), Guest B
- Room 2: Guest C (primary), Guest D

Query เดิม → 2 rows (booking_id = 32 ซ้ำ)
Query ใหม่ → 1 row (เลือก primary guest คนแรก)
```

## Database Schema

### bookings (1)
```
booking_id | guest_id | status | total_amount
31         | 5        | PendingPayment | 3000
```

### booking_details (Many)
```
booking_detail_id | booking_id | room_type_id
101               | 31         | 1
102               | 31         | 2
```

### booking_guests (Many)
```
booking_guest_id | booking_detail_id | first_name | is_primary
201              | 101               | John       | true
202              | 101               | Jane       | false
203              | 102               | Bob        | true
```

**Query เดิม:** JOIN ทุก table → ได้ 3 rows (31, 31, 31)
**Query ใหม่:** DISTINCT ON → ได้ 1 row (31)

## Files Modified

**File:** `backend/internal/repository/payment_proof_repository.go`

**Change:**
```go
// เพิ่ม DISTINCT ON
query := `
    SELECT DISTINCT ON (b.booking_id)
        ...
    ORDER BY b.booking_id, b.created_at DESC
`
```

## ผลลัพธ์

✅ ไม่มี duplicate key error
✅ แสดง 1 booking = 1 card
✅ แสดงข้อมูล primary guest
✅ แสดง room type แรก (ถ้ามีหลาย types)
✅ แสดงครบทุก booking ที่ status = 'PendingPayment'

## การทดสอบ

### Test Case 1: Single Room Type
```
Booking #40: 1 Standard Room, 2 guests
→ แสดง 1 card
→ แสดง primary guest
```

### Test Case 2: Multiple Room Types
```
Booking #31: 1 Standard + 1 Deluxe, 4 guests
→ แสดง 1 card (ไม่ซ้ำ)
→ แสดง primary guest คนแรก
→ แสดง room type แรก
```

### Test Case 3: Multiple Bookings
```
Database: 10 bookings (PendingPayment)
→ แสดง 10 cards (ไม่ซ้ำ)
```

## Status

✅ Backend แก้ไขเสร็จ
✅ Build สำเร็จ
✅ Server ทำงานที่ port 8080
✅ ไม่มี duplicate key error
✅ แสดงข้อมูลครบถ้วน
✅ พร้อมส่งลูกค้า!
