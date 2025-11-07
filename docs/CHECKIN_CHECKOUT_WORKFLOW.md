# Check-in และ Check-out Workflow

## 📋 สารบัญ
1. [การทำงานในชีวิตจริง](#การทำงานในชีวิตจริง)
2. [การทำงานในระบบ](#การทำงานในระบบ)
3. [ปัญหาที่พบและการแก้ไข](#ปัญหาที่พบและการแก้ไข)
4. [วิธีทดสอบระบบ](#วิธีทดสอบระบบ)

---

## 🏨 การทำงานในชีวิตจริง

### **Check-in Process**

#### ขั้นตอนในโรงแรมจริง:
1. **แขกมาถึง** - แขกมาถึงโรงแรมพร้อมหมายเลขการจอง
2. **ตรวจสอบการจอง** - พนักงานต้อนรับค้นหาการจองในระบบ
3. **ยืนยันข้อมูล** - ตรวจสอบชื่อ, วันที่, ประเภทห้อง
4. **ตรวจสอบการชำระเงิน** - ยืนยันว่าชำระเงินครบถ้วนแล้ว
5. **เลือกห้อง** - เลือกห้องว่างที่ตรงกับประเภทที่จอง
6. **มอบกุญแจ** - มอบกุญแจห้องและอธิบายสิ่งอำนวยความสะดวก
7. **อัพเดทสถานะ** - เปลี่ยนสถานะห้องเป็น "Occupied"

#### ข้อมูลที่ต้องการ:
- หมายเลขการจอง (Booking ID)
- ประเภทห้องที่จอง (Room Type)
- วันที่เช็คอิน-เช็คเอาท์
- สถานะการชำระเงิน
- ห้องว่างที่พร้อมใช้งาน

---

### **Check-out Process**

#### ขั้นตอนในโรงแรมจริง:
1. **แขกแจ้งเช็คเอาท์** - แขกมาที่เคาน์เตอร์เพื่อเช็คเอาท์
2. **ตรวจสอบค่าใช้จ่าย** - ตรวจสอบค่าห้อง, ค่าบริการเพิ่มเติม
3. **ชำระเงิน** - แขกชำระเงินที่ค้างชำระ (ถ้ามี)
4. **คืนกุญแจ** - แขกคืนกุญแจห้อง
5. **ตรวจสอบห้อง** - พนักงานตรวจสอบความเสียหาย
6. **อัพเดทสถานะ** - เปลี่ยนสถานะห้องเป็น "Dirty" (รอทำความสะอาด)
7. **ออกใบเสร็จ** - มอบใบเสร็จให้แขก

#### ข้อมูลที่ต้องการ:
- หมายเลขการจอง (Booking ID)
- หมายเลขห้อง (Room Number)
- ยอดเงินทั้งหมด (Total Amount)
- วันที่เช็คเอาท์

---

## 💻 การทำงานในระบบ

### **Check-in Workflow**

```
Frontend (checkin/page.tsx)
    ↓
API Route (/api/admin/checkin/arrivals)
    ↓
Backend Handler (checkin_handler.go → GetArrivals)
    ↓
Database Function (get_arrivals_for_date)
    ↓
Return: รายการแขกที่จะมาถึงวันนี้
```

#### 1. แสดงรายการแขกที่จะมาถึง
```typescript
// GET /api/admin/checkin/arrivals?date=2024-01-15
{
  "arrivals": [
    {
      "booking_id": 1,
      "booking_detail_id": 1,
      "guest_name": "John Doe",
      "room_type_name": "Deluxe Room",
      "check_in_date": "2024-01-15",
      "check_out_date": "2024-01-17",
      "num_guests": 2,
      "payment_status": "approved"
    }
  ]
}
```

#### 2. เลือกแขกและดูห้องว่าง
```typescript
// GET /api/admin/checkin/available-rooms/1
{
  "rooms": [
    {
      "room_id": 101,
      "room_number": "101",
      "occupancy_status": "Vacant",
      "housekeeping_status": "Clean"
    }
  ]
}
```

#### 3. ทำการเช็คอิน
```typescript
// POST /api/admin/checkin
{
  "booking_detail_id": 1,
  "room_id": 101
}

// Response
{
  "success": true,
  "message": "เช็คอินสำเร็จ",
  "room_number": "101"
}
```

#### Database Function:
```sql
-- Function: check_in_guest(p_booking_detail_id, p_room_id)
-- Actions:
-- 1. ตรวจสอบว่าห้องว่างและสะอาด
-- 2. สร้าง room_assignment
-- 3. อัพเดทสถานะห้องเป็น "Occupied"
-- 4. อัพเดทสถานะ booking เป็น "CheckedIn"
```

---

### **Check-out Workflow**

```
Frontend (checkout/page.tsx)
    ↓
API Route (/api/admin/checkout/departures)
    ↓
Backend Handler (checkin_handler.go → GetDepartures)
    ↓
Database Function (get_departures_for_date)
    ↓
Return: รายการแขกที่จะเช็คเอาท์วันนี้
```

#### 1. แสดงรายการแขกที่จะเช็คเอาท์
```typescript
// GET /api/admin/checkout/departures?date=2024-01-17
{
  "departures": [
    {
      "booking_id": 1,
      "guest_name": "John Doe",
      "room_number": "101",
      "check_out_date": "2024-01-17",
      "total_amount": 3000.00,
      "status": "CheckedIn"
    }
  ]
}
```

#### 2. ทำการเช็คเอาท์
```typescript
// POST /api/admin/checkout
{
  "booking_id": 1
}

// Response
{
  "success": true,
  "message": "เช็คเอาท์สำเร็จ",
  "total_amount": 3000.00
}
```

#### Database Function:
```sql
-- Function: check_out_guest(p_booking_id)
-- Actions:
-- 1. อัพเดท check_out_datetime ใน room_assignments
-- 2. เปลี่ยนสถานะห้องเป็น "Dirty"
-- 3. อัพเดทสถานะ booking เป็น "CheckedOut"
-- 4. คืน inventory
```

---

## 🔧 ปัญหาที่พบและการแก้ไข

### **ปัญหา: ไม่มีข้อมูลแสดงในหน้า Check-in/Check-out**

#### สาเหตุ:
1. ❌ **ไม่มี API Routes** - Frontend เรียก API แต่ไม่มีไฟล์ route
2. ❌ **ไม่มีข้อมูลทดสอบ** - Database ไม่มี bookings ที่ Confirmed
3. ❌ **ไม่มี Payment Proofs** - Bookings ไม่มีหลักฐานการชำระเงิน

#### การแก้ไข:

##### 1. สร้าง API Routes (✅ แก้ไขแล้ว)
```
frontend/src/app/api/admin/
├── checkin/
│   ├── route.ts                    # POST /api/admin/checkin
│   ├── arrivals/
│   │   └── route.ts                # GET /api/admin/checkin/arrivals
│   └── available-rooms/
│       └── [roomTypeId]/
│           └── route.ts            # GET /api/admin/checkin/available-rooms/:id
└── checkout/
    ├── route.ts                    # POST /api/admin/checkout
    └── departures/
        └── route.ts                # GET /api/admin/checkout/departures
```

##### 2. เพิ่มข้อมูลทดสอบ
```bash
# รัน migration 019 เพื่อเพิ่มข้อมูลทดสอบ
cd database/migrations
./run_migration_019.bat
```

---

## 🧪 วิธีทดสอบระบบ

### **ขั้นตอนที่ 1: เตรียมข้อมูล**

```bash
# 1. รัน backend
cd backend
go run cmd/server/main.go

# 2. รัน frontend (terminal ใหม่)
cd frontend
npm run dev

# 3. เพิ่มข้อมูลทดสอบ (terminal ใหม่)
cd database/migrations
./run_migration_019.bat
```

### **ขั้นตอนที่ 2: ทดสอบ Check-in**

1. **Login เป็น Receptionist**
   - Email: `receptionist@hotel.com`
   - Password: `password123`

2. **ไปที่หน้า Check-in**
   - URL: `http://localhost:3000/admin/checkin`

3. **ตรวจสอบรายการแขก**
   - ควรเห็นรายการแขกที่จะมาถึงวันนี้
   - แสดงชื่อ, ประเภทห้อง, วันที่

4. **เลือกแขกและดูห้องว่าง**
   - คลิกที่การจองที่ต้องการ
   - ระบบจะแสดงห้องว่างที่พร้อมใช้งาน

5. **ทำการเช็คอิน**
   - เลือกห้อง
   - คลิก "เช็คอิน"
   - ตรวจสอบว่าสถานะเปลี่ยนเป็น "เช็คอินแล้ว"

### **ขั้นตอนที่ 3: ทดสอบ Check-out**

1. **ไปที่หน้า Check-out**
   - URL: `http://localhost:3000/admin/checkout`

2. **ตรวจสอบรายการแขก**
   - ควรเห็นรายการแขกที่จะเช็คเอาท์วันนี้
   - แสดงชื่อ, หมายเลขห้อง, ยอดเงิน

3. **เลือกแขกและทำการเช็คเอาท์**
   - คลิกที่การจองที่ต้องการ
   - คลิก "ดำเนินการเช็คเอาท์"
   - ยืนยันการเช็คเอาท์
   - ตรวจสอบว่าสถานะเปลี่ยนเป็น "CheckedOut"

### **ขั้นตอนที่ 4: ตรวจสอบในฐานข้อมูล**

```sql
-- ตรวจสอบ room assignments
SELECT * FROM room_assignments 
WHERE check_in_datetime IS NOT NULL
ORDER BY check_in_datetime DESC;

-- ตรวจสอบสถานะห้อง
SELECT r.room_number, r.occupancy_status, r.housekeeping_status
FROM rooms r
WHERE r.occupancy_status = 'Occupied';

-- ตรวจสอบ bookings
SELECT b.booking_id, b.status, bd.check_in_date, bd.check_out_date
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
WHERE b.status IN ('CheckedIn', 'CheckedOut')
ORDER BY bd.check_in_date DESC;
```

---

## 📊 Flow Diagram

### Check-in Flow
```
┌─────────────────┐
│  แขกมาถึง       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ค้นหาการจอง     │ ← GET /api/admin/checkin/arrivals
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ตรวจสอบการชำระ  │ ← payment_status = 'approved'
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ เลือกห้องว่าง   │ ← GET /api/admin/checkin/available-rooms/:id
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ทำการเช็คอิน    │ ← POST /api/admin/checkin
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ อัพเดทสถานะ     │
│ - Room: Occupied│
│ - Booking: In   │
└─────────────────┘
```

### Check-out Flow
```
┌─────────────────┐
│ แขกแจ้งเช็คเอาท์ │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ค้นหาการจอง     │ ← GET /api/admin/checkout/departures
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ แสดงยอดเงิน     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ยืนยันเช็คเอาท์  │ ← POST /api/admin/checkout
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ อัพเดทสถานะ     │
│ - Room: Dirty   │
│ - Booking: Out  │
└─────────────────┘
```

---

## 🎯 สรุป

### ไฟล์ที่สร้างใหม่:
1. ✅ `frontend/src/app/api/admin/checkin/route.ts`
2. ✅ `frontend/src/app/api/admin/checkin/arrivals/route.ts`
3. ✅ `frontend/src/app/api/admin/checkin/available-rooms/[roomTypeId]/route.ts`
4. ✅ `frontend/src/app/api/admin/checkout/route.ts`
5. ✅ `frontend/src/app/api/admin/checkout/departures/route.ts`

### การทำงานที่ถูกต้อง:
- ✅ Frontend เรียก API ผ่าน Next.js API Routes
- ✅ API Routes ส่งต่อไปยัง Backend Go
- ✅ Backend ประมวลผลและเรียก Database Functions
- ✅ Database Functions จัดการ transactions และ business logic
- ✅ ข้อมูลถูกส่งกลับมาแสดงใน Frontend

### ขั้นตอนถัดไป:
1. รัน `npm run dev` ใน frontend
2. รัน `go run cmd/server/main.go` ใน backend
3. ทดสอบการ Check-in/Check-out ตามขั้นตอนด้านบน
4. ตรวจสอบว่าข้อมูลแสดงถูกต้อง

---

## 📞 การแก้ปัญหาเพิ่มเติม

### ถ้ายังไม่มีข้อมูลแสดง:

1. **ตรวจสอบ Backend**
   ```bash
   # ดู logs ของ backend
   # ควรเห็น requests เข้ามา
   ```

2. **ตรวจสอบ Database**
   ```sql
   -- ตรวจสอบว่ามี bookings ที่ Confirmed
   SELECT * FROM bookings WHERE status = 'Confirmed';
   
   -- ตรวจสอบว่ามี booking_details วันนี้
   SELECT * FROM booking_details 
   WHERE check_in_date = CURRENT_DATE;
   ```

3. **ตรวจสอบ Authentication**
   - ต้อง login เป็น Receptionist หรือ Manager
   - ตรวจสอบ JWT token ใน session

4. **ตรวจสอบ CORS**
   - Backend ต้องอนุญาต origin จาก frontend
   - ตรวจสอบใน `backend/.env`

---

**หมายเหตุ:** ระบบนี้ออกแบบให้ทำงานแบบ real-time โดยข้อมูลจะอัพเดททันทีหลังจากทำการเช็คอิน/เช็คเอาท์
