# Task 18 Completion: API Client และ React Query Setup

## สรุปการทำงาน

ได้ทำการสร้างและปรับปรุง API Client และ React Query Setup สำหรับ Frontend ของระบบจองโรงแรม โดยครบถ้วนตามที่กำหนดไว้ใน tasks.md

## ไฟล์ที่สร้างและแก้ไข

### 1. API Client (lib/api.ts) ✅
- ✅ ปรับปรุง axios instance พร้อม interceptors
- ✅ เพิ่ม authentication token handling ผ่าน NextAuth
- ✅ เพิ่ม error handling และ auto-redirect on 401
- ✅ สร้าง API helper functions (get, post, put, patch, delete)
- ✅ สร้าง specific API endpoints:
  - `authApi` - Authentication operations
  - `roomApi` - Room search and management
  - `bookingApi` - Booking operations
  - `checkinApi` - Check-in/out operations
  - `housekeepingApi` - Housekeeping operations
  - `pricingApi` - Pricing management
  - `inventoryApi` - Inventory management
  - `reportApi` - Reporting operations

### 2. TanStack Query Provider (components/providers.tsx) ✅
- ✅ ตั้งค่า QueryClient พร้อม default options
- ✅ กำหนด staleTime, gcTime, retry logic
- ✅ เพิ่ม global error handling
- ✅ รวม SessionProvider, ThemeProvider
- ✅ เพิ่ม ReactQueryDevtools สำหรับ development

### 3. Custom Hooks ✅

#### use-bookings.ts
- ✅ `useBookings()` - ดึงรายการการจองทั้งหมด
- ✅ `useBooking(id)` - ดึงการจองเดียว
- ✅ `useCreateBookingHold()` - สร้าง booking hold
- ✅ `useCreateBooking()` - สร้างการจอง
- ✅ `useConfirmBooking()` - ยืนยันการจอง
- ✅ `useCancelBooking()` - ยกเลิกการจอง

#### use-rooms.ts (ใหม่)
- ✅ `useRoomSearch()` - ค้นหาห้องว่าง
- ✅ `useRoomTypes()` - ดึงประเภทห้องทั้งหมด
- ✅ `useRoomType(id)` - ดึงประเภทห้องเดียว
- ✅ `useRoomPricing()` - คำนวณราคาห้อง

#### use-checkin.ts (ใหม่)
- ✅ `useArrivals()` - รายการแขกที่จะมาถึง
- ✅ `useDepartures()` - รายการแขกที่จะเช็คเอาท์
- ✅ `useCheckIn()` - ทำการเช็คอิน
- ✅ `useCheckOut()` - ทำการเช็คเอาท์
- ✅ `useMoveRoom()` - ย้ายห้อง
- ✅ `useNoShow()` - ทำเครื่องหมาย no-show

#### use-housekeeping.ts (ใหม่)
- ✅ `useHousekeepingTasks()` - รายการงานทำความสะอาด
- ✅ `useUpdateRoomStatus()` - อัปเดตสถานะห้อง
- ✅ `useInspectRoom()` - ตรวจสอบห้อง
- ✅ `useReportMaintenance()` - รายงานปัญหา

#### use-pricing.ts (ใหม่)
- ✅ `useRateTiers()` - ดึง rate tiers
- ✅ `usePricingCalendar()` - ดึง pricing calendar
- ✅ `useRatePricing()` - ดึงเมทริกซ์ราคา
- ✅ `useCreateRateTier()` - สร้าง rate tier
- ✅ `useUpdateRateTier()` - อัปเดต rate tier
- ✅ `useUpdatePricingCalendar()` - อัปเดต calendar
- ✅ `useUpdateRatePricing()` - อัปเดตราคา

#### use-inventory.ts (ใหม่)
- ✅ `useInventory()` - ดึงข้อมูล inventory
- ✅ `useUpdateInventory()` - อัปเดต allotment

#### use-reports.ts (ใหม่)
- ✅ `useOccupancyReport()` - รายงานการเข้าพัก
- ✅ `useRevenueReport()` - รายงานรายได้
- ✅ `useVoucherReport()` - รายงานคูปอง
- ✅ `useExportReport()` - ส่งออกรายงาน

#### use-room-status.ts (ใหม่)
- ✅ `useRoomStatus()` - สถานะห้องทั้งหมด
- ✅ `useRoomsByStatus()` - กรองห้องตามสถานะ
- ✅ `useRoomStatusSummary()` - สรุปสถานะห้อง

#### hooks/index.ts (ใหม่)
- ✅ Export all hooks จากจุดเดียว

### 4. ProtectedRoute Component (components/protected-route.tsx) ✅
- ✅ ปรับปรุงการตรวจสอบ authentication
- ✅ รองรับ single role และ multiple roles
- ✅ เพิ่ม custom fallback และ redirectTo
- ✅ ปรับปรุง loading state UI
- ✅ เพิ่ม HOC pattern (`withProtectedRoute`)
- ✅ เพิ่ม callback URL สำหรับ redirect หลัง login

### 5. Documentation ✅
- ✅ สร้าง `API_CLIENT_REFERENCE.md` - คู่มือการใช้งานแบบละเอียด
- ✅ มีตัวอย่างการใช้งานทุก hook
- ✅ มี best practices และ error handling patterns

