# Phase 4: Frontend Core - Next.js & NextAuth

Tasks 16-19: การตั้งค่า Frontend และ Authentication UI

## ✅ Completed Tasks

### Task 16: ตั้งค่า Next.js 16 Project
- [TASK_16_COMPLETION.md](./TASK_16_COMPLETION.md)
- [TASK_16_COMPLETION_SUMMARY.md](./TASK_16_COMPLETION_SUMMARY.md)
- [TASK_16_SETUP_CONFIRMED.md](./TASK_16_SETUP_CONFIRMED.md)
- สร้าง Next.js project ด้วย App Router
- ติดตั้ง dependencies (NextAuth, TanStack Query, Tailwind CSS, Zustand)
- ตั้งค่า Tailwind CSS และ theme
- สร้างโครงสร้างโฟลเดอร์

### Task 17: ตั้งค่า NextAuth.js
- [TASK_17_COMPLETION.md](./TASK_17_COMPLETION.md)
- [TASK_17_INDEX.md](./TASK_17_INDEX.md)
- [TASK_17_SUMMARY.md](./TASK_17_SUMMARY.md)
- [TASK_17_VERIFICATION_CHECKLIST.md](./TASK_17_VERIFICATION_CHECKLIST.md)
- สร้าง /api/auth/[...nextauth]/route.ts
- ตั้งค่า CredentialsProvider เชื่อมกับ Go backend
- สร้างหน้า sign-in, register, error
- ทดสอบการ login/logout

### Task 18: สร้าง API Client และ React Query Setup
- [TASK_18_COMPLETION.md](./TASK_18_COMPLETION.md)
- สร้าง lib/api.ts สำหรับเรียก Go backend
- ตั้งค่า TanStack Query Provider
- สร้าง custom hooks (useBookings, useRoomTypes, etc.)
- สร้าง ProtectedRoute component

### Task 19: สร้างหน้า Guest - Room Search
- [TASK_19_COMPLETION.md](./TASK_19_COMPLETION.md)
- [TASK_19_VERIFICATION.md](./TASK_19_VERIFICATION.md)
- สร้าง search form (check-in, check-out, guests)
- สร้าง room cards แสดงผลลัพธ์
- แสดงราคาและสิ่งอำนวยความสะดวก
- เชื่อมกับ /api/rooms/search

## 📚 Related Documentation

### Frontend Setup
- [Frontend Setup](../../../frontend/SETUP.md)
- [Frontend Quick Reference](../../../frontend/QUICK_REFERENCE.md)
- [Frontend README](../../../frontend/README.md)

### NextAuth
- [NextAuth Setup](../../../frontend/NEXTAUTH_SETUP.md)
- [NextAuth Quick Reference](../../../frontend/NEXTAUTH_QUICK_REFERENCE.md)
- [NextAuth Flow Diagram](../../../frontend/NEXTAUTH_FLOW_DIAGRAM.md)
- [Auth README](../../../frontend/src/app/auth/README.md)

### API & Hooks
- [API Client Reference](../../../frontend/API_CLIENT_REFERENCE.md)
- [Theme Reference](../../../frontend/THEME_REFERENCE.md)

### Task Specific
- [Task 16 Quickstart](../../../frontend/TASK_16_QUICKSTART.md)
- [Task 16 Verification](../../../frontend/TASK_16_VERIFICATION.md)
- [Task 16 Final Summary](../../../frontend/TASK_16_FINAL_SUMMARY.md)
- [Task 17 Testing](../../../frontend/TASK_17_TESTING.md)
- [Task 18 Quickstart](../../../frontend/TASK_18_QUICKSTART.md)
- [Task 18 Verification](../../../frontend/TASK_18_VERIFICATION.md)
- [Task 19 Quickstart](../../../frontend/TASK_19_QUICKSTART.md)

## 🔗 Requirements Covered

- Requirements 1.1-1.6 - Guest Registration & Authentication (UI)
- Requirements 2.1-2.8 - Room Search & Availability (UI)

## 🛠️ Key Technologies

- Next.js 16 (App Router)
- TypeScript
- Tailwind CSS
- React Query (TanStack Query)
- Zustand (State Management)
- NextAuth.js v5

## 🎨 Features

- **Dark/Light Theme** - Theme toggle with system preference
- **Responsive Design** - Mobile-first approach
- **Type Safety** - Full TypeScript support
- **Authentication** - NextAuth.js with JWT
- **Data Fetching** - React Query with caching
- **Protected Routes** - Role-based access control

## ⏮️ Previous Phase

[Phase 3: PostgreSQL Functions & Booking Logic](../phase-3-booking-logic/)

## ⏭️ Next Phase

Phase 5: Staff Features - Check-in/out & Housekeeping (Tasks 20-29)
