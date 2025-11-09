# แก้ไขปัญหา Rate Limit (429 Too Many Requests)

## ปัญหา

เมื่อ guest account เข้าหน้า `booking/guest-info`:
- Backend ถูกเรียก `/api/bookings/hold` มากเกินไป
- ได้รับ error 429 (Rate limit exceeded)
- ไม่สามารถสร้าง hold ได้
- ถูก redirect กลับไปหน้า search

## สาเหตุ

**Infinite Loop ใน useEffect:**
```typescript
useEffect(() => {
  if (searchParams && selectedRoomTypeId && !holdExpiry && !isCreatingHold) {
    createHold.mutate(holdData, { ... });
  }
}, [searchParams, selectedRoomTypeId, holdExpiry, createHold, setHoldExpiry, router, isCreatingHold]);
```

ปัญหา:
1. `createHold` เป็น mutation object ที่เปลี่ยนแปลงทุกครั้ง render
2. เมื่อ `createHold` เปลี่ยน → useEffect ทำงานอีก
3. เรียก API ซ้ำๆ → Rate limit exceeded

## การแก้ไข

### ใช้ useRef เพื่อป้องกัน Duplicate Calls

**File:** `frontend/src/app/(guest)/booking/guest-info/page.tsx`

```typescript
import { useState, useEffect, useRef } from 'react';

export default function GuestInfoPage() {
  // ... existing state
  const holdCreatedRef = useRef(false); // ← เพิ่ม ref

  useEffect(() => {
    // Prevent duplicate calls using ref
    if (holdCreatedRef.current) {
      console.log('[Hold] Already created, skipping');
      return;
    }
    
    if (searchParams && selectedRoomTypeId && !holdExpiry && !isCreatingHold) {
      holdCreatedRef.current = true; // ← Mark as creating
      setIsCreatingHold(true);
      
      // ... create hold logic
      
      createHold.mutate(holdData, {
        onSuccess: (data: any) => {
          // ... success logic
        },
        onError: (error: any) => {
          // ... error logic
          holdCreatedRef.current = false; // ← Reset on error to allow retry
        },
      });
    }
  }, [searchParams, selectedRoomTypeId, holdExpiry, isCreatingHold, createHold, setHoldExpiry, router]);
}
```

## Logic Flow

### ครั้งแรก (Component Mount):
1. `holdCreatedRef.current = false`
2. เข้า useEffect → ตรวจสอบ conditions
3. Set `holdCreatedRef.current = true`
4. เรียก `createHold.mutate()`
5. รอ response

### ครั้งที่สอง (Re-render):
1. `holdCreatedRef.current = true`
2. เข้า useEffect → ตรวจสอบ ref
3. **Skip** เพราะ ref เป็น true
4. ไม่เรียก API ซ้ำ

### กรณี Error:
1. `onError` callback ทำงาน
2. Set `holdCreatedRef.current = false`
3. อนุญาตให้ retry ได้

## วิธีแก้ไข Rate Limit ที่เกิดขึ้นแล้ว

### Option 1: รอให้หมดอายุ (แนะนำ)
```
รอ 1-5 นาที (ขึ้นอยู่กับ rate limit window)
Rate limiter จะ reset อัตโนมัติ
```

### Option 2: Restart Backend
```bash
# หยุด backend (Ctrl+C)
# รัน backend ใหม่
cd backend
hotel-booking-api.exe
```

### Option 3: Clear Rate Limit (ถ้าใช้ Redis)
```bash
# ถ้า rate limiter ใช้ Redis
redis-cli FLUSHDB
```

## การป้องกัน

### 1. ใช้ useRef สำหรับ One-Time Operations
```typescript
const hasRunRef = useRef(false);

useEffect(() => {
  if (hasRunRef.current) return;
  hasRunRef.current = true;
  
  // One-time operation
}, [dependencies]);
```

### 2. ใช้ Debounce สำหรับ Frequent Operations
```typescript
import { useDebounce } from '@/hooks/use-debounce';

const debouncedValue = useDebounce(value, 500);

useEffect(() => {
  // API call with debounced value
}, [debouncedValue]);
```

### 3. ตรวจสอบ Dependencies อย่างระมัดระวัง
```typescript
// ❌ Bad - mutation object เปลี่ยนทุก render
useEffect(() => {
  mutation.mutate();
}, [mutation]);

// ✅ Good - ใช้ ref หรือ empty deps
useEffect(() => {
  if (!hasRun.current) {
    mutation.mutate();
    hasRun.current = true;
  }
}, []);
```

## Rate Limiter Configuration

ถ้าต้องการปรับ rate limit ใน backend:

**File:** `backend/internal/middleware/rate_limiter.go`

```go
// Adjust these values
const (
    requestsPerMinute = 60  // เพิ่มจาก 60 เป็น 120
    burstSize = 10          // เพิ่มจาก 10 เป็น 20
)
```

## ผลลัพธ์

✅ ไม่มี infinite loop
✅ เรียก API ครั้งเดียวต่อ component mount
✅ ไม่ถูก rate limit
✅ สามารถเข้าหน้า guest-info ได้ปกติ
✅ Hold ถูกสร้างสำเร็จ

## การทดสอบ

### Test 1: Normal Flow
```
1. เลือกห้องจากหน้า search
2. คลิก "Book Now"
3. ✅ ควรเข้าหน้า guest-info ได้
4. ✅ ควรเห็น countdown timer
5. ✅ Backend log ควรเห็น POST /api/bookings/hold เพียงครั้งเดียว
```

### Test 2: Refresh Page
```
1. อยู่ในหน้า guest-info
2. กด F5 (refresh)
3. ✅ ควรเข้าหน้าได้ (มี holdExpiry อยู่แล้ว)
4. ✅ ไม่ควรเรียก API ซ้ำ
```

### Test 3: Back and Forward
```
1. อยู่ในหน้า guest-info
2. กด Back
3. กด Forward
4. ✅ ควรเข้าหน้าได้
5. ✅ ไม่ควรเรียก API ซ้ำ (มี holdExpiry)
```

## หมายเหตุ

- useRef ไม่ trigger re-render เมื่อเปลี่ยนค่า
- เหมาะสำหรับเก็บค่าที่ไม่ต้องการให้ trigger useEffect
- Rate limit ปกป้อง backend จาก abuse
- ควรใช้ debounce สำหรับ user input

## ไฟล์ที่แก้ไข

1. `frontend/src/app/(guest)/booking/guest-info/page.tsx` - เพิ่ม useRef เพื่อป้องกัน duplicate calls
