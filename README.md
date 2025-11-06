# 🏨 Hotel Booking System - Production Ready

> **ระบบจองโรงแรมแบบ Full-Stack พร้อม Deploy บน Production**

ระบบจองโรงแรมที่สมบูรณ์ พร้อมใช้งานจริง รองรับการจัดการห้องพัก การจอง การเช็คอิน/เช็คเอาท์ และระบบ Backend API ที่ทันสมัย

---

## ✅ สถานะโปรเจค: **READY FOR PRODUCTION**

- ✅ Backend API (Go + Gin) - พร้อม Deploy
- ✅ Frontend (Next.js + TypeScript) - พร้อม Deploy  
- ✅ Database (PostgreSQL) - Configured
- ✅ Environment Configuration - Complete
- ✅ Documentation - Complete
- ✅ Vercel Deployment - Ready

---

## 🚀 Quick Start

### 🌐 Production Deployment (30 นาที)

**สถานะปัจจุบัน:**
- ✅ Backend deployed บน Render
- ⚠️ Database migrations ต้องรันก่อน (5 นาที)
- ⏳ Frontend พร้อม deploy บน Vercel

**เริ่มต้นที่นี่:**

➡️ **[START_DEPLOYMENT.md](START_DEPLOYMENT.md)** - เลือกเอกสารที่เหมาะกับคุณ

**Quick Links:**
- 🚨 [QUICK_FIX_RENDER.md](docs-archive/deployment/QUICK_FIX_RENDER.md) - แก้ไขปัญหาด่วน (5 นาที)
- 📖 [คู่มือ_DEPLOY_PRODUCTION.md](docs-archive/deployment/คู่มือ_DEPLOY_PRODUCTION.md) - คู่มือภาษาไทย
- 🚀 [DEPLOYMENT_WORKFLOW.md](docs-archive/deployment/DEPLOYMENT_WORKFLOW.md) - Workflow ทั้งหมด
- ⚡ [QUICK_REFERENCE_PRODUCTION.md](docs-archive/deployment/QUICK_REFERENCE_PRODUCTION.md) - Quick reference

**Architecture:**
- Frontend (Next.js) → Vercel (ฟรี)
- Backend (Go) → Render (ฟรี 750 ชม./เดือน)
- Database → Neon PostgreSQL (ฟรี 512MB)

### 💻 Local Development

```bash
# 1. Backend
cd backend
cp .env.local.example .env
# แก้ไข .env ใส่ database credentials
go run cmd/server/main.go
# เปิด: http://localhost:8080

# 2. Frontend (terminal ใหม่)
cd frontend
npm install
npm run dev
# เปิด: http://localhost:3000
```

### สำหรับ Production Deployment

```bash
# ดูคู่มือฉบับเต็ม
1. อ่าน: QUICK_START_PRODUCTION.md (10 นาที)
2. หรือ: DEPLOYMENT_CHECKLIST.md (ละเอียด)
```

---

## 📁 โครงสร้างโปรเจค

```
booking-hotel/
├── backend/                      # 🔧 Go Backend API
│   ├── cmd/server/              # Main application
│   ├── internal/                # Business logic
│   │   ├── handlers/           # HTTP handlers
│   │   ├── models/             # Data models
│   │   ├── repository/         # Database layer
│   │   ├── service/            # Business services
│   │   ├── middleware/         # Middleware
│   │   └── jobs/               # Background jobs
│   ├── pkg/                    # Shared packages
│   ├── .env.example           # Environment template
│   ├── .env.local.example     # Local dev template
│   ├── .env.production.example # Production template
│   ├── vercel.json            # Vercel config
│   └── Documentation/         # API docs
│
├── frontend/                   # 🎨 Next.js Frontend
│   ├── src/
│   │   ├── app/              # Next.js App Router
│   │   │   ├── (guest)/      # Guest pages
│   │   │   ├── (staff)/      # Staff pages
│   │   │   ├── (manager)/    # Manager pages
│   │   │   └── api/          # API routes
│   │   ├── components/       # React components
│   │   ├── lib/              # Utilities
│   │   │   ├── api.ts        # API client
│   │   │   └── auth.ts       # Auth utilities
│   │   ├── hooks/            # Custom hooks
│   │   ├── store/            # Zustand stores
│   │   └── types/            # TypeScript types
│   └── package.json          # Dependencies
│
├── database/                  # 🗄️ Database files
├── docs/                     # 📚 Documentation
│
├── PRODUCTION_READY.md       # 🎯 Project overview
├── QUICK_START_PRODUCTION.md # ⚡ 10-minute guide
├── DEPLOYMENT_CHECKLIST.md   # ✅ Pre-deployment checklist
├── QUICK_REFERENCE.md        # 📝 Quick commands
└── README.md                 # 📖 This file
```

