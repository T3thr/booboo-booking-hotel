# NextAuth.js Quick Reference

## Quick Start

### 1. Sign In
```tsx
'use client';
import { signIn } from 'next-auth/react';

// In a component
const handleSignIn = async () => {
  await signIn('credentials', {
    email: 'user@example.com',
    password: 'password123',
    callbackUrl: '/dashboard'
  });
};
```

### 2. Sign Out
```tsx
'use client';
import { signOut } from 'next-auth/react';

const handleSignOut = async () => {
  await signOut({ callbackUrl: '/' });
};
```

### 3. Get Session (Client)
```tsx
'use client';
import { useSession } from 'next-auth/react';

export default function MyComponent() {
  const { data: session, status } = useSession();
  
  if (status === 'loading') return <div>Loading...</div>;
  if (status === 'unauthenticated') return <div>Not signed in</div>;
  
  return <div>Welcome, {session.user.name}</div>;
}
```

### 4. Get Session (Server)
```tsx
import { auth } from '@/lib/auth';

export default async function ServerPage() {
  const session = await auth();
  
  if (!session) {
    redirect('/auth/signin');
  }
  
  return <div>User: {session.user.email}</div>;
}
```

### 5. Protected Route
```tsx
import { ProtectedRoute } from '@/components/protected-route';

export default function ProtectedPage() {
  return (
    <ProtectedRoute requiredRole={['manager', 'receptionist']}>
      <div>Protected Content</div>
    </ProtectedRoute>
  );
}
```

### 6. API Call with Auth
```tsx
'use client';
import { useSession } from 'next-auth/react';

export default function MyComponent() {
  const { data: session } = useSession();
  
  const fetchData = async () => {
    const res = await fetch('/api/bookings', {
      headers: {
        'Authorization': `Bearer ${session?.accessToken}`,
        'Content-Type': 'application/json'
      }
    });
    return res.json();
  };
  
  // Use fetchData...
}
```

## Session Object

```typescript
{
  user: {
    id: string;        // "1"
    email: string;     // "user@example.com"
    name: string;      // "John Doe"
    role: string;      // "guest" | "receptionist" | "housekeeper" | "manager"
  },
  accessToken: string; // JWT token from backend
  expires: string;     // ISO date string
}
```

## Common Patterns

### Check if Authenticated
```tsx
const { status } = useSession();
const isAuthenticated = status === 'authenticated';
```

### Check User Role
```tsx
const { data: session } = useSession();
const isManager = session?.user.role === 'manager';
```

### Redirect if Not Authenticated
```tsx
'use client';
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function MyPage() {
  const { status } = useSession();
  const router = useRouter();
  
  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/auth/signin');
    }
  }, [status, router]);
  
  if (status === 'loading') return <div>Loading...</div>;
  
  return <div>Protected Content</div>;
}
```

### Custom Hook for Auth
```tsx
// hooks/use-auth.ts
import { useSession } from 'next-auth/react';

export function useAuth() {
  const { data: session, status } = useSession();
  
  return {
    user: session?.user,
    accessToken: session?.accessToken,
    isAuthenticated: status === 'authenticated',
    isLoading: status === 'loading',
    role: session?.user.role
  };
}

// Usage
const { user, isAuthenticated, role } = useAuth();
```

## Environment Variables

```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
BACKEND_URL=http://backend:8080
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key-here
```

## Pages

- Sign In: `/auth/signin`
- Register: `/auth/register`
- Error: `/auth/error`
- Test: `/auth/test`

## API Routes

- Session: `GET /api/auth/session`
- Sign In: `POST /api/auth/signin`
- Sign Out: `POST /api/auth/signout`
- CSRF: `GET /api/auth/csrf`

## TypeScript Types

```typescript
import { Session } from 'next-auth';

// Extend session type
declare module 'next-auth' {
  interface Session {
    user: {
      id: string;
      role: string;
    } & DefaultSession['user'];
    accessToken: string;
  }
}
```

## Troubleshooting

### Session not persisting
- Check cookies are enabled
- Check NEXTAUTH_URL matches your domain
- Clear browser cookies and try again

### "Invalid token" error
- Check NEXTAUTH_SECRET is set
- Restart dev server
- Check backend is returning valid JWT

### Cannot connect to backend
- Check backend is running
- Check BACKEND_URL is correct
- Check network/firewall settings

## Testing

```bash
# Start backend
cd backend && make run

# Start frontend
cd frontend && npm run dev

# Visit test page
http://localhost:3000/auth/test
```

## Resources

- [NextAuth.js Docs](https://next-auth.js.org/)
- [Full Setup Guide](./NEXTAUTH_SETUP.md)
- [Testing Guide](./TASK_17_TESTING.md)
