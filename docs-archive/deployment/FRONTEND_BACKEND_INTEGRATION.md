# 🔗 Frontend-Backend Integration Guide (Production)

## 🚀 Production Deployment Status

### Current Setup
- ✅ **Backend**: Deployed on Render (https://booboo-booking.onrender.com)
- ⏳ **Frontend**: Ready to deploy on Vercel
- ✅ **Database**: Neon PostgreSQL (configured)
- ⚠️ **Issue**: Database migrations need to be run

### 🚨 แก้ไขปัญหาก่อน!
**ปัญหา**: `ERROR: function release_expired_holds() does not exist`

**วิธีแก้ไข**: อ่าน [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) (ใช้เวลา 5-10 นาที)

### Quick Links
- 🚨 [แก้ไขปัญหา Render ด่วน](QUICK_FIX_RENDER.md) - อ่านก่อน!
- 📖 [Production Setup Guide](RENDER_PRODUCTION_SETUP.md) - ขั้นตอนครบถ้วน
- 🔐 [Environment Variables](RENDER_ENVIRONMENT_VARIABLES.md)

---

## 📋 Overview

ระบบ Hotel Booking ประกอบด้วย:
- **Frontend**: Next.js 16 (App Router) → Deploy บน Vercel
- **Backend**: Go (Gin framework) → Deploy บน Render
- **Database**: PostgreSQL → Neon (Serverless)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Browser                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Vercel CDN (Frontend)                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Next.js 16 (App Router)                            │  │
│  │  - Server Components                                 │  │
│  │  - Client Components                                 │  │
│  │  - API Routes (optional)                            │  │
│  └──────────────────┬───────────────────────────────────┘  │
└────────────────────┬┴───────────────────────────────────────┘
                     │
                     │ HTTPS + JWT
                     │ CORS: Allowed Origins
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              Render (Backend)                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Go Backend (Gin)                                    │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │  Middleware Chain                               │ │  │
│  │  │  1. CORS                                       │ │  │
│  │  │  2. Rate Limiting                              │ │  │
│  │  │  3. JWT Authentication                         │ │  │
│  │  │  4. Security Headers                           │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │  Handlers → Services → Repositories            │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────┬───────────────────────────────────┘  │
└────────────────────┬┴───────────────────────────────────────┘
                     │
                     │ PostgreSQL Protocol
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              Neon (Database)                                 │
│  - PostgreSQL 15+                                           │
│  - Connection Pooling                                       │
│  - Serverless                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Production Configuration

### Backend (Render)

**Service URL**: `https://booboo-booking.onrender.com`

**Environment Variables** (ตั้งใน Render Dashboard):
```env
# Database
DATABASE_URL=postgresql://user:password@host:port/database

# Server
PORT=8080
GIN_MODE=release
ENVIRONMENT=production

# Security
JWT_SECRET=<your-32-char-secret>

# CORS (อัปเดตหลัง deploy frontend)
ALLOWED_ORIGINS=https://your-app.vercel.app,https://your-app-*.vercel.app

# Redis (Optional)
REDIS_ENABLED=false

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

### Frontend (Vercel)

**Environment Variables** (ตั้งใน Vercel Dashboard):
```env
# API Configuration
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api

# NextAuth
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=<your-32-char-secret>

# Environment
NODE_ENV=production
```

---

## 🔄 Request Flow

### Example: Search Available Rooms

```
1. User Action (Browser)
   ↓
2. Frontend Component (Vercel)
   - useRooms() hook
   - Calls: api.get('/rooms/available?check_in=2025-11-10&check_out=2025-11-12')
   ↓
3. API Client (lib/api.ts)
   - Adds Authorization header
   - Sends: GET https://booboo-booking.onrender.com/api/rooms/available
   ↓
4. Backend Middleware (Render)
   - CORS check
   - Rate limiting
   - JWT validation
   ↓
5. Handler → Service → Repository
   - Business logic
   - Database query
   ↓
6. Database (Neon)
   - Execute query
   - Return results
   ↓
7. Response flows back up
```

### Code Example

**Frontend** (Vercel):
```typescript
// frontend/src/hooks/use-rooms.ts
export function useRooms() {
  const searchRooms = async (params: SearchParams) => {
    const response = await api.get('/rooms/available', { params });
    return response.data;
  };
  
  return { searchRooms };
}

// frontend/src/lib/api.ts
const api = {
  get: async (endpoint: string, options?: any) => {
    const token = useAuthStore.getState().token;
    const url = `${process.env.NEXT_PUBLIC_API_URL}${endpoint}`;
    
    const response = await fetch(url, {
      headers: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Content-Type': 'application/json',
      },
      ...options
    });
    
    if (!response.ok) throw new Error('API Error');
    return response.json();
  }
};
```

**Backend** (Render):
```go
// backend/internal/handlers/room_handler.go
func (h *RoomHandler) GetAvailableRooms(c *gin.Context) {
    // 1. Parse parameters
    checkIn := c.Query("check_in")
    checkOut := c.Query("check_out")
    
    // 2. Call service
    rooms, err := h.roomService.GetAvailableRooms(checkIn, checkOut)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    // 3. Return response
    c.JSON(200, rooms)
}

// backend/internal/service/room_service.go
func (s *RoomService) GetAvailableRooms(checkIn, checkOut string) ([]Room, error) {
    return s.roomRepo.FindAvailable(checkIn, checkOut)
}

