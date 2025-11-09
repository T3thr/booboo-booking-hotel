# คู่มือแก้ไขปัญหาข้อมูล Guest และ Payment Status แบบสมบูรณ์

## 🎯 ปัญหาที่แก้ไข

### ปัญหาที่ 1: สถานะการชำระเงินไม่ตรงกัน
- ❌ **admin/checkin** แสดง "ยังไม่ชำระ"
- ✅ **admin/reception** แสดง "ยืนยันแล้ว"
- **สาเหตุ**: GetArrivals API ไม่ได้ตรวจสอบ booking status

### ปัญหาที่ 2: ข้อมูล Guest ใช้ Mock Data
- ❌ แสดง "Fon Testuser, fon.test@example.com, 0867890006"
- ✅ ควรแสดงข้อมูลจาก guest account ที่ sign in
- **สาเหตุ**: CreateBooking ไม่ได้ใช้ข้อมูลจาก guest account อย่างถูกต้อง

## 🔧 การแก้ไข

### 1. แก้ Payment Status Logic

**ไฟล์**: `backend/internal/repository/booking_repository.go`

เพิ่ม CASE statement ใน GetArrivals query:

```sql
CASE 
    WHEN b.status IN ('Confirmed', 'CheckedIn', 'Completed') THEN 'approved'
    WHEN pp.status IS NOT NULL THEN pp.status
    ELSE 'none'
END as payment_status
```

### 2. แก้ Guest Data Logic

**ไฟล์**: `backend/internal/service/booking_service.go`

แก้ให้ใช้ข้อมูลจาก guest account เสมอ:

```go
if guest.IsPrimary && guestAccount != nil {
    // ALWAYS use account data for signed-in users
    phone = &guestAccount.Phone
    email = &guestAccount.Email
    firstName = guestAccount.FirstName
    lastName = guestAccount.LastName
}
```

### 3. แก้ Booking เก่าที่มี Mock Data

**ไฟล์**: `database/migrations/fix_mock_guest_data.sql`

SQL script ที่ update booking_guests table ให้ใช้ข้อมูลจาก guest account

## 📋 ขั้นตอนการแก้ไข

### Step 1: Rebuild Backend

```bash
# Windows
test-guest-data-fix.bat

# หรือ manual
cd backend
go build -o hotel-booking-server.exe ./cmd/server
taskkill /F /IM hotel-booking-server.exe
start hotel-booking-server.exe
```

### Step 2: แก้ไข Booking เก่า (Optional)

```bash
# Windows
cd database/migrations
run_fix_mock_guest_data.bat

# หรือ manual
psql -h localhost -U postgres -d hotel_booking -f fix_mock_guest_data.sql
```

## ✅ การทดสอบ

### Test 1: สร้าง Booking ใหม่

1. **Sign in** ด้วย guest account
   - Email: john.doe@example.com
   - Password: password123

2. **สร้าง booking**
   - ค้นหาห้อง
   - เลือกห้องและวันที่
   - กรอกข้อมูล guest
   - Complete booking

3. **ตรวจสอบ admin/reception**
   - ไปที่แท็บ "จัดการการจอง"
   - ดู booking ล่าสุด
   - ✅ ต้องแสดงชื่อ/อีเมล/เบอร์จาก guest account
   - ✅ สถานะ "ยืนยันแล้ว"

4. **ตรวจสอบ admin/checkin**
   - เลือกวันที่ check-in
   - ดู booking ล่าสุด
   - ✅ ต้องแสดงชื่อจาก guest account
   - ✅ สถานะการชำระ "approved"

### Test 2: ตรวจสอบ Booking เก่า (ถ้ารัน fix script)

1. **เข้า admin/reception**
   - ดู booking เก่าๆ
   - ✅ ต้องแสดงข้อมูลจาก guest account แล้ว
   - ✅ ไม่มี "Fon Testuser" อีกต่อไป

2. **เข้า admin/checkin**
   - ดู booking ที่ Confirmed
   - ✅ สถานะการชำระต้องเป็น "approved"

## 📊 ผลลัพธ์ที่คาดหวัง

### Payment Status
| หน้า | ก่อนแก้ไข | หลังแก้ไข |
|------|-----------|-----------|
| admin/reception | ยืนยันแล้ว | ยืนยันแล้ว ✅ |
| admin/checkin | ยังไม่ชำระ ❌ | approved ✅ |

### Guest Data
| ข้อมูล | ก่อนแก้ไข | หลังแก้ไข |
|--------|-----------|-----------|
| ชื่อ | Fon Testuser ❌ | John Doe ✅ |
| อีเมล | fon.test@example.com ❌ | john.doe@example.com ✅ |
| เบอร์ | 0867890006 ❌ | 0812345678 ✅ |

## 🔍 การตรวจสอบเพิ่มเติม

### ตรวจสอบ Database

```sql
-- ดู booking ล่าสุดพร้อมข้อมูล guest
SELECT 
    b.booking_id,
    b.status,
    CONCAT(g.first_name, ' ', g.last_name) as account_name,
    g.email as account_email,
    CONCAT(bg.first_name, ' ', bg.last_name) as booking_guest_name,
    bg.email as booking_guest_email,
    CASE 
        WHEN bg.first_name = g.first_name AND bg.email = g.email 
        THEN 'MATCHED ✓' 
        ELSE 'NOT MATCHED ✗' 
    END as status
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE bg.is_primary = true
ORDER BY b.booking_id DESC
LIMIT 10;
```

### ตรวจสอบ Backend Logs

```
[CreateBooking] Using guest account data for primary guest: John Doe, email: john.doe@example.com, phone: 0812345678
```

## 🚨 หมายเหตุสำคัญ

1. **Booking เก่า**: ถ้าไม่รัน fix script จะยังคงแสดงข้อมูล mock
2. **Booking ใหม่**: จะใช้ข้อมูลจาก guest account อัตโนมัติ
3. **Non-signed-in users**: จะใช้ข้อมูลจากฟอร์มตามปกติ
4. **Payment status**: จะแสดง "approved" สำหรับ booking ที่ Confirmed/CheckedIn/Completed

## 📁 ไฟล์ที่เกี่ยวข้อง

1. `backend/internal/repository/booking_repository.go` - GetArrivals query
2. `backend/internal/service/booking_service.go` - CreateBooking logic
3. `database/migrations/fix_mock_guest_data.sql` - Fix script สำหรับ booking เก่า
4. `test-guest-data-fix.bat` - Script สำหรับ rebuild backend
5. `GUEST_DATA_FIX_SUMMARY.md` - สรุปการแก้ไข

## 🎉 สรุป

หลังจากแก้ไขแล้ว:
- ✅ Payment status ตรงกันทั้ง admin/reception และ admin/checkin
- ✅ Guest data ใช้ข้อมูลจาก guest account สำหรับ signed-in users
- ✅ ไม่มีข้อมูล mock (Fon Testuser) ใน booking ใหม่
- ✅ Booking เก่าสามารถแก้ไขได้ด้วย SQL script
