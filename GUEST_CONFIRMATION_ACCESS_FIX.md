# แก้ไขการเข้าถึงหน้า Booking Confirmation สำหรับ Guest (Non-Session)

## สรุปการแก้ไข

ทำให้หน้า `/booking/confirmation/[id]` สามารถเข้าถึงได้โดย:
1. ✅ **Guest ที่ไม่ได้ Sign In** - ใช้ phone number verification
2. ✅ **Guest ที่ Sign In แล้ว** - ใช้ session authentication
3. ✅ **ไม่มีข้อจำกัดการดูซ้ำ** - สามารถดูได้หลายครั้ง

## การเปลี่ยนแปลง

### 1. หน้า Confirmation Page (`frontend/src/app/(guest)/booking/confirmation/[id]/page.tsx`)

#### ลบ One-Time Access Restriction
- ❌ ลบ `accessDenied` state และ logic ที่จำกัดการดูเพียงครั้งเดียว
- ❌ ลบ `sessionStorage` check สำหรับ `booking_${bookingId}_viewed`
- ✅ Guest สามารถดูหน้านี้ได้ทุกครั้งที่มี phone number ที่ถูกต้อง

#### ปรับปรุง Error Handling
```typescript
// แสดง error message ที่เหมาะสมตามสถานะ
{!session && !primaryGuestPhone 
  ? 'Unable to verify booking. Please sign in to view your booking details.'
  : 'We couldn\'t find the booking you\'re looking for.'}
```

#### เพิ่ม Guest Notice
- แสดง notice สำหรับ guest ที่ไม่ได้ sign in
- แนะนำให้สร้าง account เพื่อจัดการ booking ได้ง่ายขึ้น
- แสดงว่าสามารถค้นหา booking ด้วย phone number ได้

#### ปรับปรุง Action Buttons
```typescript
// สำหรับ Signed-in users
- View My Bookings (primary)
- Book Another Room (secondary)

// สำหรับ Guest users
- Book Another Room (primary)
- Search My Bookings (secondary)
```

### 2. API Routes (ไม่ต้องแก้ไข)

#### `/api/bookings/[id]/public/route.ts`
- ✅ รองรับการดึงข้อมูล booking ด้วย phone verification
- ✅ ตรวจสอบ ownership ผ่าน phone number
- ✅ ไม่ต้อง authentication

### 3. Middleware (ไม่ต้องแก้ไข)

#### `frontend/src/middleware.ts`
- ✅ `/booking` และ sub-paths เป็น public routes
- ✅ ไม่ต้อง authentication สำหรับ confirmation page

### 4. Hooks & API Client (ไม่ต้องแก้ไข)

#### `frontend/src/hooks/use-bookings.ts`
- ✅ `useBooking(id, phone)` รองรับทั้ง authenticated และ public access

#### `frontend/src/lib/api.ts`
- ✅ `bookingApi.getByIdPublic(id, phone)` ทำงานได้ถูกต้อง

## วิธีการทำงาน

### สำหรับ Guest ที่ไม่ได้ Sign In

1. **หลังจอง Booking สำเร็จ**
   - Phone number ถูกเก็บใน `sessionStorage` key: `booking_${bookingId}_phone`
   - Redirect ไปหน้า `/booking/confirmation/[id]`

2. **เมื่อเข้าหน้า Confirmation**
   - ดึง phone จาก sessionStorage
   - เรียก API `/api/bookings/[id]/public?phone=xxx`
   - Backend verify ownership ผ่าน phone number
   - แสดงข้อมูล booking

3. **การดูซ้ำ**
   - สามารถ refresh หรือกลับมาดูได้ตลอด (ถ้ายังมี phone ใน sessionStorage)
   - หรือค้นหาด้วย phone number ที่หน้า `/bookings`

### สำหรับ Guest ที่ Sign In แล้ว

1. **เข้าหน้า Confirmation**
   - ใช้ session authentication
   - เรียก API `/api/bookings/[id]` (authenticated)
   - แสดงข้อมูล booking

2. **สิทธิ์เพิ่มเติม**
   - ดู booking history ได้ทั้งหมด
   - จัดการ booking ได้ง่ายขึ้น

## การทดสอบ

### Test Case 1: Guest Booking (ไม่ Sign In)
```bash
1. ไปที่ /rooms/search
2. เลือกห้องและจองโดยไม่ sign in
3. กรอกข้อมูล guest พร้อม phone number
4. ชำระเงิน (mock)
5. ✅ ควรเห็นหน้า confirmation พร้อมข้อมูลครบถ้วน
6. Refresh หน้า
7. ✅ ควรยังเห็นข้อมูลได้ (ไม่ถูกบล็อก)
8. คัดลอก URL และเปิดใน tab ใหม่
9. ✅ ควรยังเห็นข้อมูลได้ (ถ้ายังมี phone ใน sessionStorage)
```

### Test Case 2: Signed-in User Booking
```bash
1. Sign in ก่อน
2. จอง booking
3. ✅ ควรเห็นหน้า confirmation
4. ✅ ควรมีปุ่ม "View My Bookings"
5. คลิก "View My Bookings"
6. ✅ ควรเห็น booking ทั้งหมด
```

### Test Case 3: Direct URL Access (Guest)
```bash
1. เปิด browser ใหม่ (clear sessionStorage)
2. ไปที่ /booking/confirmation/123 โดยตรง
3. ✅ ควรแสดง error "Unable to verify booking"
4. ✅ ควรมีปุ่ม "Sign In" และ "Search for Rooms"
```

### Test Case 4: Search Booking by Phone
```bash
1. ไปที่ /bookings
2. กรอก phone number ที่ใช้จอง
3. ✅ ควรเห็น booking list
4. คลิกดู booking detail
5. ✅ ควรเห็นข้อมูลครบถ้วน
```

## Security Considerations

### ✅ ปลอดภัย
- Phone number verification ป้องกันการเข้าถึงโดยไม่ได้รับอนุญาต
- Backend ตรวจสอบ ownership ผ่าน phone number
- ไม่มี sensitive data รั่วไหล

### ⚠️ ข้อควรระวัง
- Phone number ใน sessionStorage อาจหายถ้าปิด browser
- แนะนำให้ guest สร้าง account เพื่อความสะดวก

## Benefits

### สำหรับ Guest
- ✅ ไม่บังคับให้สร้าง account
- ✅ ดูข้อมูล booking ได้ทันที
- ✅ สามารถดูซ้ำได้ไม่จำกัด
- ✅ ค้นหา booking ด้วย phone ได้

### สำหรับ Business
- ✅ ลด friction ในการจอง
- ✅ เพิ่ม conversion rate
- ✅ ยังคงมี security ที่ดี
- ✅ Encourage account creation ผ่าน notice

## Files Changed

```
frontend/src/app/(guest)/booking/confirmation/[id]/page.tsx
```

## Files Verified (No Changes Needed)

```
frontend/src/app/api/bookings/[id]/public/route.ts
frontend/src/middleware.ts
frontend/src/hooks/use-bookings.ts
frontend/src/lib/api.ts
```

## สรุป

การแก้ไขนี้ทำให้ระบบ booking confirmation เป็น **guest-friendly** มากขึ้น โดยไม่ลดความปลอดภัย:

1. ✅ Guest สามารถดู confirmation ได้โดยไม่ต้อง sign in
2. ✅ ไม่มีข้อจำกัดการดูซ้ำ
3. ✅ มี phone verification เพื่อความปลอดภัย
4. ✅ Encourage account creation แต่ไม่บังคับ
5. ✅ UX ที่ดีขึ้นสำหรับทั้ง guest และ signed-in users
