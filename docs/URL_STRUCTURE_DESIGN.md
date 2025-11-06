# 🌐 URL Structure Design - Role-Based Access

## 🎯 Design Principles

### 1. **SEO & Performance**
- Clean URLs without unnecessary nesting
- Static segments for better caching
- Predictable patterns for prefetching

### 2. **Security**
- Role-based path prefixes
- Server-side middleware protection
- No sensitive data in URLs

### 3. **User Experience**
- Intuitive navigation
- Consistent patterns
- Clear role indication

### 4. **Scalability**
- Easy to add new features
- Supports subdomain deployment
- Compatible with Vercel/Next.js

---

## 📁 URL Structure Overview

```
Main Domain: hotel.example.com
├── /                          (Public - Guest booking)
├── /auth/*                    (Authentication)
├── /bookings/*                (Guest bookings)
├── /staff/*                   (Staff portal)
├── /admin/*                   (Manager portal)
└── /api/*                     (API endpoints)
```

---

## 🔐 Role-Based URL Mapping

### 1. **Guest (ผู้เข้าพัก)** - Public Access

```
Base: / (root domain)

Public Pages:
├── /                          → Home page
├── /rooms                     → Room catalog
├── /rooms/search              → Search rooms
├── /rooms/[id]                → Room details
└── /about                     → About hotel

Authentication:
├── /auth/signin               → Sign in
├── /auth/register             → Register
└── /auth/forgot-password      → Password reset

Protected (Requires Login):
├── /bookings                  → My bookings list
├── /bookings/[id]             → Booking details
├── /booking/new               → New booking flow
│   ├── /booking/guest-info    → Guest information
│   ├── /booking/summary       → Booking summary
│   └── /booking/confirmation/[id] → Confirmation
└── /profile                   → User profile
```

**Middleware Protection:**
```typescript
// frontend/src/middleware.ts
if (pathname.startsWith('/bookings') || pathname.startsWith('/profile')) {
  if (!session || session.user.role !== 'GUEST') {
    return redirect('/auth/signin');
  }
}
```

---

### 2. **Receptionist (พนักงานต้อนรับ)** - Staff Portal

```
Base: /staff

Dashboard:
└── /staff                     → Staff dashboard

Check-in/Check-out:
├── /staff/checkin             → Check-in page
├── /staff/checkout            → Check-out page
├── /staff/arrivals            → Today's arrivals
└── /staff/departures          → Today's departures

Booking Management:
├── /staff/bookings            → All bookings
├── /staff/bookings/[id]       → Booking details
├── /staff/bookings/new        → Create booking
└── /staff/bookings/[id]/edit  → Edit booking

Room Operations:
├── /staff/rooms               → Room status
├── /staff/rooms/[id]          → Room details
├── /staff/move-room           → Move guest to another room
└── /staff/no-show             → Handle no-show

Guest Management:
├── /staff/guests              → Guest list
└── /staff/guests/[id]         → Guest profile
```

**Middleware Protection:**
```typescript
if (pathname.startsWith('/staff')) {
  if (!session || !['RECEPTIONIST', 'MANAGER'].includes(session.user.role)) {
    return redirect('/unauthorized');
  }
}
```

---

### 3. **Housekeeper (แม่บ้าน)** - Housekeeping Portal

```
Base: /staff/housekeeping

Dashboard:
└── /staff/housekeeping        → Housekeeping dashboard

Task Management:
├── /staff/housekeeping/tasks  → Task list
├── /staff/housekeeping/rooms  → Room status
└── /staff/housekeeping/inspection → Room inspection

Maintenance:
├── /staff/housekeeping/maintenance → Maintenance reports
└── /staff/housekeeping/maintenance/[id] → Report details
```

**Middleware Protection:**
```typescript
if (pathname.startsWith('/staff/housekeeping')) {
  if (!session || !['HOUSEKEEPER', 'MANAGER'].includes(session.user.role)) {
    return redirect('/unauthorized');
  }
}
```

---

### 4. **Manager (ผู้จัดการ)** - Admin Portal

```
Base: /admin

Dashboard:
└── /admin                     → Manager dashboard

Pricing Management:
├── /admin/pricing             → Pricing overview
├── /admin/pricing/tiers       → Rate tiers
├── /admin/pricing/calendar    → Pricing calendar
├── /admin/pricing/matrix      → Rate matrix
└── /admin/pricing/plans       → Rate plans

Inventory Management:
├── /admin/inventory           → Room inventory
└── /admin/inventory/calendar  → Inventory calendar

Reports & Analytics:
├── /admin/reports             → Reports dashboard
├── /admin/reports/occupancy   → Occupancy report
├── /admin/reports/revenue     → Revenue report
└── /admin/reports/vouchers    → Voucher usage

Configuration:
├── /admin/rooms               → Room management
├── /admin/rooms/types         → Room types
├── /admin/vouchers            → Voucher management
├── /admin/policies            → Cancellation policies
└── /admin/settings            → System settings

Staff Management:
├── /admin/staff               → Staff list
└── /admin/staff/[id]          → Staff details
```

**Middleware Protection:**
```typescript
if (pathname.startsWith('/admin')) {
  if (!session || session.user.role !== 'MANAGER') {
    return redirect('/unauthorized');
  }
}
```

---

## 🚀 Vercel Subdomain Strategy

### Option 1: Path-Based (Recommended for Single Domain)

```
Production: hotel.example.com
├── /                          → Guest portal
├── /staff/*                   → Staff portal
└── /admin/*                   → Admin portal
```

**Pros:**
- Single SSL certificate
- Easier session management
- Better for SEO
- Simpler deployment

**Cons:**
- Longer URLs
- All code in one deployment

---

### Option 2: Subdomain-Based (Enterprise)

