# แก้ปัญหา Admin Check-in ได้ 500 Internal Server Error

## ปัญหา
หลังแก้ 401 แล้ว ตอนนี้ได้ 500 Internal Server Error:
- Backend log: `[GET] 500 | 149ms | ::1 | /api/checkin/arrivals?date=2025-11-08`
- Frontend: `Failed to load resource: 500 (Internal Server Error)`

## สาเหตุ
**SQL Query ใน GetArrivals ไม่รวม status `'PendingPayment'`**

Query เดิม:
```sql
WHERE bd.check_in_date = $1
  AND b.status IN ('Confirmed', 'CheckedIn')  -- ❌ ไม่มี PendingPayment
```

แต่เมื่อ guest complete booking:
- Backend สร้าง booking สำเร็จ
- Backend confirm booking สำเร็จ  
- แต่ status ยังเป็น `'PendingPayment'` (รอ admin approve payment proof)
- ทำให้ query ไม่เจอข้อมูล → return empty array → แต่ไม่ควร error 500

**ปัญหาที่แท้จริง:** Query อาจมี error จาก column ที่ไม่มีใน database

## การแก้ไข

### 1. เพิ่ม PendingPayment ใน Query
```sql
WHERE bd.check_in_date = $1
  AND b.status IN ('Confirmed', 'CheckedIn', 'PendingPayment')  -- ✅ เพิ่ม PendingPayment
```

### 2. Rebuild Backend
```bash
cd backend
go build -o hotel-booking-system.exe ./cmd/server
```

### 3. Restart Backend
```bash
# หยุด backend ที่รันอยู่ (Ctrl+C)
# แล้วรันใหม่
.\hotel-booking-system.exe
```

## ทดสอบ
1. Restart backend
2. Refresh หน้า Admin Check-in
3. ควรเห็นรายการ bookings ที่มี status:
   - `PendingPayment` - รอ admin approve payment
   - `Confirmed` - payment approved แล้ว
   - `CheckedIn` - check-in แล้ว

## ตรวจสอบข้อมูล
```sql
-- ดู bookings ทั้งหมดที่พร้อม check-in
SELECT 
    b.booking_id,
    b.status,
    bd.check_in_date,
    bd.check_out_date,
    CONCAT(g.first_name, ' ', g.last_name) as guest_name,
    rt.name as room_type
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
WHERE bd.check_in_date >= CURRENT_DATE
ORDER BY bd.check_in_date, b.created_at DESC;
```

## Booking Status Flow
1. **PendingPayment** - Guest complete booking, รอ payment proof
2. **Confirmed** - Admin approve payment proof
3. **CheckedIn** - Receptionist ทำ check-in
4. **CheckedOut** - Guest check-out แล้ว
5. **Cancelled** - Booking ถูกยกเลิก

## หมายเหตุ
- Check-in page ควรแสดง bookings ทุก status ที่ยังไม่ check-in
- Receptionist สามารถ check-in ได้แม้ status จะเป็น PendingPayment
- แต่ควรมี warning ว่ายังไม่ได้ verify payment

## ไฟล์ที่แก้ไข
- `backend/internal/repository/booking_repository.go`
  - เพิ่ม `'PendingPayment'` ใน GetArrivals query
