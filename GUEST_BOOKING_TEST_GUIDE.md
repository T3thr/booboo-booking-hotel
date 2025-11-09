# คู่มือทดสอบระบบ Guest Booking

## 🚀 Quick Start

### 1. Deploy การแก้ไข
```bash
deploy-guest-booking-fix.bat
```

### 2. Restart Services
```bash
# Terminal 1: Backend
cd backend
hotel-booking-api.exe

# Terminal 2: Frontend
cd frontend
npm run dev
```

## ✅ Test Cases

### Test 1: Guest ไม่ได้ Sign In (Non-Authenticated Booking)

#### ขั้นตอน:
1. เปิด browser (Incognito mode แนะนำ)
2. ไปที่ `http://localhost:3000`
3. คลิก "Search Rooms" หรือไปที่ `/rooms/search`
4. เลือกวันที่และจำนวนผู้เข้าพัก (เช่น 2 Adults)
5. คลิก "Search"
6. เลือกห้องและคลิก "Book Now"

#### หน้า Guest Info:
7. ✅ **ตรวจสอบ:** ควรเห็น email field สำหรับ Guest 1 (Primary)
8. กรอกข้อมูล:
   - Guest 1 (Primary):
     - First Name: `Somchai`
     - Last Name: `Testuser`
     - Phone: `0812345678`
     - **Email: `somchai.test@example.com`** ← ใหม่!
   - Guest 2:
     - First Name: `Somsri`
     - Last Name: `Testuser`
9. คลิก "Continue to Payment"

#### หน้า Summary:
10. กรอกข้อมูลบัตรเครดิต (mock):
    - Card Number: `1234 5678 9012 3456`
    - Name: `SOMCHAI TESTUSER`
    - Expiry: `12/25`
    - CVV: `123`
11. คลิก "Complete Booking"

#### ผลลัพธ์ที่คาดหวัง:
12. ✅ **ควรเห็น:** Toast notification "การจองของคุณสำเร็จแล้ว!"
13. ✅ **ควร redirect ไป:** `/booking/confirmation/[id]` โดยอัตโนมัติ
14. ✅ **ควรเห็น:** หน้า confirmation พร้อมรายละเอียดการจอง
15. ✅ **ควรเห็น:** ข้อมูล Guest Information แสดง phone number ที่กรอก

#### ทดสอบ One-Time Access:
16. คัดลอก URL ของหน้า confirmation
17. กด Back button หรือไปหน้าอื่น
18. Paste URL กลับมา
19. ✅ **ควรเห็น:** หน้า "Access Denied" พร้อมข้อความ "This confirmation page can only be viewed once"
20. ✅ **ควรมีปุ่ม:** "Sign In" และ "Go Home"

#### ทดสอบใน Admin Panel:
21. เปิด tab ใหม่
22. Sign in เป็น receptionist:
    - Email: `receptionist@hotel.com`
    - Password: `Receptionist123!`
23. ไปที่ `/admin/reception`
24. คลิกแท็บ "จัดการการจอง"
25. ✅ **ควรเห็นการจองล่าสุด:**
    - ผู้จอง: `Somchai Testuser`
    - อีเมล: `somchai.test@example.com` ← **ต้องเป็น email ที่กรอกจริง ไม่ใช่ fon.test@example.com**
    - โทร: `0812345678` ← **ต้องเป็นเบอร์ที่กรอกจริง ไม่ใช่ 0867890006**

---

### Test 2: Guest ที่ Sign In แล้ว (Authenticated Booking)

#### ขั้นตอน:
1. เปิด browser (Incognito mode แนะนำ)
2. ไปที่ `http://localhost:3000`
3. คลิก "Sign In"
4. Sign in ด้วย guest account:
   - Email: `john.doe@example.com`
   - Password: `GuestPassword123!`
5. ไปที่ `/rooms/search`
6. เลือกวันที่และจำนวนผู้เข้าพัก
7. คลิก "Search" และเลือกห้อง
8. คลิก "Book Now"

#### หน้า Guest Info:
9. ✅ **ตรวจสอบ:** ไม่ควรเห็น email field (เพราะ signed in แล้ว)
10. กรอกข้อมูล:
    - Guest 1 (Primary):
      - First Name: `John`
      - Last Name: `Doe`
      - Phone: `0898765432`
    - Guest 2 (ถ้ามี):
      - First Name: `Jane`
      - Last Name: `Doe`
11. คลิก "Continue to Payment"

#### หน้า Summary:
12. กรอกข้อมูลบัตรเครดิต (mock)
13. คลิก "Complete Booking"

#### ผลลัพธ์ที่คาดหวัง:
14. ✅ **ควร redirect ไป:** `/booking/confirmation/[id]`
15. ✅ **ควรเห็น:** หน้า confirmation

#### ทดสอบ Multiple Access:
16. คัดลอก URL
17. ไปหน้าอื่น
18. Paste URL กลับมา
19. ✅ **ควรเข้าได้:** เพราะ signed in แล้ว (ไม่มี one-time restriction)
20. ✅ **ควรเห็น:** หน้า confirmation ปกติ