```
Main: hotel.example.com        → Guest portal
Staff: staff.hotel.example.com → Staff portal
Admin: admin.hotel.example.com → Admin portal
```

**Vercel Configuration:**
```json
// vercel.json
{
  "routes": [
    {
      "src": "^/staff/(.*)",
      "dest": "https://staff.hotel.example.com/$1"
    },
    {
      "src": "^/admin/(.*)",
      "dest": "https://admin.hotel.example.com/$1"
    }
  ]
}
```

**Pros:**
- Clear separation
- Independent deployments
- Better security isolation
- Easier to scale

**Cons:**
- Multiple SSL certificates
- Complex session management
- More DNS configuration

---

## 📊 Performance Optimization

### 1. **Route Groups (Next.js 13+)**

```
app/
├── (guest)/                   → Public routes
│   ├── page.tsx              → /
│   ├── rooms/
│   └── bookings/
├── (staff)/                   → Staff routes
│   ├── layout.tsx            → Staff layout
│   ├── page.tsx              → /staff
│   └── checkin/
└── (admin)/                   → Admin routes
    ├── layout.tsx            → Admin layout
    ├── page.tsx              → /admin
    └── pricing/
```

**Benefits:**
- Shared layouts per role
- Code splitting by role
- Better bundle size
- Faster page loads

---

### 2. **Middleware Optimization**

```typescript
// frontend/src/middleware.ts
export const config = {
  matcher: [
    '/bookings/:path*',
    '/staff/:path*',
    '/admin/:path*',
  ],
};

export async function middleware(request: NextRequest) {
  const session = await auth();
  const { pathname } = request.nextUrl;

  // Fast path for public routes
  if (!pathname.startsWith('/bookings') && 
      !pathname.startsWith('/staff') && 
      !pathname.startsWith('/admin')) {
    return NextResponse.next();
  }

  // Role-based access control
  const roleAccess = {
    '/bookings': ['GUEST', 'RECEPTIONIST', 'MANAGER'],
    '/staff': ['RECEPTIONIST', 'HOUSEKEEPER', 'MANAGER'],
    '/admin': ['MANAGER'],
  };

  // Check access
  for (const [prefix, roles] of Object.entries(roleAccess)) {
    if (pathname.startsWith(prefix)) {
      if (!session || !roles.includes(session.user.role)) {
        return NextResponse.redirect(new URL('/unauthorized', request.url));
      }
    }
  }

  return NextResponse.next();
}
```

---

### 3. **API Routes Organization**

```
app/api/
├── auth/
│   ├── login/route.ts
│   ├── register/route.ts
│   └── logout/route.ts
├── bookings/
│   ├── route.ts              → GET /api/bookings
│   ├── [id]/route.ts         → GET /api/bookings/[id]
│   └── [id]/cancel/route.ts  → POST /api/bookings/[id]/cancel
├── staff/
│   ├── checkin/route.ts
│   └── checkout/route.ts
└── admin/
    ├── pricing/route.ts
    └── reports/route.ts
```

---

## 🎨 Navigation Structure

### Guest Navigation

```typescript
const guestNav = [
  { label: 'หน้าแรก', href: '/' },
  { label: 'ห้องพัก', href: '/rooms' },
  { label: 'การจองของฉัน', href: '/bookings', protected: true },
  { label: 'โปรไฟล์', href: '/profile', protected: true },
];
```

### Staff Navigation

```typescript
const staffNav = [
  { label: 'แดชบอร์ด', href: '/staff' },
  { label: 'เช็คอิน', href: '/staff/checkin' },
  { label: 'เช็คเอาท์', href: '/staff/checkout' },
  { label: 'การจอง', href: '/staff/bookings' },
  { label: 'ห้องพัก', href: '/staff/rooms' },
];
```

### Housekeeper Navigation

```typescript
const housekeeperNav = [
  { label: 'แดชบอร์ด', href: '/staff/housekeeping' },
  { label: 'งานทำความสะอาด', href: '/staff/housekeeping/tasks' },
  { label: 'ตรวจสอบห้อง', href: '/staff/housekeeping/inspection' },
  { label: 'รายงานซ่อมบำรุง', href: '/staff/housekeeping/maintenance' },
];
```

### Manager Navigation

```typescript
const managerNav = [
  { label: 'แดชบอร์ด', href: '/admin' },
  { label: 'ราคา', href: '/admin/pricing' },
  { label: 'สต็อก', href: '/admin/inventory' },
  { label: 'รายงาน', href: '/admin/reports' },
  { label: 'ตั้งค่า', href: '/admin/settings' },
];
```

---

## ✅ Recommended Structure

### For This Project: **Path-Based with Route Groups**

```
Reasons:
1. ✅ Single domain = easier SSL
2. ✅ Shared session = better UX
3. ✅ Next.js route groups = clean code
4. ✅ Vercel-friendly = easy deployment
5. ✅ SEO-friendly = better ranking
6. ✅ Performance = code splitting by role
```

### URL Pattern:

```
Guest:        /                → Public
              /bookings/*      → Protected (GUEST)

Staff:        /staff/*         → Protected (RECEPTIONIST, MANAGER)
              /staff/housekeeping/* → Protected (HOUSEKEEPER, MANAGER)

Admin:        /admin/*         → Protected (MANAGER only)
```

---

## 📝 Implementation Checklist

- [ ] Create migration 014 for role system
- [ ] Update middleware with role-based access
- [ ] Rename (manager) → (admin)
- [ ] Move housekeeping under /staff/housekeeping
- [ ] Update navigation components
- [ ] Add role-based redirects
- [ ] Test all protected routes
- [ ] Update documentation

---

**Status:** ✅ Design Complete  
**Next:** Implementation  
**Date:** November 4, 2025
