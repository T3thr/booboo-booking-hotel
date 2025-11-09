# TODO: แก้ไขระบบ Booking สำหรับ Guest Account

## ✅ สิ่งที่แก้ไขแล้ว

### 1. Backend - Guest Account Data (✅ เสร็จแล้ว)
**ไฟล์:** `backend/internal/service/booking_service.go`

**การแก้ไข:**
- เปลี่ยนจาก "ใช้ account data ถ้าไม่มีค่า" → "ใช้ account data เสมอ" สำหรับ signed-in users
- เพิ่มการตรวจสอบชื่อจำลอง (Fon, Testuser) และแทนที่ด้วยชื่อจริงจาก account
- เพิ่ม validation สำหรับ non-signed-in users ต้องมี phone และ email

**โค้ดที่แก้:**
```go
if guest.IsPrimary && guestAccount != nil {
    // For signed-in users: ALWAYS use account data
    phone = &guestAccount.Phone
    email = &guestAccount.Email
    // Also use account name if form name is empty or generic
    if firstName == "" || firstName == "Guest" || firstName == "Fon" {
        firstName = guestAccount.FirstName
    }
    if lastName == "" || lastName == "Testuser" {
        lastName = guestAccount.LastName
    }
}
```

## ⏳ สิ่งที่ต้องทำต่อ

### 2. Backend - Arrivals API (❌ ยังไม่มี)

**ปัญหา:** Backend ยังไม่มี `/api/checkin/arrivals` endpoint

**ต้องสร้าง:**

#### 2.1 เพิ่ม Handler Method
**ไฟล์:** `backend/internal/handlers/checkin_handler.go`

```go
// GetArrivals handles GET /api/checkin/arrivals
func (h *CheckInHandler) GetArrivals(c *gin.Context) {
    date := c.Query("date")
    if date == "" {
        date = time.Now().Format("2006-01-02")
    }

    arrivals, err := h.bookingService.GetArrivals(c.Request.Context(), date)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, arrivals)
}
```

#### 2.2 เพิ่ม Service Method
**ไฟล์:** `backend/internal/service/booking_service.go`

```go
// GetArrivals gets all bookings arriving on a specific date
func (s *BookingService) GetArrivals(ctx context.Context, date string) ([]models.Arrival, error) {
    return s.bookingRepo.GetArrivals(ctx, date)
}
```

#### 2.3 เพิ่ม Repository Method
**ไฟล์:** `backend/internal/repository/booking_repository.go`

```go
// GetArrivals gets all bookings arriving on a specific date
func (r *BookingRepository) GetArrivals(ctx context.Context, date string) ([]models.Arrival, error) {
    query := `
        SELECT 
            b.booking_id,
            b.status as booking_status,
            COALESCE(pp.status, 'pending') as payment_status,
            CONCAT(bg.first_name, ' ', bg.last_name) as guest_name,
            bg.email as guest_email,
            bg.phone as guest_phone,
            rt.name as room_type_name,
            bd.check_in_date,
            bd.check_out_date,
            bd.num_guests,
            b.total_amount
        FROM bookings b
        JOIN booking_details bd ON b.booking_id = bd.booking_id
        JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id AND bg.is_primary = true
        JOIN room_types rt ON bd.room_type_id = rt.room_type_id
        LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
        WHERE bd.check_in_date = $1
          AND b.status IN ('PendingPayment', 'Confirmed')
        ORDER BY bd.check_in_date, b.booking_id
    `

    rows, err := r.db.Pool.Query(ctx, query, date)
    if err != nil {
        return nil, fmt.Errorf("failed to query arrivals: %w", err)
    }
    defer rows.Close()

    var arrivals []models.Arrival
    for rows.Next() {
        var arrival models.Arrival
        err := rows.Scan(
            &arrival.BookingID,
            &arrival.BookingStatus,
            &arrival.PaymentStatus,
            &arrival.GuestName,
            &arrival.GuestEmail,
            &arrival.GuestPhone,
            &arrival.RoomTypeName,
            &arrival.CheckInDate,
            &arrival.CheckOutDate,
            &arrival.NumGuests,
            &arrival.TotalAmount,
        )
        if err != nil {
            return nil, fmt.Errorf("failed to scan arrival: %w", err)
        }
        arrivals = append(arrivals, arrival)
    }

    return arrivals, nil
}
```

#### 2.4 เพิ่ม Model
**ไฟล์:** `backend/internal/models/checkin.go`

```go
type Arrival struct {
    BookingID     int     `json:"booking_id"`
    BookingStatus string  `json:"booking_status"` // PendingPayment, Confirmed
    PaymentStatus string  `json:"payment_status"` // pending, approved, rejected
    GuestName     string  `json:"guest_name"`
    GuestEmail    string  `json:"guest_email"`
    GuestPhone    string  `json:"guest_phone"`
    RoomTypeName  string  `json:"room_type_name"`
    CheckInDate   string  `json:"check_in_date"`
    CheckOutDate  string  `json:"check_out_date"`
    NumGuests     int     `json:"num_guests"`
    TotalAmount   float64 `json:"total_amount"`
}
```

