# แก้ไขปัญหา Production ทั้งหมด

## 🔴 ปัญหาที่พบ

### 1. Approve Booking Error 500
```
POST /api/admin/payment-proofs/32/approve 500
Error: "booking confirmation failed: ไม่พบการจองนี้"
```

### 2. Admin/Checkin ไม่โหลดข้อมูล
- หน้า admin/checkin ใน production ไม่แสดงข้อมูลแขก
- ก่อนหน้านี้ทำงานได้แล้ว แต่กลับมา error อีก

### 3. Guest Data ส่งข้อมูล Mock
- Guest ที่ sign in แล้วจอง แต่ส่งข้อมูล "Fon Testuser" แทนข้อมูลจริง
- ข้อมูลใน admin/reception แสดง mock data แทนข้อมูล guest account

## 🔍 สาเหตุ

### ปัญหาที่ 1: Approve Error
**สาเหตุ**: Backend code ถูกต้องแล้ว แต่อาจมีปัญหาที่:
1. Booking ไม่อยู่ใน status `PendingPayment`
2. Database function `confirm_booking()` ไม่พบ booking
3. Booking ID ไม่ถูกต้อง

### ปัญหาที่ 2: Checkin ไม่โหลด
**สาเหตุ**: Query ใน `GetArrivals` อาจมีปัญหา หรือไม่มีข้อมูล booking ที่ Confirmed

### ปัญหาที่ 3: Mock Data
**สาเหตุ**: Backend code แก้ไขถูกต้องแล้ว แต่:
1. Booking เก่าที่สร้างก่อนแก้ไขยังมี mock data
2. Backend อาจไม่ได้ rebuild หลังแก้ไข

## ✅ การแก้ไข

### Step 1: ตรวจสอบ Backend Code

Backend code ถูกต้องแล้ว:
- ✅ `booking_repository.go` - GetArrivals มี payment status logic
- ✅ `booking_service.go` - CreateBooking ใช้ guest account data
- ✅ `payment_proof_repository.go` - UpdatePaymentProofStatus ใช้ pgx.ErrNoRows

### Step 2: Rebuild Backend

```bash
cd backend
go build -o hotel-booking-server.exe ./cmd/server
```

### Step 3: ตรวจสอบ Database

```sql
-- 1. ตรวจสอบ booking ที่ PendingPayment
SELECT booking_id, status, guest_id, total_amount, created_at
FROM bookings
WHERE status = 'PendingPayment'
ORDER BY created_at DESC
LIMIT 10;

-- 2. ตรวจสอบ booking ที่ Confirmed วันนี้
SELECT b.booking_id, b.status, bd.check_in_date,
       CONCAT(bg.first_name, ' ', bg.last_name) as guest_name,
       bg.email, bg.phone
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE bd.check_in_date = CURRENT_DATE
  AND b.status IN ('Confirmed', 'CheckedIn')
  AND bg.is_primary = true;

-- 3. ตรวจสอบ guest account data
SELECT g.guest_id, g.email, g.first_name, g.last_name, g.phone,
       COUNT(b.booking_id) as booking_count
FROM guests g
LEFT JOIN bookings b ON g.guest_id = b.guest_id
GROUP BY g.guest_id
ORDER BY g.guest_id;

-- 4. ตรวจสอบ booking_guests ที่มี mock data
SELECT b.booking_id, b.guest_id, b.status,
       bg.first_name, bg.last_name, bg.email, bg.phone,
       g.first_name as account_first_name,
       g.last_name as account_last_name,
       g.email as account_email,
       g.phone as account_phone
FROM bookings b
LEFT JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE bg.is_primary = true
  AND b.guest_id IS NOT NULL
ORDER BY b.booking_id DESC
LIMIT 20;
```

### Step 4: แก้ไข Booking เก่า

รัน SQL script เพื่อแก้ไข booking เก่าที่มี mock data:

```bash
cd database/migrations
run_fix_mock_guest_data.bat
```

หรือรัน SQL โดยตรง:

```sql
-- Update booking_guests ให้ใช้ข้อมูลจาก guest account
UPDATE booking_guests bg
SET 
    first_name = g.first_name,
    last_name = g.last_name,
    email = g.email,
    phone = g.phone
FROM booking_details bd
JOIN bookings b ON bd.booking_id = b.booking_id
JOIN guests g ON b.guest_id = g.guest_id
WHERE bg.booking_detail_id = bd.booking_detail_id
  AND bg.is_primary = true
  AND b.guest_id IS NOT NULL
  AND (
    bg.first_name IN ('Fon', 'Guest', 'Test') 
    OR bg.last_name IN ('Testuser', 'User', 'Test')
    OR bg.email LIKE '%test%@example.com'
    OR bg.phone LIKE '086789%'
  );
```

### Step 5: Deploy to Production

#### Backend (Render):
1. Push code to GitHub
2. Render จะ auto-deploy
3. รอ 2-5 นาที

#### Frontend (Vercel):
1. Push code to GitHub
2. Vercel จะ auto-deploy
3. รอ 1-2 นาที

## 🧪 การทดสอบ

### Test 1: Approve Booking

