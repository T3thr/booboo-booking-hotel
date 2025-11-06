# Manager Flow Verification Guide

## สรุปการตรวจสอบ Manager Flow

เอกสารนี้อธิบายว่า Manager Dashboard และฟีเจอร์ต่างๆ ทำงานอย่างไรกับระบบ Role-Based Access Control

---

## 1. Database Schema (Role System)

### Tables ที่เกี่ยวข้อง

```sql
-- Roles Table
roles (
  role_id: 1=GUEST, 2=RECEPTIONIST, 3=HOUSEKEEPER, 4=MANAGER
  role_code: 'GUEST', 'RECEPTIONIST', 'HOUSEKEEPER', 'MANAGER'
)

-- Staff Table
staff (
  staff_id,
  email,
  role_id -> references roles(role_id)
)

-- Unified View
v_all_users (
  user_type: 'guest' | 'staff'
  role_code: 'GUEST' | 'RECEPTIONIST' | 'HOUSEKEEPER' | 'MANAGER'
)
```

### Manager Accounts

```
Email: manager@hotel.com
Password: staff123
Role: MANAGER (role_id = 4)
```

---

## 2. Backend API Protection

### Middleware Stack

```go
// router.go
pricing := api.Group("/pricing")
pricing.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
pricing.Use(middleware.RequireManager()) // MANAGER only

inventory := api.Group("/inventory")
inventory.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
inventory.Use(middleware.RequireManager()) // MANAGER only

reports := api.Group("/reports")
reports.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
reports.Use(middleware.RequireManager()) // MANAGER only
```

### Role Middleware Logic

```go
// middleware/role.go
func RequireManager() gin.HandlerFunc {
    return RequireRole("MANAGER")
}

func RequireRole(allowedRoles ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        userRole, exists := c.Get("user_role")
        if !exists {
            c.JSON(401, gin.H{"error": "Unauthorized"})
            c.Abort()
            return
        }
        
        role := userRole.(string)
        for _, allowedRole := range allowedRoles {
            if role == allowedRole {
                c.Next()
                return
            }
        }
        
        c.JSON(403, gin.H{
            "error": "Forbidden",
            "message": "คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้",
            "required_roles": allowedRoles,
            "user_role": role,
        })
        c.Abort()
    }
}
```

---

## 3. Frontend Authentication Flow

### NextAuth Configuration

```typescript
// lib/auth.ts
async authorize(credentials) {
  const res = await fetch(`${apiUrl}/auth/login`, {
    method: "POST",
    body: JSON.stringify({
      email: credentials.email,
      password: credentials.password
    })
  });
  
  const response = await res.json();
  
  if (response.success && response.data) {
    return {
      id: response.data.id.toString(),
      email: response.data.email,
      name: `${response.data.first_name} ${response.data.last_name}`,
      role: response.data.role_code,  // 'MANAGER'
      userType: response.data.user_type,  // 'staff'
      accessToken: response.data.accessToken
    };
  }
}

callbacks: {
  async jwt({ token, user }) {
    if (user) {
      token.role = user.role;  // Store role in JWT
    }
    return token;
  },
  async session({ session, token }) {
    session.user.role = token.role;  // Add role to session
    return session;
  }
}
```

### Middleware Protection

```typescript
// middleware.ts
const roleAccess: Record<string, string[]> = {
  '/dashboard': ['MANAGER'],
  '/pricing': ['MANAGER'],
  '/inventory': ['MANAGER'],
  '/reports': ['MANAGER'],
  '/settings': ['MANAGER'],
};

export async function middleware(request: NextRequest) {
  const token = await getToken({ req: request });
  const userRole = token.role as string;
  
  // MANAGER has access to everything (superuser)
  if (userRole === 'MANAGER') {
    return NextResponse.next();
  }
  
  // Check specific role access
  for (const [prefix, allowedRoles] of Object.entries(roleAccess)) {
    if (pathname.startsWith(prefix)) {
      if (!allowedRoles.includes(userRole)) {
        return NextResponse.redirect(new URL('/unauthorized', request.url));
      }
    }
  }
}
```

---

## 4. Manager Dashboard Implementation

### Dashboard Page

```typescript
// app/(manager)/dashboard/page.tsx
export default function ManagerDashboardPage() {
  const { data: session } = useSession();
  
  // Fetch real-time stats
  const { data: stats } = useQuery({
    queryKey: ['dashboard-stats', today],
    queryFn: async () => {
      const [revenueRes, occupancyRes, bookingsRes] = await Promise.all([
        api.get('/api/reports/revenue', {
          params: { start_date: today, end_date: today }
        }),
        api.get('/api/reports/occupancy', {
          params: { start_date: today, end_date: today }
        }),
        api.get('/api/bookings', {
          params: { status: 'Confirmed', limit: 100 }
        })
      ]);
      
      return {
        revenue: revenueRes.data.data?.[0]?.total_revenue || 0,
        occupancy: occupancyRes.data.data?.[0]?.occupancy_rate || 0,
        bookings: todayBookings,
        totalBookings: bookingsRes.data.total || 0
      };
    }
  });
}
```

### API Client with Auth

```typescript
// lib/api.ts
import { getSession } from 'next-auth/react';

export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api',
});

api.interceptors.request.use(async (config) => {
  const session = await getSession();
  if (session?.accessToken) {
    config.headers.Authorization = `Bearer ${session.accessToken}`;
  }
  return config;
});
```

---

## 5. Manager Features Access

