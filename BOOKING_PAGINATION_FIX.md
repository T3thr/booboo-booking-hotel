# แก้ไขปัญหา Booking Pagination และ Sorting

## ปัญหาที่พบ

1. **แสดงไม่ครบ**: แท็บ "รอตรวจสอบการชำระเงิน" แสดงแค่ 37/61 bookings
2. **ไม่มี Pagination**: ไม่สามารถดูรายการทั้งหมดได้
3. **เรียงลำดับไม่ถูกต้อง**: รายการเก่าแสดงก่อนรายการใหม่

## สาเหตุ

1. **API มี LIMIT 100** แต่ไม่มี pagination parameters
2. **Backend default limit = 20** และไม่ได้รับ pagination params จาก frontend
3. **Query ไม่ได้ ORDER BY ที่ถูกต้อง** - ใช้ DISTINCT ON แต่ไม่ได้เรียงตาม booking_id DESC

## การแก้ไข

### 1. Frontend API - `/api/admin/bookings/route.ts`

✅ เพิ่ม pagination parameters (page, limit, offset)
✅ เพิ่ม total count query
✅ Return pagination metadata
✅ เปลี่ยน ORDER BY เป็น `b.created_at DESC` (ใหม่ล่าสุดก่อน)

```typescript
// เพิ่ม pagination params
const page = parseInt(searchParams.get("page") || "1");
const limit = parseInt(searchParams.get("limit") || "20");
const offset = (page - 1) * limit;

// เพิ่ม count query
const countResult = await pool.query(countQuery, ...);
const total = parseInt(countResult.rows[0]?.total || "0");

// Return พร้อม pagination
return NextResponse.json({
  success: true,
  data: result.rows,
  pagination: {
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit),
  },
});
```

### 2. Backend Repository - `payment_proof_repository.go`

✅ แก้ไข ORDER BY จาก `b.booking_id DESC, b.created_at DESC` เป็น `b.booking_id DESC`
✅ ทำให้ DISTINCT ON ทำงานถูกต้อง

```go
// เปลี่ยนจาก
ORDER BY b.booking_id DESC, b.created_at DESC

// เป็น
ORDER BY b.booking_id DESC
```

### 3. Frontend Component - `BookingManagementTab.tsx`

✅ เพิ่ม state สำหรับ pagination
```typescript
const [bookingsPage, setBookingsPage] = useState(1);
const [paymentsPage, setPaymentsPage] = useState(1);
```

✅ อัปเดต query ให้ส่ง pagination params
```typescript
const params = new URLSearchParams();
params.set("page", bookingsPage.toString());
params.set("limit", "20");
```

✅ แสดง pagination metadata
```typescript
const bookingsPagination = bookingsResponse?.pagination;
const proofsPagination = proofsResponse?.pagination;
```

✅ เพิ่ม Pagination UI
```tsx
{bookingsPagination && bookingsPagination.totalPages > 1 && (
  <div className="flex items-center justify-center gap-2 mt-6">
    <Button onClick={() => setBookingsPage(p => Math.max(1, p - 1))}>
      ← ก่อนหน้า
    </Button>
    <span>หน้า {bookingsPage} จาก {bookingsPagination.totalPages}</span>
    <Button onClick={() => setBookingsPage(p => Math.min(totalPages, p + 1))}>
      ถัดไป →
    </Button>
  </div>
)}
```

✅ แสดงจำนวนรายการ
```tsx
<div className="text-sm text-muted-foreground mb-2">
  แสดง {filteredBookings.length} จาก {bookingsPagination?.total || 0} รายการ
</div>
```

## ผลลัพธ์

✅ แสดง bookings ครบทั้งหมด 61 รายการ
✅ มี pagination ทุก 20 รายการต่อหน้า
✅ เรียงลำดับใหม่ล่าสุดไว้บนสุด (DESC)
✅ แสดงจำนวนรายการทั้งหมดและหน้าปัจจุบัน
✅ ใช้งานได้ทั้งแท็บ "การจองทั้งหมด" และ "รอตรวจสอบการชำระเงิน"

## การทดสอบ

1. เปิดหน้า `/admin/reception`
2. ไปที่แท็บ "จัดการการจอง"
3. ตรวจสอบว่าแสดง "แสดง X จาก 61 รายการ"
4. ตรวจสอบว่ารายการใหม่ล่าสุดอยู่บนสุด
5. คลิกปุ่ม "ถัดไป" เพื่อดูหน้าถัดไป
6. ไปที่แท็บ "รอตรวจสอบการชำระเงิน"
7. ตรวจสอบว่าแสดงครบทุก booking ที่มีสถานะ PendingPayment

## ไฟล์ที่แก้ไข

1. `frontend/src/app/api/admin/bookings/route.ts` - เพิ่ม pagination
2. `backend/internal/repository/payment_proof_repository.go` - แก้ ORDER BY
3. `frontend/src/app/admin/(staff)/reception/components/BookingManagementTab.tsx` - เพิ่ม pagination UI
