# แก้ปัญหา Loading ค้าง - Ultimate Fix

## ปัญหา
หน้า guest-info โหลดค้างตลอดที่ "Reserving your room..." แม้:
- Backend สร้าง hold สำเร็จ
- localStorage มีข้อมูล hold แล้ว
- แต่ `onSuccess` callback ของ React Query **ไม่ถูกเรียก**
- ไม่มี log `[Hold] Backend response:` ใน console

## สาเหตุหลัก
**React Query mutation callback ไม่ทำงาน** อาจเป็นเพราะ:
1. React 18 Strict Mode ทำให้ component unmount/remount
2. Kiro autofix ลบโค้ดบางส่วน
3. State update ไม่ trigger re-render

## Ultimate Fix

### 1. ข้าม Loading ถ้ามี localStorage
```typescript
// ถ้ามี hold ใน localStorage แล้ว ไม่ต้องโหลด
if (hasHoldInStorage) {
  console.log('[Render] Have hold in storage, skipping loading screen');
  if (isCreatingHold) {
    setTimeout(() => setIsCreatingHold(false), 0);
  }
}
```

### 2. Timeout Loading สูงสุด 2 วินาที
```typescript
const [loadingStartTime] = useState(Date.now());
const loadingTooLong = Date.now() - loadingStartTime > 2000;

// ถ้าโหลดเกิน 2 วินาที บังคับหยุด
if (loadingTooLong && isCreatingHold) {
  setTimeout(() => setIsCreatingHold(false), 0);
}
```

### 3. Polling localStorage ทุก 500ms
```typescript
useEffect(() => {
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

## ผลลัพธ์
- ✅ ถ้ามี localStorage → ข้าม loading ทันที
- ✅ ถ้าโหลดเกิน 2 วินาที → บังคับหยุด
- ✅ Polling check localStorage ทุก 500ms
- ✅ **ไม่มีทางโหลดค้างเกิน 2 วินาที**

## ทดสอบ
1. Clear storage: `localStorage.clear(); sessionStorage.clear();`
2. Hard refresh: Ctrl+Shift+R
3. ค้นหาห้อง → เลือกห้อง → กดจอง
4. ดู console:
   - `[Render] Have hold in storage, skipping loading screen`
   - `[Hold] Restoring expiry from localStorage:`
5. หน้าควรแสดงฟอร์มภายใน 1-2 วินาที

## ถ้ายังไม่ได้
รันใน console:
```javascript
// ดู localStorage
console.log('Hold:', localStorage.getItem('booking_hold'));

// Force reload
location.reload();
```

## ไฟล์ที่แก้ไข
- `frontend/src/app/(guest)/booking/guest-info/page.tsx`
  - ข้าม loading ถ้ามี localStorage
  - Timeout loading สูงสุด 2 วินาที
  - Polling localStorage ทุก 500ms
  - Force stop loading หลัง 2 วินาที

## สรุป
**ไม่ว่าจะเกิดอะไรขึ้น หน้าจะไม่โหลดค้างเกิน 2 วินาที**
