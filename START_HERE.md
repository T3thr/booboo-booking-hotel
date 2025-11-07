# 🚀 START HERE - Hotel Booking System

> **ยินดีต้อนรับสู่โปรเจกต์ระบบจองโรงแรมและที่พัก!**

## 📍 คุณอยู่ที่นี่

นี่คือจุดเริ่มต้นสำหรับทุกคนที่เข้ามาในโปรเจกต์นี้

## 🎯 เริ่มต้นอย่างรวดเร็ว (5 นาที)

### 1. อ่านภาพรวมโปรเจกต์
📖 [README.md](./README.md) - เข้าใจว่าโปรเจกต์นี้คืออะไร

### 2. ตั้งค่าและรันโปรเจกต์
🐳 [Docker Quickstart](./docs/guides/DOCKER_QUICKSTART.md) - รันโปรเจกต์ใน 3 คำสั่ง

```bash
# 1. Clone (ถ้ายังไม่ได้ clone)
git clone <repository-url>
cd booking-hotel

# 2. Start services
docker-compose up -d

# 3. Check status
docker-compose ps
```

### 3. เข้าถึงระบบ
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080
- **Database:** localhost:5432

## 📚 ฉันต้องการ...

### 🆕 เริ่มต้นใช้งาน
1. [Main README](./README.md) - ภาพรวมโปรเจกต์
2. [Docker Quickstart](./docs/guides/DOCKER_QUICKSTART.md) - รันโปรเจกต์
3. [Quick Navigation](./docs/QUICK_NAVIGATION.md) - นำทางด่วน

### 📖 เข้าใจระบบ
1. [Requirements](./docs/architecture/REQUIREMENTS.md) - ความต้องการ
2. [Design](./docs/architecture/DESIGN.md) - การออกแบบ
3. [Tasks](./docs/tasks/README.md) - แผนการพัฒนา

### 💻 เริ่มเขียนโค้ด
**เลือกตามบทบาทของคุณ:**

#### Backend Developer
1. [Backend Quick Start](./backend/QUICK_START.md)

### 🔧 แก้ปัญหา
**ปัญหาที่พบบ่อย:**

#### Check-in/Check-out ไม่แสดงข้อมูล
📄 [Quick Fix Guide](./docs/CHECKIN_CHECKOUT_QUICKFIX.md) - แก้ไขใน 3 ขั้นตอน

```bash
# 1. เพิ่มข้อมูลทดสอบ
cd database/migrations
run_migration_020.bat

# 2. รัน backend
cd backend
go run cmd/server/main.go

# 3. รัน frontend
cd frontend
npm run dev
```

**เอกสารเพิ่มเติม:**
- [Check-in/Check-out Workflow](./docs/CHECKIN_CHECKOUT_WORKFLOW.md) - คู่มือฉบับเต็ม
- [Receptionist Guide](./docs/user-guides/RECEPTIONIST_GUIDE.md) - คู่มือพนักงาน
2. [Backend Architecture](./backend/ARCHITECTURE.md)
3. [API Reference](./docs/api/README.md)

#### Frontend Developer
1. [Frontend Setup](./frontend/SETUP.md)
2. [Frontend Quick Reference](./frontend/QUICK_REFERENCE.md)
3. [NextAuth Guide](./frontend/NEXTAUTH_QUICK_REFERENCE.md)

#### Database Developer
1. [Database Quick Start](./database/migrations/QUICK_START.md)
2. [Schema Diagram](./database/migrations/SCHEMA_DIAGRAM.md)
3. [Function References](./database/migrations/)

#### Full-Stack Developer
1. อ่านทั้ง 3 ด้านข้างบน
2. [Project Structure](./docs/architecture/PROJECT_STRUCTURE.md)
3. [Complete Documentation](./DOCUMENTATION_INDEX.md)

### 🔍 หาเอกสาร
📚 [Documentation Index](./DOCUMENTATION_INDEX.md) - ศูนย์รวมเอกสารทั้งหมด

## 🗺️ โครงสร้างโปรเจกต์

```
booking-hotel/
├── 📖 START_HERE.md              ← คุณอยู่ที่นี่!
├── 📖 README.md                  ← อ่านต่อไป
├── 📚 DOCUMENTATION_INDEX.md     ← ศูนย์รวมเอกสาร
│
├── 📁 docs/                      ← เอกสารทั้งหมด
│   ├── README.md                 ← Documentation hub
│   ├── QUICK_NAVIGATION.md       ← นำทางด่วน
│   ├── architecture/             ← สถาปัตยกรรม
│   ├── tasks/                    ← Task แบ่งตาม phase
│   ├── guides/                   ← คู่มือการใช้งาน
│   ├── deployment/               ← การ deploy
│   └── api/                      ← API reference
│
├── 💻 backend/                   ← Go API
├── 🎨 frontend/                  ← Next.js 16
├── 🗄️ database/                  ← PostgreSQL
├── 🐳 docker-compose.yml         ← Docker config
└── 📝 .env.example               ← Environment template
```

## ✅ Progress Overview

| Phase | Status | Tasks | Description |
|-------|--------|-------|-------------|
| Phase 1 | ✅ Complete | 1-6 | Project Setup & Database |
| Phase 2 | ✅ Complete | 7-10 | Backend Core - Go API |
| Phase 3 | ✅ Complete | 11-15 | Booking Logic & Functions |
| Phase 4 | ✅ Complete | 16-19 | Frontend Core - Next.js |
| Phase 5 | ✅ Complete | 20-29 | Staff Features |
| Phase 6 | ✅ Complete | 30-38 | Manager Features |
| Phase 7 | ✅ Complete | 39-45 | Testing & Optimization |
| Phase 8 | 🚧 In Progress | 46-50 | Documentation & Deployment |

