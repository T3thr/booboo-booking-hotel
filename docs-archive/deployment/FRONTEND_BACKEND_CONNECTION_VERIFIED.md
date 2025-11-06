# ✅ Frontend ↔ Backend Connection Verification

## 📊 สถานะการเชื่อมต่อ

### Backend (Render)
```
✅ Deployed: https://booboo-booking.onrender.com
✅ API Endpoint: https://booboo-booking.onrender.com/api
✅ Health Check: /api/health
⚠️ Database Migrations: ต้องรันก่อน (ดู QUICK_FIX_RENDER.md)
```

### Frontend (Vercel)
```
⏳ Ready to Deploy
✅ Configuration: frontend/.env.production
✅ API Client: frontend/src/lib/api.ts
✅ Auth: frontend/src/lib/auth.ts
```

---

## 🔍 การตรวจสอบ Code

### 1. API Configuration ✅

**File**: `frontend/src/lib/api.ts`

```typescript
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';
// Production: https://booboo-booking.onrender.com/api
```

**Features**:
- ✅ Axios client configured
- ✅ JWT token auto-injection
- ✅ Error handling
- ✅ 401 redirect to login
- ✅ Timeout: 30 seconds

**API Methods**:
```typescript
api.get()    // GET requests
api.post()   // POST requests
api.put()    // PUT requests
api.delete() // DELETE requests
```

---

### 2. Authentication ✅

**File**: `frontend/src/lib/auth.ts`

```typescript
const BACKEND_URL = process.env.BACKEND_URL || 'http://backend:8080';
// Production: https://booboo-booking.onrender.com
```

**Flow**:
1. User submits login form
2. Frontend calls: `POST /api/auth/login`
3. Backend validates credentials
4. Backend returns JWT token
5. Frontend stores token in NextAuth session
6. Token auto-added to all API requests

**Features**:
- ✅ NextAuth v5 integration
- ✅ JWT strategy
- ✅ Session management (24 hours)
- ✅ Role-based access
- ✅ Error handling

---

### 3. Environment Variables ✅

**File**: `frontend/.env.production`

```env
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api
BACKEND_URL=https://booboo-booking.onrender.com
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=
NODE_ENV=production
```

**Status**: ✅ Configured for Render backend

---

### 4. API Endpoints Mapping

| Frontend Hook | Backend Endpoint | Method | Auth |
|--------------|------------------|--------|------|
| `authApi.login()` | `/api/auth/login` | POST | No |
| `authApi.register()` | `/api/auth/register` | POST | No |
| `roomApi.search()` | `/api/rooms/search` | GET | No |
| `roomApi.getTypes()` | `/api/rooms/types` | GET | No |
| `bookingApi.createHold()` | `/api/bookings/hold` | POST | Yes |
| `bookingApi.confirm()` | `/api/bookings/:id/confirm` | POST | Yes |
| `bookingApi.getAll()` | `/api/bookings` | GET | Yes |
| `checkinApi.checkIn()` | `/api/checkin` | POST | Yes |
| `checkinApi.checkOut()` | `/api/checkout` | POST | Yes |
| `housekeepingApi.getTasks()` | `/api/housekeeping/tasks` | GET | Yes |
| `pricingApi.getTiers()` | `/api/pricing/tiers` | GET | Yes |
| `reportApi.getOccupancy()` | `/api/reports/occupancy` | GET | Yes |

**Status**: ✅ All endpoints mapped correctly

---

## 🔄 Request Flow Verification

### Example: User Login

```
1. User Input (Browser)
   Email: admin@hotel.com
   Password: admin123
   ↓
2. Frontend (Vercel)
   File: frontend/src/app/auth/signin/page.tsx
   Action: signIn('credentials', { email, password })
   ↓
3. NextAuth (Vercel)
   File: frontend/src/lib/auth.ts
   Function: authorize()
   Request: POST https://booboo-booking.onrender.com/api/auth/login
   Body: { email, password }
   ↓
4. Backend (Render)
   File: backend/internal/handlers/auth_handler.go
   Function: Login()
   Validates: email + password
   Generates: JWT token
   Response: { id, email, role, accessToken }
   ↓
5. NextAuth Session (Vercel)
   Stores: { user, accessToken }
   Cookie: next-auth.session-token
   ↓
6. Subsequent Requests
   All API calls include:
   Header: Authorization: Bearer <accessToken>
```

**Status**: ✅ Flow verified in code

---

### Example: Search Rooms

