# แก้ปัญหา Admin Check-in ได้ 401 Unauthorized

## ปัญหา
หน้า Admin Check-in ไม่สามารถโหลดข้อมูลได้:
- Frontend log: `[Admin Layout] Authenticated with role: MANAGER`
- Frontend log: `[Admin Layout] Valid staff role, allowing access`
- แต่ API call ได้ `401 Unauthorized`
- Backend log: `[GET] 401 | 0s | ::1 | /api/checkin/arrivals?date=2025-11-08`

## สาเหตุ
**API routes ใช้ `session.user.accessToken` แทน `session.accessToken`**

ใน NextAuth session structure:
```typescript
{
  user: { name, email, role, ... },
  accessToken: "jwt_token_here"  // ← อยู่ที่ root level
}
```

แต่โค้ดใช้:
```typescript
'Authorization': `Bearer ${session.user.accessToken}`  // ❌ ผิด
```

ควรเป็น:
```typescript
'Authorization': `Bearer ${session.accessToken}`  // ✅ ถูก
```

## การแก้ไข

### ไฟล์ที่แก้ไข
1. `frontend/src/app/api/admin/checkin/arrivals/route.ts`
2. `frontend/src/app/api/admin/checkout/departures/route.ts`
3. `frontend/src/app/api/admin/checkin/route.ts`

### เปลี่ยนจาก
```typescript
headers: {
  'Authorization': `Bearer ${session.user.accessToken}`,
}
```

### เป็น
```typescript
headers: {
  'Authorization': `Bearer ${session.accessToken}`,
}
```

## ทดสอบ
1. Login เป็น Manager: `manager@hotel.com` / `Manager123!`
2. ไปที่หน้า Admin → Check-in
3. ควรเห็นรายการ arrivals สำหรับวันนี้
4. ถ้ามี booking ที่ confirm แล้ว ควรแสดงในรายการ
5. Backend log ควรแสดง `[GET] 200` แทน `[GET] 401`

## ตรวจสอบข้อมูล
```sql
-- ดู bookings ที่พร้อม check-in วันนี้
SELECT 
    b.booking_id,
    b.status,
    b.check_in_date,
    b.check_out_date,
    bg.first_name,
    bg.last_name
FROM bookings b
JOIN booking_guests bg ON b.booking_id = bg.booking_id AND bg.is_primary = true
WHERE b.check_in_date = CURRENT_DATE
  AND b.status IN ('Confirmed', 'PendingPayment')
ORDER BY b.created_at DESC;
```

## หมายเหตุ
- ถ้ายังไม่มีข้อมูล ให้ทำการจองห้องก่อน (complete booking)
- หรือรัน seed data: `database/migrations/020_seed_checkin_test_data.sql`
- Check-in จะแสดงเฉพาะ bookings ที่ check_in_date = วันนี้
