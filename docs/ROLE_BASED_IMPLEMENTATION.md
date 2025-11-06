# 🔐 Role-Based Access Implementation Guide

## 📋 Overview

การ implement role-based access control สำหรับ 4 roles:
1. **Guest** (GUEST) - `/` และ `/bookings/*`
2. **Receptionist** (RECEPTIONIST) - `/staff/*`
3. **Housekeeper** (HOUSEKEEPER) - `/staff/housekeeping/*`
4. **Manager** (MANAGER) - `/admin/*`

---

## 🗄️ Database Changes

### Step 1: Run Migration 014

```bash
# Run migration
psql -U postgres -d hotel_booking -f database/migrations/014_create_role_system.sql

# Or using script
cd database/migrations
./run_migration_014.sh
```

### Step 2: Verify Database

```sql
-- Check roles
SELECT * FROM roles;

-- Check staff
SELECT * FROM staff;

-- Check unified view
SELECT * FROM v_all_users;
```

---

## 🎨 Frontend Structure Changes

### Current Structure (ต้องแก้)

```
frontend/src/app/
├── (guest)/
├── (staff)/
└── (manager)/          ❌ ต้องเปลี่ยน
```

### New Structure (แนะนำ)

```
frontend/src/app/
├── (public)/           → Public pages (/, /rooms, /about)
├── (guest)/            → Guest protected (/bookings, /profile)
├── (staff)/            → Staff portal (/staff/*)
│   └── housekeeping/   → Housekeeping (/staff/housekeeping/*)
└── (admin)/            → Admin portal (/admin/*)
```

---

## 🔧 Implementation Steps

### Step 1: Update Middleware

```typescript
// frontend/src/middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { auth } from '@/lib/auth';

const roleAccess = {
  '/bookings': ['GUEST', 'RECEPTIONIST', 'MANAGER'],
  '/profile': ['GUEST', 'RECEPTIONIST', 'HOUSEKEEPER', 'MANAGER'],
  '/staff': ['RECEPTIONIST', 'MANAGER'],
  '/staff/housekeeping': ['HOUSEKEEPER', 'MANAGER'],
  '/admin': ['MANAGER'],
};

export async function middleware(request: NextRequest) {
  const session = await auth();
  const { pathname } = request.nextUrl;

  // Public routes
  const publicRoutes = ['/', '/rooms', '/about', '/auth'];
  if (publicRoutes.some(route => pathname.startsWith(route))) {
    return NextResponse.next();
  }

  // Check authentication
  if (!session) {
    const url = new URL('/auth/signin', request.url);
    url.searchParams.set('callbackUrl', pathname);
    return NextResponse.redirect(url);
  }

  // Check role-based access
  for (const [prefix, allowedRoles] of Object.entries(roleAccess)) {
    if (pathname.startsWith(prefix)) {
      if (!allowedRoles.includes(session.user.role)) {
        return NextResponse.redirect(new URL('/unauthorized', request.url));
      }
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
```

### Step 2: Update Auth Configuration

```typescript
// frontend/src/lib/auth.ts
export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    CredentialsProvider({
      async authorize(credentials) {
        // ... existing code ...
        
        // Update to handle both guest and staff login
        const response = await fetch(`${BACKEND_URL}/api/auth/login`, {
          method: 'POST',
          body: JSON.stringify({
            email: credentials.email,
            password: credentials.password,
          }),
          headers: { 'Content-Type': 'application/json' },
        });

        if (!response.ok) {
          throw new Error('Invalid credentials');
        }

        const result = await response.json();
        const data = result.data || result;

        return {
          id: data.id.toString(),
          email: data.email,
          name: `${data.first_name} ${data.last_name}`,
          role: data.role_code, // GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER
          userType: data.user_type, // 'guest' or 'staff'
          accessToken: data.accessToken,
        };
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.role = user.role;
        token.userType = user.userType;
        token.accessToken = user.accessToken;
      }
      return token;
    },
    async session({ session, token }) {
      if (token) {
        session.user.id = token.id;
        session.user.role = token.role;
        session.user.userType = token.userType;
        session.accessToken = token.accessToken;
      }
      return session;
    },
  },
  pages: {
    signIn: '/auth/signin',
    error: '/auth/error',
  },
});
```

