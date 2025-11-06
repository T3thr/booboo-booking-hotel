# แก้ไข Guest Booking 401 Error - คำแนะนำ

## ปัญหา
Guest ที่ไม่ได้ signin ไม่สามารถสร้างการจองได้ เกิด error 401:
```
POST /api/bookings 401
{"code":"AUTH_REQUIRED","error":"Unauthorized","message":"ไม่พบข้อมูลการยืนยันตัวตน"}
```

## สาเหตุ
Backend อาจยังไม่ได้ rebuild หลังจากแก้ไข router configuration

## การแก้ไข

### วิธีที่ 1: Rebuild Backend (แนะนำ)
```bash
fix-guest-booking-401.bat
```

### วิธีที่ 2: Manual Rebuild
```bash
# 1. Stop backend
taskkill /F /IM main.exe

# 2. Go to backend directory
cd backend

# 3. Clean old build
del main.exe

# 4. Rebuild
go build -o main.exe ./cmd/server

# 5. Start backend
start cmd /k "main.exe"
```

## การตรวจสอบ

### 1. ตรวจสอบ Router Configuration
**ไฟล์:** `backend/internal/router/router.go`

```go
// Booking routes
bookings := api.Group("/bookings")
bookings.Use(middleware.BookingRateLimiter.Middleware())
{
    // Public endpoints
    bookings.POST("/hold", bookingHandler.CreateBookingHold)
    bookings.GET("/search", bookingHandler.SearchBookingsByPhone)
    
    // Optional auth endpoints - ✅ ต้องใช้ OptionalAuth
    optionalAuth := bookings.Group("")
    optionalAuth.Use(middleware.OptionalAuth(cfg.JWT.Secret))
    {
        optionalAuth.POST("/", bookingHandler.CreateBooking)  // ✅ ไม่บังคับ auth
        optionalAuth.POST("/:id/confirm", bookingHandler.ConfirmBooking)
    }
}
```

### 2. ตรวจสอบ OptionalAuth Middleware
**ไฟล์:** `backend/internal/middleware/auth.go`

```go
// OptionalAuth middleware - validates token if present but doesn't require it
func OptionalAuth(jwtSecret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.Next()  // ✅ ไม่มี header ก็ผ่าน
            return
        }

        // Validate token if present
        parts := strings.Split(authHeader, " ")
        if len(parts) == 2 && parts[0] == "Bearer" {
            claims, err := utils.ValidateToken(parts[1], jwtSecret)
            if err == nil {
                c.Set("user_id", claims.UserID)
                c.Set("user_email", claims.Email)
                c.Set("user_role", claims.Role)
                c.Set("user_type", claims.UserType)
            }
        }

        c.Next()  // ✅ ผ่านไม่ว่าจะมี token หรือไม่
    }
}
```

### 3. ตรวจสอบ Handler
**ไฟล์:** `backend/internal/handlers/booking_handler.go`

```go
// CreateBooking handles POST /api/bookings
// Works with or without authentication (guest booking)
func (h *BookingHandler) CreateBooking(c *gin.Context) {
    var req models.CreateBookingRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Get guest ID from context if authenticated (optional)
    var guestID int
    if userID, exists := c.Get("user_id"); exists {
        guestID = userID.(int)  // ✅ มี auth ก็ใช้
    }
    // ✅ ไม่มี auth ก็ guestID = 0 (ยังทำงานได้)

    response, err := h.bookingService.CreateBooking(c.Request.Context(), guestID, &req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, response)
}
```

### 4. ตรวจสอบ Frontend
**ไฟล์:** `frontend/src/app/api/bookings/route.ts`

```typescript
export async function POST(request: NextRequest) {
  const session = await auth();
  
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };

  // Only add Authorization header if we have a valid session
  if (session?.accessToken) {
    headers['Authorization'] = `Bearer ${session.accessToken}`;
    console.log('[Bookings Proxy] Adding auth token');
  } else {
    console.log('[Bookings Proxy] No auth token - guest booking');
    // ✅ ไม่ส่ง Authorization header
  }

  const response = await fetch(backendUrl, {
    method: 'POST',
    headers,  // ✅ ไม่มี Authorization header สำหรับ guest
    body: JSON.stringify(body),
  });
}
```

## การทดสอบ