### ✅ Dashboard (`/dashboard`)
- **Stats Cards**: Revenue, Occupancy, Bookings
- **API Calls**:
  - `GET /api/reports/revenue`
  - `GET /api/reports/occupancy`
  - `GET /api/bookings`

### ✅ Pricing Management (`/pricing/*`)
- **Rate Tiers** (`/pricing/tiers`):
  - `GET /api/pricing/tiers`
  - `POST /api/pricing/tiers`
  - `PUT /api/pricing/tiers/:id`

- **Pricing Calendar** (`/pricing/calendar`):
  - `GET /api/pricing/calendar`
  - `PUT /api/pricing/calendar`

- **Rate Matrix** (`/pricing/matrix`):
  - `GET /api/pricing/rates`
  - `PUT /api/pricing/rates`
  - `POST /api/pricing/rates/bulk`

### ✅ Inventory Management (`/inventory`)
- **API Calls**:
  - `GET /api/inventory`
  - `PUT /api/inventory`
  - `POST /api/inventory/bulk`

### ✅ Reports (`/reports`)
- **API Calls**:
  - `GET /api/reports/summary`
  - `GET /api/reports/occupancy`
  - `GET /api/reports/revenue`
  - `GET /api/reports/vouchers`
  - `GET /api/reports/no-shows`
  - `GET /api/reports/comparison`

### ✅ Settings (`/settings`)
- Manager-specific settings and configurations

---

## 6. Testing the Flow

### Automated Test

```bash
# Run automated verification
verify-manager-access.bat
```

This script will:
1. ✅ Login as manager@hotel.com
2. ✅ Extract JWT token
3. ✅ Test dashboard API calls (revenue, occupancy)
4. ✅ Test pricing management endpoints
5. ✅ Test inventory management endpoints
6. ✅ Test reports endpoints
7. ✅ Verify no 403/404 errors

### Manual Test

1. **Login**:
   ```
   URL: http://localhost:3000/auth/signin
   Email: manager@hotel.com
   Password: staff123
   ```

2. **Verify Redirect**:
   - Should redirect to `/dashboard`

3. **Test Dashboard**:
   - Should see revenue, occupancy, bookings stats
   - No 403 errors

4. **Test Pricing**:
   - Navigate to `/pricing/tiers`
   - Should see rate tiers list
   - Can create/edit tiers

5. **Test Inventory**:
   - Navigate to `/inventory`
   - Should see room inventory
   - Can update availability

6. **Test Reports**:
   - Navigate to `/reports`
   - Should see various reports
   - Can export data

---

## 7. Common Issues & Solutions

### Issue: 403 Forbidden Error

**Cause**: Role not properly set in JWT or middleware not recognizing role

**Solution**:
```typescript
// Check session in browser console
console.log(session);
// Should show: { user: { role: 'MANAGER' } }

// Check API request headers
// Should include: Authorization: Bearer <token>
```

### Issue: 404 Not Found

**Cause**: API endpoint doesn't exist or backend not running

**Solution**:
```bash
# Check backend is running
curl http://localhost:8080/health

# Check specific endpoint
curl http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer <token>"
```

### Issue: Redirect to Unauthorized

**Cause**: Frontend middleware blocking access

**Solution**:
```typescript
// Check middleware.ts roleAccess configuration
// Ensure '/dashboard' allows 'MANAGER'
```

---

## 8. Role Hierarchy

```
MANAGER (Superuser)
  ├── Full access to all features
  ├── Can access RECEPTIONIST features
  ├── Can access HOUSEKEEPER features
  └── Can access GUEST features

RECEPTIONIST
  ├── Check-in/Check-out
  ├── Booking management
  └── Room status

HOUSEKEEPER
  ├── Room cleaning
  ├── Maintenance reports
  └── Inspection

GUEST
  ├── Room search
  ├── Booking
  └── View own bookings
```

---

## 9. Security Checklist

- ✅ JWT token includes role_code
- ✅ Backend validates role on every protected endpoint
- ✅ Frontend middleware checks role before rendering
- ✅ API client includes Authorization header
- ✅ Session expires after 24 hours
- ✅ Password hashed with bcrypt
- ✅ CORS configured properly
- ✅ Rate limiting enabled

---

## 10. Demo Credentials

```
Manager:
  Email: manager@hotel.com
  Password: staff123
  Role: MANAGER

Assistant Manager:
  Email: assistant.manager@hotel.com
  Password: staff123
  Role: MANAGER

Receptionist:
  Email: receptionist1@hotel.com
  Password: staff123
  Role: RECEPTIONIST

Housekeeper:
  Email: housekeeper1@hotel.com
  Password: staff123
  Role: HOUSEKEEPER

Guest:
  Email: anan.test@example.com
  Password: password123
  Role: GUEST
```

---

## สรุป

ระบบ Manager Flow ทำงานได้อย่างสมบูรณ์:

1. ✅ **Database**: Role system ถูกออกแบบและ seed ข้อมูลแล้ว
2. ✅ **Backend**: API endpoints มี role middleware ป้องกัน
3. ✅ **Frontend**: NextAuth + middleware ตรวจสอบ role
4. ✅ **Dashboard**: แสดงข้อมูล real-time จาก API
5. ✅ **Features**: Pricing, Inventory, Reports ทำงานได้
6. ✅ **No Errors**: ไม่มี 403 หรือ 404 errors

Manager สามารถ login และใช้งานทุกฟีเจอร์ได้โดยไม่มีปัญหา!
