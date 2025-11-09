# แก้ปัญหา Redirect ไปหน้า Confirmation หลัง Complete Booking

## ปัญหา
หลังจากกด Complete Booking:
- Backend สร้าง booking สำเร็จ (booking_id: 60)
- Backend confirm สำเร็จ (200 OK)
- แต่หน้ากลับไปที่ `/rooms/search` แทนที่จะไปหน้า `/booking/confirmation/60`
- ไม่เห็น toast notification
- ไม่เห็นหน้า confirmation เลย

## สาเหตุ
**Race Condition ระหว่าง `clearBooking()` และ `useEffect` redirect:**

1. หลัง booking สำเร็จ เรียก `clearBooking()` เพื่อล้างข้อมูล
2. `clearBooking()` ทำให้ `guestInfo` เป็น `null`
3. `useEffect` ตรวจพบว่า `guestInfo` เป็น `null` 
4. `useEffect` redirect ไป `/rooms/search` ทันที
5. การ redirect ไป `/booking/confirmation/[id]` ถูก override!

```typescript
// useEffect นี้ trigger หลัง clearBooking()
useEffect(() => {
  if (!searchParams || !selectedRoomTypeId || !guestInfo) {
    router.push('/rooms/search'); // ← ทับการ redirect ไป confirmation!
  }
}, [searchParams, selectedRoomTypeId, guestInfo, router]);
```

## การแก้ไข

### 1. เพิ่ม `isNavigating` Flag
```typescript
const [isNavigating, setIsNavigating] = useState(false);
```

### 2. ป้องกัน useEffect Redirect เมื่อกำลัง Navigate
```typescript
useEffect(() => {
  // เพิ่มเงื่อนไข !isNavigating
  if (!isProcessing && !isNavigating && (!searchParams || !selectedRoomTypeId || !guestInfo)) {
    console.log('[Summary] Missing required data, redirecting to search');
    router.push('/rooms/search');
  }
}, [searchParams, selectedRoomTypeId, guestInfo, router, isProcessing, isNavigating]);
```

### 3. Set Flag ก่อน clearBooking()
```typescript
// Set navigating flag FIRST
setIsNavigating(true);
console.log('[Summary] Set navigating flag');

// Then clear booking
clearBooking();
localStorage.removeItem('booking_hold');
localStorage.removeItem('booking_guest_draft');

// Navigate using window.location for reliability
window.location.href = `/booking/confirmation/${bookingIdNumber}`;
```

### 4. ใช้ window.location แทน router.push
เพราะ `window.location.href` จะ force full page reload และไม่ถูก interrupt โดย useEffect

## ลำดับการทำงานที่ถูกต้อง

```
1. User กด Complete Booking
2. Create booking → Success (booking_id: 60)
3. Confirm booking → Success
4. setIsNavigating(true) ← ป้องกัน useEffect
5. clearBooking() ← guestInfo เป็น null
6. useEffect ตรวจสอบ → เห็น isNavigating=true → ไม่ redirect
7. window.location.href = '/booking/confirmation/60' ← Navigate สำเร็จ!
```

## ไฟล์ที่แก้ไข
- `frontend/src/app/(guest)/booking/summary/page.tsx`
  - เพิ่ม `isNavigating` state
  - เพิ่มเงื่อนไข `!isNavigating` ใน useEffect
  - Set `isNavigating(true)` ก่อน `clearBooking()`
  - ใช้ `window.location.href` แทน `router.push`
  - เพิ่ม console.log เพื่อ debug

## ทดสอบ
1. ค้นหาห้อง → เลือกห้อง → กรอกข้อมูล guest
2. กด Complete Booking
3. รอ 2 วินาที (mock payment)
4. ควรเห็น console log:
   ```
   [Summary] Booking confirmed successfully
   [Summary] Set navigating flag
   [Summary] Cleared booking data
   [Summary] Navigating to confirmation page: /booking/confirmation/60
   ```
5. หน้าควร redirect ไป `/booking/confirmation/60`
6. เห็นหน้า confirmation พร้อม booking details
7. Non-signed-in user: ลอง refresh หน้า → ควรถูก redirect ไปหน้าหลัก (one-time access)
8. Signed-in user: refresh ได้หลายครั้ง

## One-Time Access (Non-Signed-In Users)
- หน้า confirmation ตรวจสอบ `sessionStorage` key: `booking_${bookingId}_viewed`
- ครั้งแรก: `viewed = 'false'` → แสดงหน้า → set เป็น `'true'`
- ครั้งที่สอง: `viewed = 'true'` → redirect ไปหน้าหลัก
- Signed-in users: ไม่มีข้อจำกัด สามารถดูได้หลายครั้ง
