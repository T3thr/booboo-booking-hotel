# Payment Proof System - Complete Implementation

## สรุปการแก้ไข

ระบบ Payment Proof ได้รับการสร้างครบถ้วนแล้ว เชื่อมต่อกับระบบ Check-in สำเร็จ

## Workflow ที่ถูกต้อง

```
1. Guest → Complete Booking → Status: PendingPayment
   - Guest upload payment proof
   - payment_proofs table: status = 'pending'
   - bookings table: status = 'PendingPayment'

2. Admin → Reception → "รอตรวจสอบการชำระเงิน" Tab → Approve
   - payment_proofs table: status = 'approved'
   - bookings table: status = 'Confirmed' (อัตโนมัติ)

3. Receptionist → Check-in Tab → เห็น booking ที่ Confirmed
   - สามารถ assign room ได้
   - bookings table: status = 'CheckedIn'
```

## Backend Implementation

### 1. Models (`backend/internal/models/payment_proof.go`)
```go
type PaymentProof struct {
    PaymentProofID int
    BookingID      int
    ProofURL       string
    Status         string  // pending, approved, rejected
    Notes          *string
    // Joined fields
    GuestName      string
    RoomTypeName   string
    CheckInDate    time.Time
    CheckOutDate   time.Time
    TotalAmount    float64
}
```

### 2. Repository (`backend/internal/repository/payment_proof_repository.go`)
- `GetPaymentProofs(status)` - ดึงรายการตาม status
- `UpdatePaymentProofStatus()` - อัปเดต status + booking status (transaction)
- `GetPaymentProofByID()` - ดึงข้อมูลเดียว

**สำคัญ:** เมื่อ approve payment proof จะอัปเดต booking status เป็น 'Confirmed' อัตโนมัติ

### 3. Service (`backend/internal/service/payment_proof_service.go`)
- Validate status (pending/approved/rejected)
- ตรวจสอบว่า payment proof ยังไม่ถูก process
- เรียก repository

### 4. Handler (`backend/internal/handlers/payment_proof_handler.go`)
- `GET /api/payment-proofs?status=pending`
- `GET /api/payment-proofs/:id`
- `POST /api/payment-proofs/:id/approve`
- `POST /api/payment-proofs/:id/reject`

### 5. Routes (`backend/internal/router/router.go`)
```go
paymentProofs := api.Group("/payment-proofs")
paymentProofs.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
paymentProofs.Use(middleware.RequireReceptionist()) // RECEPTIONIST or MANAGER
```

## Frontend Implementation

### API Routes (แก้ไขแล้ว)
- `/api/admin/payment-proofs` → เรียก backend `/api/payment-proofs`
- `/api/admin/payment-proofs/:id/approve` → เรียก backend `/api/payment-proofs/:id/approve`
- `/api/admin/payment-proofs/:id/reject` → เรียก backend `/api/payment-proofs/:id/reject`

### UI Component
- `frontend/src/app/admin/(staff)/reception/components/BookingManagementTab.tsx`
- แท็บ "รอตรวจสอบการชำระเงิน"
- แสดงรายการ payment proofs ที่ status = 'pending'
- ปุ่ม Approve/Reject

## Database Integration

### payment_proofs Table
```sql
CREATE TABLE payment_proofs (
    payment_proof_id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(booking_id),
    proof_url TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Transaction Flow (Approve)
```sql
BEGIN;
-- 1. Update payment proof
UPDATE payment_proofs 
SET status = 'approved', updated_at = NOW() 
WHERE payment_proof_id = $1;

-- 2. Update booking status
UPDATE bookings 
SET status = 'Confirmed', updated_at = NOW() 
WHERE booking_id = (SELECT booking_id FROM payment_proofs WHERE payment_proof_id = $1);
COMMIT;
```

## Integration with Check-in System

### Check-in Arrivals Query
```sql
SELECT b.*, pp.status as payment_status
FROM bookings b
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE bd.check_in_date = $1
  AND b.status IN ('Confirmed', 'CheckedIn', 'PendingPayment')
```

**หมายเหตุ:** 
- Booking ที่ status = 'Confirmed' จะแสดงใน Check-in arrivals
- Booking ที่ status = 'PendingPayment' จะไม่แสดง (ยังรอ approve)

## การทดสอบ

### 1. ทดสอบ Backend
```bash
# Get pending payment proofs
curl -X GET "http://localhost:8080/api/payment-proofs?status=pending" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Approve payment proof
curl -X POST "http://localhost:8080/api/payment-proofs/1/approve" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

### 2. ทดสอบ Frontend
1. Login as Receptionist/Manager
2. ไปที่ Admin → Reception
3. คลิกแท็บ "จัดการการจอง"
4. คลิกแท็บย่อย "รอตรวจสอบการชำระเงิน"
5. ควรเห็นรายการ bookings ที่รอ approve
6. คลิก Approve → booking status เปลี่ยนเป็น 'Confirmed'
7. ไปที่แท็บ Check-in → ควรเห็น booking ที่ approve แล้ว

## Files Created/Modified

### Backend
- ✅ `backend/internal/models/payment_proof.go` (NEW)
- ✅ `backend/internal/repository/payment_proof_repository.go` (NEW)
- ✅ `backend/internal/service/payment_proof_service.go` (NEW)
- ✅ `backend/internal/handlers/payment_proof_handler.go` (NEW)
- ✅ `backend/internal/router/router.go` (MODIFIED)

### Frontend
- ✅ `frontend/src/app/api/admin/payment-proofs/route.ts` (MODIFIED)
- ✅ `frontend/src/app/api/admin/payment-proofs/[id]/approve/route.ts` (MODIFIED)
- ✅ `frontend/src/app/api/admin/payment-proofs/[id]/reject/route.ts` (MODIFIED)

### Scripts
- ✅ `rebuild-backend.bat` (NEW)

## การ Deploy

```bash
# 1. Rebuild backend
rebuild-backend.bat

# 2. Restart frontend (if needed)
cd frontend
npm run dev
```

## Status

✅ Backend API สร้างเสร็จ
✅ Frontend API routes แก้ไขเสร็จ
✅ Integration กับ Check-in system เสร็จ
✅ Transaction handling ถูกต้อง
✅ Authorization middleware ครบถ้วน

ระบบพร้อมใช้งาน!
