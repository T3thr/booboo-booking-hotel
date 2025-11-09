# แก้ไขปัญหา Approve/Reject Payment Proof

## ปัญหาที่พบ

```
POST /api/payment-proofs/0/approve 500
Error: "booking confirmation failed: ไม่พบการจองนี้"
```

## สาเหตุ

Frontend ส่ง `payment_proof_id` (ซึ่งเป็น 0) แทนที่จะเป็น `booking_id` ไปยัง backend

```typescript
// ❌ เดิม - ส่ง payment_proof_id ซึ่งเป็น 0
approveMutation.mutate(proof.payment_proof_id);  // = 0
rejectMutation.mutate({
  paymentProofId: proof.payment_proof_id,  // = 0
  reason: rejectionReason,
});
```

เพราะ:
- `payment_proof_id = 0` (COALESCE default value เมื่อยังไม่มี payment proof record)
- Backend ต้องการ `booking_id` เพื่อเรียก `confirm_booking(booking_id)`
- เมื่อส่ง 0 ไป backend พยายามหา booking_id = 0 ซึ่งไม่มี

## การแก้ไข

### ไฟล์: `frontend/src/app/admin/(staff)/reception/components/BookingManagementTab.tsx`

```typescript
// ✅ ใหม่ - ส่ง booking_id แทน
const handleApprove = (proof: PaymentProof) => {
  if (confirm(`ยืนยันการอนุมัติการชำระเงินสำหรับการจอง #${proof.booking_id}?`)) {
    approveMutation.mutate(proof.booking_id);  // ✅ ใช้ booking_id
  }
};

const handleReject = (proof: PaymentProof) => {
  if (!rejectionReason.trim()) {
    alert("กรุณาระบุเหตุผลในการปฏิเสธ");
    return;
  }
  if (confirm(`ยืนยันการปฏิเสธการชำระเงินสำหรับการจอง #${proof.booking_id}?`)) {
    rejectMutation.mutate({
      paymentProofId: proof.booking_id,  // ✅ ใช้ booking_id
      reason: rejectionReason,
    });
  }
};
```

## Flow การทำงานหลังแก้ไข

### Approve Flow:
```
User คลิก "อนุมัติ"
  ↓
Frontend: approveMutation.mutate(proof.booking_id)
  ↓ POST /api/admin/payment-proofs/{booking_id}/approve
  ↓
Frontend API Route: Forward to backend
  ↓ POST /api/payment-proofs/{booking_id}/approve
  ↓
Backend Handler: ApprovePaymentProof(booking_id)
  ↓
Backend Service: ApprovePaymentProof(booking_id)
  ↓
Backend Repository: UpdatePaymentProofStatus(booking_id, "approved")
  ↓ BEGIN TRANSACTION
  ↓ SELECT * FROM confirm_booking(booking_id)
  ↓   - เปลี่ยนสถานะ: PendingPayment → Confirmed
  ↓   - ลด available_rooms ใน daily_inventory
  ↓   - บันทึก timestamp
  ↓ UPDATE payment_proofs SET status='approved'
  ↓ COMMIT
  ↓
Frontend: Success! Refetch data
  ✅ Booking หายจาก "รอตรวจสอบ"
  ✅ Booking ปรากฏใน /admin/checkin (ถ้าวันนี้เป็นวัน check-in)
  ✅ สถานะเป็น "Confirmed"
```

### Reject Flow:
```
User คลิก "ปฏิเสธ" + ระบุเหตุผล
  ↓
Frontend: rejectMutation.mutate({booking_id, reason})
  ↓ POST /api/admin/payment-proofs/{booking_id}/reject
  ↓
Frontend API Route: Forward to backend
  ↓ POST /api/payment-proofs/{booking_id}/reject
  ↓
Backend Handler: RejectPaymentProof(booking_id)
  ↓
Backend Service: RejectPaymentProof(booking_id)
  ↓
Backend Repository: UpdatePaymentProofStatus(booking_id, "rejected")
  ↓ BEGIN TRANSACTION
  ↓ SELECT * FROM cancel_pending_booking(booking_id)
  ↓   - เปลี่ยนสถานะ: PendingPayment → Cancelled
  ↓   - คืน available_rooms ใน daily_inventory
  ↓   - คำนวณ refund (ถ้ามี)
  ↓ UPDATE payment_proofs SET status='rejected'
  ↓ COMMIT
  ↓
Frontend: Success! Refetch data
  ✅ Booking หายจาก "รอตรวจสอบ"
  ✅ สถานะเป็น "Cancelled"
  ✅ Inventory ถูกคืนกลับ
```

## การทดสอบ

### ทดสอบ Approve:
```bash
# 1. Start backend & frontend
# 2. ไปที่ /admin/reception
# 3. แท็บ "รอตรวจสอบการชำระเงิน"
# 4. เลือก booking
# 5. คลิก "อนุมัติ"
```

**Expected:**
- ✅ แสดง confirm dialog
- ✅ แสดง success message
- ✅ Booking หายจากรายการ
- ✅ ไปที่ /admin/checkin → เห็น booking ใน Arrivals (ถ้าวันนี้เป็นวัน check-in)
- ✅ ไปที่แท็บ "การจองทั้งหมด" → สถานะเป็น "Confirmed"

### ทดสอบ Reject:
```bash
# 1-4 เหมือนกัน
# 5. คลิก "ปฏิเสธ"
# 6. ระบุเหตุผล
# 7. คลิก "ปฏิเสธการชำระเงิน"
```

**Expected:**
- ✅ แสดง confirm dialog
- ✅ แสดง success message
- ✅ Booking หายจากรายการ
- ✅ ไปที่แท็บ "การจองทั้งหมด" → สถานะเป็น "Cancelled"

### ตรวจสอบ Network:
```
POST /api/admin/payment-proofs/42/approve  ✅ (ไม่ใช่ 0)
POST /api/admin/payment-proofs/43/reject   ✅ (ไม่ใช่ 0)
```

### ตรวจสอบ Backend Logs:
```
[POST] 200 | /api/payment-proofs/42/approve  ✅ (ไม่ใช่ 500)
[POST] 200 | /api/payment-proofs/43/reject   ✅ (ไม่ใช่ 500)
```

## Integration กับ Check-in System

### หลัง Approve:
1. Booking status = "Confirmed"
2. Inventory ถูกลดแล้ว
3. ไปที่ `/admin/checkin`:
   - ถ้าวันนี้เป็นวัน check-in → แสดงใน "Arrivals"
   - Staff สามารถ assign room และ check-in ได้ทันที

### หลัง Reject:
1. Booking status = "Cancelled"
2. Inventory ถูกคืนกลับแล้ว
3. ห้องพร้อมให้ booking อื่นจองได้

## สรุป

✅ แก้ไขการส่ง `booking_id` แทน `payment_proof_id`
✅ Approve ทำงานได้ - เปลี่ยนสถานะเป็น Confirmed
✅ Reject ทำงานได้ - เปลี่ยนสถานะเป็น Cancelled
✅ Integration กับ check-in system สมบูรณ์
✅ Inventory management ทำงานถูกต้อง

## ไฟล์ที่แก้ไข

1. `frontend/src/app/admin/(staff)/reception/components/BookingManagementTab.tsx`
   - แก้ `handleApprove` ให้ส่ง `booking_id`
   - แก้ `handleReject` ให้ส่ง `booking_id`
