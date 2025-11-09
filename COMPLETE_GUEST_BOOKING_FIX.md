# แก้ไขระบบ Guest Account Booking - สมบูรณ์

## สถานะปัจจุบัน

### ✅ เสร็จแล้ว:
1. **Backend ใช้ Account Data** - แก้ไขแล้ว ต้อง RESTART
2. **Hold Indicator** - มีอยู่แล้วใน guest layout

### ⏳ ต้องทำ:
3. **Admin/Checkin แสดงสถานะ** - ต้องสร้าง API และแก้ไข UI

---

## ขั้นตอนที่ 1: RESTART BACKEND (⚠️ ทำทันที!)

```bash
# 1. Stop backend (Ctrl+C)
# 2. Run:
cd backend
./hotel-booking-api.exe
```

**ทดสอบ:**
1. Login ด้วย guest account
2. จองห้อง → Complete booking
3. ไปที่ `/admin/reception`
4. ตรวจสอบ: ชื่อ, email, phone ควรเป็นข้อมูลจาก account ✅

---

## ขั้นตอนที่ 2: สร้าง Arrivals API (Backend)

### 2.1 เพิ่ม Model
**ไฟล์:** `backend/internal/models/checkin.go`

```go
package models

type Arrival struct {
    BookingID       int     `json:"booking_id"`
    BookingDetailID int     `json:"booking_detail_id"`
    BookingStatus   string  `json:"booking_status"`   // PendingPayment, Confirmed
    PaymentStatus   string  `json:"payment_status"`   // pending, approved
    GuestName       string  `json:"guest_name"`
    GuestEmail      string  `json:"guest_email"`
    GuestPhone      string  `json:"guest_phone"`
    RoomTypeName    string  `json:"room_type_name"`
    CheckInDate     string  `json:"check_in_date"`
    CheckOutDate    string  `json:"check_out_date"`
    NumGuests       int     `json:"num_guests"`
    TotalAmount     float64 `json:"total_amount"`
}
```

### 2.2 เพิ่ม Repository Method
**ไฟล์:** `backend/internal/repository/booking_repository.go`

เพิ่ม method:
```go
// GetArrivals gets all bookings arriving on a specific date
func (r *BookingRepository) GetArrivals(ctx context.Context, date string) ([]models.Arrival, error) {
    query := `
        SELECT 
            b.booking_id,
            bd.booking_detail_id,
            b.status as booking_status,
            COALESCE(pp.status, 'pending') as payment_status,
            CONCAT(bg.first_name, ' ', bg.last_name) as guest_name,
            COALESCE(bg.email, '') as guest_email,
            COALESCE(bg.phone, '') as guest_phone,
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
        ORDER BY b.status DESC, b.booking_id
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
            &arrival.BookingDetailID,
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

### 2.3 เพิ่ม Service Method
**ไฟล์:** `backend/internal/service/booking_service.go`

เพิ่ม method:
```go
// GetArrivals gets all bookings arriving on a specific date
func (s *BookingService) GetArrivals(ctx context.Context, date string) ([]models.Arrival, error) {
    return s.bookingRepo.GetArrivals(ctx, date)
}
```

### 2.4 เพิ่ม Handler Method
**ไฟล์:** `backend/internal/handlers/checkin_handler.go`

เพิ่ม method:
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

    c.JSON(http.StatusOK, gin.H{"arrivals": arrivals})
}
```

### 2.5 เพิ่ม Route
**ไฟล์:** `backend/internal/router/router.go`

ค้นหา checkin routes และเพิ่ม:
```go
checkinRoutes := api.Group("/checkin")
checkinRoutes.Use(middleware.AuthMiddleware())
{
    checkinRoutes.GET("/arrivals", checkinHandler.GetArrivals)  // ✅ เพิ่มบรรทัดนี้
    checkinRoutes.POST("", checkinHandler.CheckIn)
    // ... existing routes
}
```

---

## ขั้นตอนที่ 3: แก้ไข Frontend Checkin Page

**ไฟล์:** `frontend/src/app/admin/(staff)/checkin/page.tsx`

### 3.1 เพิ่ม Interface
```typescript
interface Arrival {
  booking_id: number;
  booking_detail_id: number;
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
```

### 3.2 แสดงสถานะ
ใน table cell เพิ่ม:
```typescript
<td className="px-6 py-4">
  <div className="flex flex-col gap-1">
    {/* Booking Status */}
    {arrival.booking_status === 'PendingPayment' && (
      <span className="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">
        ⏳ ยังไม่ยืนยัน
      </span>
    )}
    {arrival.booking_status === 'Confirmed' && (
      <span className="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
        ✅ ยืนยันแล้ว
      </span>
    )}
    
    {/* Payment Status */}
    {arrival.payment_status === 'pending' && (
      <span className="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-orange-100 text-orange-800">
        💳 ยังไม่ชำระ
      </span>
    )}
    {arrival.payment_status === 'approved' && (
      <span className="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
        💰 ชำระเงินแล้ว
      </span>
    )}
  </div>
</td>
```

---

## Workflow ที่สมบูรณ์

```
Guest Account Login
    ↓
Search Rooms → Select Room
    ↓
Guest Info (auto-fill from account) ✅
    ↓
Create Hold → Status: PendingPayment
    ↓
[Hold Indicator แสดงที่มุมขวาล่าง] ✅
    ↓
Admin/Checkin แสดง: "⏳ ยังไม่ยืนยัน" + "💳 ยังไม่ชำระ"
    ↓
Complete Booking → Status: Confirmed
    ↓
Admin/Checkin แสดง: "✅ ยืนยันแล้ว" + "💳 ยังไม่ชำระ"
    ↓
Admin/Reception → Approve Payment
    ↓
Admin/Checkin แสดง: "✅ ยืนยันแล้ว" + "💰 ชำระเงินแล้ว"
    ↓
Receptionist Check-in → Status: CheckedIn
```

---

## สรุปสิ่งที่ต้องทำ

### ✅ เสร็จแล้ว:
1. Backend ใช้ account data เสมอ
2. Hold indicator มีอยู่แล้ว

### ⏳ ต้องทำต่อ:
3. สร้าง Arrivals API (Backend)
   - เพิ่ม Model
   - เพิ่ม Repository method
   - เพิ่ม Service method
   - เพิ่ม Handler method
   - เพิ่ม Route
   - Rebuild backend

4. แก้ไข Checkin Page (Frontend)
   - เพิ่ม interface
   - แสดงสถานะ booking
   - แสดงสถานะ payment

---

## ขั้นตอนการทำ

1. **RESTART Backend** (ทำทันที!)
2. **ทดสอบ Guest Account Booking** → ควรแสดงข้อมูลถูกต้องแล้ว
3. **สร้าง Arrivals API** (Backend)
4. **Rebuild Backend**
5. **แก้ไข Checkin Page** (Frontend)
6. **ทดสอบสถานะทั้งหมด**

---

## หมายเหตุ

- Frontend ส่งข้อมูลถูกต้องแล้ว ✅
- Backend บันทึกข้อมูลถูกต้องแล้ว ✅
- Hold Indicator มีอยู่แล้ว ✅
- ต้องสร้าง Arrivals API เพื่อแสดงสถานะ ⏳
