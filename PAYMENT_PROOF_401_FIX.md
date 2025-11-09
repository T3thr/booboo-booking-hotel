# แก้ปัญหา Payment Proof API ได้ 401 Unauthorized

## ปัญหา
หน้า Admin Reception → แท็บ "รอตรวจสอบการชำระเงิน" ได้ 401:
- `GET /api/admin/payment-proofs?status=pending 401`
- User login เป็น MANAGER แล้ว
- แต่ API return 401 Unauthorized

## สาเหตุ
**Role check ใช้ lowercase แต่ role จริงเป็น uppercase**

Code เดิม:
```typescript
if (!session || (session.user.role !== 'manager' && session.user.role !== 'receptionist'))
```

แต่ role จริงจาก session:
```typescript
session.user.role = 'MANAGER'  // ← uppercase
```

## การแก้ไข

### แก้ทั้ง 3 ไฟล์:
1. `frontend/src/app/api/admin/payment-proofs/route.ts`
2. `frontend/src/app/api/admin/payment-proofs/[id]/approve/route.ts`
3. `frontend/src/app/api/admin/payment-proofs/[id]/reject/route.ts`

### เปลี่ยนจาก:
```typescript
if (!session || (session.user.role !== 'manager' && session.user.role !== 'receptionist')) {
  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
}
```

### เป็น:
```typescript
const userRole = session?.user?.role?.toUpperCase();
if (!session || !session.accessToken || (userRole !== 'MANAGER' && userRole !== 'RECEPTIONIST')) {
  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
}
```

## ทดสอบ
1. Refresh หน้า Admin Reception
2. คลิกแท็บ "รอตรวจสอบการชำระเงิน"
3. ควรเห็นรายการ payment proofs ที่รอ approve

## Workflow: Payment Proof → Check-in

### 1. Guest Complete Booking
- Guest จองห้องและ upload payment proof
- Booking status: `PendingPayment`
- Payment proof status: `pending`

### 2. Admin Approve Payment (หน้า Reception)
- Admin ไปที่ Reception → "รอตรวจสอบการชำระเงิน"
- กด Approve payment proof
- Booking status เปลี่ยนเป็น: `Confirmed`
- Payment proof status เปลี่ยนเป็น: `approved`

### 3. Receptionist Check-in (หน้า Check-in)
- Receptionist ไปที่ Check-in
- เห็น booking ที่ status = `Confirmed`
- เลือกห้องว่างให้ guest
- กด Check-in
- Booking status เปลี่ยนเป็น: `CheckedIn`

## Database Flow
```sql
-- 1. Guest complete booking
INSERT INTO bookings (status) VALUES ('PendingPayment');
INSERT INTO payment_proofs (status) VALUES ('pending');

-- 2. Admin approve payment
UPDATE payment_proofs SET status = 'approved' WHERE payment_proof_id = ?;
UPDATE bookings SET status = 'Confirmed' WHERE booking_id = ?;

-- 3. Receptionist check-in
INSERT INTO room_assignments (booking_detail_id, room_id);
UPDATE bookings SET status = 'CheckedIn' WHERE booking_id = ?;
```

## ไฟล์ที่แก้ไข
- `frontend/src/app/api/admin/payment-proofs/route.ts`
- `frontend/src/app/api/admin/payment-proofs/[id]/approve/route.ts`
- `frontend/src/app/api/admin/payment-proofs/[id]/reject/route.ts`

**ตอนนี้ refresh หน้า Admin Reception ควรทำงานได้แล้ว!**
