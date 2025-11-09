# แก้ไขปัญหา Redirect ไปหน้า Confirmation

## ปัญหา

หลังจาก complete booking สำเร็จ:
- ✅ Backend confirm สำเร็จ (200)
- ✅ Frontend redirect ไป `/booking/confirmation/[id]`
- ❌ แต่หน้า confirmation แสดง "Booking Not Found"
- ❌ Redirect กลับไปหน้า `/rooms/search`
- ❌ ไม่เห็น toast notification

## สาเหตุ

1. **API Authentication Issue:**
   - `/api/bookings/[id]` ต้องการ authentication
   - Non-signed-in guest ไม่มี session
   - API return error → แสดง "Booking Not Found"

2. **Missing Public API Usage:**
   - มี `/api/bookings/[id]/public` แต่ไม่ได้ใช้
   - Public API ต้องการ phone number สำหรับ verification
   - `useBooking` hook ไม่รองรับ public API

3. **Phone Number Not Saved:**
   - หลัง complete booking, guestInfo ถูก clear
   - Confirmation page ไม่มี phone เพื่อเรียก public API

## การแก้ไข

### 1. เพิ่ม Public API Support ใน useBooking Hook

**File:** `frontend/src/hooks/use-bookings.ts`

```typescript
export function useBooking(id: number, phone?: string) {
  return useQuery({
    queryKey: ['bookings', id, phone],
    queryFn: () => {
      // If phone is provided, use public API (for non-signed-in guests)
      if (phone) {
        return bookingApi.getByIdPublic(id, phone);
      }
      // Otherwise use authenticated API
      return bookingApi.getById(id);
    },
    enabled: !!id,
  });
}
```

### 2. เพิ่ม getByIdPublic Function

**File:** `frontend/src/lib/api.ts`

```typescript
export const bookingApi = {
  // ... existing functions
  
  getByIdPublic: async (id: number, phone: string) => {
    const response = await fetch(`/api/bookings/${id}/public?phone=${encodeURIComponent(phone)}`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (!response.ok) throw new Error(`Get booking failed: ${response.status}`);
    const result = await response.json();
    // Unwrap the data if it's wrapped in success/data structure
    return result.data || result;
  },
};
```

### 3. บันทึก Phone ใน sessionStorage

**File:** `frontend/src/app/(guest)/booking/summary/page.tsx`

```typescript
// Success! Save phone for confirmation page access (non-signed-in users)
if (!session && guestInfo) {
  const primaryGuest = guestInfo.find(g => g.is_primary);
  if (primaryGuest?.phone) {
    sessionStorage.setItem(`booking_${bookingIdNumber}_phone`, primaryGuest.phone);
  }
}

// Clear booking state and hold from localStorage
clearBooking();
localStorage.removeItem('booking_hold');
localStorage.removeItem('booking_guest_draft');

// Mark this booking as viewable once for non-signed-in users
if (!session) {
  sessionStorage.setItem(`booking_${bookingIdNumber}_viewed`, 'false');
}

// Navigate to confirmation page
router.push(`/booking/confirmation/${bookingIdNumber}`);
```

### 4. ดึง Phone จาก sessionStorage ใน Confirmation Page

**File:** `frontend/src/app/(guest)/booking/confirmation/[id]/page.tsx`

```typescript
export default function BookingConfirmationPage() {
  const router = useRouter();
  const params = useParams();
  const { data: session } = useSession();
  const bookingId = parseInt(params.id as string);
  const { clearBooking } = useBookingStore();
  const [showToast, setShowToast] = useState(true);
  const [accessDenied, setAccessDenied] = useState(false);

  // Get phone from sessionStorage for non-signed-in users
  const [primaryGuestPhone, setPrimaryGuestPhone] = useState<string | undefined>();
  
  useEffect(() => {
    if (!session && bookingId) {
      const phone = sessionStorage.getItem(`booking_${bookingId}_phone`);
      if (phone) {
        setPrimaryGuestPhone(phone);
      }
    }
  }, [session, bookingId]);
  
  const { data: booking, isLoading, error } = useBooking(bookingId, primaryGuestPhone);
  
  // ... rest of the component
}
```