### Step 3: Update Navbar

```typescript
// frontend/src/components/navbar.tsx
'use client';

import { useSession } from 'next-auth/react';
import Link from 'next/link';

export function Navbar() {
  const { data: session } = useSession();

  const getNavLinks = () => {
    if (!session) {
      return [
        { label: 'หน้าแรก', href: '/' },
        { label: 'ห้องพัก', href: '/rooms' },
      ];
    }

    switch (session.user.role) {
      case 'GUEST':
        return [
          { label: 'หน้าแรก', href: '/' },
          { label: 'ห้องพัก', href: '/rooms' },
          { label: 'การจองของฉัน', href: '/bookings' },
        ];
      
      case 'RECEPTIONIST':
        return [
          { label: 'แดชบอร์ด', href: '/staff' },
          { label: 'เช็คอิน', href: '/staff/checkin' },
          { label: 'เช็คเอาท์', href: '/staff/checkout' },
          { label: 'การจอง', href: '/staff/bookings' },
        ];
      
      case 'HOUSEKEEPER':
        return [
          { label: 'แดชบอร์ด', href: '/staff/housekeeping' },
          { label: 'งานทำความสะอาด', href: '/staff/housekeeping/tasks' },
          { label: 'ตรวจสอบห้อง', href: '/staff/housekeeping/inspection' },
        ];
      
      case 'MANAGER':
        return [
          { label: 'แดชบอร์ด', href: '/admin' },
          { label: 'ราคา', href: '/admin/pricing' },
          { label: 'สต็อก', href: '/admin/inventory' },
          { label: 'รายงาน', href: '/admin/reports' },
        ];
      
      default:
        return [];
    }
  };

  return (
    <nav>
      {/* Render navigation based on role */}
      {getNavLinks().map(link => (
        <Link key={link.href} href={link.href}>
          {link.label}
        </Link>
      ))}
    </nav>
  );
}
```

### Step 4: Create Role-Based Redirect

```typescript
// frontend/src/utils/role-redirect.ts
export function getRoleHomePage(role: string): string {
  switch (role) {
    case 'GUEST':
      return '/';
    case 'RECEPTIONIST':
      return '/staff';
    case 'HOUSEKEEPER':
      return '/staff/housekeeping';
    case 'MANAGER':
      return '/admin';
    default:
      return '/';
  }
}

// Use in signin page
// frontend/src/app/auth/signin/page.tsx
const handleSubmit = async (e: React.FormEvent) => {
  // ... existing code ...
  
  if (result?.ok) {
    const session = await getSession();
    const homePage = getRoleHomePage(session?.user?.role || 'GUEST');
    router.push(callbackUrl || homePage);
  }
};
```

---

## 🔄 Backend Changes

### Step 1: Update Auth Service