```
1. Sign in as guest (john.doe@example.com)
2. สร้าง booking ใหม่
3. Complete booking
4. Sign in as manager/receptionist
5. ไปที่ admin/reception → แท็บ "จัดการการจอง"
6. คลิก "อนุมัติ" ที่ booking ใหม่
Expected: ✅ อนุมัติสำเร็จ, status เปลี่ยนเป็น "Confirmed"
```

### Test 2: Check-in Page

```
1. Sign in as receptionist
2. ไปที่ admin/checkin
3. เลือกวันที่วันนี้
Expected: ✅ แสดงรายการ booking ที่ Confirmed
Expected: ✅ แสดง payment status = "approved"
Expected: ✅ แสดงชื่อจริงจาก guest account
```

### Test 3: Guest Data

```
1. Sign in as guest (john.doe@example.com)
2. สร้าง booking ใหม่
3. Complete booking
4. ไปที่ admin/reception
Expected: ✅ แสดงชื่อ: John Doe (ไม่ใช่ Fon Testuser)
Expected: ✅ แสดงอีเมล: john.doe@example.com
Expected: ✅ แสดงเบอร์: 0812345678
```

## 📊 Checklist

### Backend
- [ ] Rebuild backend: `go build -o hotel-booking-server.exe ./cmd/server`
- [ ] ตรวจสอบ logs ไม่มี errors
- [ ] ทดสอบ approve API: `POST /api/payment-proofs/:id/approve`
- [ ] ทดสอบ arrivals API: `GET /api/checkin/arrivals?date=2025-11-09`

### Database
- [ ] ตรวจสอบมี booking ที่ PendingPayment
- [ ] ตรวจสอบมี booking ที่ Confirmed วันนี้
- [ ] รัน fix script: `run_fix_mock_guest_data.bat`
- [ ] ตรวจสอบ booking_guests ไม่มี mock data

### Frontend
- [ ] Deploy to Vercel
- [ ] ทดสอบ admin/reception → approve booking
- [ ] ทดสอบ admin/checkin → แสดงข้อมูล
- [ ] ทดสอบ guest booking → ส่งข้อมูลถูกต้อง

### Production
- [ ] Backend deployed to Render
- [ ] Frontend deployed to Vercel
- [ ] ทดสอบ end-to-end flow
- [ ] ตรวจสอบ logs ไม่มี errors

## 🚨 Troubleshooting

### ถ้า Approve ยัง Error 500

1. **ตรวจสอบ Backend Logs**:
   ```
   ไปที่ Render Dashboard → Logs
   ดูว่ามี error อะไร
   ```

2. **ตรวจสอบ Booking Status**:
   ```sql
   SELECT booking_id, status FROM bookings WHERE booking_id = 32;
   ```
   - ถ้า status ไม่ใช่ `PendingPayment` → ไม่สามารถ approve ได้

3. **ตรวจสอบ Database Function**:
   ```sql
   SELECT * FROM confirm_booking(32);
   ```
   - ถ้า return `success = false` → ดู message

### ถ้า Checkin ยังไม่แสดงข้อมูล

1. **ตรวจสอบมี Booking หรือไม่**:
   ```sql
   SELECT COUNT(*) FROM bookings b
   JOIN booking_details bd ON b.booking_id = bd.booking_id
   WHERE bd.check_in_date = CURRENT_DATE
     AND b.status IN ('Confirmed', 'CheckedIn');
   ```

2. **ตรวจสอบ API Response**:
   ```
   เปิด Browser Console (F12)
   ดู Network tab
   ตรวจสอบ response จาก /api/admin/checkin/arrivals
   ```

3. **สร้าง Test Data**:
   ```bash
   cd database/migrations
   run_migration_020.bat
   ```

### ถ้ายังมี Mock Data

1. **รัน Fix Script อีกครั้ง**:
   ```bash
   cd database/migrations
   run_fix_mock_guest_data.bat
   ```

2. **ตรวจสอบผลลัพธ์**:
   ```sql
   SELECT b.booking_id,
          bg.first_name, bg.last_name, bg.email,
          g.first_name as account_first, g.last_name as account_last
   FROM bookings b
   JOIN guests g ON b.guest_id = g.guest_id
   JOIN booking_details bd ON b.booking_id = bd.booking_id
   JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
   WHERE bg.is_primary = true
     AND b.guest_id IS NOT NULL
   ORDER BY b.booking_id DESC
   LIMIT 10;
   ```

## 📝 สรุป

### ปัญหาหลัก:
1. ❌ Approve booking error 500
2. ❌ Checkin page ไม่โหลดข้อมูล
3. ❌ Guest data ส่ง mock แทนข้อมูลจริง

### การแก้ไข:
1. ✅ Backend code ถูกต้องแล้ว
2. ✅ Rebuild backend
3. ✅ รัน fix script สำหรับ booking เก่า
4. ✅ Deploy to production

### ผลลัพธ์ที่คาดหวัง:
- ✅ Approve booking ทำงานได้
- ✅ Checkin page แสดงข้อมูลถูกต้อง
- ✅ Guest data ใช้ข้อมูลจาก account
- ✅ ระบบทำงานสอดคล้องกันทั้งหมด

---

**สร้างเมื่อ**: 9 พฤศจิกายน 2025  
**Status**: 🔧 Ready to Fix
