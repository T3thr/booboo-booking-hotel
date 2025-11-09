# Final Fix: Payment Proof UI Errors

## ปัญหาที่แก้ไข

### 1. Duplicate Key Error
**Error:** `Encountered two children with the same key, 0`
**สาเหตุ:** ใช้ `payment_proof_id` เป็น key แต่ค่าเป็น 0 ซ้ำกัน (เพราะไม่มี payment_proof จริง)
**แก้ไข:** เปลี่ยนใช้ `booking_id` เป็น key แทน

### 2. Empty Image Source Error
**Error:** `An empty string ("") was passed to the src attribute`
**สาเหตุ:** `proof_url` เป็น empty string เพราะยังไม่มีการ upload proof
**แก้ไข:** เช็คว่ามี `proof_url` ก่อนแสดงรูป ถ้าไม่มีแสดงข้อความแทน

### 3. Missing Fields Error (500)
**สาเหตุ:** Backend ไม่ได้ส่ง fields: `guest_email`, `guest_phone`, `payment_method`
**แก้ไข:** เพิ่ม fields ใน query และ model

## การแก้ไข

### Frontend (`BookingManagementTab.tsx`)

```tsx
// เปลี่ยน key จาก payment_proof_id เป็น booking_id
<Card key={proof.booking_id} className="overflow-hidden">

// เช็คว่ามี proof_url ก่อนแสดงรูป
{proof.proof_url && proof.proof_url !== '' ? (
  <div>
    <img src={proof.proof_url} alt="Payment proof" />
  </div>
) : (
  <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-lg p-4">
    <p>⚠️ ยังไม่มีหลักฐานการโอนเงิน</p>
    <p className="text-xs">รอลูกค้าอัปโหลดหลักฐาน</p>
  </div>
)}
```

### Backend

**Model (`payment_proof.go`):**
```go
type PaymentProof struct {
    // ... existing fields
    GuestEmail    string `json:"guest_email" db:"guest_email"`
    GuestPhone    string `json:"guest_phone" db:"guest_phone"`
    TotalAmount   float64 `json:"amount" db:"total_amount"` // เปลี่ยน json tag
    PaymentMethod string `json:"payment_method" db:"payment_method"`
}
```

**Repository (`payment_proof_repository.go`):**
```sql
SELECT 
    -- ... existing fields
    g.email as guest_email,
    g.phone as guest_phone,
    b.total_amount,
    'bank_transfer' as payment_method  -- default value
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
-- ...
WHERE b.status = 'PendingPayment'
```

## ผลลัพธ์

✅ ไม่มี duplicate key error
✅ ไม่มี empty src error  
✅ แสดงข้อมูลครบถ้วน (email, phone, payment_method)
✅ แสดงข้อความเตือนเมื่อยังไม่มี payment proof
✅ Backend ส่ง 200 OK

## การทดสอบ

1. เข้า Admin → Reception → จัดการการจอง → รอตรวจสอบการชำระเงิน
2. ควรเห็น booking ทั้งหมดที่ status = 'PendingPayment'
3. ถ้ายังไม่มี proof จะแสดงข้อความ "⚠️ ยังไม่มีหลักฐานการโอนเงิน"
4. แสดงข้อมูลครบ: ชื่อ, email, เบอร์โทร, ห้อง, วันที่, จำนวนเงิน
5. สามารถ Approve/Reject ได้

## Status

✅ Frontend แก้ไขเสร็จ
✅ Backend แก้ไขเสร็จ
✅ Build สำเร็จ
✅ Server ทำงานที่ port 8080
✅ พร้อมส่งลูกค้า!
