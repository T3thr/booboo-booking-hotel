# แก้ไขระบบ Booking สำหรับ Guest Account

## ปัญหาที่พบ

### 1. ข้อมูล Guest Account ไม่ถูกต้องใน Admin/Reception
- Guest account ที่ login แล้วจอง แต่แสดงชื่อ "Fon Testuser" แทนชื่อจริง
- Email และ Phone ไม่ตรงกับ account ที่ login

### 2. สถานะ Hold/Confirmed ไม่แสดงใน Admin/Checkin
- Hold booking (ยังไม่ complete) ควรแสดง "ยังไม่ยืนยัน"
- Complete booking ควรแสดง "ยืนยันแล้ว"

### 3. สถานะการชำระเงิน
- ควบคุมโดยการ Approve ใน Admin/Reception

## สาเหตุ

### Frontend (✅ ทำงานถูกต้องแล้ว)
```typescript
// guest-info/page.tsx - Line 400+
if (session?.user) {
  // ใช้ข้อมูลจาก account
  finalGuests[0] = {
    first_name: accountFirstName,
    last_name: accountLastName,
    phone: accountPhone,
    email: accountEmail,  // ✅ ส่งข้อมูลถูกต้อง
  };
}
```

### Backend (❌ ต้องตรวจสอบ)
ต้องตรวจสอบว่า:
1. Backend รับข้อมูล guest ถูกต้องหรือไม่
2. บันทึกลง `booking_guests` table ถูกต้องหรือไม่
3. Query ใน admin/reception ดึงข้อมูลถูกต้องหรือไม่

## การแก้ไข

### ขั้นตอนที่ 1: ตรวจสอบ Backend Booking Handler

ต้องตรวจสอบไฟล์:
- `backend/internal/handlers/booking_handler.go`
- `backend/internal/service/booking_service.go`
- `backend/internal/repository/booking_repository.go`

ให้แน่ใจว่า:
```go
// บันทึก email และ phone จาก request
for _, guest := range req.Guests {
    _, err = tx.Exec(ctx, `
        INSERT INTO booking_guests (
            booking_detail_id, 
            first_name, 
            last_name, 
            email,      -- ✅ ต้องมี
            phone,      -- ✅ ต้องมี
            type, 
            is_primary
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, bookingDetailID, guest.FirstName, guest.LastName, 
       guest.Email, guest.Phone, guest.Type, guest.IsPrimary)
}
```

### ขั้นตอนที่ 2: ตรวจสอบ Admin/Reception Query

ต้องตรวจสอบ:
- `backend/internal/repository/payment_proof_repository.go`
- Method: `GetPaymentProofs()`

ให้แน่ใจว่า query ดึง email และ phone จาก `booking_guests`:
```sql
SELECT 
    bg.email,  -- ✅ ต้องดึง
    bg.phone,  -- ✅ ต้องดึง
    bg.first_name,
    bg.last_name
FROM booking_guests bg
WHERE bg.is_primary = true
```

### ขั้นตอนที่ 3: เพิ่มสถานะ Hold/Confirmed ใน Admin/Checkin

ต้องแก้ไข:
- `frontend/src/app/admin/(staff)/checkin/page.tsx`
- `backend/internal/handlers/checkin_handler.go`

เพิ่ม field `booking_status` ใน response:
```typescript
interface Arrival {
  booking_id: number;
  booking_status: 'PendingPayment' | 'Confirmed';  // ✅ เพิ่ม
  payment_status: 'pending' | 'paid';               // ✅ เพิ่ม
  guest_name: string;
  // ...
}
```

แสดงสถานะ:
```typescript
{arrival.booking_status === 'PendingPayment' && (
  <span className="text-yellow-600">⏳ ยังไม่ยืนยัน</span>
)}
{arrival.booking_status === 'Confirmed' && (
  <span className="text-green-600">✅ ยืนยันแล้ว</span>
)}

{arrival.payment_status === 'pending' && (
  <span className="text-orange-600">💳 ยังไม่ชำระ</span>
)}
{arrival.payment_status === 'paid' && (
  <span className="text-green-600">💰 ชำระเงินแล้ว</span>
)}
```

## Workflow ที่ถูกต้อง

```
Guest Account Login
    ↓
Search Rooms → Select Room
    ↓
Guest Info (auto-fill from account)
    ↓
Create Hold → Status: PendingPayment
    ↓
Admin/Checkin แสดง: "⏳ ยังไม่ยืนยัน" + "💳 ยังไม่ชำระ"
    ↓
Complete Booking → Status: Confirmed
    ↓
Admin/Checkin แสดง: "✅ ยืนยันแล้ว" + "💳 ยังไม่ชำระ"
    ↓
Admin/Reception → Approve Payment
    ↓
Admin/Checkin แสดง: "✅ ยืนยันแล้ว" + "💰 ชำระเงินแล้ว"
    ↓
Receptionist Check-in → Status: CheckedIn
```

## ไฟล์ที่ต้องแก้ไข

### Backend:
1. `backend/internal/handlers/booking_handler.go` - ตรวจสอบการบันทึก guest data
2. `backend/internal/repository/booking_repository.go` - ตรวจสอบ INSERT query
3. `backend/internal/repository/payment_proof_repository.go` - แก้ไข query ดึงข้อมูล
4. `backend/internal/handlers/checkin_handler.go` - เพิ่ม booking_status และ payment_status

### Frontend:
1. `frontend/src/app/admin/(staff)/checkin/page.tsx` - แสดงสถานะ hold/confirmed
2. `frontend/src/app/admin/(staff)/reception/page.tsx` - ตรวจสอบการแสดงข้อมูล guest

## ขั้นตอนทดสอบ

1. **ทดสอบ Guest Account Booking:**
   ```
   - Login ด้วย guest account
   - จองห้อง → ตรวจสอบว่าข้อมูล auto-fill ถูกต้อง
   - Complete booking
   - ไปที่ Admin/Reception → ตรวจสอบชื่อ, email, phone
   ```

2. **ทดสอบสถานะ Hold:**
   ```
   - สร้าง hold (ยังไม่ complete)
   - ไปที่ Admin/Checkin → ควรแสดง "ยังไม่ยืนยัน"
   - Complete booking
   - Refresh Admin/Checkin → ควรแสดง "ยืนยันแล้ว"
   ```

3. **ทดสอบสถานะชำระเงิน:**
   ```
   - Complete booking → ควรแสดง "ยังไม่ชำระ"
   - Admin/Reception → Approve
   - Admin/Checkin → ควรแสดง "ชำระเงินแล้ว"
   ```

## หมายเหตุ

- Frontend ส่งข้อมูลถูกต้องแล้ว ✅
- ปัญหาน่าจะอยู่ที่ Backend การบันทึกหรือ Query ❌
- ต้องตรวจสอบ Backend ก่อน
