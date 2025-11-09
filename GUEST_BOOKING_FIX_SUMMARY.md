# สรุปการแก้ไขระบบ Booking สำหรับ Guest

## ปัญหาที่แก้ไข

### 1. ✅ Redirect ไปหน้า Confirmation หลัง Complete Booking
**ปัญหา:** Guest ไม่ถูก redirect ไปหน้า `/booking/confirmation/[id]` หลังจอง สำเร็จ

**การแก้ไข:**
- อัพเดท `frontend/src/app/(guest)/booking/summary/page.tsx`
- เพิ่ม logic เพื่อ mark booking เป็น viewable once สำหรับ non-signed-in users
- ใช้ `sessionStorage` เพื่อติดตามการเข้าดูครั้งแรก
- Redirect ไป `/booking/confirmation/${bookingId}` หลังจาก confirm สำเร็จ

### 2. ✅ จำกัดการเข้าดูหน้า Confirmation ครั้งเดียวสำหรับ Non-Signed-In Guest
**ปัญหา:** Guest ที่ไม่ได้ sign in สามารถเข้าดูหน้า confirmation ได้หลายครั้ง

**การแก้ไข:**
- อัพเดท `frontend/src/app/(guest)/booking/confirmation/[id]/page.tsx`
- เพิ่ม logic ตรวจสอบ `sessionStorage` key: `booking_${bookingId}_viewed`
- ครั้งแรกที่เข้า: mark เป็น `true` และแสดงหน้า
- ครั้งถัดไป: แสดงหน้า "Access Denied" และ redirect ไปหน้าหลัก
- สำหรับ signed-in users: สามารถเข้าดูได้ตลอด (ต้อง verify phone number ตรงกับ booking)

### 3. ✅ เพิ่ม Email Field และแก้ไขข้อมูลผู้จอง
**ปัญหา:** 
- ไม่มี email field สำหรับ guest ที่ไม่ได้ sign in
- ข้อมูลผู้จองใน admin panel ไม่ถูกต้อง (แสดงข้อมูลปลอม)

**การแก้ไข:**

#### Frontend Changes:
1. **guest-info page** (`frontend/src/app/(guest)/booking/guest-info/page.tsx`):
   - เพิ่ม `email` field ใน `GuestInfo` interface
   - แสดง email input สำหรับ primary guest (guest แรก) เมื่อไม่ได้ sign in
   - เพิ่ม validation สำหรับ email
   - สำหรับ signed-in users: ใช้ข้อมูลจาก account (name, email, phone)

2. **Admin Bookings API** (`frontend/src/app/api/admin/bookings/route.ts`):
   - ใช้ CTE (Common Table Expression) เพื่อดึงข้อมูล primary guest จาก `booking_guests`
   - Logic: ถ้า signed in ใช้ข้อมูลจาก `guests` table, ถ้าไม่ใช้ข้อมูลจาก `booking_guests` table
   - เพิ่ม `email` field ใน booking_guests aggregation

#### Backend Changes:
1. **Database Migration** (`database/migrations/021_add_email_phone_to_booking_guests.sql`):
   - เพิ่ม `phone` column (VARCHAR(20))
   - เพิ่ม `email` column (VARCHAR(255))
   - เพิ่ม indexes สำหรับ phone และ email lookups

2. **Models** (`backend/internal/models/booking.go`):
   - เพิ่ม `Email *string` ใน `BookingGuest` struct
   - เพิ่ม `Email *string` ใน `CreateGuestRequest` struct

3. **Service** (`backend/internal/service/booking_service.go`):
   - อัพเดท guest creation เพื่อรวม email field

4. **Repository** (`backend/internal/repository/booking_repository.go`):
   - อัพเดท `CreateBookingGuest` function เพื่อ insert email

## ไฟล์ที่แก้ไข

### Frontend:
1. `frontend/src/app/(guest)/booking/guest-info/page.tsx` - เพิ่ม email field และ validation
2. `frontend/src/app/(guest)/booking/summary/page.tsx` - เพิ่ม redirect logic
3. `frontend/src/app/(guest)/booking/confirmation/[id]/page.tsx` - เพิ่ม one-time access control
4. `frontend/src/app/api/admin/bookings/route.ts` - แก้ไข query เพื่อใช้ข้อมูลจาก booking_guests
5. `frontend/src/app/admin/(staff)/reception/components/BookingManagementTab.tsx` - เพิ่ม email ใน interface

### Backend:
1. `backend/internal/models/booking.go` - เพิ่ม email field
2. `backend/internal/service/booking_service.go` - อัพเดท guest creation
3. `backend/internal/repository/booking_repository.go` - อัพเดท insert query

