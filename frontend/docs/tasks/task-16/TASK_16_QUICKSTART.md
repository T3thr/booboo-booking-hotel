# 🚀 Task 16 Quick Start - Next.js 16 Setup

## การติดตั้งและรัน

### 1. ติดตั้ง Dependencies
```bash
cd frontend
npm install
```

### 2. ตั้งค่า Environment Variables
สร้างไฟล์ `.env.local`:
```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

### 3. รัน Development Server
```bash
npm run dev
```

เปิดเบราว์เซอร์ที่ http://localhost:3000

## โครงสร้างโปรเจกต์

```
frontend/
├── src/
│   ├── app/              # Next.js App Router
│   ├── components/       # React components
│   ├── hooks/            # Custom React hooks
│   ├── lib/              # Utilities และ configs
│   ├── store/            # Zustand stores
│   ├── types/            # TypeScript types
│   └── utils/            # Helper functions
├── .env.local            # Environment variables
├── next.config.ts        # Next.js config
├── package.json          # Dependencies
└── tsconfig.json         # TypeScript config
```

## Custom Hooks ที่พร้อมใช้งาน

### Authentication
```typescript
import { useAuth } from '@/hooks/use-auth';

const { login, register, logout, isAuthenticated } = useAuth();

// Login
login({ username: 'user', password: 'pass' });

// Register
register({
  first_name: 'John',
  last_name: 'Doe',
  email: 'john@example.com',
  phone: '0812345678',
  username: 'johndoe',
  password: 'password123'
});

// Logout
logout();
```

### Room Search
```typescript
import { useRoomSearch, useRoomTypes } from '@/hooks/use-rooms';

// ค้นหาห้องว่าง
const { data: rooms } = useRoomSearch({
  check_in_date: '2025-11-10',
  check_out_date: '2025-11-12',
  adults: 2,
  children: 0
});

// ดึงประเภทห้องทั้งหมด
const { data: roomTypes } = useRoomTypes();
```

### Bookings
```typescript
import { useBookings, useCreateBooking, useCancelBooking } from '@/hooks/use-bookings';

// ดึงรายการจอง
const { data: bookings } = useBookings();

// สร้างการจองใหม่
const createBooking = useCreateBooking();
createBooking.mutate(bookingData);

// ยกเลิกการจอง
const cancelBooking = useCancelBooking();
cancelBooking.mutate(bookingId);
```

## Utility Functions

### Date Formatting
```typescript
import { formatDate, formatDateTime, calculateNights, formatCurrency } from '@/utils/date';

formatDate('2025-11-03');              // "03 พ.ย. 2568"
formatDateTime('2025-11-03T14:30:00'); // "03 พ.ย. 2568 14:30"
calculateNights('2025-11-10', '2025-11-12'); // 2
formatCurrency(1500);                  // "฿1,500.00"
```

### Validation
```typescript
import { loginSchema, registerSchema, searchSchema } from '@/utils/validation';

// Validate login form
const result = loginSchema.safeParse({
  username: 'user',
  password: 'pass123'
});

if (!result.success) {
  console.error(result.error.errors);
}
```

## Protected Routes

```typescript
import { ProtectedRoute } from '@/components/protected-route';

export default function DashboardPage() {
  return (
    <ProtectedRoute requiredRole={['manager']}>
      <div>Dashboard Content</div>
    </ProtectedRoute>
  );
}
```

## API Client

```typescript
import { api } from '@/lib/api';

// GET request
const rooms = await api.get('/rooms/types');

// POST request
const booking = await api.post('/bookings', bookingData);

// Token จะถูกเพิ่มอัตโนมัติจาก localStorage
```

## State Management

### Auth Store
```typescript
import { useAuthStore } from '@/store/useAuthStore';

const { token, guest, account, setAuth, clearAuth, isAuthenticated } = useAuthStore();

// ตรวจสอบการ login
if (isAuthenticated()) {
  console.log('User is logged in');
}
```

## เทคโนโลยีที่ใช้

- **Next.js 16** - React framework
- **React 19.2** - UI library
- **TypeScript** - Type safety
- **Tailwind CSS 4** - Styling
- **TanStack Query** - Server state management
- **Zustand** - Client state management
- **Axios** - HTTP client
- **Zod** - Schema validation
- **date-fns** - Date utilities

## คำสั่งที่มีประโยชน์

```bash
# Development
npm run dev

# Build
npm run build

# Production
npm start

# Lint
npm run lint
```

## Next Steps

Task 17: ตั้งค่า NextAuth.js สำหรับ authentication ที่สมบูรณ์