```go
// backend/internal/service/auth_service.go

type LoginResponse struct {
    ID          int    `json:"id"`
    Email       string `json:"email"`
    FirstName   string `json:"first_name"`
    LastName    string `json:"last_name"`
    RoleCode    string `json:"role_code"`
    RoleName    string `json:"role_name"`
    UserType    string `json:"user_type"` // "guest" or "staff"
    AccessToken string `json:"accessToken"`
}

func (s *AuthService) Login(ctx context.Context, req *LoginRequest) (*LoginResponse, error) {
    // Try guest login first
    guest, err := s.authRepo.GetGuestByEmail(ctx, req.Email)
    if err == nil && guest != nil {
        // Guest found, verify password
        account, err := s.authRepo.GetGuestAccountByGuestID(ctx, guest.GuestID)
        if err == nil && utils.CheckPassword(req.Password, account.HashedPassword) {
            token, _ := utils.GenerateToken(guest.GuestID, guest.Email, "GUEST", s.jwtSecret)
            return &LoginResponse{
                ID:          guest.GuestID,
                Email:       guest.Email,
                FirstName:   guest.FirstName,
                LastName:    guest.LastName,
                RoleCode:    "GUEST",
                RoleName:    "Guest",
                UserType:    "guest",
                AccessToken: token,
            }, nil
        }
    }

    // Try staff login
    staff, err := s.authRepo.GetStaffByEmail(ctx, req.Email)
    if err == nil && staff != nil {
        account, err := s.authRepo.GetStaffAccountByStaffID(ctx, staff.StaffID)
        if err == nil && utils.CheckPassword(req.Password, account.HashedPassword) {
            token, _ := utils.GenerateToken(staff.StaffID, staff.Email, staff.RoleCode, s.jwtSecret)
            return &LoginResponse{
                ID:          staff.StaffID,
                Email:       staff.Email,
                FirstName:   staff.FirstName,
                LastName:    staff.LastName,
                RoleCode:    staff.RoleCode,
                RoleName:    staff.RoleName,
                UserType:    "staff",
                AccessToken: token,
            }, nil
        }
    }

    return nil, errors.New("อีเมลหรือรหัสผ่านไม่ถูกต้อง")
}
```

### Step 2: Add Role Middleware

```go
// backend/internal/middleware/role.go
package middleware

func RequireRole(allowedRoles ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        userRole, exists := c.Get("user_role")
        if !exists {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
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

        c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden"})
        c.Abort()
    }
}

// Usage in router
router.GET("/admin/reports", 
    middleware.AuthMiddleware(),
    middleware.RequireRole("MANAGER"),
    reportHandler.GetReports)
```

---

## 📊 Testing

### Test Credentials

```
Guest:
  Email: anan.test@example.com
  Password: password123
  Access: /, /bookings

Receptionist:
  Email: receptionist1@hotel.com
  Password: staff123
  Access: /staff/*

Housekeeper:
  Email: housekeeper1@hotel.com
  Password: staff123
  Access: /staff/housekeeping/*

Manager:
  Email: manager@hotel.com
  Password: staff123
  Access: /admin/*
```

### Test Cases

```bash
# 1. Guest can access bookings
curl -X GET http://localhost:3000/bookings \
  -H "Cookie: next-auth.session-token=..."

# 2. Receptionist can access staff
curl -X GET http://localhost:3000/staff \
  -H "Cookie: next-auth.session-token=..."

# 3. Housekeeper can access housekeeping
curl -X GET http://localhost:3000/staff/housekeeping \
  -H "Cookie: next-auth.session-token=..."

# 4. Manager can access admin
curl -X GET http://localhost:3000/admin \
  -H "Cookie: next-auth.session-token=..."

# 5. Guest cannot access staff (should redirect)
curl -X GET http://localhost:3000/staff \
  -H "Cookie: next-auth.session-token=..." \
  -L  # Follow redirects
```

---

## ✅ Checklist

### Database
- [ ] Run migration 014
- [ ] Verify roles table
- [ ] Verify staff table
- [ ] Test v_all_users view

### Backend
- [ ] Update auth service
- [ ] Add role middleware
- [ ] Update JWT generation
- [ ] Test API endpoints

### Frontend
- [ ] Update middleware
- [ ] Update auth config
- [ ] Update navbar
- [ ] Add role-based redirects
- [ ] Test protected routes

### Testing
- [ ] Test guest access
- [ ] Test receptionist access
- [ ] Test housekeeper access
- [ ] Test manager access
- [ ] Test unauthorized access

---

**Status:** Ready for Implementation  
**Date:** November 4, 2025