#### ทดสอบใน Admin Panel:
21. เปิด tab ใหม่
22. Sign in เป็น receptionist
23. ไปที่ `/admin/reception` → "จัดการการจอง"
24. ✅ **ควรเห็นการจองล่าสุด:**
    - ผู้จอง: `John Doe` ← **จาก guest account**
    - อีเมล: `john.doe@example.com` ← **จาก guest account**
    - โทร: 
      - ถ้าไม่กรอก phone: แสดงเบอร์จาก guest account
      - ถ้ากรอก phone: แสดงเบอร์ที่กรอก (`0898765432`)

---

### Test 3: Validation Tests

#### Test 3.1: Email Validation (Non-Signed-In)
1. ไปที่หน้า guest-info (ไม่ sign in)
2. กรอก email ไม่ถูกต้อง: `invalid-email`
3. คลิก "Continue to Payment"
4. ✅ **ควรเห็น:** Error message "Please enter a valid email address"

#### Test 3.2: Required Fields
1. ไปที่หน้า guest-info (ไม่ sign in)
2. ไม่กรอก email
3. คลิก "Continue to Payment"
4. ✅ **ควรเห็น:** Error message "Email is required for primary guest"

#### Test 3.3: Phone Validation
1. กรอก phone ไม่ครบ 10 หลัก: `081234`
2. คลิก "Continue to Payment"
3. ✅ **ควรเห็น:** Error message "Please enter a valid 10-digit phone number"

---

## 🔍 Debugging Tips

### ตรวจสอบ Database
```sql
-- ดูข้อมูล booking_guests ล่าสุด
SELECT 
    bg.booking_guest_id,
    bg.first_name,
    bg.last_name,
    bg.phone,
    bg.email,
    bg.is_primary,
    bd.booking_id
FROM booking_guests bg
JOIN booking_details bd ON bg.booking_detail_id = bd.booking_detail_id
ORDER BY bg.booking_guest_id DESC
LIMIT 10;

-- ดูข้อมูลการจองล่าสุดพร้อม guest info
SELECT 
    b.booking_id,
    b.status,
    b.created_at,
    g.first_name || ' ' || g.last_name AS account_name,
    g.email AS account_email,
    g.phone AS account_phone,
    bg.first_name || ' ' || bg.last_name AS booking_guest_name,
    bg.email AS booking_guest_email,
    bg.phone AS booking_guest_phone,
    bg.is_primary
FROM bookings b
LEFT JOIN guests g ON b.guest_id = g.guest_id
LEFT JOIN booking_details bd ON b.booking_id = bd.booking_id
LEFT JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE bg.is_primary = true
ORDER BY b.created_at DESC
LIMIT 5;
```

### ตรวจสอบ Browser Console
```javascript
// ดู sessionStorage
console.log('Booking viewed:', sessionStorage.getItem('booking_1_viewed'));

// ดู localStorage
console.log('Booking hold:', localStorage.getItem('booking_hold'));
console.log('Guest draft:', localStorage.getItem('booking_guest_draft'));
```

### ตรวจสอบ Backend Logs
```bash
# ดู logs ของ booking creation
grep "CreateBooking" backend.log

# ดู logs ของ guest creation
grep "CreateBookingGuest" backend.log
```

---

## 📊 Expected Results Summary

| Scenario | Email Field | One-Time Access | Admin Shows |
|----------|-------------|-----------------|-------------|
| Non-Signed-In | ✅ Required | ✅ Yes | Booking guest data |
| Signed-In | ❌ Hidden | ❌ No | Account data |

---

## 🐛 Common Issues

### Issue 1: Email field ไม่แสดง
**สาเหตุ:** อาจจะ signed in อยู่
**แก้ไข:** Sign out หรือใช้ Incognito mode

### Issue 2: ไม่ redirect ไป confirmation
**สาเหตุ:** Booking ID ไม่ถูกต้อง
**แก้ไข:** ตรวจสอบ console logs และ backend response

### Issue 3: Admin แสดงข้อมูลเก่า
**สาเหตุ:** Cache หรือ migration ยังไม่รัน
**แก้ไข:** 
1. รัน migration 021 อีกครั้ง
2. Restart backend
3. Hard refresh browser (Ctrl+Shift+R)

### Issue 4: One-time access ไม่ทำงาน
**สาเหตุ:** sessionStorage ถูก clear
**แก้ไข:** ปกติ - sessionStorage จะ clear เมื่อปิด tab

---

## ✨ Success Criteria

✅ Guest ที่ไม่ sign in ต้องกรอก email
✅ Guest ที่ sign in ไม่ต้องกรอก email
✅ หลัง complete booking redirect ไป confirmation
✅ Non-signed-in guest เข้าดู confirmation ได้ครั้งเดียว
✅ Signed-in guest เข้าดู confirmation ได้หลายครั้ง
✅ Admin เห็นข้อมูลจริงที่ guest กรอก (ไม่ใช่ข้อมูลปลอม)
✅ Phone และ email ถูกบันทึกใน database
✅ Validation ทำงานถูกต้อง

---

## 📝 Notes

- Email field จะแสดงเฉพาะ Guest 1 (Primary) เท่านั้น
- One-time access ใช้ sessionStorage (จะ reset เมื่อปิด browser tab)
- สำหรับ production ควรพิจารณาใช้ server-side session
- Phone number เป็น required สำหรับ primary guest ทุกคน
