# แก้ไขการแสดงสถานะใน Check-in Page

## ปัญหาที่พบ

หน้า `/admin/checkin` แสดง booking ที่ยังไม่ได้ชำระเงิน (PendingPayment) ด้วย ทำให้ receptionist สับสนและไม่สามารถจัดการได้อย่างถูกต้อง

## สาเหตุ

Backend query ใน `GetArrivals` รวม status `'PendingPayment'` ด้วย:

```sql
-- ❌ เดิม
WHERE bd.check_in_date = $1
  AND b.status IN ('Confirmed', 'CheckedIn', 'PendingPayment')
```

## การแก้ไข

### 1. Backend - แก้ไข GetArrivals Query

**ไฟล์**: `backend/internal/repository/booking_repository.go`

```sql
-- ✅ ใหม่ - แสดงเฉพาะ Confirmed และ CheckedIn
WHERE bd.check_in_date = $1
  AND b.status IN ('Confirmed', 'CheckedIn')
```

**เหตุผล**:
- `PendingPayment` = ยังไม่ได้รับการอนุมัติ → ไม่ควรแสดงใน check-in
- `Confirmed` = อนุมัติแล้ว → พร้อม check-in
- `CheckedIn` = เช็คอินแล้ว → แสดงเพื่อดูข้อมูล

### 2. Frontend - เพิ่ม Booking Status Badge

**ไฟล์**: `frontend/src/app/admin/(staff)/checkin/page.tsx`

```typescript
// เพิ่ม status field ใน interface
interface Arrival {
  // ... existing fields
  status: string;  // ✅ เพิ่ม
  // ...
}

// เพิ่ม status badges ใน UI
<div className="mt-2 flex flex-wrap gap-2">
  {/* Booking Status */}
  {arrival.status === 'Confirmed' && (
    <span className="... bg-blue-100 text-blue-800">
      ✓ ยืนยันแล้ว
    </span>
  )}
  {arrival.status === 'CheckedIn' && (
    <span className="... bg-green-100 text-green-800">
      ✓ เช็คอินแล้ว
    </span>
  )}
  
  {/* Payment Status */}
  {arrival.payment_status === 'approved' ? (
    <span className="... bg-green-100 text-green-800">
      💰 ชำระเงินแล้ว
    </span>
  ) : ...}
</div>
```

## ผลลัพธ์

### ก่อนแก้ไข:
```
Check-in Page แสดง:
- Booking #1 (PendingPayment) ❌ ไม่ควรแสดง
- Booking #2 (Confirmed) ✓
- Booking #3 (CheckedIn) ✓
```

### หลังแก้ไข:
```
Check-in Page แสดง:
- Booking #2 (Confirmed) ✓ พร้อม check-in
- Booking #3 (CheckedIn) ✓ เช็คอินแล้ว

Booking #1 (PendingPayment) → แสดงเฉพาะใน /admin/reception
```

## Status Flow

```
Guest จอง
  ↓
PendingPayment (รอชำระเงิน)
  ↓ แสดงใน: /admin/reception → "รอตรวจสอบการชำระเงิน"
  ↓
Admin อนุมัติ
  ↓
Confirmed (ยืนยันแล้ว)
  ↓ แสดงใน: /admin/checkin → "Arrivals" ✅
  ↓
Receptionist assign room + check-in
  ↓
CheckedIn (เช็คอินแล้ว)
  ↓ แสดงใน: /admin/checkin → "Arrivals" (เพื่อดูข้อมูล)
  ↓ แสดงใน: /admin/checkout → "Departures"
  ↓
Check-out
  ↓
Completed (เสร็จสิ้น)
```

## Status Badges

### Booking Status:
- 🔵 **ยืนยันแล้ว** (Confirmed) - พร้อม check-in
- 🟢 **เช็คอินแล้ว** (CheckedIn) - อยู่ในโรงแรม

### Payment Status:
- 🟢 **💰 ชำระเงินแล้ว** (approved) - อนุมัติแล้ว
- 🟡 **⏳ รอตรวจสอบ** (pending) - รอ admin ตรวจสอบ
- 🔴 **✗ ยังไม่ชำระ** (none) - ยังไม่มีหลักฐาน

## การทดสอบ

### ทดสอบ Check-in Page:
```bash
# 1. Start backend & frontend
# 2. ไปที่ /admin/reception
# 3. อนุมัติ booking 1-2 รายการ
# 4. ไปที่ /admin/checkin
# 5. ตรวจสอบว่า:
```

**Expected:**
- ✅ แสดงเฉพาะ booking ที่ Confirmed และ CheckedIn
- ✅ ไม่แสดง booking ที่ PendingPayment
- ✅ แสดง status badge ชัดเจน (ยืนยันแล้ว / เช็คอินแล้ว)
- ✅ แสดง payment status (ชำระเงินแล้ว / รอตรวจสอบ)
- ✅ Receptionist สามารถ assign room และ check-in ได้

### ทดสอบ Reception Page:
```bash
# 1. ไปที่ /admin/reception
# 2. แท็บ "รอตรวจสอบการชำระเงิน"
# 3. ตรวจสอบว่า:
```

**Expected:**
- ✅ แสดง booking ที่ PendingPayment
- ✅ สามารถอนุมัติ/ปฏิเสธได้
- ✅ หลังอนุมัติ → booking หายจากรายการ
- ✅ หลังอนุมัติ → booking ปรากฏใน /admin/checkin

## สรุป

✅ **Backend**: แก้ query ให้แสดงเฉพาะ Confirmed และ CheckedIn
✅ **Frontend**: เพิ่ม booking status badge
✅ **UX**: Receptionist เห็นสถานะชัดเจน
✅ **Workflow**: แยก PendingPayment (reception) และ Confirmed (check-in) อย่างชัดเจน

## ไฟล์ที่แก้ไข

1. `backend/internal/repository/booking_repository.go` - แก้ GetArrivals query
2. `frontend/src/app/admin/(staff)/checkin/page.tsx` - เพิ่ม status badge