### Test 1: Guest Booking (ไม่ signin)
```bash
1. เปิด http://localhost:3000
2. ไม่ต้อง signin
3. ค้นหาห้อง
4. เลือกห้อง → Book
5. กรอกข้อมูล guest
6. Continue to Payment
7. Upload payment proof
8. Complete booking

Expected:
✅ ไม่เกิด error 401
✅ สร้างการจองสำเร็จ
✅ Redirect to confirmation page
```

### Test 2: Authenticated Booking (signin)
```bash
1. เปิด http://localhost:3000
2. Sign in
3. ค้นหาห้อง
4. เลือกห้อง → Book
5. กรอกข้อมูล guest
6. Continue to Payment
7. Upload payment proof
8. Complete booking

Expected:
✅ ไม่เกิด error
✅ สร้างการจองสำเร็จ
✅ การจองเชื่อมโยงกับ account
```

### Test 3: Backend Logs
```bash
# ดู backend logs เมื่อ guest booking
[POST] 200 | xxx ms | ::1 | /api/bookings

# ไม่ควรเห็น:
[POST] 401 | xxx ms | ::1 | /api/bookings
```

## Debug Steps

### ถ้ายังเกิด 401 อยู่:

#### 1. ตรวจสอบ Backend Version
```bash
# ดูว่า backend rebuild แล้วหรือยัง
cd backend
go version
go build -o main.exe ./cmd/server

# ดู timestamp ของ main.exe
dir main.exe
```

#### 2. ตรวจสอบ Backend Logs
```bash
# ดู console ของ backend
# ควรเห็น:
[Middleware] OptionalAuth: No auth header, allowing
[Handler] CreateBooking: guestID = 0 (guest booking)
```

#### 3. ตรวจสอบ Frontend Logs
```bash
# เปิด DevTools → Console
# ควรเห็น:
[Bookings Proxy] Session: Guest
[Bookings Proxy] No auth token - guest booking
[Bookings Proxy] Calling backend: http://localhost:8080/api/bookings
```

#### 4. ตรวจสอบ Network Tab
```bash
# เปิด DevTools → Network → POST /api/bookings
# Headers ควรเป็น:
Content-Type: application/json
# ไม่ควรมี:
Authorization: Bearer xxx
```

#### 5. Test Direct Backend Call
```bash
# Test โดยตรงกับ backend
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test_123",
    "details": [{
      "room_type_id": 1,
      "rate_plan_id": 1,
      "check_in": "2025-11-10",
      "check_out": "2025-11-12",
      "num_guests": 1,
      "guests": [{
        "first_name": "Test",
        "last_name": "User",
        "phone": "0812345678",
        "type": "Adult",
        "is_primary": true
      }]
    }]
  }'

# Expected: 201 Created (ไม่ใช่ 401)
```

## สาเหตุที่เป็นไปได้

### 1. Backend ไม่ได้ Rebuild
**แก้ไข:** รัน `fix-guest-booking-401.bat`

### 2. Cache ของ Go Build
**แก้ไข:**
```bash
cd backend
go clean -cache
go build -o main.exe ./cmd/server
```

### 3. Wrong Backend URL
**ตรวจสอบ:** `frontend/.env`
```
BACKEND_URL=http://localhost:8080
NEXT_PUBLIC_API_URL=http://localhost:8080
```

### 4. Middleware Order ผิด
**ตรวจสอบ:** `backend/internal/router/router.go`
```go
// ✅ ถูกต้อง
optionalAuth := bookings.Group("")
optionalAuth.Use(middleware.OptionalAuth(cfg.JWT.Secret))
{
    optionalAuth.POST("/", bookingHandler.CreateBooking)
}

// ❌ ผิด
bookings.Use(middleware.AuthMiddleware(cfg.JWT.Secret))  // บังคับ auth!
bookings.POST("/", bookingHandler.CreateBooking)
```

### 5. Frontend ส่ง Empty Token
**ตรวจสอบ:** Network tab
```
# ❌ ผิด
Authorization: Bearer 

# ✅ ถูกต้อง (ไม่มี header เลย)
(no Authorization header)
```

## สถานะ
⚠️ **ต้อง Rebuild Backend** - รัน `fix-guest-booking-401.bat`

หลังจาก rebuild:
✅ Guest สามารถจองได้โดยไม่ต้อง signin
✅ Authenticated user ยังจองได้ตามปกติ
✅ ไม่เกิด error 401
