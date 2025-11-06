# คู่มือแก้ไขระบบ Admin ให้สมบูรณ์

## สรุปสถานะปัจจุบัน

### ✅ Backend APIs ที่มีแล้ว (จาก router.go)
- Inventory: GET, PUT, POST /api/inventory
- Rooms: GET /api/rooms/status
- Pricing: GET, POST, PUT /api/pricing/tiers
- Pricing: GET, PUT /api/pricing/rates
- Housekeeping: GET /api/housekeeping/tasks
- Check-in: GET /api/checkin/arrivals
- Check-out: GET /api/checkout/departures
- Reports: GET /api/reports/*

### ❌ ปัญหาที่พบ
1. Frontend ไม่ส่ง auth token → 401 Unauthorized
2. Frontend เรียก API ผิด endpoint
3. Frontend ไม่ handle empty data
4. UI ไม่มี CRUD forms

## แก้ไขทีละหน้า

### 1. Inventory Management Page

**ปัญหา**: Empty response `{}`

**สาเหตุ**:
- API ต้องการ auth token (Manager only)
- ต้องส่ง `start_date` และ `end_date` parameters

**วิธีแก้**:

```typescript
// frontend/src/hooks/use-inventory.ts
export function useInventory(params?: {
  room_type_id?: number;
  start_date?: string;
  end_date?: string;
}) {
  const { data: session } = useSession();
  
  return useQuery({
    queryKey: ['inventory', params],
    queryFn: async () => {
      // ต้องมี start_date และ end_date
      if (!params?.start_date || !params?.end_date) {
        console.warn('[useInventory] Missing required params');
        return [];
      }
      
      const response = await fetch(
        `/api/inventory?${new URLSearchParams(params as any)}`,
        {
          headers: {
            'Authorization': `Bearer ${session?.accessToken}`,
            'Content-Type': 'application/json',
          },
        }
      );
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      const data = await response.json();
      return data.data || [];
    },
    enabled: !!session && !!params?.start_date && !!params?.end_date,
  });
}
```

**UI Changes**:
```typescript
// frontend/src/app/admin/(manager)/inventory/page.tsx
export default function InventoryManagementPage() {
  const { data: session } = useSession();
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  });
  
  // Calculate start_date and end_date from selectedMonth
  const [year, month] = selectedMonth.split('-').map(Number);
  const start_date = `${year}-${String(month).padStart(2, '0')}-01`;
  const end_date = new Date(year, month, 0).toISOString().split('T')[0];
  
  const { data: inventory, isLoading } = useInventory({
    start_date,
    end_date,
  });
  
  // ... rest of component
}
```

### 2. Reception (Room Status) Page

**ปัญหา**: ไม่มีข้อมูลห้อง

**API Endpoint**: `/api/rooms/status` (ต้อง auth, Receptionist or Manager)

**วิธีแก้**:

```typescript
// frontend/src/hooks/use-room-status.ts
import { useQuery } from '@tanstack/react-query';
import { useSession } from 'next-auth/react';

export function useRoomStatus() {
  const { data: session } = useSession();
  
  return useQuery({
    queryKey: ['room-status'],
    queryFn: async () => {
      const response = await fetch('/api/rooms/status', {
        headers: {
          'Authorization': `Bearer ${session?.accessToken}`,
        },
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      const data = await response.json();
      return data.data || [];
    },
    enabled: !!session,
    refetchInterval: 30000, // Refresh every 30 seconds
  });
}
```

### 3. Pricing Tiers Page

**ปัญหา**: ไม่สามารถ CRUD ได้

**APIs Available**:
- GET /api/pricing/tiers
- POST /api/pricing/tiers
- PUT /api/pricing/tiers/:id

**วิธีแก้**:

```typescript
// frontend/src/hooks/use-pricing.ts
export function useCreateRateTier() {
  const { data: session } = useSession();
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (data: { tier_name: string; multiplier: number }) => {
      const response = await fetch('/api/pricing/tiers', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session?.accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });
      
      if (!response.ok) {
        throw new Error('Failed to create tier');
      }
      
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['pricing-tiers'] });
      toast.success('สร้าง tier สำเร็จ!');
    },
  });
}

export function useUpdateRateTier() {
  const { data: session } = useSession();
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, data }: { id: number; data: any }) => {
      const response = await fetch(`/api/pricing/tiers/${id}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${session?.accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });
      
      if (!response.ok) {
        throw new Error('Failed to update tier');
      }
      
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['pricing-tiers'] });
      toast.success('อัพเดท tier สำเร็จ!');
    },
  });
}
```

### 4. Bookings Management Page

**ปัญหา**: ต้องแสดง payment proofs

**API Endpoint**: `/api/admin/payment-proofs` (มีแล้ว แต่ไม่ได้ register ใน router!)

**วิธีแก้**: ต้องเพิ่ม routes ใน backend router

```go
// backend/internal/router/router.go
// เพิ่มใน admin group
admin := api.Group("/admin")
admin.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
admin.Use(middleware.RequireManager())
{
    // Payment Proof Management
    admin.GET("/payment-proofs", bookingHandler.GetPaymentProofs)
    admin.POST("/payment-proofs/:id/approve", bookingHandler.ApprovePaymentProof)
    admin.POST("/payment-proofs/:id/reject", bookingHandler.RejectPaymentProof)
    
    // ... existing routes
}
```

### 5. Manager Dashboard

**ปัญหา**: ต้องแสดง real-time stats

**วิธีแก้**: ใช้ reports API ที่มีอยู่แล้ว

```typescript
// frontend/src/app/admin/(manager)/dashboard/page.tsx
export default function ManagerDashboardPage() {
  const { data: session } = useSession();
  const today = new Date().toISOString().split('T')[0];
  
  // Use existing reports APIs
  const { data: occupancy } = useQuery({
    queryKey: ['dashboard-occupancy', today],
    queryFn: async () => {
      const response = await fetch(
        `/api/reports/occupancy?start_date=${today}&end_date=${today}`,
        {
          headers: {
            'Authorization': `Bearer ${session?.accessToken}`,
          },
        }
      );
      return response.json();
    },
    enabled: !!session,
  });
  
  const { data: revenue } = useQuery({
    queryKey: ['dashboard-revenue', today],
    queryFn: async () => {
      const response = await fetch(
        `/api/reports/revenue?start_date=${today}&end_date=${today}`,
        {
          headers: {
            'Authorization': `Bearer ${session?.accessToken}`,
          },
        }
      );
      return response.json();
    },
    enabled: !!session,
  });
  
  // ... render stats
}
```

## สิ่งที่ต้องทำ (Checklist)

### Backend
- [ ] เพิ่ม payment-proofs routes ใน router
- [ ] ตรวจสอบว่า all handlers return data ในรูปแบบ `{ success: true, data: [...] }`
- [ ] Test ทุก API endpoints ด้วย Postman

### Frontend Hooks
- [ ] แก้ไข use-inventory.ts ให้ส่ง auth token
- [ ] แก้ไข use-room-status.ts ให้เรียก API จริง
- [ ] แก้ไข use-pricing.ts ให้มี CRUD mutations
- [ ] เพิ่ม use-payment-proofs.ts

### Frontend Pages
- [ ] inventory/page.tsx - เพิ่ม date range picker
- [ ] reception/page.tsx - ใช้ useRoomStatus hook
- [ ] pricing/tiers/page.tsx - เพิ่ม CRUD forms
- [ ] pricing/matrix/page.tsx - แสดง matrix จริง
- [ ] bookings/page.tsx - แสดง payment proofs
- [ ] dashboard/page.tsx - ใช้ reports APIs

### UI/UX
- [ ] เพิ่ม loading states ทุกหน้า
- [ ] เพิ่ม empty states ทุกหน้า
- [ ] เพิ่ม error handling
- [ ] เพิ่ม toast notifications
- [ ] ใช้ globals.css สำหรับ styling

## Flow การทำงานที่ถูกต้อง

### Inventory Management Flow
```
1. User เลือกเดือน → set selectedMonth
2. Calculate start_date, end_date จาก selectedMonth
3. useInventory({ start_date, end_date }) → fetch data
4. แสดง calendar view
5. User คลิกวัน → เปิด modal แก้ไข allotment
6. User save → call updateInventory mutation
7. Invalidate query → refresh data
```

### Reception Flow
```
1. useRoomStatus() → fetch all rooms
2. แสดงรายการห้อง with status badges
3. User filter by status → client-side filtering
4. User search by room number → client-side search
5. User คลิกห้อง → แสดง details modal
6. (Optional) Update status → call API
```

### Pricing Tiers Flow
```
1. useRateTiers() → fetch all tiers
2. แสดงรายการ tiers ในตาราง
3. User คลิก "Create" → เปิด form modal
4. User กรอกข้อมูล → submit
5. useCreateRateTier() → POST to API
6. Success → close modal, refresh list
```

### Bookings Management Flow
```
1. usePaymentProofs() → fetch pending proofs
2. แสดงรายการ bookings with proof images
3. User คลิกดูรูป → เปิด image modal
4. User คลิก "Approve" → confirm dialog
5. useApprovePaymentProof() → POST to API
6. Success → booking status = 'Confirmed'
7. Refresh list
```

## Testing Steps

### 1. Test Inventory Page
```bash
# 1. Login as manager
# 2. Go to /admin/inventory
# 3. Should see room types dropdown
# 4. Select room type
# 5. Should see calendar with allotment numbers
# 6. Click a date
# 7. Should see edit modal
# 8. Change allotment
# 9. Click save
# 10. Should see success toast
# 11. Data should update in calendar
```

### 2. Test Reception Page
```bash
# 1. Login as receptionist or manager
# 2. Go to /admin/reception
# 3. Should see list of all rooms
# 4. Should see status badges (Available, Occupied, etc.)
# 5. Filter by status
# 6. Search by room number
# 7. Click a room
# 8. Should see room details
```

### 3. Test Pricing Tiers
```bash
# 1. Login as manager
# 2. Go to /admin/pricing/tiers
# 3. Should see list of tiers
# 4. Click "Create New Tier"
# 5. Fill form (name, multiplier)
# 6. Click save
# 7. Should see new tier in list
# 8. Click edit on a tier
# 9. Change values
# 10. Click save
# 11. Should see updated values
```

## คำแนะนำเพิ่มเติม

1. **ใช้ useSession() ทุกครั้ง** เพื่อเช็ค authentication
2. **ส่ง Authorization header** ในทุก API calls
3. **Handle loading states** ด้วย isLoading
4. **Handle error states** ด้วย error
5. **Handle empty states** เมื่อไม่มีข้อมูล
6. **ใช้ toast notifications** สำหรับ feedback
7. **Invalidate queries** หลัง mutations
8. **ใช้ globals.css** สำหรับ consistent styling

## Next Steps

1. เริ่มจากแก้ไข backend router (เพิ่ม payment-proofs routes)
2. แก้ไข frontend hooks ทีละตัว
3. แก้ไข frontend pages ทีละหน้า
4. Test แต่ละหน้าให้ทำงานได้
5. เพิ่ม UI/UX improvements