## 🎓 Learning Path

### Day 1: Understanding
- [ ] Read [README.md](./README.md)
- [ ] Read [Requirements](./docs/architecture/REQUIREMENTS.md)
- [ ] Understand [Design](./docs/architecture/DESIGN.md)

### Day 2: Setup
- [ ] Follow [Docker Quickstart](./docs/guides/DOCKER_QUICKSTART.md)
- [ ] Run the project locally
- [ ] Explore the running application

### Day 3: Deep Dive
- [ ] Study your area (Backend/Frontend/Database)
- [ ] Review completed tasks in [docs/tasks/](./docs/tasks/)
- [ ] Understand the codebase

### Day 4+: Contributing
- [ ] Pick a task from Phase 5+
- [ ] Follow the development workflow
- [ ] Submit your first contribution

## 🛠️ Quick Commands

### Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart a service
docker-compose restart backend
```

### Database
```bash
# Access PostgreSQL
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking

# Run migration
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/001_create_guests_tables.sql
```

### Backend
```bash
cd backend

# Run tests
go test ./...

# Build
go build -o bin/server cmd/server/main.go
```

### Frontend
```bash
cd frontend

# Install dependencies
npm install

# Run dev server
npm run dev

# Build
npm run build
```

## 📞 Need Help?

### Documentation
1. [Documentation Index](./DOCUMENTATION_INDEX.md) - ศูนย์รวมเอกสาร
2. [Quick Navigation](./docs/QUICK_NAVIGATION.md) - นำทางด่วน
3. [Guides](./docs/guides/) - คู่มือการใช้งาน

### Common Issues
- **Port already in use?** → Check [Docker Test](./docs/deployment/DOCKER_TEST.md)
- **Database connection failed?** → Check [Docker Setup](./docs/deployment/DOCKER_SETUP.md)
- **Frontend not connecting?** → Check `.env` files

### Where to Find...
- **API endpoints?** → [API Reference](./docs/api/README.md)
- **Database schema?** → [Schema Diagram](./database/migrations/SCHEMA_DIAGRAM.md)
- **Task progress?** → [Tasks Overview](./docs/tasks/README.md)
- **How to do X?** → [Quick Navigation](./docs/QUICK_NAVIGATION.md)

## 🎯 Next Steps

### Immediate (Now)
1. ✅ You're reading START_HERE.md
2. ⏭️ Read [README.md](./README.md)
3. ⏭️ Follow [Docker Quickstart](./docs/guides/DOCKER_QUICKSTART.md)

### Short Term (This Week)
1. ⏭️ Understand [Requirements](./docs/architecture/REQUIREMENTS.md)
2. ⏭️ Study [Design](./docs/architecture/DESIGN.md)
3. ⏭️ Review completed [Tasks](./docs/tasks/)

### Long Term (This Month)
1. ⏭️ Master your area (Backend/Frontend/Database)
2. ⏭️ Contribute to Phase 5+ tasks
3. ⏭️ Help improve documentation

## 💡 Pro Tips

### For Efficiency
- ✅ Bookmark [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)
- ✅ Use [Quick Navigation](./docs/QUICK_NAVIGATION.md) frequently
- ✅ Keep Docker running during development
- ✅ Use hot reload (Air for Go, Next.js dev server)

### For Learning
- ✅ Read task completion docs to understand implementation
- ✅ Study the database functions - they're the core logic
- ✅ Follow the booking flow to understand the system
- ✅ Check tests for usage examples

### For Contributing
- ✅ Follow the existing code structure
- ✅ Write tests for new features
- ✅ Update documentation when adding features
- ✅ Use meaningful commit messages

## 🌟 Key Features

### For Guests
- 🔐 Register & Login
- 🔍 Search available rooms
- 📅 Book rooms with hold system
- 📜 View booking history
- ❌ Cancel bookings

### For Staff
- ✅ Check-in/Check-out
- 🏨 Room status dashboard
- 🧹 Housekeeping management
- 🔄 Room movement

### For Managers
- 💰 Pricing management
- 📊 Inventory control
- 🎫 Voucher management
- 📈 Reports & analytics

## 🚀 Technology Stack

- **Frontend:** Next.js 16, TypeScript, Tailwind CSS, NextAuth.js
- **Backend:** Go 1.21+, Gin Framework, JWT
- **Database:** PostgreSQL 15+, PL/pgSQL Functions
- **DevOps:** Docker, Docker Compose, Air (hot reload)

## 📊 Project Status

**Current Phase:** Phase 8 - Documentation & Deployment
**Completion:** 49/50 tasks (98%)
**Last Updated:** 2025-02-04

---

## 🎉 Ready to Start?

### Choose Your Path:

#### 🚀 Quick Start (5 minutes)
→ [Docker Quickstart](./docs/guides/DOCKER_QUICKSTART.md)

#### 📖 Learn First (30 minutes)
→ [README.md](./README.md) → [Requirements](./docs/architecture/REQUIREMENTS.md) → [Design](./docs/architecture/DESIGN.md)

#### 💻 Start Coding (1 hour)
→ Choose your role above → Follow the guide → Start contributing

#### 📚 Deep Dive (Full day)
→ [Documentation Index](./DOCUMENTATION_INDEX.md) → Study all docs → Master the system

---

**Welcome aboard! Let's build something amazing! 🚀**

---

**Project:** Hotel Booking System
**Tech Stack:** Next.js 16 + Go + PostgreSQL
**Status:** Production Ready (Task 50 pending)
**Documentation:** Clean & Organized ✅
**Last Updated:** 2025-02-04
