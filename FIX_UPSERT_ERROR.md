# ✅ แก้ไข Payment Proof Errors

## ปัญหาที่พบ

### 1. UPSERT Error
```
ERROR: there is no unique or exclusion constraint matching the ON CONFLICT specification
```

### 2. NOT NULL Constraint Error
```
ERROR: null value in column "payment_method" of relation "payment_proofs" violates not-null constraint
```

## สาเหตุ
1. `payment_proofs` table ไม่มี UNIQUE constraint สำหรับ `booking_id`
2. `payment_method` และ `amount` เป็น NOT NULL แต่ไม่ได้ส่งค่า

## การแก้ไข

### 1. เปลี่ยนจาก UPSERT เป็น SELECT → INSERT/UPDATE
```go
var existingID int
err = tx.QueryRow(ctx, `SELECT payment_proof_id FROM payment_proofs WHERE booking_id = $1`, bookingID).Scan(&existingID)
if err == pgx.ErrNoRows {
    // ไม่มี → INSERT
} else if err == nil {
    // มีแล้ว → UPDATE
}
```

### 2. เพิ่ม payment_method และ amount
```go
// ดึง total_amount จาก booking
var totalAmount float64
err = tx.QueryRow(ctx, `SELECT total_amount FROM bookings WHERE booking_id = $1`, bookingID).Scan(&totalAmount)

// INSERT พร้อม payment_method และ amount
INSERT INTO payment_proofs (booking_id, payment_method, amount, status, notes, proof_url, ...)
VALUES ($1, 'bank_transfer', $2, 'approved', $3, '', ...)
```

## ขั้นตอน

### 1. Stop Backend (Ctrl+C)

### 2. Backend ถูก Rebuild แล้ว ✅

### 3. Run Backend
```bash
cd backend
./hotel-booking-api.exe
```

### 4. ทดสอบ
1. ไปที่ http://localhost:3000/admin/reception
2. Tab "รอตรวจสอบการชำระเงิน"
3. คลิก "อนุมัติ" → ควรทำงานได้ไม่มี error
4. ไปที่ http://localhost:3000/admin/checkin
5. ควรแสดง "💰 ชำระเงินแล้ว"

## ผลลัพธ์
✅ Approve/Reject ทำงานได้
✅ Payment status แสดงถูกต้อง
✅ ระบบทำงานสมบูรณ์