```
1. User Input (Browser)
   Check-in: 2025-11-10
   Check-out: 2025-11-12
   Guests: 2
   ↓
2. Frontend (Vercel)
   File: frontend/src/hooks/use-rooms.ts
   Hook: useRooms()
   Call: roomApi.search({ check_in_date, check_out_date, adults, children })
   ↓
3. API Client (Vercel)
   File: frontend/src/lib/api.ts
   Transform params:
   {
     checkIn: "2025-11-10",
     checkOut: "2025-11-12",
     guests: 2
   }
   Request: GET https://booboo-booking.onrender.com/api/rooms/search
   ↓
4. Backend (Render)
   File: backend/internal/handlers/room_handler.go
   Function: SearchRooms()
   Query database for available rooms
   Response: [{ id, room_number, type, price, available }]
   ↓
5. Frontend Display (Vercel)
   Component renders room cards
   User sees available rooms
```

**Status**: ✅ Flow verified in code

---

## 🔐 Security Verification

### CORS Configuration

**Backend** (Render):
```go
// backend/internal/middleware/cors.go
allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
// Will be: https://hotel-booking-frontend.vercel.app
```

**Status**: ⏳ Need to update after frontend deployment

### JWT Validation

**Backend**:
```go
// backend/internal/middleware/auth.go
func AuthMiddleware() gin.HandlerFunc {
    // Validates JWT on every protected route
    token := c.GetHeader("Authorization")
    claims, err := jwt.ValidateToken(token, JWT_SECRET)
}
```

**Frontend**:
```typescript
// frontend/src/lib/api.ts
apiClient.interceptors.request.use(async (config) => {
    const session = await getSession();
    if (session?.accessToken) {
        config.headers.Authorization = `Bearer ${session.accessToken}`;
    }
});
```

**Status**: ✅ JWT flow verified

---

## 🧪 Testing Plan

### 1. Backend Health Check

```bash
curl https://booboo-booking.onrender.com/api/health
```

**Expected**:
```json
{
  "status": "ok",
  "timestamp": "2025-11-04T..."
}
```

### 2. Frontend → Backend Connection

```javascript
// Browser console on Vercel deployment
fetch('https://booboo-booking.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log)
```

**Expected**: Response without CORS error

### 3. Authentication Flow

```bash
# Test login endpoint
curl -X POST https://booboo-booking.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@hotel.com",
    "password": "admin123"
  }'
```

**Expected**:
```json
{
  "id": 1,
  "email": "admin@hotel.com",
  "role": "admin",
  "accessToken": "eyJ..."
}
```

### 4. Protected Endpoint

```bash
# Test with JWT token
curl https://booboo-booking.onrender.com/api/bookings \
  -H "Authorization: Bearer <token>"
```

**Expected**: List of bookings (not 401)

---

## 📋 Deployment Checklist

### Backend (Render) ✅
- [x] Service deployed
- [x] API endpoints working
- [x] Health check OK
- [ ] Database migrations (⚠️ ต้องทำก่อน!)
- [ ] CORS configured (หลัง deploy frontend)

### Frontend (Vercel) ⏳
- [x] Code ready
- [x] Configuration files created
- [x] Environment variables prepared
- [ ] Deploy to Vercel
- [ ] Update NEXTAUTH_URL
- [ ] Test connection

### Integration ⏳
- [ ] CORS configured
- [ ] Authentication tested
- [ ] Booking flow tested
- [ ] All features working

---

## 🎯 Next Steps

### 1. แก้ไข Database Migrations (ด่วน!)

```bash
cd backend\scripts
run-migrations.bat
```

➡️ [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)

### 2. Deploy Frontend

```bash
# Option A: Use script
deploy-vercel.bat

# Option B: Manual
cd frontend
vercel --prod
```

➡️ [VERCEL_DEPLOYMENT_GUIDE.md](VERCEL_DEPLOYMENT_GUIDE.md)

### 3. Update CORS

```
Render Dashboard → Environment → ALLOWED_ORIGINS
Add: https://hotel-booking-frontend.vercel.app
```

### 4. Test Integration

```bash
# Test all features
- Login
- Search rooms
- Create booking
- View bookings
```

---

## 📚 Documentation

- [VERCEL_DEPLOYMENT_GUIDE.md](VERCEL_DEPLOYMENT_GUIDE.md) - Deploy guide
- [VERCEL_SETUP_CHECKLIST.md](VERCEL_SETUP_CHECKLIST.md) - Step-by-step checklist
- [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) - Fix migrations
- [DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md) - Complete workflow
- [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) - Integration details

---

## ✅ Verification Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Backend API | ✅ | Deployed on Render |
| Frontend Code | ✅ | Ready to deploy |
| API Client | ✅ | Configured correctly |
| Authentication | ✅ | NextAuth + JWT |
| Environment Vars | ✅ | Prepared |
| CORS | ⏳ | Update after frontend deploy |
| Database | ⚠️ | Migrations needed |
| Integration | ⏳ | Test after deployment |

---

**Created**: 2025-11-04  
**Status**: 🟡 Ready to deploy frontend  
**Priority**: 🚨 Fix migrations first, then deploy frontend
