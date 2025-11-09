# แก้ไข Error 500 ใน Check-in Page

## ปัญหา

```
GET /api/checkin/arrivals?date=2025-11-09 500
```

## สาเหตุ

Query ใน `GetArrivals` ใช้ `JOIN guests` แต่บาง booking ไม่มี `guest_id` (NULL) เพราะเรา allow NULL แล้วใน migration 020

```sql
-- ❌ เดิม - ใช้ JOIN
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id  -- Error ถ้า guest_id = NULL
```

## การแก้ไข

เปลี่ยนเป็น `LEFT JOIN` และใช้ข้อมูลจาก `booking_guests` แทน:

```sql
-- ✅ ใหม่ - ใช้ LEFT JOIN + CTE
WITH primary_guest AS (
  SELECT DISTINCT ON (bd.booking_id)
    bd.booking_id,
    bg.first_name,
    bg.last_name
  FROM booking_details bd
  JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
  WHERE bg.is_primary = true
  ORDER BY bd.booking_id, bd.booking_detail_id
)
SELECT 
  ...
  COALESCE(
    CONCAT(g.first_name, ' ', g.last_name),  -- จาก guest account
    CONCAT(pg.first_name, ' ', pg.last_name), -- จาก booking_guests
    'Guest'  -- fallback
  ) as guest_name,
  ...
FROM bookings b
LEFT JOIN guests g ON b.guest_id = g.guest_id  -- ✅ LEFT JOIN
LEFT JOIN primary_guest pg ON b.booking_id = pg.booking_id
...
```

## ขั้นตอนแก้ไข

### 1. Stop Backend
```bash
# กด Ctrl+C
```

### 2. Rebuild Backend
```bash
cd backend
go build -o hotel-booking-api.exe ./cmd/server
```

### 3. Run Backend ใหม่
```bash
./hotel-booking-api.exe
# หรือ
go run cmd/server/main.go
```

### 4. ทดสอบ
```bash
# ไปที่ http://localhost:3000/admin/checkin
# ควรแสดงข้อมูลได้ปกติ ไม่มี error 500
```

## ผลลัพธ์

✅ Check-in page ทำงานได้ปกติ
✅ รองรับทั้ง booking ที่มีและไม่มี guest account
✅ แสดงชื่อจาก booking_guests ถ้าไม่มี guest account

## ไฟล์ที่แก้ไข

1. `backend/internal/repository/booking_repository.go`
   - แก้ GetArrivals query
   - เปลี่ยน JOIN เป็น LEFT JOIN
   - เพิ่ม CTE สำหรับ primary_guest
