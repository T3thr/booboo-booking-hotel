# Quick Fix: Payment Proof System

## ปัญหา
หน้า admin/reception แท็บ "รอตรวจสอบการชำระเงิน" ไม่แสดงข้อมูล เพราะยังไม่มีระบบ upload payment proof

## การแก้ไข (URGENT FIX)

### Backend Changes

**แก้ไข Query ให้แสดงทุก booking ที่ status = 'PendingPayment':**

```sql
-- เดิม: ดึงจาก payment_proofs table (ไม่มีข้อมูล)
SELECT * FROM payment_proofs WHERE status = 'pending'

-- ใหม่: ดึงจาก bookings table
SELECT * FROM bookings 
LEFT JOIN payment_proofs ON bookings.booking_id = payment_proofs.booking_id
WHERE bookings.status = 'PendingPayment'
```

**เปลี่ยน Logic:**
- ใช้ `booking_id` แทน `payment_proof_id` ในการ approve/reject
- Approve → อัปเดต booking status เป็น 'Confirmed'
- Reject → อัปเดต booking status เป็น 'Cancelled'

### Files Modified

1. `backend/internal/repository/payment_proof_repository.go`
   - `GetPaymentProofs()` - ดึงจาก bookings แทน payment_proofs
   - `UpdatePaymentProofStatus()` - อัปเดต bookings.status โดยตรง

2. `backend/internal/service/payment_proof_service.go`
   - เปลี่ยนพารามิเตอร์จาก `paymentProofID` เป็น `bookingID`

3. `backend/internal/handlers/payment_proof_handler.go`
   - อัปเดต comment ให้ชัดเจนว่าใช้ booking_id

## การทำงาน

### 1. แสดงรายการ
```
GET /api/payment-proofs?status=pending
→ แสดงทุก booking ที่ status = 'PendingPayment'
```

### 2. Approve Booking
```
POST /api/payment-proofs/:booking_id/approve
→ UPDATE bookings SET status = 'Confirmed' WHERE booking_id = :booking_id
```

### 3. Reject Booking
```
POST /api/payment-proofs/:booking_id/reject
→ UPDATE bookings SET status = 'Cancelled' WHERE booking_id = :booking_id
```

## Workflow

```
1. Guest จอง → Status: PendingPayment
2. Admin เห็นใน "รอตรวจสอบการชำระเงิน"
3. Admin คลิก Approve → Status: Confirmed
4. Receptionist เห็นใน Check-in Tab
5. Assign Room → Status: CheckedIn
```

## ทดสอบ

1. สร้าง booking ใหม่ (status = PendingPayment)
2. Login as Receptionist/Manager
3. ไปที่ Admin → Reception → จัดการการจอง → รอตรวจสอบการชำระเงิน
4. ควรเห็น booking ที่สร้าง
5. คลิก Approve
6. ไปที่ Check-in Tab → ควรเห็น booking ที่ approve แล้ว

## Status

✅ Backend แก้ไขเสร็จ
✅ Build สำเร็จ
✅ Server ทำงานที่ port 8080
✅ พร้อมใช้งานทันที

**หมายเหตุ:** นี่เป็น temporary fix เพื่อให้ระบบทำงานได้ก่อน ในอนาคตจะเพิ่มระบบ upload payment proof จริง