### 6. Test Page ✅
- ✅ สร้าง `/test-api` page สำหรับทดสอบ API client
- ✅ ทดสอบ useRoomTypes และ useBookings
- ✅ แสดง API configuration

## คุณสมบัติหลัก

### 1. Type Safety
- ใช้ TypeScript ทั้งหมด
- Type definitions ครบถ้วนใน `types/index.ts`
- Auto-completion ใน IDE

### 2. Automatic Caching
- Query results ถูก cache อัตโนมัติ
- Configurable staleTime และ gcTime
- Smart refetching strategies

### 3. Real-time Updates
- Auto-refetch ทุก 30 วินาทีสำหรับ:
  - Room status dashboard
  - Housekeeping tasks
  - Arrivals/Departures

### 4. Error Handling
- Global error interceptor
- Automatic 401 redirect
- Component-level error states
- Mutation error callbacks

### 5. Cache Invalidation
- Mutations invalidate related queries อัตโนมัติ
- ตัวอย่าง: สร้างการจอง → invalidate bookings และ inventory

### 6. Authentication Integration
- ใช้ NextAuth session สำหรับ token
- Auto-attach Bearer token ใน requests
- Protected routes with role-based access

## การทดสอบ

### 1. ทดสอบ API Client
```bash
# เปิด test page
http://localhost:3000/test-api
```

### 2. ทดสอบ Hooks ใน Component
```typescript
import { useRoomTypes, useBookings } from '@/hooks';

function TestComponent() {
  const { data, isLoading, error } = useRoomTypes();
  // ...
}
```

### 3. ทดสอบ Protected Routes
```typescript
<ProtectedRoute requiredRole="guest">
  <GuestDashboard />
</ProtectedRoute>
```

## ตัวอย่างการใช้งาน

### 1. Room Search Flow
```typescript
const { data: rooms } = useRoomSearch({
  check_in_date: '2025-01-01',
  check_out_date: '2025-01-05',
  adults: 2,
});
```

### 2. Booking Flow
```typescript
const createHold = useCreateBookingHold();
const createBooking = useCreateBooking();

// Step 1: Create hold
createHold.mutate(holdData);

// Step 2: Create booking
createBooking.mutate(bookingData);
```

### 3. Check-in Flow
```typescript
const { data: arrivals } = useArrivals(today);
const checkIn = useCheckIn();

checkIn.mutate({
  booking_detail_id: 123,
  room_id: 456,
});
```

## Integration Points

### Backend API Endpoints
ทุก hook เชื่อมต่อกับ Go backend API ที่:
- Base URL: `http://localhost:8080/api`
- Authentication: Bearer token จาก NextAuth
- Response format: JSON

### NextAuth Integration
- Session management
- Token refresh
- Role-based access control

### TanStack Query
- Query caching
- Automatic refetching
- Optimistic updates
- DevTools integration

## Best Practices ที่ใช้

1. ✅ **Separation of Concerns**: แยก API calls, hooks และ components
2. ✅ **Type Safety**: ใช้ TypeScript ทั้งหมด
3. ✅ **Error Handling**: Handle errors ทุกระดับ
4. ✅ **Loading States**: แสดง loading UI ที่เหมาะสม
5. ✅ **Cache Management**: Invalidate queries อย่างถูกต้อง
6. ✅ **Real-time Data**: Auto-refresh สำหรับข้อมูลที่เปลี่ยนบ่อย
7. ✅ **Security**: Protected routes และ role-based access
8. ✅ **Documentation**: คู่มือการใช้งานที่ครบถ้วน

## ไฟล์ที่เกี่ยวข้อง

```
frontend/
├── src/
│   ├── lib/
│   │   └── api.ts                    ✅ Enhanced
│   ├── hooks/
│   │   ├── index.ts                  ✅ New
│   │   ├── use-bookings.ts          ✅ Enhanced
│   │   ├── use-rooms.ts             ✅ New
│   │   ├── use-checkin.ts           ✅ New
│   │   ├── use-housekeeping.ts      ✅ New
│   │   ├── use-pricing.ts           ✅ New
│   │   ├── use-inventory.ts         ✅ New
│   │   ├── use-reports.ts           ✅ New
│   │   └── use-room-status.ts       ✅ New
│   ├── components/
│   │   ├── providers.tsx             ✅ Enhanced
│   │   └── protected-route.tsx       ✅ Enhanced
│   └── app/
│       └── test-api/
│           └── page.tsx               ✅ New
└── API_CLIENT_REFERENCE.md            ✅ New
```

## สรุป

Task 18 เสร็จสมบูรณ์ครบทุกข้อตามที่กำหนด:
- ✅ สร้าง lib/api.ts สำหรับเรียก Go backend
- ✅ ตั้งค่า TanStack Query Provider
- ✅ สร้าง custom hooks (useBookings, useRoomTypes, etc.)
- ✅ สร้าง ProtectedRoute component
- ✅ ครอบคลุม requirements ทุกข้อ (frontend infrastructure)

ระบบพร้อมใช้งานสำหรับการพัฒนา UI components ในขั้นตอนถัดไป!

## ขั้นตอนถัดไป

Task 19: สร้างหน้า Guest - Room Search
- ใช้ `useRoomSearch` hook
- ใช้ `useRoomTypes` hook
- ใช้ `ProtectedRoute` component
