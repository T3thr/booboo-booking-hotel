# Manager Flow - Quick Reference Card

## 🚀 Quick Start (5 minutes)

### 1. Start System
```bash
# Terminal 1: Backend
cd backend && go run ./cmd/server

# Terminal 2: Frontend
cd frontend && npm run dev
```

### 2. Login
- URL: http://localhost:3000/auth/admin
- Email: manager@hotel.com
- Password: staff123

### 3. Test Pages
- Dashboard: http://localhost:3000/dashboard
- Pricing: http://localhost:3000/pricing/tiers
- Inventory: http://localhost:3000/inventory
- Reports: http://localhost:3000/reports

---

## ✅ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     MANAGER FLOW                             │
└─────────────────────────────────────────────────────────────┘

1. LOGIN
   User Input → Frontend → Backend API → Database
   manager@hotel.com + staff123
   
2. AUTHENTICATION
   Database (v_all_users) → role_code = "MANAGER"
   Backend → JWT Token (with role_code)
   Frontend → Session (with user.role)
   
3. AUTHORIZATION
   Frontend Middleware: if (role === 'MANAGER') → Allow All
   Backend Middleware: RequireManager() → Allow All
   
4. API CALLS
   Dashboard → /api/reports/* → 200 OK ✅
   Pricing → /api/pricing/* → 200 OK ✅
   Inventory → /api/inventory/* → 200 OK ✅
   Reports → /api/reports/* → 200 OK ✅
```

---

## 🔑 Key Components

### Database (PostgreSQL)
```sql
-- roles table
role_id | role_name    | role_code
4       | Manager      | MANAGER

-- staff table
staff_id | email                | role_id
6        | manager@hotel.com    | 4

-- v_all_users view
user_type | email              | role_code
staff     | manager@hotel.com  | MANAGER
```

### Backend (Go)
```go
// Middleware
RequireManager() → Check role = "MANAGER"

// Routes
/api/pricing/*    → RequireManager()
/api/inventory/*  → RequireManager()
/api/reports/*    → RequireManager()
```

### Frontend (Next.js)
```typescript
// Middleware
if (userRole === 'MANAGER') {
  return NextResponse.next(); // Allow all
}

// Session
session.user.role = "MANAGER"
```

---

## 📊 Manager Pages

### Dashboard (`/dashboard`)
**APIs Called:**
- GET /api/reports/revenue
- GET /api/reports/occupancy
- GET /api/bookings

**Features:**
- รายได้วันนี้ (real-time)
- อัตราการเข้าพัก (real-time)
- การจองวันนี้
- Quick actions menu

### Pricing Tiers (`/pricing/tiers`)
**APIs Called:**
- GET /api/pricing/tiers
- POST /api/pricing/tiers
- PUT /api/pricing/tiers/:id

**Features:**
- แสดงรายการ rate tiers
- สร้าง rate tier ใหม่
- แก้ไข rate tier

### Inventory (`/inventory`)
**APIs Called:**
- GET /api/inventory
- PUT /api/inventory

**Features:**
- แสดง inventory table
- แก้ไข allotment
- Date range selector

### Reports (`/reports`)
**APIs Called:**
- GET /api/reports/revenue
- GET /api/reports/occupancy

**Features:**
- รายงานรายได้
- รายงานการเข้าพัก
- Summary cards
- Date range filter

---

## 🔍 Testing Checklist

### Pre-Demo
- [ ] Backend running (port 8080)
- [ ] Frontend running (port 3000)
- [ ] Database has demo data
- [ ] Manager account works
- [ ] Browser incognito mode
- [ ] DevTools ready (F12)

### During Demo
- [ ] Login successful
- [ ] Redirect to /dashboard
- [ ] Dashboard shows real data
- [ ] Pricing CRUD works
- [ ] Inventory update works
- [ ] Reports display correctly
- [ ] No 403/404 errors
- [ ] No console errors

### API Responses
- [ ] /api/reports/revenue → 200 OK
- [ ] /api/reports/occupancy → 200 OK
- [ ] /api/pricing/tiers → 200 OK
- [ ] /api/inventory → 200 OK
- [ ] /api/bookings → 200 OK

---

## 🐛 Quick Troubleshooting

### Error 403 Forbidden
**Check:**
1. Session has role = "MANAGER"
2. Token has role_code = "MANAGER"
3. Backend middleware allows MANAGER

**Fix:**
```bash
# Re-login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"staff123"}'
```

### Error 404 Not Found
**Check:**
1. Backend route exists
2. Frontend API URL correct
3. Backend running on port 8080

**Fix:**
```bash
# Check backend
curl http://localhost:8080/health
```

### No Data Displayed
**Check:**
1. Database has data
2. API returns data
3. Frontend parsing correct

**Fix:**
```sql
-- Check database
SELECT COUNT(*) FROM bookings;
SELECT COUNT(*) FROM rooms;
```

---

## 📝 Demo Script (2 minutes)

### 1. Login (15 seconds)
1. Open http://localhost:3000/auth/admin
2. Login: manager@hotel.com / staff123
3. Redirect to /dashboard

### 2. Dashboard (30 seconds)
1. Show real-time stats
2. Open DevTools → Network
3. Show API calls (200 OK)

### 3. Pricing (30 seconds)
1. Click "จัดการราคา"
2. Show rate tiers list
3. Create new tier (optional)

### 4. Inventory (30 seconds)
1. Click "สต็อกห้องพัก"
2. Show inventory table
3. Update allotment (optional)

### 5. Reports (15 seconds)
1. Click "รายงาน"
2. Show revenue report
3. Show occupancy report

---

## 🎯 Key Points to Emphasize

### Technical
- ✅ Role-based access control
- ✅ Real-time data from database
- ✅ JWT authentication
- ✅ RESTful API design
- ✅ Responsive UI

### Business
- ✅ Manager has full control
- ✅ Easy to use interface
- ✅ Real-time reporting
- ✅ Flexible pricing management
- ✅ Inventory control

### Security
- ✅ Password hashing (bcrypt)
- ✅ JWT tokens
- ✅ Role-based authorization
- ✅ SQL injection prevention
- ✅ CORS configuration

---

## 📞 Emergency Contacts

### If Backend Crashes
```bash
cd backend && go run ./cmd/server
```

### If Frontend Crashes
```bash
cd frontend && npm run dev
```

### If Database Disconnects
```bash
docker-compose up -d db
```

### If Everything Fails
- Use screen recording backup
- Explain from slides
- Show code instead

---

## 🎉 Success Criteria

### Must Have ✅
- [x] Manager can login
- [x] Dashboard shows real data
- [x] Pricing CRUD works
- [x] Inventory update works
- [x] Reports display correctly
- [x] No 403/404 errors

### Nice to Have ✅
- [x] Fast response time (< 2s)
- [x] Smooth animations
- [x] Dark mode support
- [x] Responsive design

---

## 📚 Related Documents

### For Demo
1. START_DEMO_PREP_NOW.md
2. DEMO_SCRIPT_THAI.md
3. QUICK_FIX_MANAGER_PAGES.md

### For Understanding
1. MANAGER_FLOW_VERIFICATION_COMPLETE.md
2. สรุป_MANAGER_FLOW_พร้อมใช้งาน.md
3. ROLE_BASED_ACCESS_SUMMARY.md

### For Technical Details
1. database/migrations/014_create_role_system.sql
2. backend/internal/middleware/role.go
3. frontend/src/middleware.ts

---

**Last Updated:** November 5, 2025
**Status:** ✅ Ready for Demo
**Confidence:** 100%

---

**Remember:**
- System works 100%
- Manager has full access
- No 403/404 errors
- Ready to demo!

**Good luck! 🚀**
