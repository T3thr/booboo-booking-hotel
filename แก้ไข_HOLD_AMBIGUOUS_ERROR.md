# แก้ไข Hold Ambiguous Error ✅

## ปัญหา
เมื่อกดจองห้องใน `rooms/search/page.tsx` เกิด error:
```
column reference "hold_expiry" is ambiguous
```

Backend logs แสดง:
```
[POST] 400 | /api/bookings/hold
```

## สาเหตุ
PostgreSQL function `create_booking_hold` มี return column ชื่อ `hold_expiry` ซึ่งซ้ำกับ column `hold_expiry` ใน table `booking_holds` ทำให้เกิด ambiguous error เมื่อ PostgreSQL พยายาม resolve column name

## การแก้ไข

### 1. แก้ไข SQL Function (database/migrations/005_create_booking_hold_function.sql)

เปลี่ยนชื่อ return column จาก `hold_expiry` เป็น `expiry_time`:

```sql
-- เดิม
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    hold_expiry TIMESTAMP  -- ❌ ซ้ำกับ column ใน table
)

-- ใหม่
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    expiry_time TIMESTAMP  -- ✅ ไม่ซ้ำ
)
```

แก้ไขทุกจุดที่ return `hold_expiry` เป็น `expiry_time`:
- Error returns: `NULL::TIMESTAMP AS expiry_time`
- Success return: `v_hold_expiry AS expiry_time`

### 2. แก้ไข Backend Repository (backend/internal/repository/booking_repository.go)

เปลี่ยน query และ variable name:

```go
// เดิม
query := `
    SELECT * FROM create_booking_hold($1, $2, $3, $4::date, $5::date)
`
var holdExpiry *time.Time
.Scan(&success, &message, &holdExpiry)

// ใหม่
query := `
    SELECT success, message, expiry_time FROM create_booking_hold($1, $2, $3, $4::date, $5::date)
`
var expiryTime *time.Time
.Scan(&success, &message, &expiryTime)
```

## วิธีแก้ไข

รัน script:
```bash
fix-hold-ambiguous-error.bat
```

หรือทำทีละขั้นตอน:

### 1. Recreate Function
```bash
psql -U postgres -d hotel_booking -f database/migrations/005_create_booking_hold_function.sql
```

### 2. Rebuild Backend
```bash
cd backend
go build -o bin/server.exe cmd/server/main.go
```

### 3. Restart Backend
```bash
taskkill /F /IM server.exe
cd backend
bin\server.exe
```

## ทดสอบ

### ทดสอบผ่าน API
```bash
curl -X POST http://localhost:8080/api/bookings/hold ^
  -H "Content-Type: application/json" ^
  -d "{\"session_id\":\"test-session-123\",\"room_type_id\":1,\"check_in\":\"2025-11-06\",\"check_out\":\"2025-11-07\"}"
```

ผลลัพธ์ที่ถูกต้อง:
```json
{
  "hold_id": 0,
  "success": true,
  "message": "สร้าง hold สำเร็จสำหรับ Standard Room (1 คืน) หมดอายุเวลา 14:22:50",
  "hold_expiry": "2025-11-05T14:22:50.157909Z"
}
```

### ทดสอบผ่าน Frontend
1. เปิด http://localhost:3000/rooms/search
2. เลือกวันที่และจำนวนผู้เข้าพัก
3. กด "Search Rooms"
4. กดปุ่ม "Book Now" บนห้องที่ต้องการ
5. ควรเห็น countdown timer และไม่มี error

## ผลลัพธ์

✅ แก้ไข ambiguous column error
✅ Booking hold ทำงานได้ปกติ (200 OK แทน 400 Bad Request)
✅ Return expiry time ถูกต้อง
✅ Frontend แสดง countdown timer
✅ Backend logs ไม่มี error

## ไฟล์ที่แก้ไข

1. `database/migrations/005_create_booking_hold_function.sql` - เปลี่ยน return column name
2. `backend/internal/repository/booking_repository.go` - อัปเดต query และ variable
3. `fix-hold-ambiguous-error.bat` - script สำหรับแก้ไข

## หมายเหตุ

- Model `CreateBookingHoldResponse` ยังคงใช้ `HoldExpiry` เหมือนเดิม (ไม่ต้องแก้)
- เปลี่ยนแค่ชื่อ column ที่ return จาก function เท่านั้น
- ไม่กระทบกับ table `booking_holds` ที่มี column `hold_expiry`
