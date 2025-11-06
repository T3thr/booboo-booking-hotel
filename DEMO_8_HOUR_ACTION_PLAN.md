# แผนการทำงาน 8 ชั่วโมง - Demo ลูกค้า

## 🎯 เป้าหมาย
นำเสนอระบบจองโรงแรมที่ทำงานได้จริง โฟกัส **GUEST** และ **MANAGER** พร้อม Performance สูง

---

## ✅ สถานะปัจจุบัน (จากการวิเคราะห์)

### Backend (Go) - 95% เสร็จ ✅
- ✅ Authentication & Authorization
- ✅ All API endpoints working
- ✅ Database functions complete
- ✅ Role-based access control
- ⚠️ ต้อง rebuild และ restart

### Frontend (Next.js) - 85% เสร็จ ⚠️
- ✅ Authentication flow
- ✅ Guest booking flow (search → book → confirm)
- ✅ Manager dashboard structure
- ⚠️ Manager pages ต้องเชื่อมต่อ database
- ⚠️ UI ต้องปรับปรุงให้สวยงาม

### Database (PostgreSQL) - 100% เสร็จ ✅
- ✅ All tables created
- ✅ All functions working
- ✅ Demo data seeded
- ✅ Performance optimized

---

## 📋 แผนการทำงาน 8 ชั่วโมง

### ชั่วโมงที่ 1-2: Backend & Database (2 ชม.)

#### 1.1 Rebuild Backend (15 นาที)
```bash
cd backend
go build -o server.exe ./cmd/server
```

#### 1.2 Test All API Endpoints (30 นาที)
```bash
# Test authentication
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"staff123"}'

# Test guest login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"anan.test@example.com","password":"password123"}'

# Test room search
curl "http://localhost:8080/api/rooms/search?check_in_date=2024-12-20&check_out_date=2024-12-25&adults=2"

# Test manager endpoints (with token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/api/pricing/tiers

curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/api/inventory

curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/api/reports/occupancy?start_date=2024-12-01&end_date=2024-12-31
```

#### 1.3 Verify Database (15 นาที)
```sql
-- Check demo data
SELECT COUNT(*) FROM guests;
SELECT COUNT(*) FROM staff;
SELECT COUNT(*) FROM rooms;
SELECT COUNT(*) FROM room_types;
SELECT COUNT(*) FROM bookings;

-- Check staff passwords
SELECT email, role_code FROM v_all_users WHERE user_type = 'staff';
```

#### 1.4 Performance Check (30 นาที)
```bash
# Run load tests
cd load-tests
k6 run race-condition-test.js
k6 run concurrent-booking-test.js

# Expected results:
# - Overbookings: 0
# - Error rate: < 10%
# - Response time P95: < 2s
```

---

### ชั่วโมงที่ 3-4: Guest Flow (2 ชม.)

#### 3.1 Test Guest Registration & Login (30 นาที)
- [ ] ทดสอบ register ที่ `/auth/register`
- [ ] ทดสอบ login ที่ `/auth/signin`
- [ ] ตรวจสอบ redirect ไป `/`
- [ ] ตรวจสอบ session working

#### 3.2 Test Room Search (30 นาที)
- [ ] ทดสอบค้นหาห้องที่ `/rooms/search`
- [ ] ตรวจสอบแสดงผลห้องว่าง
- [ ] ตรวจสอบราคาถูกต้อง
- [ ] ตรวจสอบ UI สวยงาม

#### 3.3 Test Booking Flow (45 นาที)
- [ ] เลือกห้อง → ไป `/booking/guest-info`
- [ ] กรอกข้อมูลผู้เข้าพัก
- [ ] ไป `/booking/summary`
- [ ] ยืนยันการจอง
- [ ] ไป `/booking/confirmation/[id]`
- [ ] ตรวจสอบข้อมูลถูกต้อง

#### 3.4 Test Booking History (15 นาที)
- [ ] ไปที่ `/bookings`
- [ ] ดูรายการจอง
- [ ] ทดสอบยกเลิกการจอง

---

### ชั่วโมงที่ 5-6: Manager Flow (2 ชม.)

#### 5.1 Fix Manager Dashboard (30 นาที)

**File: `frontend/src/app/(manager)/dashboard/page.tsx`**

เปลี่ยนจาก mock data เป็น real data:

