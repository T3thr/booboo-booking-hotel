# โครงสร้างโปรเจกต์ - ระบบจองโรงแรมและที่พัก

## ภาพรวม

โปรเจกต์นี้เป็นระบบจองโรงแรมแบบ full-stack ที่ใช้สถาปัตยกรรม microservices แยก frontend, backend และ database ออกจากกัน

## โครงสร้างหลัก

```
hotel-booking-system/
├── frontend/                           # Next.js 16 Application
│   ├── src/
│   │   ├── app/                        # App Router (Next.js 16)
│   │   │   ├── (guest)/                # Guest routes (public)
│   │   │   ├── (staff)/                # Staff routes (receptionist, housekeeper)
│   │   │   ├── (manager)/              # Manager routes (admin)
│   │   │   └── api/
│   │   │       └── auth/
│   │   │           └── [...nextauth]/  # NextAuth.js configuration
│   │   ├── components/                 # React components
│   │   ├── lib/                        # Utilities
│   │   │   ├── api.ts                  # API client
│   │   │   └── auth.ts                 # Auth utilities
│   │   └── types/                      # TypeScript types
│   ├── public/                         # Static assets
│   ├── Dockerfile                      # Production Dockerfile
│   ├── Dockerfile.dev                  # Development Dockerfile
│   └── package.json
│
├── backend/                            # Go API Server
│   ├── cmd/
│   │   └── server/
│   │       └── main.go                 # Entry point
│   ├── internal/
│   │   ├── handlers/                   # HTTP handlers
│   │   │   ├── auth.go
│   │   │   ├── booking.go
│   │   │   ├── room.go
│   │   │   └── pricing.go
│   │   ├── models/                     # Data models
│   │   ├── repository/                 # Database layer
│   │   ├── service/                    # Business logic
│   │   └── middleware/                 # Middleware (auth, CORS)
│   ├── pkg/
│   │   ├── database/                   # DB connection
│   │   └── utils/                      # Utilities
│   ├── Dockerfile                      # Production Dockerfile
│   ├── Dockerfile.dev                  # Development Dockerfile
│   ├── go.mod
│   └── go.sum
│
├── database/                           # PostgreSQL Scripts
│   ├── migrations/                     # Database migrations
│   │   ├── 001_create_guests_tables.sql
│   │   ├── 002_create_rooms_tables.sql
│   │   ├── 003_create_bookings_tables.sql
│   │   ├── 004_create_pricing_tables.sql
│   │   └── 005_create_functions.sql
│   └── queries/                        # Complex queries
│
├── .kiro/                              # Kiro specs
│   └── specs/
│       └── hotel-reservation-system/
│           ├── requirements.md         # ความต้องการของระบบ
│           ├── design.md               # เอกสารออกแบบ
│           └── tasks.md                # แผนการพัฒนา
│
├── docker-compose.yml                  # Docker Compose configuration
├── .env.example                        # Environment variables template
├── .gitignore                          # Git ignore rules
├── README.md                           # เอกสารหลัก
└── PROJECT_STRUCTURE.md                # เอกสารนี้
```

## รายละเอียดโครงสร้าง

### Frontend (Next.js 16)

**เทคโนโลยี:**
- Next.js 16 with App Router
- TypeScript
- Tailwind CSS
- NextAuth.js v5 (Authentication)
- TanStack Query (Data fetching)
- Zustand (State management)

**โครงสร้างโฟลเดอร์:**
- `src/app/` - App Router routes
  - `(guest)/` - หน้าสำหรับผู้เข้าพัก (ค้นหาห้อง, จอง, ประวัติ)
  - `(staff)/` - หน้าสำหรับพนักงาน (เช็คอิน/เอาท์, แม่บ้าน)
  - `(manager)/` - หน้าสำหรับผู้จัดการ (ราคา, รายงาน)
  - `api/auth/[...nextauth]/` - NextAuth configuration
- `src/components/` - React components ที่ใช้ร่วมกัน
- `src/lib/` - Utility functions และ API client
- `src/types/` - TypeScript type definitions

### Backend (Go)

**เทคโนโลยี:**
- Go 1.21+
- Gin Web Framework
- pgx v5 (PostgreSQL driver)
- golang-jwt (JWT authentication)
- bcrypt (Password hashing)

**โครงสร้างโฟลเดอร์:**
- `cmd/server/` - Application entry point
- `internal/` - Private application code
  - `handlers/` - HTTP request handlers
  - `models/` - Data structures
  - `repository/` - Database access layer
  - `service/` - Business logic layer
  - `middleware/` - HTTP middleware
- `pkg/` - Public libraries
  - `database/` - Database connection utilities
  - `utils/` - Helper functions

### Database (PostgreSQL)

**โครงสร้าง:**
- `migrations/` - SQL migration files
  - ตารางหลัก (guests, rooms, bookings, pricing)
  - PostgreSQL functions (stored procedures)
  - Indexes และ constraints
- `queries/` - Complex SQL queries

**ตารางหลัก:**
- Guests & Authentication
- Room Management (types, rooms, amenities)
- Pricing & Inventory
- Bookings & Assignments
- Housekeeping

## การพัฒนา

### ขั้นตอนการเริ่มต้น

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd hotel-booking-system
   ```

2. **ตั้งค่า environment variables**
   ```bash
   cp .env.example .env
   ```

3. **รันด้วย Docker Compose**
   ```bash
   docker-compose up -d
   ```

4. **รัน database migrations**
   ```bash
   docker exec -i hotel-booking-system-db-1 psql -U postgres -d hotel_booking < database/migrations/001_create_guests_tables.sql
   ```

### การพัฒนาแบบ Local

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

**Backend:**
```bash
cd backend
go mod download
go run cmd/server/main.go
```

## Git Workflow

### Branch Strategy
- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches

### Commit Convention
- `feat:` - ฟีเจอร์ใหม่
- `fix:` - แก้ไข bug
- `docs:` - เปลี่ยนแปลงเอกสาร
- `style:` - การจัดรูปแบบโค้ด
- `refactor:` - ปรับปรุงโค้ด
- `test:` - เพิ่มหรือแก้ไข tests
- `chore:` - งานอื่นๆ

## เอกสารเพิ่มเติม

- [README.md](README.md) - คู่มือการใช้งานหลัก
- [Requirements](.kiro/specs/hotel-reservation-system/requirements.md) - ความต้องการของระบบ
- [Design](.kiro/specs/hotel-reservation-system/design.md) - เอกสารออกแบบระบบ
- [Tasks](.kiro/specs/hotel-reservation-system/tasks.md) - แผนการพัฒนา

## สถานะโปรเจกต์

✅ โครงสร้างโปรเจกต์ - เสร็จสมบูรณ์
⏳ Database Schema - รอดำเนินการ
⏳ Backend API - รอดำเนินการ
⏳ Frontend UI - รอดำเนินการ
⏳ Testing - รอดำเนินการ
⏳ Deployment - รอดำเนินการ

---

**อัปเดตล่าสุด:** 2 พฤศจิกายน 2025