---

## 🛠️ เทคโนโลยี

### Backend
- **Language**: Go 1.21+
- **Framework**: Gin (HTTP Framework)
- **Database**: Neon PostgreSQL (Serverless)
- **Auth**: JWT
- **Cache**: Redis (Optional - Upstash)
- **Deployment**: Vercel

### Frontend
- **Framework**: Next.js 14
- **Language**: TypeScript
- **API Client**: Axios + React Query
- **Styling**: Tailwind CSS
- **Deployment**: Vercel

### Database
- **Provider**: Neon PostgreSQL (Serverless)
- **Tables**: 12 tables with relations
- **Features**: Connection pooling, indexes, migrations

---

## 📚 Documentation

### 🎯 เริ่มต้นที่นี่
- **[PRODUCTION_READY.md](./PRODUCTION_READY.md)** - ภาพรวมโปรเจค
- **[QUICK_START_PRODUCTION.md](./backend/QUICK_START_PRODUCTION.md)** - เริ่มใช้งาน 10 นาที
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - คำสั่งที่ใช้บ่อย

### 📖 Setup & Deployment
- **[PRODUCTION_SETUP_GUIDE.md](./backend/PRODUCTION_SETUP_GUIDE.md)** - คู่มือตั้งค่าฉบับเต็ม
- **[DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)** - Checklist ก่อน deploy
- **[ENV_VARIABLES_GUIDE.md](./backend/ENV_VARIABLES_GUIDE.md)** - Environment variables ทั้งหมด

### 🔧 Technical Docs
- **[Backend API](./backend/docs/)** - API documentation
- **[Database Migrations](./database/migrations/)** - Database schema
- **[Project Architecture](./PROJECT_ARCHITECTURE.md)** - System design

### 📦 Submission
- **[READY_FOR_CLIENT_SUBMISSION.md](./READY_FOR_CLIENT_SUBMISSION.md)** - คู่มือส่งงาน

---

## 🌐 API Endpoints

### Public Endpoints
```bash
GET  /health                    # Health check
GET  /api/rooms                 # List all rooms
GET  /api/rooms/:id             # Room details
GET  /api/rooms?checkIn=&checkOut=  # Search available rooms
```

### Protected Endpoints (JWT Required)
```bash
POST /api/bookings              # Create booking
GET  /api/bookings              # Get user bookings
PUT  /api/bookings/:id          # Update booking
DELETE /api/bookings/:id        # Cancel booking
```

**Full API Docs**: [API_DOCUMENTATION.md](./backend/API_DOCUMENTATION.md)

---

## 🗄️ Database Schema

### 12 Tables
1. **guests** - Guest information
2. **guest_accounts** - Login credentials
3. **room_types** - Room type definitions
4. **rooms** - Individual rooms
5. **amenities** - Hotel amenities
6. **room_type_amenities** - Room-amenity relations
7. **room_images** - Room photos
8. **rate_plans** - Pricing plans
9. **daily_rates** - Date-specific rates
10. **inventory** - Room availability
11. **bookings** - Booking records
12. **booking_room_stays** - Booking details

**Schema File**: `frontend/src/db/schema.ts`

---

## ⚙️ Environment Configuration

### Backend (.env)

```bash
# Database (PostgreSQL)
DATABASE_URL=postgresql://user:pass@host:port/database?sslmode=require
DB_HOST=your-db-host
DB_USER=your_username
DB_PASSWORD=your_password

# Server
PORT=8080
GIN_MODE=debug  # or 'release' for production

# JWT
JWT_SECRET=your-secret-32-chars-minimum

# CORS
FRONTEND_URL=http://localhost:3000
```

