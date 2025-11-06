# Fix Booking Confirm "undefined" Error

## ปัญหา
เมื่อผู้ใช้กด "Complete Booking" ในหน้า summary จะเกิด error:
```
[POST] 400 | 0s | ::1 | /api/bookings/undefined/confirm
Confirm booking failed: 400
```

Booking ถูกสร้างสำเร็จ (201) แต่ booking ID เป็น `undefined` เมื่อพยายาม confirm

## สาเหตุ
ใน `frontend/src/app/(guest)/booking/summary/page.tsx` บรรทัด 130-131:
```typescript
const bookingResponse: any = await createBooking.mutateAsync(bookingData);
const newBookingId = bookingResponse.booking_id;
```

Response structure อาจจะแตกต่างจากที่คาดหวัง ทำให้ `booking_id` เป็น undefined

## การแก้ไข

### 1. เพิ่ม Fallback และ Logging
อัพเดทโค้ดให้รองรับ response structures หลายแบบ:

```typescript
const bookingResponse: any = await createBooking.mutateAsync(bookingData);
console.log('Booking response:', bookingResponse);

// Handle different response structures
const newBookingId = bookingResponse.booking_id || 
                    bookingResponse.data?.booking_id || 
                    bookingResponse.bookingId;

if (!newBookingId) {
  throw new Error('Booking ID not found in response');
}

setBookingId(newBookingId);
```

### 2. ตรวจสอบ Response จาก Backend
Backend ควรส่ง response ในรูปแบบ:
```json
{
  "booking_id": 123,
  "total_amount": 4500.00,
  "status": "pending",
  "message": "Booking created successfully"
}
```

### 3. ตรวจสอบ Console Log
เมื่อทดสอบอีกครั้ง ให้ดู console log เพื่อดู response structure ที่แท้จริง:
- เปิด Browser DevTools (F12)
- ไปที่ Console tab
- ทำการจองใหม่
- ดู log "Booking response:" เพื่อดู structure

## ไฟล์ที่แก้ไข
- `frontend/src/app/(guest)/booking/summary/page.tsx` - เพิ่ม fallback และ error handling

## การทดสอบ
1. ค้นหาห้องพัก
2. เลือกห้องและสร้าง hold
3. กรอกข้อมูลผู้เข้าพัก
4. กรอกข้อมูลการชำระเงิน (mock)
5. กด "Complete Booking"
6. ตรวจสอบ console log เพื่อดู booking response
7. ควรจะ redirect ไปหน้า confirmation โดยไม่มี error

## หมายเหตุ
หากยังมีปัญหา ให้ตรวจสอบ:
- Backend response format ใน `backend/internal/handlers/booking_handler.go`
- Next.js API proxy ใน `frontend/src/app/api/bookings/route.ts`
- ตรวจสอบว่า session/auth token ถูกส่งไปยัง backend ถูกต้อง
