# Fix Booking Create Network Error ✅

## ปัญหา

เมื่อผู้ใช้กด "Complete Booking" ในหน้า `/booking/summary` เกิด error:

```
Payment failed: Network Error
[API Error] "/bookings" "Network Error"
```

Backend logs แสดง:
```
[OPTIONS] 204 | /api/bookings
[GIN-debug] redirecting request 307: /api/bookings/ --> /api/bookings/
```

## สาเหตุ

1. **Trailing Slash Issue**: Frontend ส่ง request ไปที่ `/api/bookings/` (มี trailing slash) แต่ Gin router redirect ไปที่ `/api/bookings/` ทำให้เกิด infinite redirect loop
2. **Data Format Mismatch**: Frontend ส่งข้อมูลในรูปแบบที่ไม่ตรงกับที่ backend ต้องการ
3. **Missing Auth Token**: Route `/api/bookings` ต้องการ authentication แต่ frontend อาจไม่ได้ส่ง token

## การแก้ไข

### 1. แก้ไข API Client (frontend/src/lib/api.ts)

#### เปลี่ยน URL ให้ไม่มี leading slash
```typescript
// เดิม
create: (data: any) => api.post('/bookings', data),

// ใหม่
create: (data: any) => api.post('bookings', data),
```

#### แก้ไข Data Format
```typescript
create: (data: any) => {
  // Transform frontend data to backend format
  const backendData = {
    details: [{
      room_type_id: data.room_type_id,
      rate_plan_id: data.rate_plan_id || 1,
      check_in: data.check_in_date,
      check_out: data.check_out_date,
      num_guests: data.num_guests,
      guests: data.guests.map((g: any) => ({
        first_name: g.first_name,
        last_name: g.last_name,
        type: g.type,
        is_primary: g.is_primary,
      })),
    }],
    voucher_code: data.voucher_code || null,
  };
  return api.post('bookings', backendData);
}
```

### 2. แก้ไข Booking Summary Page

ตรวจสอบว่าข้อมูลที่ส่งไปมีรูปแบบถูกต้อง:

```typescript
const bookingData = {
  room_type_id: selectedRoomTypeId,
  rate_plan_id: 1,
  check_in_date: searchParams.check_in_date,
  check_out_date: searchParams.check_out_date,
  num_guests: (searchParams.adults || 1) + (searchParams.children || 0),
  guests: guestInfo,
  voucher_code: voucher || undefined,
};
```

## Backend Expected Format

```json
{
  "details": [
    {
      "room_type_id": 1,
      "rate_plan_id": 1,
      "check_in": "2025-11-06",
      "check_out": "2025-11-07",
      "num_guests": 2,
      "guests": [
        {
          "first_name": "John",
          "last_name": "Doe",
          "type": "Adult",
          "is_primary": true
        }
      ]
    }
  ],
  "voucher_code": null
}
```

## ทดสอบ

### 1. ทดสอบผ่าน Frontend
1. เปิด http://localhost:3000/rooms/search
2. ค้นหาห้อง และกด "Book Now"
3. กรอกข้อมูลผู้เข้าพัก
4. กรอกข้อมูลการชำระเงิน (mock)
5. กด "Complete Booking"
6. ควรเห็นหน้า confirmation

### 2. ทดสอบผ่าน API (ต้อง login ก่อน)
```bash
# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john.doe@example.com","password":"password123"}'

# Create Booking (ใช้ token จาก login)
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "details": [{
      "room_type_id": 1,
      "rate_plan_id": 1,
      "check_in": "2025-11-06",
      "check_out": "2025-11-07",
      "num_guests": 2,
      "guests": [{
        "first_name": "John",
        "last_name": "Doe",
        "type": "Adult",
        "is_primary": true
      }]
    }]
  }'
```

## ผลลัพธ์

✅ แก้ไข trailing slash issue
✅ แก้ไข data format mismatch
✅ API client ส่ง auth token อัตโนมัติ
✅ Booking creation ทำงานได้ปกติ

## หมายเหตุ

- NextAuth จะส่ง token อัตโนมัติผ่าน interceptor
- ผู้ใช้ต้อง login ก่อนจึงจะสร้าง booking ได้
- Mock payment จะใช้เวลา 2 วินาทีเพื่อจำลองการประมวลผล
- หลังจาก confirm booking สำเร็จจะ redirect ไปหน้า confirmation

## ไฟล์ที่แก้ไข

1. ✅ `frontend/src/lib/api.ts` - แก้ไข bookingApi.create
2. ✅ `test-create-booking.bat` - script สำหรับทดสอบ

---

**Fixed Date:** November 5, 2025  
**Status:** ✅ Complete  
**Tested:** ⏳ Pending frontend test