#### 2.5 เพิ่ม Route
**ไฟล์:** `backend/internal/router/router.go`

```go
// Check-in routes
checkinRoutes := api.Group("/checkin")
checkinRoutes.Use(middleware.AuthMiddleware())
{
    checkinRoutes.GET("/arrivals", checkinHandler.GetArrivals)  // ✅ เพิ่มบรรทัดนี้
    checkinRoutes.POST("", checkinHandler.CheckIn)
    // ...
}
```

### 3. Frontend - แสดงสถานะใน Admin/Checkin (❌ ยังไม่แก้)

**ไฟล์:** `frontend/src/app/admin/(staff)/checkin/page.tsx`

**ต้องแก้:**

```typescript
// เพิ่ม interface
interface Arrival {
  booking_id: number;
  booking_status: 'PendingPayment' | 'Confirmed';  // ✅ เพิ่ม
  payment_status: 'pending' | 'approved';           // ✅ เพิ่ม
  guest_name: string;
  guest_email: string;
  guest_phone: string;
  room_type_name: string;
  check_in_date: string;
  check_out_date: string;
  num_guests: number;
  total_amount: number;
}

// แสดงสถานะ
<div className="flex gap-2">
  {/* Booking Status */}
  {arrival.booking_status === 'PendingPayment' && (
    <span className="px-2 py-1 text-xs rounded bg-yellow-100 text-yellow-800">
      ⏳ ยังไม่ยืนยัน
    </span>
  )}
  {arrival.booking_status === 'Confirmed' && (
    <span className="px-2 py-1 text-xs rounded bg-green-100 text-green-800">
      ✅ ยืนยันแล้ว
    </span>
  )}
  
  {/* Payment Status */}
  {arrival.payment_status === 'pending' && (
    <span className="px-2 py-1 text-xs rounded bg-orange-100 text-orange-800">
      💳 ยังไม่ชำระ
    </span>
  )}
  {arrival.payment_status === 'approved' && (
    <span className="px-2 py-1 text-xs rounded bg-green-100 text-green-800">
      💰 ชำระเงินแล้ว
    </span>
  )}
</div>
```

## ขั้นตอนการทำ

### Step 1: Rebuild Backend (✅ เสร็จแล้ว)
```bash
cd backend
go build -o hotel-booking-api.exe ./cmd/server
```

### Step 2: Restart Backend
```bash
# Stop backend (Ctrl+C)
cd backend
./hotel-booking-api.exe
```

### Step 3: ทดสอบ Guest Account Booking
```
1. Login ด้วย guest account
2. จองห้อง → ตรวจสอบว่าข้อมูล auto-fill ถูกต้อง
3. Complete booking
4. ไปที่ Admin/Reception → ตรวจสอบชื่อ, email, phone
   ✅ ควรแสดงข้อมูลจาก account แล้ว!
```

### Step 4: สร้าง Arrivals API (⏳ ต้องทำ)
```
1. เพิ่ม Model (Arrival struct)
2. เพิ่ม Repository method (GetArrivals)
3. เพิ่ม Service method (GetArrivals)
4. เพิ่ม Handler method (GetArrivals)
5. เพิ่ม Route
6. Rebuild backend
```

### Step 5: แก้ไข Frontend Checkin Page (⏳ ต้องทำ)
```
1. เพิ่ม interface Arrival
2. แสดงสถานะ booking_status
3. แสดงสถานะ payment_status
```

### Step 6: ทดสอบสถานะ
```
1. สร้าง hold (ยังไม่ complete)
   → Admin/Checkin ควรแสดง "⏳ ยังไม่ยืนยัน" + "💳 ยังไม่ชำระ"
   
2. Complete booking
   → Admin/Checkin ควรแสดง "✅ ยืนยันแล้ว" + "💳 ยังไม่ชำระ"
   
3. Admin/Reception → Approve
   → Admin/Checkin ควรแสดง "✅ ยืนยันแล้ว" + "💰 ชำระเงินแล้ว"
```

## สรุป

### ✅ เสร็จแล้ว:
1. Backend ใช้ account data สำหรับ signed-in users

### ⏳ ต้องทำต่อ:
2. สร้าง Arrivals API ใน backend
3. แสดงสถานะใน frontend checkin page

### 🎯 เป้าหมาย:
- Guest account booking แสดงข้อมูลถูกต้อง ✅
- แสดงสถานะ hold/confirmed ใน checkin ⏳
- แสดงสถานะชำระเงิน ⏳
