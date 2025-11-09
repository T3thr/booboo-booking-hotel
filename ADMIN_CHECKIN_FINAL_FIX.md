# แก้ปัญหา Admin Check-in 500 Error - Final Fix

## ปัญหา
ยังได้ 500 Error หลังแก้ไปแล้ว เพราะ:
- SQL Query ใช้ column name ผิด: `pp.image_url` 
- แต่ใน database ชื่อจริงคือ: `pp.proof_url`

## สาเหตุ
ใน `database/migrations/015_create_payment_proof_table.sql`:
```sql
CREATE TABLE payment_proofs (
    ...
    proof_url TEXT NOT NULL,  -- ← ชื่อจริง
    ...
);
```

แต่ใน query ใช้:
```sql
pp.image_url as payment_proof_url  -- ❌ ผิด
```

## การแก้ไข

### 1. แก้ Column Name ใน Query
```sql
-- เปลี่ยนจาก
pp.image_url as payment_proof_url

-- เป็น
pp.proof_url as payment_proof_url  -- ✅ ถูก
```

### 2. Rebuild Backend
```bash
cd backend
go build -o hotel-booking-system.exe ./cmd/server
```

### 3. Restart Backend
```bash
# หยุด backend (Ctrl+C)
# รันใหม่
.\hotel-booking-system.exe
```

## ทดสอบ
1. **Restart backend** (สำคัญมาก!)
2. Refresh หน้า Admin Check-in
3. ควรเห็นรายการ bookings

## ถ้ายังไม่มีข้อมูล
รัน seed data:
```bash
cd database/migrations
run_migration_020.bat
```

หรือทำการจองห้องใหม่:
1. ไปที่หน้า Rooms Search
2. เลือกห้อง → กรอกข้อมูล → Complete Booking
3. กลับมาหน้า Admin Check-in
4. ควรเห็น booking ที่เพิ่งสร้าง

## ตรวจสอบว่า Backend Restart แล้ว
ดูที่ backend terminal ควรเห็น:
```
Starting server on :8080
Database connected successfully
```

## สรุปการแก้ไขทั้งหมด
1. ✅ แก้ `session.user.accessToken` → `session.accessToken` (401 → 200)
2. ✅ เพิ่ม `'PendingPayment'` ใน status filter
3. ✅ แก้ `pp.image_url` → `pp.proof_url` (500 → 200)

## ไฟล์ที่แก้ไข
- `frontend/src/app/api/admin/checkin/arrivals/route.ts`
- `frontend/src/app/api/admin/checkout/departures/route.ts`
- `frontend/src/app/api/admin/checkin/route.ts`
- `backend/internal/repository/booking_repository.go`

**ตอนนี้ RESTART BACKEND แล้ว refresh หน้า Admin Check-in ควรทำงานได้แล้ว!**
