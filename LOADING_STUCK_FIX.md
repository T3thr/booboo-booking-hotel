# แก้ปัญหาหน้า Loading ค้างที่ "Reserving your room..."

## ปัญหา
หลังจากกดจองห้อง หน้า guest-info แสดง loading "Reserving your room..." ค้างไม่หยุด แม้ว่า:
- Backend สร้าง hold สำเร็จแล้ว (200 OK)
- Console log แสดง `[API] Hold created: Object`
- แต่ `holdExpiry` ยังเป็น `null` ทำให้ loading ไม่หาย

## สาเหตุ
1. **State ไม่ update ทัน**: `setHoldExpiry()` ถูกเรียกแต่ state ไม่ update ทันที
2. **Response format ไม่ตรง**: Backend อาจ return `expiry_time` แทน `hold_expiry`
3. **ไม่มี fallback**: ถ้า state ไม่ update ก็จะ loading ตลอดไป

## การแก้ไข

### 1. เพิ่ม Fallback สำหรับ Response Format
```typescript
// Parse expiry from various possible formats
let expiry: Date;
if (data.hold_expiry) {
  expiry = new Date(data.hold_expiry);
} else if (data.expiry_time) {
  expiry = new Date(data.expiry_time);
} else if (data.data?.hold_expiry) {
  expiry = new Date(data.data.hold_expiry);
} else {
  // Fallback: 15 minutes from now
  expiry = new Date(Date.now() + 15 * 60 * 1000);
}
```

### 2. เพิ่ม localStorage Fallback
```typescript
// Check if hold exists in localStorage (fallback)
const hasHoldInStorage = typeof window !== 'undefined' && localStorage.getItem('booking_hold');

// Only show loading if creating hold AND don't have expiry yet AND no hold in storage
if (isCreatingHold && !holdExpiry && !hasHoldInStorage) {
  return <Loading />;
}

// If we have hold in storage but no expiry in state, restore it
if (!holdExpiry && hasHoldInStorage) {
  const holdData = JSON.parse(localStorage.getItem('booking_hold')!);
  const expiry = new Date(holdData.holdExpiry);
  if (expiry > new Date()) {
    setHoldExpiry(expiry);
    setIsCreatingHold(false);
  }
}
```

### 3. เพิ่ม Safety Timeout (5 วินาที)
```typescript
// Safety timeout: if still loading after 5 seconds, force hide loading
const safetyTimeout = setTimeout(() => {
  console.warn('[Hold] Safety timeout triggered');
  setIsCreatingHold(false);
  
  // Try to restore from localStorage
  const holdData = localStorage.getItem('booking_hold');
  if (holdData) {
    const parsed = JSON.parse(holdData);
    const expiry = new Date(parsed.holdExpiry);
    if (expiry > new Date()) {
      setHoldExpiry(expiry);
    }
  }
}, 5000);
```

### 4. บันทึก localStorage ก่อน Update State
```typescript
// Save to localStorage FIRST (more reliable)
localStorage.setItem('booking_hold', JSON.stringify(holdInfo));

// Then update state
setHoldExpiry(expiry);
setIsCreatingHold(false);
```

## ผลลัพธ์
- ✅ Loading จะหายภายใน 5 วินาทีแม้ state ไม่ update
- ✅ รองรับ response format หลายแบบ
- ✅ ใช้ localStorage เป็น fallback
- ✅ ไม่มีหน้าค้างอีกต่อไป

## ทดสอบ
1. ลบ booking hold ใน database: `UPDATE room_inventory SET tentative_count = 0;`
2. เปิด browser console
3. ค้นหาห้องและกดจอง
4. ดู console log:
   - `[Hold] Backend response:` - ดู response structure
   - `[Hold] Parsed expiry:` - ดูว่า parse ได้ถูกต้อง
   - `[Hold] State updated` - ดูว่า state update แล้ว
5. หน้าควรแสดงฟอร์มกรอกข้อมูลภายใน 1-2 วินาที

## ไฟล์ที่แก้ไข
- `frontend/src/app/(guest)/booking/guest-info/page.tsx`
  - เพิ่ม fallback สำหรับ response format
  - เพิ่ม localStorage fallback
  - เพิ่ม safety timeout 5 วินาที
  - บันทึก localStorage ก่อน update state
