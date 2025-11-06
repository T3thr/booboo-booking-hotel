# Frontend Quick Reference Guide

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env.local

# Start development server
npm run dev

# Open browser
http://localhost:3000
```

## 📁 Project Structure

```
src/
├── app/          # Pages and routes
├── components/   # React components
├── lib/          # Utilities and config
├── types/        # TypeScript types
├── store/        # Zustand stores
├── hooks/        # Custom hooks
└── utils/        # Helper functions
```

## 🔑 Key Files

| File | Purpose |
|------|---------|
| `lib/api.ts` | API client (Axios) |
| `lib/auth.ts` | NextAuth config |
| `lib/query-client.ts` | React Query setup |
| `types/index.ts` | All TypeScript types |
| `store/useAuthStore.ts` | Auth state |
| `store/useBookingStore.ts` | Booking state |

## 🎨 UI Components

```tsx
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';

// Button variants
<Button variant="default">Default</Button>
<Button variant="destructive">Delete</Button>
<Button variant="outline">Outline</Button>
<Button variant="secondary">Secondary</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="link">Link</Button>

// Button sizes
<Button size="sm">Small</Button>
<Button size="default">Default</Button>
<Button size="lg">Large</Button>
<Button size="icon">Icon</Button>
```

## 🔐 Authentication

```tsx
import { useAuth } from '@/hooks/use-auth';

function LoginPage() {
  const { login, isLoading, error } = useAuth();

  const handleLogin = () => {
    login({ email: 'user@example.com', password: 'password' });
  };

  return <button onClick={handleLogin}>Login</button>;
}
```

## 🛡️ Protected Routes

```tsx
import { ProtectedRoute } from '@/components/protected-route';

export default function StaffPage() {
  return (
    <ProtectedRoute requiredRole={['receptionist', 'housekeeper']}>
      <div>Staff Only Content</div>
    </ProtectedRoute>
  );
}
```

## 📡 API Calls

```tsx
import { api } from '@/lib/api';

// GET request
const rooms = await api.get('/rooms');

// POST request
const booking = await api.post('/bookings', { data });

// PUT request
await api.put('/bookings/1', { data });

// DELETE request
await api.delete('/bookings/1');
```

## 🔄 React Query Hooks

```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';

// Fetch data
function useRooms() {
  return useQuery({
    queryKey: ['rooms'],
    queryFn: () => api.get('/rooms'),
  });
}

// Mutate data
function useCreateBooking() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (data) => api.post('/bookings', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
    },
  });
}

// Usage
function Component() {
  const { data, isLoading, error } = useRooms();
  const createBooking = useCreateBooking();
  
  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  
  return <div>{data.map(room => ...)}</div>;
}
```

## 🗄️ Zustand Store

```tsx
import { useAuthStore } from '@/store/useAuthStore';

function Component() {
  const { token, guest, setAuth, clearAuth, isAuthenticated } = useAuthStore();
  
  // Check if authenticated
  if (isAuthenticated()) {
    return <div>Welcome {guest?.first_name}</div>;
  }
  
  return <div>Please login</div>;
}
```

## 📝 TypeScript Types

```tsx
import type { 
  User, 
  Guest, 
  Booking, 
  RoomType,
  RoomSearchParams 
} from '@/types';

// Use types in components
interface Props {
  booking: Booking;
  onCancel: (id: number) => void;
}

function BookingCard({ booking, onCancel }: Props) {
  return <div>{booking.booking_id}</div>;
}
```

## 🎨 Tailwind CSS Classes

```tsx
// Common patterns
<div className="flex items-center justify-between">
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
<div className="p-4 rounded-lg border bg-card shadow-sm">
<h1 className="text-2xl font-bold text-foreground">
<p className="text-sm text-muted-foreground">
<button className="bg-primary text-primary-foreground hover:bg-primary/90">
```

## 🌐 Environment Variables

```env
# .env.local
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key
BACKEND_URL=http://backend:8080
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

Access in code:
```tsx
// Server-side only
process.env.BACKEND_URL

// Client-side (must start with NEXT_PUBLIC_)
process.env.NEXT_PUBLIC_API_URL
```

## 🔧 Common Commands

```bash
# Development
npm run dev          # Start dev server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint

# Docker
docker-compose up frontend              # Start with Docker
docker-compose -f docker-compose.prod.yml up frontend  # Production
```

## 📦 Adding New Dependencies

```bash
# Install package
npm install package-name

# Install dev dependency
npm install -D package-name

# Update all packages
npm update
```

## 🐛 Debugging

```tsx
// React Query DevTools (already included)
// Open browser and look for React Query icon

// Console logging
console.log('Debug:', data);

// React DevTools
// Install browser extension

// Network requests
// Check browser DevTools Network tab
```

## 🎯 Best Practices

1. **Always use TypeScript types**
   ```tsx
   // Good
   const user: User = { ... };
   
   // Bad
   const user = { ... };
   ```

2. **Use custom hooks for data fetching**
   ```tsx
   // Good
   const { data } = useBookings();
   
   // Bad
   const [data, setData] = useState([]);
   useEffect(() => { fetch... }, []);
   ```

3. **Use Zustand for client state**
   ```tsx
   // Good
   const { searchParams } = useBookingStore();
   
   // Bad
   const [searchParams, setSearchParams] = useState();
   ```

4. **Use UI components**
   ```tsx
   // Good
   <Button variant="primary">Click</Button>
   
   // Bad
   <button className="...">Click</button>
   ```

5. **Handle loading and error states**
   ```tsx
   if (isLoading) return <Loading />;
   if (error) return <Error message={error.message} />;
   return <Content data={data} />;
   ```

## 🔗 Useful Links

- [Next.js Docs](https://nextjs.org/docs)
- [React Query Docs](https://tanstack.com/query/latest)
- [Zustand Docs](https://zustand-demo.pmnd.rs/)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [NextAuth.js Docs](https://next-auth.js.org/)

## 💡 Tips

- Use `@/` alias for imports: `import { api } from '@/lib/api'`
- Check React Query DevTools for cache inspection
- Use TypeScript IntelliSense (Ctrl+Space) for autocomplete
- Format code with Prettier (if installed)
- Use ESLint to catch errors early

## 🆘 Common Issues

### Port already in use
```bash
# Kill process on port 3000
npx kill-port 3000
```

### Module not found
```bash
# Clear cache and reinstall
rm -rf node_modules .next
npm install
```

### TypeScript errors
```bash
# Check for errors
npx tsc --noEmit
```

### Environment variables not working
- Restart dev server after changing .env.local
- Client-side vars must start with NEXT_PUBLIC_

---

**Last Updated:** November 3, 2025
