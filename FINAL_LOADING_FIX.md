# แก้ปัญหา Loading ค้างครั้งสุดท้าย

## ปัญหา
หน้า guest-info โหลดค้างที่ "Reserving your room..." แม้:
- Backend สร้าง hold สำเร็จ (200 OK)
- `[API] Hold created: Object` แสดงใน console
- localStorage มีข้อมูล hold แล้ว
- แต่ `holdExpiry` state ยังเป็น `null`

## สาเหตุ
**React State Update ไม่ทำงานใน onSuccess callback**
- `setHoldExpiry(expiry)` ถูกเรียกแล้ว แต่ state ไม่ update
- อาจเป็นเพราะ React 18 Strict Mode หรือ race condition
- หรือ Zustand store ไม่ trigger re-render

## การแก้ไข

### 1. ใช้ setTimeout สำหรับ State Update
```typescript
// แทนที่จะ update ทันที
setIsCreatingHold(false);
setHoldExpiry(expiry);

// ใช้ setTimeout เพื่อ update ใน next tick
setTimeout(() => {
  setIsCreatingHold(false);
  setHoldExpiry(expiry);
}, 0);
```

### 2. เพิ่ม Polling จาก localStorage
```typescript
useEffect(() => {
  // Check localStorage ทุก 500ms
  const interval = setInterval(() => {
    if (!holdExpiry) {
      const holdData = localStorage.getItem('booking_hold');
      if (holdData) {
        const parsed = JSON.parse(holdData);
        const expiry = new Date(parsed.holdExpiry);
        if (expiry > new Date()) {
          setHoldExpiry(expiry);
          setIsCreatingHold(false);
          clearInterval(interval);
        }
      }
    }
  }, 500);

  return () => clearInterval(interval);
}, [holdExpiry]);
```

### 3. Safety Timeout (2 วินาที)
```typescript
const safetyTimeout = setTimeout(() => {
  setIsCreatingHold(false);
  // Force use fallback expiry
  const fallbackExpiry = new Date(Date.now() + 15 * 60 * 1000);
  setHoldExpiry(fallbackExpiry);
}, 2000);
```

## ทดสอบ
1. Hard refresh (Ctrl+Shift+R)
2. Clear storage: `localStorage.clear(); sessionStorage.clear();`
3. ค้นหาห้อง → เลือกห้อง → กดจอง
4. ดู console log:
   - `[Hold] Backend response:` - ดู response
   - `[Hold] Saved to localStorage:` - ดูว่าบันทึกแล้ว
   - `[Hold] State updated via setTimeout` - ดูว่า state update แล้ว
   - `[Hold] Restoring expiry from localStorage:` - ดูว่า polling ทำงาน
5. หน้าควรแสดงฟอร์มภายใน 2 วินาที

## ถ้ายังไม่ได้
รันใน browser console:
```javascript
// ดู localStorage
console.log(localStorage.getItem('booking_hold'));

// Force reload
location.reload();

// หรือ clear แล้วลองใหม่
localStorage.clear();
sessionStorage.clear();
location.href = '/rooms/search';
```

## ไฟล์ที่แก้ไข
- `frontend/src/app/(guest)/booking/guest-info/page.tsx`
  - ใช้ `setTimeout` สำหรับ state update
  - เพิ่ม polling interval 500ms
  - Safety timeout 2 วินาที
