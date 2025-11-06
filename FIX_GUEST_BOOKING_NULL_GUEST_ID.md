# แก้ไข Guest Booking Error - NULL guest_id

## ปัญหา
เมื่อ guest ที่ไม่ได้ sign in พยายาม complete booking เกิด error:
```
ERROR: insert or update on table "bookings" violates foreign key constraint "bookings_guest_id_fkey" (SQLSTATE 23503)
```

## สาเหตุ
- ตาราง `bookings` มี column `guest_id` ที่ไม่อนุญาตให้เป็น NULL
- Guest booking ที่ไม่มี account จะส่ง `guest_id = 0` ซึ่งถูกแปลงเป็น NULL
- Foreign key constraint ไม่อนุญาตให้ NULL

## การแก้ไข

### 1. รัน Migration 020 ✅
```bash
cd database/migrations
.\run-migration-020.ps1
```

Migration นี้จะ:
- ทำให้ `guest_id` column เป็น nullable
- อนุญาตให้ guest booking ไม่ต้องมี guest account

### 2. ตรวจสอบว่า Migration สำเร็จ ✅
```bash
test-guest-booking-fix.bat
```

ผลลัพธ์:
```
column_name | is_nullable | data_type
guest_id    | YES         | integer

Migration 020 successful - guest_id can be NULL
```

### 3. Restart Backend
```bash
restart-backend-for-guest-booking.bat
```

หรือ manual:
```bash
cd backend
go run cmd/server/main.go
```

## การทำงานของ Code

### Backend Repository (booking_repository.go)
```go
// Convert guestID to *int for NULL support
var guestIDPtr *int
if guestID > 0 {
    guestIDPtr = &guestID
}
// ถ้า guestID = 0 จะใช้ NULL
```

### Backend Handler (booking_handler.go)
```go
// Get guest ID from context if authenticated (optional for guest bookings)
var guestID int
if userID, exists := c.Get("user_id"); exists {
    guestID = userID.(int)
}
// ถ้าไม่มี authentication guestID = 0
```

### Frontend Proxy (route.ts)
```typescript
// Only add Authorization header if we have a valid session
if (session?.accessToken) {
    headers['Authorization'] = `Bearer ${session.accessToken}`;
} else {
    console.log('[Bookings Proxy] No auth token - guest booking');
}
```

## ทดสอบ Guest Booking

1. เปิด browser ในโหมด incognito (ไม่ sign in)
2. ค้นหาห้องพัก
3. เลือกห้องและกรอกข้อมูล guest
4. กด "Complete Booking"
5. ควรสร้าง booking สำเร็จโดยไม่มี error

## สถานะ
✅ Migration 020 applied successfully
✅ Database schema updated (guest_id is nullable)
✅ Backend code supports NULL guest_id
✅ Frontend proxy handles guest bookings
⏳ Restart backend and test

## ขั้นตอนถัดไป
1. Restart backend server
2. ทดสอบ guest booking flow
3. ตรวจสอบว่า booking ถูกสร้างใน database โดยมี guest_id = NULL