// backend/internal/repository/room_repository.go
func (r *RoomRepository) FindAvailable(checkIn, checkOut string) ([]Room, error) {
    query := `
        SELECT r.*, rt.name, ri.available_count
        FROM rooms r
        JOIN room_types rt ON r.room_type_id = rt.id
        JOIN room_inventory ri ON rt.id = ri.room_type_id
        WHERE ri.date BETWEEN $1 AND $2
          AND ri.available_count > 0
    `
    // Execute query...
}
```

---

## 🔐 Authentication Flow

### 1. User Login

```typescript
// Frontend: User submits login form
const { token, user } = await api.post('/auth/login', {
  email: 'user@example.com',
  password: 'password123'
});

// Store in Zustand store (memory only)
useAuthStore.setState({ token, user, isAuthenticated: true });
```

### 2. Authenticated Requests

```typescript
// All subsequent requests include JWT
const bookings = await api.get('/bookings'); // Auto-adds Bearer token
```

### 3. Backend Validation

```go
// Middleware validates JWT on every request
func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(401, gin.H{"error": "unauthorized"})
            c.Abort()
            return
        }
        
        token := strings.TrimPrefix(authHeader, "Bearer ")
        claims, err := jwt.ValidateToken(token, os.Getenv("JWT_SECRET"))
        if err != nil {
            c.JSON(401, gin.H{"error": "invalid token"})
            c.Abort()
            return
        }
        
        c.Set("user_id", claims.UserID)
        c.Set("role", claims.Role)
        c.Next()
    }
}
```

---

## 🌐 CORS Configuration

### Why CORS?
Browser security prevents frontend (Vercel) from calling backend (Render) unless explicitly allowed.

### Backend Setup

```go
// backend/internal/middleware/cors.go
func CORSMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        allowedOrigins := strings.Split(os.Getenv("ALLOWED_ORIGINS"), ",")
        origin := c.Request.Header.Get("Origin")
        
        // Check if origin is allowed
        for _, allowed := range allowedOrigins {
            if matchOrigin(origin, allowed) {
                c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
                c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
                c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
                c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
                break
            }
        }
        
        // Handle preflight
        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }
        
        c.Next()
    }
}
```

### Environment Variable

```env
# Render Dashboard → Backend Service → Environment
ALLOWED_ORIGINS=https://your-app.vercel.app,https://your-app-*.vercel.app
```

---

## 📊 API Endpoints

### Public (No Auth)

```
GET  /api/health                    - Health check
GET  /api/rooms/types               - List room types
GET  /api/rooms/available           - Search rooms
POST /api/auth/login                - Login
POST /api/auth/register             - Register
```

### Protected (Auth Required)

```
# Guest
POST   /api/bookings/hold           - Create hold
POST   /api/bookings/confirm        - Confirm booking
GET    /api/bookings                - List bookings
DELETE /api/bookings/:id            - Cancel booking

# Staff
POST   /api/checkin                 - Check-in
POST   /api/checkout                - Check-out
GET    /api/housekeeping            - Room status
PUT    /api/housekeeping/:id        - Update status

# Manager
GET    /api/reports/occupancy       - Reports
PUT    /api/pricing/tiers           - Update pricing
GET    /api/inventory               - View inventory
```

---

## 🧪 Testing Integration

### Test Backend

```bash
# Health check
curl https://booboo-booking.onrender.com/api/health

# Search rooms
curl "https://booboo-booking.onrender.com/api/rooms/available?check_in=2025-11-10&check_out=2025-11-12"

# Login
curl -X POST https://booboo-booking.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Test Frontend → Backend

```javascript
// Browser console (after deploying frontend)
fetch('https://booboo-booking.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log);

// Expected: { status: "ok", timestamp: "..." }
```

---

## 🚨 Common Issues

### Issue 1: CORS Error

**Error**:
```
Access to fetch blocked by CORS policy
```

**Solution**:
1. ตรวจสอบ `ALLOWED_ORIGINS` บน Render
2. ต้องมี Vercel URL
3. Redeploy backend

### Issue 2: 401 Unauthorized

**Error**:
```json
{"error": "unauthorized"}
```

**Solution**:
1. ตรวจสอบ JWT token
2. Login ใหม่
3. ตรวจสอบ token expiry

### Issue 3: Function Not Found

**Error**:
```
ERROR: function release_expired_holds() does not exist
```

**Solution**:
อ่าน [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)

---

## 📝 Deployment Steps

### 1. แก้ไข Backend Issues (ด่วน!)
```bash
# รัน migrations
cd backend/scripts
run-migrations.bat
```

### 2. Deploy Frontend
```bash
cd frontend
vercel --prod
```

### 3. อัปเดต CORS
```
Render Dashboard → Environment → ALLOWED_ORIGINS
เพิ่ม: https://your-app.vercel.app
```

### 4. Test Integration
```bash
# ทดสอบ API connection
curl https://booboo-booking.onrender.com/api/health
```

---

## 📚 Related Documentation

- [RENDER_PRODUCTION_SETUP.md](RENDER_PRODUCTION_SETUP.md) - Complete setup guide
- [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) - Fix migration issues
- [RENDER_ENVIRONMENT_VARIABLES.md](RENDER_ENVIRONMENT_VARIABLES.md) - All env vars
- [backend/docs/swagger.yaml](backend/docs/swagger.yaml) - API docs

---

**Last Updated**: 2025-11-04  
**Status**: 🟡 Backend deployed, migrations pending, frontend ready