### 5. อัพเดท GuestInfo Interface

**File:** `frontend/src/store/useBookingStore.ts`

```typescript
interface GuestInfo {
  first_name: string;
  last_name: string;
  phone?: string;  // ← เพิ่ม
  email?: string;  // ← เพิ่ม
  type: 'Adult' | 'Child';
  is_primary: boolean;
}
```

## Logic Flow

### Non-Signed-In Guest:
1. Complete booking → บันทึก phone ใน `sessionStorage`
2. Redirect ไป `/booking/confirmation/[id]`
3. Confirmation page ดึง phone จาก `sessionStorage`
4. เรียก `useBooking(id, phone)` → ใช้ public API
5. แสดงหน้า confirmation พร้อม toast

### Signed-In Guest:
1. Complete booking → ไม่ต้องบันทึก phone
2. Redirect ไป `/booking/confirmation/[id]`
3. Confirmation page ไม่มี phone
4. เรียก `useBooking(id)` → ใช้ authenticated API
5. แสดงหน้า confirmation พร้อม toast

## sessionStorage Keys

| Key | Purpose | When Set | When Used |
|-----|---------|----------|-----------|
| `booking_${id}_phone` | Phone for public API | After confirm | Confirmation page |
| `booking_${id}_viewed` | One-time access flag | After confirm | Confirmation page |

## ผลลัพธ์

✅ Non-signed-in guest เห็นหน้า confirmation
✅ Signed-in guest เห็นหน้า confirmation
✅ Toast notification แสดงขึ้น
✅ ไม่ redirect กลับไปหน้า search
✅ One-time access ยังทำงานปกติ

## การทดสอบ

### Test 1: Non-Signed-In Guest
```
1. ไม่ sign in
2. จองห้อง → กรอก phone: 0812345678
3. Complete booking
4. ✅ ควรเห็นหน้า confirmation
5. ✅ ควรเห็น toast "การจองของคุณสำเร็จแล้ว!"
6. ตรวจสอบ sessionStorage:
   - booking_58_phone = "0812345678"
   - booking_58_viewed = "true"
```

### Test 2: Signed-In Guest
```
1. Sign in
2. จองห้อง
3. Complete booking
4. ✅ ควรเห็นหน้า confirmation
5. ✅ ควรเห็น toast
6. ตรวจสอบ sessionStorage:
   - ไม่มี booking_58_phone (ไม่จำเป็น)
   - ไม่มี booking_58_viewed (ไม่จำเป็น)
```

### Test 3: One-Time Access (Non-Signed-In)
```
1. ทำ Test 1 จนเสร็จ
2. คัดลอก URL: /booking/confirmation/58
3. ไปหน้าอื่น
4. Paste URL กลับมา
5. ✅ ควรเห็น "Access Denied"
6. ✅ Redirect ไปหน้าหลัก
```

## หมายเหตุ

- Phone ถูกเก็บใน `sessionStorage` (จะหายเมื่อปิด tab)
- Public API ตรวจสอบ phone number กับ booking
- Signed-in users ไม่ต้องใช้ public API
- One-time access ใช้ `sessionStorage` key แยกต่างหาก

## ไฟล์ที่แก้ไข

1. `frontend/src/hooks/use-bookings.ts` - เพิ่ม phone parameter
2. `frontend/src/lib/api.ts` - เพิ่ม getByIdPublic function
3. `frontend/src/app/(guest)/booking/summary/page.tsx` - บันทึก phone
4. `frontend/src/app/(guest)/booking/confirmation/[id]/page.tsx` - ดึง phone
5. `frontend/src/store/useBookingStore.ts` - เพิ่ม phone/email ใน interface
