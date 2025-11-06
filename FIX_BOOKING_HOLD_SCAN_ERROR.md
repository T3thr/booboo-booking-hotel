# ✅ แก้ไข Booking Hold Scan Error - สำเร็จ!

## ปัญหาที่พบ

Backend พยายาม scan ผลลัพธ์จาก PostgreSQL function `create_booking_hold` แต่ **column type ไม่ตรงกัน**:

### Error Message:
```
can't scan into dest[0]: cannot scan bool (OID 16) in binary format into **int
```

### สาเหตุ:

**Database Function Returns:**
```sql
RETURNS TABLE(
    success BOOLEAN,      -- Column 1
    message TEXT,         -- Column 2
    hold_expiry TIMESTAMP -- Column 3
)
```

**Backend Code พยายาม Scan เป็น (เดิม):**
```go
var holdID *int      // ❌ ผิด! Function ไม่ return hold_id
var success bool
var message string

.Scan(&holdID, &success, &message)  // ❌ ลำดับและ type ผิด
```

## การแก้ไข

แก้ไขใน `backend/internal/repository/booking_repository.go`:

```go
// CreateBookingHold calls the PostgreSQL function to create a booking hold
func (r *BookingRepository) CreateBookingHold(ctx context.Context, req *models.CreateBookingHoldRequest) (*models.CreateBookingHoldResponse, error) {
	query := `
		SELECT * FROM create_booking_hold($1, $2, $3, $4::date, $5::date)
	`

	// ✅ แก้ไข: Scan ตาม column ที่ function return จริงๆ
	var success bool
	var message string
	var holdExpiry *time.Time

	err := r.db.Pool.QueryRow(ctx, query,
		req.SessionID,
		req.GuestAccountID,
		req.RoomTypeID,
		req.CheckIn,
		req.CheckOut,
	).Scan(&success, &message, &holdExpiry)  // ✅ ลำดับและ type ถูกต้อง

	if err != nil {
		return nil, fmt.Errorf("failed to create booking hold: %w", err)
	}

	response := &models.CreateBookingHoldResponse{
		Success: success,
		Message: message,
	}

	if holdExpiry != nil {
		response.HoldExpiry = *holdExpiry
	}

	return response, nil
}
```

## สิ่งที่เปลี่ยนแปลง

1. ✅ **ลบ `holdID` variable** - Function ไม่ return hold_id
2. ✅ **เพิ่ม `holdExpiry` variable** - Scan hold_expiry timestamp จาก function
3. ✅ **แก้ไขลำดับ Scan** - ตรงกับ column ที่ function return: (success, message, hold_expiry)
4. ✅ **ใช้ holdExpiry จาก database** - แทนที่จะคำนวณเอง

## ทดสอบ

1. เปิด Frontend: `http://localhost:3000/rooms/search`
2. ค้นหาห้อง: วันที่ **2025-11-06 ถึง 2025-11-08**, ผู้เข้าพัก **1 คน**
3. กดปุ่ม **"จองห้องนี้"**
4. ระบบจะ:
   - ✅ เรียก API `/api/bookings/hold` สำเร็จ
   - ✅ สร้าง hold ใน database (tentative_count++)
   - ✅ Return hold_expiry timestamp จาก database
   - ✅ แสดงหน้า Guest Info พร้อม countdown timer

## Files ที่แก้ไข

- ✅ `backend/internal/repository/booking_repository.go` - แก้ไข `CreateBookingHold()`
- ✅ Rebuild backend: `go build -o hotel-booking-api.exe cmd/server/main.go`
- ✅ Restart backend server

---

**ระบบ Booking Hold ทำงานได้แล้ว!** 🎉

ตอนนี้ flow จะเป็น:
1. ✅ **สร้าง Hold** → tentative_count++ (15 นาที)
2. **กรอกข้อมูลแขก** → ไปหน้า Summary
3. **ยืนยันและชำระเงิน** → สร้าง Booking
4. **Confirm Booking** → tentative_count--, booked_count++
5. **แสดงหน้า Confirmation** ✅