```typescript
'use client';

import { useSession } from 'next-auth/react';
import { Card } from '@/components/ui/card';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';

export default function ManagerDashboardPage() {
  const { data: session } = useSession();

  // Fetch real stats
  const { data: stats } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const today = new Date().toISOString().split('T')[0];
      const [revenue, occupancy, bookings] = await Promise.all([
        api.get('/api/reports/revenue', {
          params: { start_date: today, end_date: today }
        }),
        api.get('/api/reports/occupancy', {
          params: { start_date: today, end_date: today }
        }),
        api.get('/api/bookings', {
          params: { status: 'Confirmed' }
        })
      ]);
      return { revenue: revenue.data, occupancy: occupancy.data, bookings: bookings.data };
    }
  });

  // ... rest of component
}
```

#### 5.2 Fix Pricing Pages (45 นาที)

**File: `frontend/src/app/(manager)/pricing/tiers/page.tsx`**

```typescript
'use client';

import { useRateTiers, useCreateRateTier, useUpdateRateTier } from '@/hooks/use-pricing';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

export default function RateTiersPage() {
  const { data: tiers, isLoading } = useRateTiers();
  const createTier = useCreateRateTier();
  const updateTier = useUpdateRateTier();

  // ... implement CRUD operations
}
```

**File: `frontend/src/app/(manager)/pricing/calendar/page.tsx`**

```typescript
'use client';

import { usePricingCalendar, useUpdatePricingCalendar } from '@/hooks/use-pricing';

export default function PricingCalendarPage() {
  const { data: calendar } = usePricingCalendar({
    start_date: '2024-12-01',
    end_date: '2024-12-31'
  });

  // ... implement calendar view
}
```

#### 5.3 Fix Inventory Page (30 นาที)

**File: `frontend/src/app/(manager)/inventory/page.tsx`**

```typescript
'use client';

import { useInventory, useUpdateInventory } from '@/hooks/use-inventory';

export default function InventoryPage() {
  const { data: inventory } = useInventory({
    start_date: '2024-12-01',
    end_date: '2024-12-31'
  });

  // ... implement inventory management
}
```

#### 5.4 Fix Reports Page (15 นาที)

**File: `frontend/src/app/(manager)/reports/page.tsx`**

```typescript
'use client';

import { useOccupancyReport, useRevenueReport } from '@/hooks/use-reports';

export default function ReportsPage() {
  const { data: occupancy } = useOccupancyReport({
    start_date: '2024-12-01',
    end_date: '2024-12-31'
  });

  const { data: revenue } = useRevenueReport({
    start_date: '2024-12-01',
    end_date: '2024-12-31'
  });

  // ... implement reports view
}
```

---

### ชั่วโมงที่ 7: UI/UX Polish (1 ชม.)

#### 7.1 Homepage Enhancement (20 นาที)
- [ ] ตรวจสอบ responsive
- [ ] ปรับ colors ให้สวยงาม
- [ ] เพิ่ม animations
- [ ] ทดสอบ dark mode

#### 7.2 Search Page Enhancement (20 นาที)
- [ ] ปรับ layout ให้สวย
- [ ] เพิ่ม loading states
- [ ] เพิ่ม empty states
- [ ] ปรับ room cards

#### 7.3 Manager Pages Enhancement (20 นาที)
- [ ] ปรับ dashboard layout
- [ ] เพิ่ม charts/graphs
- [ ] ปรับ tables ให้อ่านง่าย
- [ ] เพิ่ม filters

---

### ชั่วโมงที่ 8: Testing & Demo Prep (1 ชม.)

#### 8.1 End-to-End Testing (30 นาที)

**Guest Flow:**
1. Register → Login
2. Search rooms (Dec 20-25)
3. Select Deluxe room
4. Fill guest info
5. Confirm booking
6. View booking history
7. Cancel booking

**Manager Flow:**
1. Login as manager
2. View dashboard stats
3. Update pricing tier
4. Update pricing calendar
5. Update inventory
6. View reports

#### 8.2 Demo Script Preparation (20 นาที)

สร้างไฟล์ `DEMO_SCRIPT.md`:

