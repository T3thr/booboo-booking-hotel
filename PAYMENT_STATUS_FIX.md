# แก้ไขปัญหา Payment Status ไม่แสดงหลัง Approve

## ปัญหาที่พบ

หลังจาก approve booking ใน `/admin/reception` แล้ว ไปดูที่ `/admin/checkin` ยังแสดงว่า "ยังไม่ชำระ" แทนที่จะเป็น "ชำระเงินแล้ว"

## สาเหตุ

เมื่อ approve booking ที่**ไม่มี** payment_proof record ใน database:
- Backend พยายาม UPDATE payment_proofs แต่ไม่มี record → ไม่เกิดอะไร
- Query ใน GetArrivals: `COALESCE(pp.status, 'none')` → return 'none'
- Frontend แสดง badge "ยังไม่ชำระ"

**สถานการณ์ที่เกิด**:
1. Guest จองแต่ยังไม่อัปโหลดหลักฐาน → ไม่มี payment_proof record
2. Admin approve โดยตรง → UPDATE ไม่เจอ record
3. Check-in แสดง payment_status = 'none' → "ยังไม่ชำระ" ❌

## การแก้ไข

### ไฟล์: `backend/internal/repository/payment_proof_repository.go`

เปลี่ยนจาก UPDATE เป็น **UPSERT** (INSERT ... ON CONFLICT DO UPDATE):

```go
// ✅ ใหม่ - UPSERT (สร้างถ้าไม่มี, อัปเดตถ้ามี)
_, err = tx.Exec(ctx, `
    INSERT INTO payment_proofs (booking_id, status, notes, proof_url, created_at, updated_at)
    VALUES ($1, 'approved', $2, '', NOW(), NOW())
    ON CONFLICT (booking_id) 
    DO UPDATE SET 
        status = 'approved',
        notes = COALESCE($2, payment_proofs.notes),
        updated_at = NOW()
`, bookingID, notes)
```

**ทำงานอย่างไร**:
1. พยายาม INSERT record ใหม่
2. ถ้ามี booking_id ซ้ำ (CONFLICT) → UPDATE แทน
3. ผลลัพธ์: มั่นใจว่ามี payment_proof record เสมอ

## ผลลัพธ์

### ก่อนแก้ไข:
```
Approve booking (ไม่มี payment_proof)
  ↓ UPDATE payment_proofs ... (ไม่เจอ record)
  ↓ ไม่มีอะไรเกิดขึ้น
  ↓
Check-in query: COALESCE(pp.status, 'none') → 'none'
  ↓ แสดง: "ยังไม่ชำระ" ❌
```

### หลังแก้ไข:
```
Approve booking (ไม่มี payment_proof)
  ↓ INSERT payment_proofs (booking_id, status='approved', ...)
  ↓ สร้าง record ใหม่ ✅
  ↓
Check-in query: COALESCE(pp.status, 'none') → 'approved'
  ↓ แสดง: "💰 ชำระเงินแล้ว" ✅
```

## สถานการณ์ที่รองรับ

### 1. Guest อัปโหลดหลักฐาน → Admin approve
```
Guest upload → payment_proof (status='pending')
  ↓
Admin approve → UPDATE status='approved' ✅
  ↓
Check-in → "💰 ชำระเงินแล้ว" ✅
```

### 2. Guest ไม่อัปโหลด → Admin approve โดยตรง
```
Guest จอง → ไม่มี payment_proof
  ↓
Admin approve → INSERT payment_proof (status='approved') ✅
  ↓
Check-in → "💰 ชำระเงินแล้ว" ✅
```

### 3. Guest อัปโหลดหลักฐาน → Admin reject
```
Guest upload → payment_proof (status='pending')
  ↓
Admin reject → UPDATE status='rejected' ✅
  ↓
Booking cancelled
```

## การทดสอบ

### Test Case 1: Approve booking ที่มีหลักฐาน
```bash
# 1. Guest จอง + อัปโหลดหลักฐาน
# 2. ไปที่ /admin/reception → "รอตรวจสอบการชำระเงิน"
# 3. คลิก "อนุมัติ"
# 4. ไปที่ /admin/checkin
# Expected: แสดง "💰 ชำระเงินแล้ว" ✅
```

### Test Case 2: Approve booking ที่ไม่มีหลักฐาน (ปัญหาเดิม)
```bash
# 1. Guest จอง (ไม่อัปโหลดหลักฐาน)
# 2. ไปที่ /admin/reception → "รอตรวจสอบการชำระเงิน"
# 3. คลิก "อนุมัติ" (admin ยืนยันว่าชำระแล้ว)
# 4. ไปที่ /admin/checkin
# Expected: แสดง "💰 ชำระเงินแล้ว" ✅ (แก้ไขแล้ว)
```

### Test Case 3: Reject booking
```bash
# 1. Guest จอง + อัปโหลดหลักฐาน
# 2. ไปที่ /admin/reception
# 3. คลิก "ปฏิเสธ" + ระบุเหตุผล
# 4. Booking ควรถูก cancel
# Expected: ไม่แสดงใน /admin/checkin ✅
```

## Database Schema

ตรวจสอบว่า payment_proofs table มี UNIQUE constraint:

```sql
-- ตรวจสอบ
SELECT * FROM pg_indexes WHERE tablename = 'payment_proofs';

-- ถ้าไม่มี UNIQUE constraint ให้เพิ่ม
ALTER TABLE payment_proofs 
ADD CONSTRAINT payment_proofs_booking_id_key UNIQUE (booking_id);
```

## สรุป

✅ **แก้ไข**: ใช้ UPSERT แทน UPDATE
✅ **ผลลัพธ์**: Payment status แสดงถูกต้องเสมอ
✅ **รองรับ**: ทั้งกรณีมีและไม่มี payment_proof record
✅ **Workflow**: Approve = ยืนยันการชำระเงิน → แสดง "ชำระเงินแล้ว"

## ไฟล์ที่แก้ไข

1. `backend/internal/repository/payment_proof_repository.go`
   - เปลี่ยน UPDATE เป็น UPSERT (INSERT ... ON CONFLICT)
   - ทั้ง approve และ reject