**Templates**:
- Local: `backend/.env.local.example`
- Production: `backend/.env.production.example`

**Complete Guide**: [ENV_VARIABLES_GUIDE.md](./backend/ENV_VARIABLES_GUIDE.md)

---

## 🧪 Testing

### Test Backend
```bash
# Health check
curl http://localhost:8080/health

# Get rooms
curl http://localhost:8080/api/rooms

# Search rooms
curl "http://localhost:8080/api/rooms?checkIn=2024-12-01&checkOut=2024-12-05"
```

### Test Frontend
```bash
# Open in browser
http://localhost:3000

# Check console for errors
# Test all pages and features
```

---

## 🚀 Deployment

### Deploy to Vercel

#### Backend
1. Push code to GitHub
2. Import repository to Vercel
3. Set root directory: `backend`
4. Add environment variables (from `.env.production.example`)
5. Deploy

#### Frontend
1. Import same repository
2. Set root directory: `frontend`
3. Add environment variables
4. Deploy

**Detailed Guide**: [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)

---

## 🔒 Security Features

- ✅ JWT Authentication
- ✅ Password Hashing
- ✅ SQL Injection Protection
- ✅ CORS Configuration
- ✅ Rate Limiting
- ✅ HTTPS Enforcement (Vercel)
- ✅ Environment Variable Security

---

## 📊 Features

### For Users
- 🏨 Browse available rooms
- 🔍 Search by date range
- 📝 Make bookings
- 📋 View booking history
- ✏️ Manage reservations

### For Admins
- 📊 Inventory management
- 💰 Rate plan management
- 📅 Booking management
- 🌙 Night audit automation
- 🧹 Hold cleanup automation

### Technical
- 🔌 RESTful API
- 🔐 JWT Authentication
- ⚡ Rate Limiting
- 💾 Redis Caching (optional)
- ⏰ Background Jobs
- 📈 Health Monitoring
- 📝 Structured Logging

---

## 🎯 Quick Commands

### Local Development
```bash
# Backend
cd backend && go run cmd/server/main.go

# Frontend  
cd frontend && npm run dev

# Database seed
cd frontend && npm run db:seed
```

### Generate JWT Secret
```bash
# Windows
cd backend\scripts && generate-jwt-secret.bat

# Mac/Linux
cd backend/scripts && ./generate-jwt-secret.sh

# Or use OpenSSL
openssl rand -base64 32
```

### Deploy
```bash
git add .
git commit -m "Deploy to production"
git push origin main
# Vercel auto-deploys
```

---

## 📞 Support & Resources

### Documentation
- Setup Guide: `backend/PRODUCTION_SETUP_GUIDE.md`
- Quick Start: `backend/QUICK_START_PRODUCTION.md`
- API Docs: `backend/API_DOCUMENTATION.md`

