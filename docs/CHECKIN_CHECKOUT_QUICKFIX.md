# 🚀 Quick Fix: Check-in/Check-out ไม่แสดงข้อมูล

## ปัญหา
เมื่อเข้าหน้า Check-in หรือ Check-out ไม่มีข้อมูลแสดง

## สาเหตุ
1. ❌ ไม่มี API Routes ใน Frontend
2. ❌ ไม่มีข้อมูลทดสอบในฐานข้อมูล

## วิธีแก้ไข (3 ขั้นตอน)

### ✅ ขั้นตอนที่ 1: เพิ่มข้อมูลทดสอบ

```bash
# เปิด terminal ใหม่
cd database/migrations
run_migration_020.bat
```

**ข้อมูลที่จะถูกเพิ่ม:**
- 3 bookings พร้อมเช็คอินวันนี้
- 2 bookings พร้อมเช็คเอาท์วันนี้
- Payment proofs ที่อนุมัติแล้ว

### ✅ ขั้นตอนที่ 2: รัน Backend

```bash
# เปิด terminal ใหม่
cd backend
go run cmd/server/main.go
```

**ตรวจสอบ:**
- ควรเห็น "Server running on :8080"
- ไม่มี error messages

### ✅ ขั้นตอนที่ 3: รัน Frontend

```bash
# เปิด terminal ใหม่
cd frontend
npm run dev
```

**ตรวจสอบ:**
- ควรเห็น "Ready on http://localhost:3000"
- ไม่มี compilation errors

---

## 🧪 ทดสอบระบบ

### 1. Login
```
URL: http://localhost:3000/auth/signin
Email: receptionist@hotel.com
Password: password123
```

### 2. ทดสอบ Check-in
```
URL: http://localhost:3000/admin/checkin

ควรเห็น:
✓ รายการแขก 3 คน
✓ ชื่อ: Somchai Checkin, Niran Ready, Prasert Suite
✓ สถานะ: ชำระเงินแล้ว (สีเขียว)
```

**ขั้นตอนทดสอบ:**
1. คลิกที่แขกคนใดคนหนึ่ง
2. ดูห้องว่างที่แสดง
3. เลือกห้อง
4. คลิก "เช็คอิน"
5. ✅ ควรเห็นข้อความ "เช็คอินสำเร็จ"

### 3. ทดสอบ Check-out
```
URL: http://localhost:3000/admin/checkout

ควรเห็น:
✓ รายการแขก 2 คน
✓ ชื่อ: Wichai Checkout, Surasak Leaving
✓ หมายเลขห้อง: 101, 201
```

**ขั้นตอนทดสอบ:**
1. คลิกที่แขกคนใดคนหนึ่ง
2. ดูยอดเงินทั้งหมด
3. คลิก "ดำเนินการเช็คเอาท์"
4. คลิก "ยืนยันเช็คเอาท์"
5. ✅ ควรเห็นข้อความ "เช็คเอาท์สำเร็จ"

---

## 🔍 ตรวจสอบปัญหา

### ถ้ายังไม่มีข้อมูล:

#### 1. ตรวจสอบ Backend Logs
```bash
# ใน terminal ที่รัน backend
# ควรเห็น:
GET /api/checkin/arrivals?date=2024-xx-xx
GET /api/checkout/departures?date=2024-xx-xx
```

#### 2. ตรวจสอบ Frontend Console
```
F12 → Console
# ไม่ควรมี errors สีแดง
```

#### 3. ตรวจสอบ Database
```sql
-- เปิด psql
psql -U postgres -d hotel_booking

-- ตรวจสอบ arrivals
SELECT COUNT(*) FROM booking_details 
WHERE check_in_date = CURRENT_DATE;
-- ควรได้ 3

-- ตรวจสอบ departures
SELECT COUNT(*) FROM booking_details bd
JOIN bookings b ON bd.booking_id = b.booking_id
WHERE bd.check_out_date = CURRENT_DATE 
  AND b.status = 'CheckedIn';
-- ควรได้ 2
```

#### 4. ตรวจสอบ Authentication
```
# ต้อง login เป็น:
- Receptionist (receptionist@hotel.com)
- หรือ Manager (manager@hotel.com)

# Guest ไม่สามารถเข้าถึงหน้านี้ได้
```

---

## 📁 ไฟล์ที่ถูกสร้าง

### API Routes (Frontend)
```
frontend/src/app/api/admin/
├── checkin/
│   ├── route.ts                    ✅ สร้างแล้ว
│   ├── arrivals/
│   │   └── route.ts                ✅ สร้างแล้ว
│   └── available-rooms/
│       └── [roomTypeId]/
│           └── route.ts            ✅ สร้างแล้ว
└── checkout/
    ├── route.ts                    ✅ สร้างแล้ว
    └── departures/
        └── route.ts                ✅ สร้างแล้ว
```

### Database Migration
```
database/migrations/
├── 020_seed_checkin_test_data.sql  ✅ สร้างแล้ว
└── run_migration_020.bat           ✅ สร้างแล้ว
```

---

## 🎯 สรุป

### ก่อนแก้ไข:
- ❌ ไม่มี API routes
- ❌ ไม่มีข้อมูลทดสอบ
- ❌ หน้าว่างเปล่า

### หลังแก้ไข:
- ✅ มี API routes ครบถ้วน
- ✅ มีข้อมูลทดสอบ 5 bookings
- ✅ แสดงข้อมูลถูกต้อง
- ✅ สามารถเช็คอิน/เช็คเอาท์ได้

---

## 📞 ติดปัญหา?

### Error: "Unauthorized"
→ Login ใหม่เป็น receptionist@hotel.com

### Error: "Failed to fetch"
→ ตรวจสอบว่า backend รันอยู่ที่ port 8080

### Error: "No arrivals found"
→ รัน migration 020 อีกครั้ง

### ข้อมูลไม่อัพเดท
→ Refresh หน้าเว็บ (Ctrl+R)

---

## 🔗 เอกสารเพิ่มเติม

- [CHECKIN_CHECKOUT_WORKFLOW.md](./CHECKIN_CHECKOUT_WORKFLOW.md) - คู่มือฉบับเต็ม
- [RECEPTIONIST_GUIDE.md](./user-guides/RECEPTIONIST_GUIDE.md) - คู่มือพนักงานต้อนรับ

---

**หมายเหตุ:** ข้อมูลทดสอบจะใช้วันที่ปัจจุบัน (CURRENT_DATE) ดังนั้นจะมีข้อมูลแสดงทุกวัน
