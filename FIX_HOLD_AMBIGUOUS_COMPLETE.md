# Fix Hold Ambiguous Error - Complete ✅

## สรุปการแก้ไข

แก้ไข error "column reference 'hold_expiry' is ambiguous" ที่เกิดขึ้นเมื่อกดจองห้องใน room search page

## ปัญหาที่พบ

```
Error: column reference "hold_expiry" is ambiguous
Status: 400 Bad Request
Endpoint: POST /api/bookings/hold
```

## สาเหตุ

PostgreSQL function `create_booking_hold` return column ชื่อ `hold_expiry` ซ้ำกับ column `hold_expiry` ใน table `booking_holds` ทำให้เกิด ambiguous error

## การแก้ไข

### 1. SQL Function (database/migrations/005_create_booking_hold_function.sql)
- เปลี่ยน return column จาก `hold_expiry` → `expiry_time`
- แก้ไขทุกจุดที่ return column นี้

### 2. Backend Repository (backend/internal/repository/booking_repository.go)
- เปลี่ยน query: `SELECT success, message, expiry_time FROM create_booking_hold(...)`
- เปลี่ยน variable: `holdExpiry` → `expiryTime`

### 3. Migration Script (backend/scripts/fix-hold-function.go)
- สร้าง Go script เพื่อ run migration กับ Neon PostgreSQL

## ผลการทดสอบ

### API Test
```bash
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{"session_id":"test-session-123","room_type_id":1,"check_in":"2025-11-06","check_out":"2025-11-07"}'
```

**Response:**
```json
{
  "hold_id": 0,
  "success": true,
  "message": "สร้าง hold สำเร็จสำหรับ Standard Room (1 คืน) หมดอายุเวลา 14:22:50",
  "hold_expiry": "2025-11-05T14:22:50.157909Z"
}
```

### Backend Logs
```
[POST] 200 | 100.6264ms | ::1 | /api/bookings/hold  ✅
```

เปลี่ยนจาก 400 Bad Request เป็น 200 OK

## ไฟล์ที่แก้ไข

1. ✅ `database/migrations/005_create_booking_hold_function.sql`
2. ✅ `backend/internal/repository/booking_repository.go`
3. ✅ `backend/scripts/fix-hold-function.go` (ใหม่)
4. ✅ `fix-hold-error-now.bat` (ใหม่)
5. ✅ `test-booking-hold-fixed.bat` (ใหม่)

## วิธีใช้งาน

### แก้ไขอัตโนมัติ
```bash
fix-hold-error-now.bat
```

### แก้ไขทีละขั้นตอน
```bash
# 1. Run migration
cd backend/scripts
go run fix-hold-function.go

# 2. Rebuild backend
cd ..
go build -o bin/server.exe cmd/server/main.go

# 3. Restart backend
taskkill /F /IM server.exe
bin\server.exe
```

### ทดสอบ
```bash
test-booking-hold-fixed.bat
```

## สถานะ

✅ **FIXED AND TESTED**

- Ambiguous error แก้ไขแล้ว
- API ทำงานได้ปกติ (200 OK)
- Frontend สามารถจองห้องได้
- Countdown timer แสดงผลถูกต้อง
- Backend logs ไม่มี error

## หมายเหตุ

- Model `CreateBookingHoldResponse` ยังคงใช้ `HoldExpiry` เหมือนเดิม (ไม่ต้องแก้)
- เปลี่ยนแค่ชื่อ column ที่ return จาก SQL function
- ไม่กระทบกับ table schema หรือ code อื่นๆ
- Compatible กับ frontend ที่มีอยู่

---

**Fixed Date:** November 5, 2025  
**Status:** ✅ Complete  
**Tested:** ✅ API + Frontend