### External Resources
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Vercel Docs](https://vercel.com/docs)
- [Go Docs](https://go.dev/doc/)
- [Next.js Docs](https://nextjs.org/docs)

---

## ✅ Pre-Submission Checklist

- [ ] Backend deployed and tested
- [ ] Frontend deployed and tested
- [ ] Database connected
- [ ] All API endpoints working
- [ ] Documentation complete
- [ ] Environment variables configured
- [ ] No sensitive data in git
- [ ] URLs documented

**Full Checklist**: [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)

---

## 🎓 Project Statistics

- **Backend**: ~5,000+ lines of Go code
- **Frontend**: TypeScript with Next.js 14
- **Database**: 12 tables, 150+ seed records
- **API Endpoints**: 15+ endpoints
- **Documentation**: 10+ comprehensive guides

---

## 📝 License

This project is for educational purposes.

---

## 🎉 Ready for Production!

Your Hotel Booking System is fully configured and ready to deploy!

**Next Steps**:
1. ✅ Read [QUICK_START_PRODUCTION.md](./backend/QUICK_START_PRODUCTION.md)
2. ✅ Follow [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)
3. ✅ Deploy to Vercel
4. ✅ Submit to client

**Good luck! 🚀**

# แก้ไขค่าใน .env ตามความเหมาะสม (สำหรับ production)
# สำหรับ development สามารถใช้ค่าเริ่มต้นได้
```

#### 3. รันด้วย Docker Compose (แนะนำ)

```bash
# วิธีที่ 1: ใช้ Makefile (แนะนำ)
make dev          # Start development environment
make logs         # View logs
make restart      # Restart services
make clean        # Clean up everything

# วิธีที่ 2: ใช้ Docker Compose โดยตรง
docker-compose up -d              # สร้างและรัน containers
docker-compose ps                 # ตรวจสอบสถานะ
docker-compose logs -f            # ดู logs
docker-compose logs -f backend    # ดู logs เฉพาะ service
docker-compose down               # หยุด containers
docker-compose down -v            # หยุดและลบ volumes
```

> 💡 **Tip**: ใช้ `make help` เพื่อดูคำสั่งทั้งหมดที่มี

#### 4. รัน Database Migrations

```bash
# ใช้ Makefile (แนะนำ)
make db-migrate

# หรือรัน manual
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/001_create_guests_tables.sql

# เข้าถึง PostgreSQL shell
make db-shell
```

### เข้าถึงระบบ

- **Frontend (Next.js):** http://localhost:3000
- **Backend API (Go):** http://localhost:8080
- **PostgreSQL Database:** localhost:5432
  - Database: `hotel_booking`
  - Username: `postgres`
  - Password: `postgres123`

### การพัฒนาแบบ Local (ไม่ใช้ Docker)

#### Frontend Development

```bash
cd frontend

# ติดตั้ง dependencies
npm install
# หรือ
yarn install

# รัน development server
npm run dev
# หรือ
yarn dev

# เข้าถึงที่ http://localhost:3000
```

#### Backend Development

```bash
cd backend

# ติดตั้ง dependencies
go mod download

# รัน server
go run cmd/server/main.go

# หรือ build แล้วรัน
go build -o bin/server cmd/server/main.go
./bin/server

# API จะรันที่ http://localhost:8080
```

#### Database Setup (Local PostgreSQL)

```bash
# สร้าง database
createdb hotel_booking

# รัน migrations
psql -U postgres -d hotel_booking -f database/migrations/001_create_guests_tables.sql
psql -U postgres -d hotel_booking -f database/migrations/002_create_functions.sql
psql -U postgres -d hotel_booking -f database/migrations/003_seed_data.sql
```

### การทดสอบการติดตั้ง

```bash
# ทดสอบ Backend API
curl http://localhost:8080/health

# ทดสอบ Frontend
# เปิด browser ไปที่ http://localhost:3000

# ทดสอบ Database Connection
docker exec -it hotel-booking-system-db-1 psql -U postgres -d hotel_booking -c "SELECT version();"
```

### การแก้ไขปัญหาที่พบบ่อย

#### Port ถูกใช้งานอยู่แล้ว

```bash
# ตรวจสอบ port ที่ใช้งาน
# Windows
netstat -ano | findstr :3000
netstat -ano | findstr :8080
netstat -ano | findstr :5432

# Linux/Mac
lsof -i :3000
lsof -i :8080
lsof -i :5432

# แก้ไข port ใน docker-compose.yml หรือ .env
```

#### Database Connection Failed

```bash
# ตรวจสอบว่า PostgreSQL container รันอยู่
docker-compose ps

# Restart database container
docker-compose restart db

# ตรวจสอบ logs
docker-compose logs db
```

#### Frontend ไม่เชื่อมต่อ Backend

```bash
# ตรวจสอบ environment variables
cat .env

# ตรวจสอบว่า NEXT_PUBLIC_API_URL ถูกต้อง
# สำหรับ Docker: http://backend:8080
# สำหรับ Local: http://localhost:8080
```

## ฟีเจอร์หลัก

### สำหรับผู้เข้าพัก (Guest)
- ลงทะเบียนและเข้าสู่ระบบ
- ค้นหาและจองห้องพัก
- ดูประวัติการจอง
- ยกเลิกการจอง

### สำหรับพนักงานต้อนรับ (Receptionist)
- จัดการการจอง
- เช็คอิน/เช็คเอาท์
- ย้ายห้อง
- ดูแดชบอร์ดสถานะห้อง

### สำหรับแม่บ้าน (Housekeeper)
- ดูรายการงานทำความสะอาด
- อัปเดตสถานะห้อง
- รายงานปัญหาการซ่อมบำรุง

### สำหรับผู้จัดการ (Manager)
- จัดการราคาและสต็อก
- สร้างคูปองส่วนลด
- ดูรายงานและวิเคราะห์

## การทดสอบ

### Backend Tests

```bash
cd backend

# รัน unit tests ทั้งหมด
go test ./...

# รัน tests พร้อม coverage
go test -cover ./...

# สร้าง coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html
```

### Frontend Tests

```bash
cd frontend

# รัน tests
npm test
# หรือ
yarn test

# รัน tests พร้อม coverage
npm test -- --coverage
```

### Integration Tests

```bash
# ทดสอบ API endpoints
cd backend
go test ./tests/integration/...
```

### Load Testing (Race Conditions & Overbooking Prevention)

> 🔥 **สำคัญ:** ทดสอบว่าระบบป้องกัน overbooking และจัดการ race conditions ได้อย่างถูกต้อง

```bash
# ติดตั้ง k6 (load testing tool)
# Windows: choco install k6
# macOS: brew install k6
# Linux: https://k6.io/docs/getting-started/installation/

cd load-tests

# รัน load tests ด้วย interactive menu
./run_load_tests.sh    # Unix/Linux/macOS
run_load_tests.bat     # Windows

# หรือรัน tests แยก
k6 run race-condition-test.js          # ทดสอบ 50 users พร้อมกัน
k6 run concurrent-booking-test.js      # ทดสอบ 50 users จองห้องสุดท้าย
k6 run connection-pool-test.js         # ทดสอบ connection pool
```

**เอกสาร Load Testing:**
- [Load Testing Guide](TASK_42_LOAD_TESTING_GUIDE.md) - คู่มือฉบับสมบูรณ์
- [Quick Start](load-tests/QUICKSTART.md) - เริ่มต้นใช้งาน 5 นาที
- [Complete Documentation](load-tests/README.md) - เอกสารละเอียด

**ผลการทดสอบที่ต้องการ:**
- ✅ Overbookings Detected = **0** (ต้องเป็น 0 เสมอ)
- ✅ Inventory Violations = **0** (ต้องเป็น 0 เสมอ)
- ✅ Error Rate < **10%**
- ✅ Response Time P95 < **2 seconds**

## โครงสร้างโปรเจกต์แบบละเอียด

```
hotel-booking-system/
├── frontend/                           # Next.js 16 Application
│   ├── src/
│   │   ├── app/                        # App Router
│   │   │   ├── (guest)/                # Guest routes (public)
│   │   │   ├── (staff)/                # Staff routes (receptionist, housekeeper)
│   │   │   ├── (manager)/              # Manager routes (admin)
│   │   │   ├── api/
│   │   │   │   └── auth/
│   │   │   │       └── [...nextauth]/  # NextAuth configuration
│   │   │   └── layout.tsx              # Root layout
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
└── README.md                           # เอกสารนี้
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - ลงทะเบียนผู้ใช้ใหม่
- `POST /api/auth/login` - เข้าสู่ระบบ
- `GET /api/auth/me` - ดึงข้อมูลผู้ใช้ปัจจุบัน

### Rooms
- `GET /api/rooms/search` - ค้นหาห้องว่าง
- `GET /api/rooms/types` - ดึงรายการประเภทห้อง
- `GET /api/rooms/types/:id` - ดึงรายละเอียดประเภทห้อง

### Bookings
- `POST /api/bookings/hold` - สร้าง booking hold
- `POST /api/bookings` - สร้างการจอง
- `POST /api/bookings/:id/confirm` - ยืนยันการจอง
- `POST /api/bookings/:id/cancel` - ยกเลิกการจอง
- `GET /api/bookings` - ดึงรายการการจอง
- `GET /api/bookings/:id` - ดึงรายละเอียดการจอง

### Check-in/Check-out
- `POST /api/checkin` - ทำการ check-in
- `POST /api/checkout` - ทำการ check-out
- `POST /api/checkin/move-room` - ย้ายห้อง

### Housekeeping
- `GET /api/housekeeping/tasks` - รายการงานทำความสะอาด
- `PUT /api/housekeeping/rooms/:id/status` - อัปเดตสถานะห้อง

### Pricing & Inventory (Manager only)
- `GET /api/pricing/tiers` - ดึงรายการ rate tiers
- `POST /api/pricing/tiers` - สร้าง rate tier
- `GET /api/inventory` - ดึงข้อมูล inventory
- `PUT /api/inventory` - อัปเดต allotment

### Reports (Manager only)
- `GET /api/reports/occupancy` - รายงานการเข้าพัก
- `GET /api/reports/revenue` - รายงานรายได้

## การพัฒนาและ Contribution

### Git Workflow

```bash
# สร้าง feature branch
git checkout -b feature/your-feature-name

# Commit changes
git add .
git commit -m "feat: add your feature description"

# Push to remote
git push origin feature/your-feature-name

# สร้าง Pull Request
```

### Commit Message Convention

- `feat:` - ฟีเจอร์ใหม่
- `fix:` - แก้ไข bug
- `docs:` - เปลี่ยนแปลงเอกสาร
- `style:` - การจัดรูปแบบโค้ด
- `refactor:` - ปรับปรุงโค้ด
- `test:` - เพิ่มหรือแก้ไข tests
- `chore:` - งานอื่นๆ (dependencies, config)

## 📚 เอกสารเพิ่มเติม

### 📖 Documentation Hub
- **[📚 Documentation Index](DOCUMENTATION_INDEX.md)** - ศูนย์รวมเอกสารทั้งหมด (เริ่มที่นี่!)
- **[🚀 Quick Navigation](docs/QUICK_NAVIGATION.md)** - นำทางด่วนไปยังเอกสารที่ต้องการ
- **[📖 Documentation Hub](docs/README.md)** - เอกสารแบ่งตามหมวดหมู่

### 🏗️ Architecture & Design
- [Requirements](docs/architecture/REQUIREMENTS.md) - ความต้องการของระบบ
- [Design](docs/architecture/DESIGN.md) - เอกสารออกแบบระบบ
- [Project Structure](docs/architecture/PROJECT_STRUCTURE.md) - โครงสร้างโปรเจกต์

### ✅ Task Documentation
- [Tasks Overview](docs/tasks/README.md) - ภาพรวมการทำงาน
- [Phase 1: Setup](docs/tasks/phase-1-setup/) - Project Setup & Database
- [Phase 2: Backend Core](docs/tasks/phase-2-backend-core/) - Go API Setup
- [Phase 3: Booking Logic](docs/tasks/phase-3-booking-logic/) - PostgreSQL Functions
- [Phase 4: Frontend Core](docs/tasks/phase-4-frontend-core/) - Next.js & NextAuth

### 📖 Guides
- [Docker Complete Guide](docs/guides/DOCKER_COMPLETE_GUIDE_2025.md) - คู่มือ Docker ฉบับสมบูรณ์
- [Docker Quickstart](docs/guides/DOCKER_QUICKSTART.md) - เริ่มต้นใช้งาน Docker

### 🚀 Deployment
- [Docker Setup](docs/deployment/DOCKER_SETUP.md) - การตั้งค่า Docker
- [Docker Test](docs/deployment/DOCKER_TEST.md) - การทดสอบ Docker

### 📝 Spec Files (Original)
- [Requirements](.kiro/specs/hotel-reservation-system/requirements.md) - ฉบับเต็ม
- [Design](.kiro/specs/hotel-reservation-system/design.md) - ฉบับเต็ม
- [Tasks](.kiro/specs/hotel-reservation-system/tasks.md) - แผนการพัฒนา

## ทีมพัฒนา

โปรเจกต์นี้พัฒนาโดยใช้ Theerapat Pooraya เพื่อสร้างระบบจองโรงแรมที่แก้ไขปัญหาจริงในอุตสาหกรรมการบริการ

## License

MIT License

---

**หมายเหตุ:** โปรเจกต์นี้เป็นส่วนหนึ่งของการเรียนรู้และพัฒนาทักษะ Full-stack Development
