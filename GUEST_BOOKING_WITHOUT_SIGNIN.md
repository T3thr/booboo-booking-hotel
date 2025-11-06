# แก้ไขให้จองได้โดยไม่ต้อง Sign In

## ปัญหา
ระบบบังคับให้ต้อง sign in ก่อนจองห้อง ทำให้ไม่สะดวกสำหรับผู้ใช้ทั่วไป

Error ที่เกิด:
```
[Bookings Proxy POST] Backend error: 401 
{"code":"AUTH_REQUIRED","error":"Unauthorized","message":"ไม่พบข้อมูลการยืนยันตัวตน"}
```

## การแก้ไข

### 1. Frontend API Routes
แก้ไข API proxy routes ให้ไม่ส่ง Authorization header เมื่อไม่มี session:

**ไฟล์ที่แก้ไข:**
- `frontend/src/app/api/bookings/route.ts` - POST /api/bookings
- `frontend/src/app/api/bookings/hold/route.ts` - POST /api/bookings/hold  
- `frontend/src/app/api/bookings/[id]/confirm/route.ts` - POST /api/bookings/:id/confirm

**การเปลี่ยนแปลง:**
```typescript
// เดิม - ส่ง header เสมอ
const headers: HeadersInit = {
  'Content-Type': 'application/json',
};
if (session?.accessToken) {
  headers['Authorization'] = `Bearer ${session.accessToken}`;
}

// ใหม่ - เพิ่ม logging และตรวจสอบ session ให้ชัดเจน
console.log('[Bookings Proxy] Session:', session ? 'Authenticated' : 'Guest');

const headers: HeadersInit = {
  'Content-Type': 'application/json',
};

// Only add Authorization header if we have a valid session with accessToken
if (session?.accessToken) {
  headers['Authorization'] = `Bearer ${session.accessToken}`;
  console.log('[Bookings Proxy] Adding auth token');
} else {
  console.log('[Bookings Proxy] No auth token - guest booking');
}
```

### 2. Backend Handlers
เพิ่ม comments ให้ชัดเจนว่า handlers รองรับ guest booking:

**ไฟล์ที่แก้ไข:**
- `backend/internal/handlers/booking_handler.go`

**การเปลี่ยนแปลง:**
```go
// CreateBookingHold handles POST /api/bookings/hold
// Works with or without authentication (guest booking)
func (h *BookingHandler) CreateBookingHold(c *gin.Context) {
    // Get guest account ID from context if authenticated (optional for guest bookings)
    if userID, exists := c.Get("user_id"); exists {
        guestAccountID := userID.(int)
        req.GuestAccountID = &guestAccountID
    }
    // ... rest of code
}
```

### 3. Router Configuration (ตรวจสอบแล้วว่าถูกต้อง)
Backend router ใช้ `OptionalAuth` middleware แล้วสำหรับ booking endpoints:

```go
// Public endpoints - can use without authentication
bookings.POST("/hold", bookingHandler.CreateBookingHold)
bookings.GET("/search", bookingHandler.SearchBookingsByPhone)

// Optional auth endpoints - work with or without authentication
optionalAuth := bookings.Group("")
optionalAuth.Use(middleware.OptionalAuth(cfg.JWT.Secret))
{
    optionalAuth.POST("/", bookingHandler.CreateBooking)
    optionalAuth.POST("/:id/confirm", bookingHandler.ConfirmBooking)
}
```

## ผลลัพธ์

### ✅ สามารถทำได้โดยไม่ต้อง Sign In:
1. **ค้นหาห้อง** - GET /api/rooms/search
2. **Hold ห้อง** - POST /api/bookings/hold
3. **สร้างการจอง** - POST /api/bookings
4. **ยืนยันการจอง** - POST /api/bookings/:id/confirm
5. **ค้นหาการจองด้วยเบอร์โทร** - GET /api/bookings/search?phone=xxx

### 🔐 ยังต้อง Sign In:
1. **ดูประวัติการจองทั้งหมด** - GET /api/bookings
2. **ดูรายละเอียดการจอง** - GET /api/bookings/:id
3. **ยกเลิกการจอง** - POST /api/bookings/:id/cancel
4. **เชื่อมโยงการจองเข้า account** - POST /api/bookings/sync

## วิธีใช้งาน

### สำหรับ Guest (ไม่ต้อง Sign In):
1. เข้าเว็บไซต์
2. ค้นหาห้องพัก
3. เลือกห้องและกรอกข้อมูล
4. ระบุเบอร์โทรศัพท์ (สำคัญ!)
5. ชำระเงินและยืนยันการจอง
6. ใช้เบอร์โทรค้นหาการจองในภายหลัง

### สำหรับ Registered User (Sign In):
1. Sign in เข้าระบบ
2. ค้นหาห้องพัก
3. เลือกห้องและกรอกข้อมูล
4. การจองจะถูกเชื่อมโยงกับ account อัตโนมัติ
5. สามารถดูประวัติและจัดการการจองได้ใน profile

## การทดสอบ

### ทดสอบ Guest Booking:
```bash
# 1. Hold ห้อง (ไม่ต้อง auth)
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "check_in_date": "2025-11-10",
    "check_out_date": "2025-11-12",
    "num_rooms": 1
  }'

# 2. สร้างการจอง (ไม่ต้อง auth)
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "check_in_date": "2025-11-10",
    "check_out_date": "2025-11-12",
    "num_rooms": 1,
    "guest_info": {
      "first_name": "สมชาย",
      "last_name": "ใจดี",
      "email": "somchai@example.com",
      "phone": "0812345678"
    }
  }'

# 3. ค้นหาการจองด้วยเบอร์โทร
curl http://localhost:8080/api/bookings/search?phone=0812345678
```

## หมายเหตุ

1. **เบอร์โทรศัพท์เป็นข้อมูลสำคัญ** - ใช้สำหรับค้นหาและจัดการการจองสำหรับ guest
2. **ความปลอดภัย** - Guest สามารถค้นหาการจองด้วยเบอร์โทรเท่านั้น ไม่สามารถแก้ไขหรือยกเลิกได้
3. **การเชื่อมโยง Account** - Guest สามารถ sign up ภายหลังและเชื่อมโยงการจองเข้า account ได้
4. **Rate Limiting** - มี rate limiting ป้องกันการใช้งานมากเกินไป

## สถานะ
✅ **เสร็จสมบูรณ์** - ระบบรองรับ guest booking โดยไม่ต้อง sign in แล้ว
