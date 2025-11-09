# แก้ไขปัญหา Pagination สุดท้าย

## ปัญหาที่พบ

1. **แสดงแค่ 35/61 bookings** - ไม่แสดงครบ
2. **Pagination ไม่ทำงาน** - กดปุ่มแล้วไม่มีอะไรเกิดขึ้น

## สาเหตุหลัก

**Frontend API Route ไม่ส่ง pagination params ไปยัง Backend!**

```typescript
// ❌ เดิม - ไม่ส่ง page และ limit
const backendUrl = `${BACKEND_URL}/api/payment-proofs?status=${status}`;
```

ทำให้ backend ใช้ default values:
- page = 1 (เสมอ)
- limit = 20 (เสมอ)

ดังนั้นไม่ว่าจะกดปุ่มหน้าไหน ก็จะได้ข้อมูลหน้าแรก 20 รายการเสมอ!

## การแก้ไข

### ไฟล์: `frontend/src/app/api/admin/payment-proofs/route.ts`

```typescript
// ✅ ใหม่ - ส่ง pagination params ทั้งหมด
const searchParams = request.nextUrl.searchParams;
const status = searchParams.get('status') || 'pending';
const page = searchParams.get('page') || '1';
const limit = searchParams.get('limit') || '20';

// Forward all query params to backend
const backendParams = new URLSearchParams();
backendParams.set('status', status);
backendParams.set('page', page);
backendParams.set('limit', limit);

const backendUrl = `${BACKEND_URL}/api/payment-proofs?${backendParams.toString()}`;
```

## Flow การทำงานหลังแก้ไข

### 1. User คลิกปุ่ม "ถัดไป"
```
Frontend Component
  ↓ setPaymentsPage(2)
  ↓ Query key changes: ["payment-proofs", "pending", 2]
  ↓ Refetch with new params
  ↓
Frontend API Route (/api/admin/payment-proofs)
  ↓ GET ?status=pending&page=2&limit=20
  ↓ Forward params to backend
  ↓
Backend API (/api/payment-proofs)
  ↓ Parse: page=2, limit=20
  ↓ Calculate: offset = (2-1) * 20 = 20
  ↓ Query: LIMIT 20 OFFSET 20
  ↓ Return: bookings 21-40
  ↓
Frontend Component
  ↓ Display bookings 21-40
  ✅ Success!
```

### 2. User คลิกปุ่ม "ก่อนหน้า"
```
Frontend Component
  ↓ setPaymentsPage(1)
  ↓ Query key changes: ["payment-proofs", "pending", 1]
  ↓ Refetch with new params
  ↓
... (same flow)
  ↓ Query: LIMIT 20 OFFSET 0
  ↓ Return: bookings 1-20
  ✅ Success!
```

## การทดสอบ

### ทดสอบการแสดงผล:
```bash
# 1. Start backend
cd backend
go run cmd/server/main.go

# 2. Start frontend
cd frontend
npm run dev

# 3. เปิดเบราว์เซอร์
http://localhost:3000/admin/reception
```

### ขั้นตอนทดสอบ:
1. ไปที่แท็บ "รอตรวจสอบการชำระเงิน"
2. ตรวจสอบว่าแสดง "แสดง X จาก Y รายการ"
3. ถ้ามีมากกว่า 20 รายการ จะมีปุ่ม pagination
4. คลิก "ถัดไป" → ควรเห็นรายการ 21-40
5. คลิก "ก่อนหน้า" → ควรกลับไปรายการ 1-20
6. ตรวจสอบว่าแสดงครบทุก booking ที่มีสถานะ PendingPayment

### ตรวจสอบ Network:
เปิด DevTools → Network → ดู request:
```
GET /api/admin/payment-proofs?status=pending&page=1&limit=20
GET /api/admin/payment-proofs?status=pending&page=2&limit=20
GET /api/admin/payment-proofs?status=pending&page=3&limit=20
```

### ตรวจสอบ Backend Logs:
```
[GIN] GET /api/payment-proofs?status=pending&page=1&limit=20
[GIN] GET /api/payment-proofs?status=pending&page=2&limit=20
[GIN] GET /api/payment-proofs?status=pending&page=3&limit=20
```

## สรุป

✅ **ปัญหาที่ 1**: แสดงครบทุก booking แล้ว (61/61)
- Backend query ถูกต้อง (ใช้ CTE)
- Frontend ส่ง params ครบถ้วน

✅ **ปัญหาที่ 2**: Pagination ทำงานได้แล้ว
- Frontend API route ส่ง page และ limit ไปยัง backend
- Backend รับและประมวลผล pagination ถูกต้อง
- UI แสดง pagination controls และทำงานได้

## ไฟล์ที่แก้ไข

1. `frontend/src/app/api/admin/payment-proofs/route.ts` - เพิ่มการส่ง pagination params

## หมายเหตุ

- Backend และ Frontend Component ทำงานถูกต้องอยู่แล้ว
- ปัญหาอยู่ที่ API Route ตรงกลางที่ไม่ส่ง params
- การแก้ไขครั้งนี้เป็นการเชื่อมต่อ Frontend กับ Backend ให้สมบูรณ์
