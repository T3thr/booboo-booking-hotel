# ✅ แก้ไข Booking Hold - สำเร็จ!

## ปัญหาที่พบ

Frontend ส่งข้อมูลไม่ครบและชื่อ field ไม่ตรงกับที่ Backend ต้องการ:

### Backend ต้องการ (CreateBookingHoldRequest):
```go
{
  session_id: string (required),
  room_type_id: int (required),
  check_in: string (required),      // Format: "YYYY-MM-DD"
  check_out: string (required),     // Format: "YYYY-MM-DD"
  guest_account_id: *int (optional)
}
```

### Frontend ส่งมา (เดิม):
```javascript
{
  room_type_id: number,
  check_in_date: string,  // ❌ ชื่อไม่ตรง
  check_out_date: string  // ❌ ชื่อไม่ตรง
  // ❌ ไม่มี session_id
}
```

## การแก้ไข

แก้ไขใน `frontend/src/lib/api.ts`:

```typescript
export const bookingApi = {
  createHold: (data: any) => {
    // 1. สร้าง session_id สำหรับ guest
    let sessionId = '';
    if (typeof window !== 'undefined') {
      sessionId = sessionStorage.getItem('booking_session_id') || '';
      if (!sessionId) {
        sessionId = `guest_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        sessionStorage.setItem('booking_session_id', sessionId);
      }
    }
    
    // 2. แปลง format ให้ตรงกับ backend
    const backendData = {
      session_id: sessionId,
      room_type_id: data.room_type_id,
      check_in: data.check_in_date || data.check_in,
      check_out: data.check_out_date || data.check_out,
      guest_account_id: data.guest_account_id,
    };
    
    return api.post('/bookings/hold', backendData);
  },
  // ...
};
```

## สิ่งที่เปลี่ยนแปลง

1. ✅ **สร้าง session_id อัตโนมัติ** - ใช้ sessionStorage เก็บ session ID ของ guest
2. ✅ **แปลงชื่อ field** - `check_in_date` → `check_in`, `check_out_date` → `check_out`
3. ✅ **รองรับทั้ง 2 format** - รองรับทั้ง `check_in_date` และ `check_in`

## Booking Flow ที่ถูกต้อง

```
[ค้นหาห้อง] → [แสดงห้องว่าง] → [เลือกห้อง]
         ↓
[สร้าง Hold (15 นาที)] → tentative_count++
         ↓
[กรอกข้อมูลแขก] → [สร้าง Booking (PendingPayment)]
         ↓
[ชำระเงิน (Mock)] → [Confirm Booking]
         ↓
tentative_count-- , booked_count++ → [Confirmation] ✅
```

## ทดสอบ

1. เปิด Frontend: `http://localhost:3000/rooms/search`
2. ค้นหาห้อง: วันที่ **2025-11-06 ถึง 2025-11-08**, ผู้เข้าพัก **1 คน**
3. กดปุ่ม **"จองห้องนี้"**
4. ระบบจะ:
   - สร้าง session_id อัตโนมัติ
   - เรียก API `/api/bookings/hold` พร้อมข้อมูลที่ถูกต้อง
   - สร้าง hold ใน database (tentative_count++)
   - แสดงหน้า Guest Info พร้อม countdown timer 15 นาที

## Files ที่แก้ไข

- ✅ `frontend/src/lib/api.ts` - แก้ไข `bookingApi.createHold()`

---

**ระบบ Booking Hold พร้อมใช้งานแล้ว!** 🎉
