# แก้ไขปัญหาข้อมูล Guest และ Payment Status

## ปัญหาที่พบ

### 1. สถานะการชำระเงินไม่ตรงกัน
- **admin/checkin** แสดง "ยังไม่ชำระ" 
- **admin/reception** แสดง "ยืนยันแล้ว"
- ทั้งที่ booking status = "Confirmed" หมายความว่าชำระเงินแล้ว

### 2. ข้อมูล Guest ไม่ถูกต้อง
- แสดงข้อมูล mock: "Fon Testuser, fon.test@example.com, 0867890006"
- แทนที่จะใช้ข้อมูลจาก guest account ที่ sign in อยู่

## การแก้ไข

### 1. แก้ Payment Status Logic (backend/internal/repository/booking_repository.go)

```sql
-- เพิ่ม CASE statement ใน GetArrivals query
CASE 
    WHEN b.status IN ('Confirmed', 'CheckedIn', 'Completed') THEN 'approved'
    WHEN pp.status IS NOT NULL THEN pp.status
    ELSE 'none'
END as payment_status
```

**เหตุผล**: ถ้า booking status เป็น Confirmed/CheckedIn/Completed แสดงว่าชำระเงินแล้ว (ผ่าน confirm_booking function)

### 2. แก้ Guest Data Logic (backend/internal/service/booking_service.go)

```go
if guest.IsPrimary && guestAccount != nil {
    // For signed-in users: ALWAYS use account data (override any form data)
    phone = &guestAccount.Phone
    email = &guestAccount.Email
    firstName = guestAccount.FirstName
    lastName = guestAccount.LastName
    
    fmt.Printf("[CreateBooking] Using guest account data for primary guest: %s %s, email: %s, phone: %s\n", 
        firstName, lastName, *email, *phone)
}
```

**เหตุผล**: สำหรับ signed-in users ต้องใช้ข้อมูลจาก guest account เสมอ ไม่ใช้ข้อมูลจากฟอร์ม

## ผลลัพธ์ที่คาดหวัง

### 1. Payment Status
- ✅ admin/checkin แสดง "approved" สำหรับ booking ที่ Confirmed
- ✅ admin/reception แสดง "ยืนยันแล้ว"
- ✅ สถานะตรงกันทั้ง 2 หน้า

### 2. Guest Data
- ✅ แสดงชื่อจริงจาก guest account
- ✅ แสดงอีเมลจาก guest account
- ✅ แสดงเบอร์โทรจาก guest account
- ✅ ไม่มีข้อมูล mock (Fon Testuser) อีกต่อไป

## การทดสอบ

### ขั้นตอนที่ 1: สร้าง Booking ใหม่
1. Sign in ด้วย guest account (เช่น john.doe@example.com)
2. ค้นหาห้องและเลือกห้อง
3. กรอกข้อมูล guest (ระบบจะใช้ข้อมูลจาก account)
4. Complete booking

### ขั้นตอนที่ 2: ตรวจสอบ admin/reception
1. เข้า admin/reception
2. ไปที่แท็บ "จัดการการจอง"
3. ตรวจสอบว่า booking ใหม่แสดง:
   - ชื่อจริงจาก guest account
   - อีเมลจาก guest account
   - เบอร์โทรจาก guest account
   - สถานะ "ยืนยันแล้ว"

### ขั้นตอนที่ 3: ตรวจสอบ admin/checkin
1. เข้า admin/checkin
2. เลือกวันที่ check-in
3. ตรวจสอบว่า booking แสดง:
   - ชื่อจริงจาก guest account
   - สถานะการชำระ "approved" (ไม่ใช่ "ยังไม่ชำระ")

## ไฟล์ที่แก้ไข

1. `backend/internal/repository/booking_repository.go` - แก้ GetArrivals query
2. `backend/internal/service/booking_service.go` - แก้ CreateBooking logic

## คำสั่งรัน

```bash
# Windows
test-guest-data-fix.bat

# หรือ manual
cd backend
go build -o hotel-booking-server.exe ./cmd/server
taskkill /F /IM hotel-booking-server.exe
start hotel-booking-server.exe
```

## หมายเหตุ

- Booking เก่าที่มีข้อมูล mock จะยังคงแสดงข้อมูลเก่า
- Booking ใหม่ที่สร้างหลังจากแก้ไขจะใช้ข้อมูลจาก guest account
- ถ้าต้องการแก้ booking เก่า ต้อง update database โดยตรง