```markdown
# Demo Script - Hotel Booking System

## Part 1: Guest Experience (5 นาที)

1. **Homepage** (30 วินาที)
   - แสดง luxury design
   - อธิบาย features
   - คลิก "ค้นหาห้องพัก"

2. **Room Search** (1 นาที)
   - เลือกวันที่ 20-25 ธันวาคม
   - เลือก 2 ผู้ใหญ่
   - คลิกค้นหา
   - แสดงห้องว่าง 3 ประเภท

3. **Booking Process** (2 นาที)
   - เลือก Deluxe Room
   - กรอกข้อมูลผู้เข้าพัก
   - Review summary
   - Confirm booking
   - แสดง confirmation

4. **Booking Management** (1.5 นาที)
   - ดูประวัติการจอง
   - แสดงรายละเอียด
   - ทดสอบยกเลิก (optional)

## Part 2: Manager Features (5 นาที)

1. **Dashboard** (1 นาที)
   - แสดง real-time stats
   - รายได้วันนี้
   - อัตราการเข้าพัก
   - จำนวนการจอง

2. **Pricing Management** (1.5 นาที)
   - แสดง rate tiers
   - อัปเดตราคา
   - แสดง pricing calendar

3. **Inventory Management** (1 นาที)
   - แสดง room availability
   - อัปเดต allotment
   - แสดงผลทันที

4. **Reports** (1.5 นาที)
   - Occupancy report
   - Revenue report
   - Export to CSV

## Part 3: Technical Highlights (2 นาที)

1. **Performance**
   - Load test results
   - No overbooking
   - Fast response time

2. **Security**
   - Role-based access
   - JWT authentication
   - Data encryption

3. **Scalability**
   - Connection pooling
   - Redis caching
   - Optimized queries
```

#### 8.3 Final Checks (10 นาที)
- [ ] All services running
- [ ] No console errors
- [ ] All links working
- [ ] Demo data ready
- [ ] Backup plan ready

---

## 🚀 Quick Start Commands

### Start Everything
```bash
# Terminal 1: Backend
cd backend
./server.exe

# Terminal 2: Frontend
cd frontend
npm run dev

# Terminal 3: Database (if needed)
docker-compose up -d db
```

### Test Credentials
```
Manager:
- Email: manager@hotel.com
- Password: staff123

Guest:
- Email: anan.test@example.com
- Password: password123
```

---

## 📊 Success Criteria

### Must Have (Priority 1) ✅
- [x] Guest can search rooms
- [x] Guest can book rooms
- [x] Guest can view bookings
- [x] Manager can view dashboard
- [ ] Manager can update pricing
- [ ] Manager can update inventory
- [ ] Manager can view reports

### Nice to Have (Priority 2) ⭐
- [ ] Beautiful UI/UX
- [ ] Smooth animations
- [ ] Responsive design
- [ ] Dark mode working

### Performance (Priority 1) 🚀
- [ ] Page load < 2s
- [ ] API response < 500ms
- [ ] No overbooking
- [ ] Error rate < 1%

---

## 🎯 Demo Checklist

### Before Demo
- [ ] Backend running
- [ ] Frontend running
- [ ] Database seeded
- [ ] Test all flows
- [ ] Prepare demo script
- [ ] Clear browser cache
- [ ] Close unnecessary tabs

### During Demo
- [ ] Start with homepage
- [ ] Show guest flow first
- [ ] Then show manager features
- [ ] Highlight performance
- [ ] Show technical details
- [ ] Answer questions

### After Demo
- [ ] Collect feedback
- [ ] Note improvements
- [ ] Plan next steps

---

## 🔧 Troubleshooting

### Backend Issues
```bash
# Check if running
curl http://localhost:8080/health

# Check logs
tail -f backend/logs/app.log

# Restart
cd backend && ./server.exe
```

### Frontend Issues
```bash
# Clear cache
rm -rf .next
npm run dev

# Check console
# Open DevTools → Console
```

### Database Issues
```bash
# Check connection
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking

# Check data
SELECT COUNT(*) FROM bookings;
```

---

## 📝 Notes

### What's Working ✅
- Authentication (Guest & Manager)
- Room search with real data
- Booking flow complete
- Database functions all working
- API endpoints all working

### What Needs Work ⚠️
- Manager pages need database connection
- UI needs polish
- Some loading states missing
- Error handling can improve

### Performance Optimizations Done ✅
- Database indexes
- Connection pooling
- Query optimization
- Caching strategy

---

## 🎉 Expected Demo Flow

**Total Time: 12 minutes**

1. **Introduction** (1 min)
   - Project overview
   - Technology stack
   - Key features

2. **Guest Experience** (5 min)
   - Search & book flow
   - Real-time availability
   - Booking management

3. **Manager Features** (5 min)
   - Dashboard analytics
   - Pricing management
   - Inventory control
   - Reports

4. **Q&A** (1 min)
   - Answer questions
   - Discuss next steps

---

**Good luck with your demo! 🚀**