### Database:
1. `database/migrations/021_add_email_phone_to_booking_guests.sql` - Migration ใหม่
2. `database/migrations/run_migration_021.bat` - Script สำหรับรัน migration

## วิธีการ Deploy

### 1. รัน Database Migration:
```bash
cd database/migrations
run_migration_021.bat
```

หรือใช้ psql โดยตรง:
```bash
psql -h localhost -p 5432 -U hotel_admin -d hotel_db -f database/migrations/021_add_email_phone_to_booking_guests.sql
```

### 2. Rebuild Backend:
```bash
cd backend
go build -o hotel-booking-api.exe ./cmd/server
```

### 3. Restart Services:
```bash
# Backend
cd backend
hotel-booking-api.exe

# Frontend (ถ้าใช้ dev mode)
cd frontend
npm run dev
```

## การทดสอบ

### Test Case 1: Guest ไม่ได้ Sign In
1. ค้นหาห้องพัก
2. กรอกข้อมูล guest (ต้องกรอก email สำหรับ guest แรก)
3. Complete booking
4. ✅ ควร redirect ไปหน้า confirmation
5. ✅ ลองกด back แล้วเข้าหน้า confirmation อีกครั้ง → ควรถูกปฏิเสธ
6. ✅ ตรวจสอบใน admin panel → ควรเห็นชื่อ, email, และเบอร์โทรที่กรอกจริง

### Test Case 2: Guest ที่ Sign In แล้ว
1. Sign in ก่อน
2. ค้นหาห้องพัก
3. กรอกข้อมูล guest (ไม่ต้องกรอก email)
4. Complete booking
5. ✅ ควร redirect ไปหน้า confirmation
6. ✅ สามารถเข้าดูหน้า confirmation ได้หลายครั้ง
7. ✅ ตรวจสอบใน admin panel → ควรเห็นข้อมูลจาก guest account

### Test Case 3: Admin Panel
1. เข้า admin/reception
2. ไปที่แท็บ "จัดการการจอง"
3. ✅ ควรเห็นข้อมูลผู้จองที่ถูกต้อง:
   - สำหรับ signed-in: ข้อมูลจาก guest account
   - สำหรับ non-signed-in: ข้อมูลจาก booking_guests (primary guest)

## หมายเหตุ

- Email field เป็น **required** สำหรับ primary guest ที่ไม่ได้ sign in เท่านั้น
- Phone field เป็น **required** สำหรับ primary guest ทุกคน
- One-time access ใช้ `sessionStorage` ดังนั้นจะ reset เมื่อปิด browser tab
- สำหรับ production ควรพิจารณาใช้ server-side session หรือ token-based approach

## การแก้ไขเพิ่มเติม (Guest Account Support)

### ปัญหา:
Guest account ที่ sign in แล้วกลับส่งข้อมูลปลอมไปยัง admin panel

### การแก้ไข:

#### Frontend Changes:
1. **guest-info page**:
   - Phone field เป็น optional สำหรับ signed-in users
   - แสดง placeholder จาก account phone
   - ถ้าไม่กรอก จะใช้ phone จาก account
   - แสดง email field เป็น disabled สำหรับ signed-in users (ใช้จาก account)

2. **Auth Configuration** (`frontend/src/lib/auth.ts`):
   - เพิ่ม phone field ใน user object
   - เพิ่ม phone ใน JWT token
   - เพิ่ม phone ใน session

3. **Type Definitions** (`frontend/src/types/next-auth.d.ts`):
   - เพิ่ม phone field ใน JWT interface

#### Backend Changes:
1. **Models** (`backend/internal/models/guest.go`):
   - เพิ่ม Phone field ใน LoginResponse

2. **Service** (`backend/internal/service/auth_service.go`):
   - อัพเดท Login function เพื่อส่ง phone
   - อัพเดท Register function เพื่อส่ง phone

## ผลลัพธ์

✅ Guest สามารถเห็นหน้า confirmation หลังจองสำเร็จ
✅ Non-signed-in guest เข้าดูหน้า confirmation ได้ครั้งเดียว
✅ Admin เห็นข้อมูลผู้จองที่ถูกต้อง (ชื่อจริง, email จริง, เบอร์จริง)
✅ ระบบรองรับทั้ง signed-in และ non-signed-in guests
✅ Guest account ส่ง email และ phone จาก account ไปยัง admin
✅ Guest account สามารถ override phone ได้ถ้าต้องการ
