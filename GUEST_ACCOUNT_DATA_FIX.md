# Guest Account Data Fix - Complete

## ปัญหาที่แก้ไข

### ปัญหา 1: แสดงข้อมูล Guest Account ผิด
**อาการ:** Admin/Reception แสดงข้อมูล "Fon Testuser" (ข้อมูลจาก guests table) แทนข้อมูลที่ guest กรอกตอน booking

**สาเหตุ:** Backend query ดึงข้อมูลจาก `guests` table (account table) แทน `booking_guests` table (ข้อมูลที่กรอกตอน booking)

**การแก้ไข:**
```sql
-- เดิม: ดึงจาก guests table (account)
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id

-- ใหม่: ดึงจาก booking_guests table (ข้อมูลที่กรอก)
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id 
  AND bg.is_primary = true
```

### ปัญหา 2: ไม่สามารถส่ง Payment Proof
**สถานะ:** ระบบยังไม่มีการ upload payment proof (จะทำในอนาคต)

**ทางแก้ชั่วคราว:** 
- แสดงข้อความ "⚠️ ยังไม่มีหลักฐานการโอนเงิน" เมื่อ `proof_url` เป็น empty
- Admin สามารถ Approve/Reject booking ได้โดยตรง

## การทำงานที่ถูกต้อง

### Guest Account Booking Flow

```
1. Guest Login → session มีข้อมูล: email, phone, name
2. Guest กรอกข้อมูลใน guest-info page
   - ถ้ากรอก: ใช้ข้อมูลที่กรอก
   - ถ้าไม่กรอก: ใช้ข้อมูลจาก account
3. ส่งไป backend → บันทึกใน booking_guests table
4. Admin ดูใน reception → แสดงข้อมูลจาก booking_guests (ข้อมูลที่กรอก)
```

### Non-Session Guest Booking Flow

```
1. Guest ไม่ login
2. กรอกข้อมูลทั้งหมดใน guest-info page (required)
3. ส่งไป backend → บันทึกใน booking_guests table
4. Admin ดูใน reception → แสดงข้อมูลจาก booking_guests
```

## Database Schema

### guests table (Account)
```sql
- guest_id (PK)
- email
- phone
- first_name
- last_name
- password_hash
```

### booking_guests table (Booking Info)
```sql
- booking_guest_id (PK)
- booking_detail_id (FK)
- first_name
- last_name
- email
- phone
- type (Adult/Child)
- is_primary (boolean)
```

## Files Modified

### Backend
**File:** `backend/internal/repository/payment_proof_repository.go`

**Change:**
```go
// เปลี่ยนจาก
JOIN guests g ON b.guest_id = g.guest_id
CONCAT(g.first_name, ' ', g.last_name) as guest_name,
g.email as guest_email,
g.phone as guest_phone,

// เป็น
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id 
  AND bg.is_primary = true
CONCAT(bg.first_name, ' ', bg.last_name) as guest_name,
bg.email as guest_email,
bg.phone as guest_phone,
```

## ผลลัพธ์

✅ Admin/Reception แสดงข้อมูลที่ guest กรอกจริง (จาก booking_guests)
✅ Guest account ใช้ข้อมูลจาก session ถ้าไม่กรอก
✅ Non-session guest ต้องกรอกข้อมูลทั้งหมด
✅ ข้อมูลถูกต้องทั้ง: ชื่อ, email, เบอร์โทร

## การทดสอบ

### Test Case 1: Guest Account Booking
1. Login as guest (fon.test@example.com)
2. จองห้อง → ไปที่ guest-info page
3. **ไม่กรอกอะไร** (ใช้ข้อมูลจาก account)
4. Complete booking
5. Login as Receptionist → ดูใน Reception → รอตรวจสอบการชำระเงิน
6. **ควรเห็น:** ข้อมูลจาก guest account (fon.test@example.com)

### Test Case 2: Guest Account with Custom Data
1. Login as guest
2. จองห้อง → ไปที่ guest-info page
3. **กรอกข้อมูลใหม่:** ชื่อ "John Doe", email "john@test.com"
4. Complete booking
5. Login as Receptionist → ดูใน Reception
6. **ควรเห็น:** John Doe, john@test.com (ข้อมูลที่กรอก)

### Test Case 3: Non-Session Guest
1. ไม่ login
2. จองห้อง → กรอกข้อมูลทั้งหมด
3. Complete booking
4. Login as Receptionist → ดูใน Reception
5. **ควรเห็น:** ข้อมูลที่กรอก

## Status

✅ Backend แก้ไขเสร็จ
✅ Query ดึงจาก booking_guests แทน guests
✅ Build สำเร็จ
✅ Server ทำงานที่ port 8080
✅ พร้อมส่งลูกค้า!

## หมายเหตุ

- Payment proof upload จะทำในอนาคต
- ตอนนี้ใช้ระบบ approve/reject โดยตรง
- ข้อมูลที่แสดงคือข้อมูลที่ guest กรอกตอน booking ไม่ใช่ข้อมูล account
