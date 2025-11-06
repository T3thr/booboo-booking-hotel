# Hotel Booking System - Documentation

เอกสารประกอบโปรเจกต์ระบบจองโรงแรมและที่พัก

> 🚀 **Quick Navigation:** [QUICK_NAVIGATION.md](./QUICK_NAVIGATION.md) - นำทางด่วนไปยังเอกสารที่ต้องการ

## 📚 โครงสร้างเอกสาร

### 🏗️ Architecture & Design
- [architecture/](./architecture/) - สถาปัตยกรรมและการออกแบบระบบ
  - [REQUIREMENTS.md](./architecture/REQUIREMENTS.md) - ความต้องการของระบบ
  - [DESIGN.md](./architecture/DESIGN.md) - เอกสารออกแบบระบบ
  - [PROJECT_STRUCTURE.md](./architecture/PROJECT_STRUCTURE.md) - โครงสร้างโปรเจกต์

### ✅ Task Documentation
- [tasks/](./tasks/) - เอกสารการทำงานแบ่งตาม Phase
  - [phase-1-setup/](./tasks/phase-1-setup/) - Project Setup & Database Foundation
  - [phase-2-backend-core/](./tasks/phase-2-backend-core/) - Backend Core - Go API
  - [phase-3-booking-logic/](./tasks/phase-3-booking-logic/) - PostgreSQL Functions & Booking Logic
  - [phase-4-frontend-core/](./tasks/phase-4-frontend-core/) - Frontend Core - Next.js & NextAuth

### 📖 Guides & Tutorials
- [guides/](./guides/) - คู่มือการใช้งานและ Quick Start
  - [DOCKER_COMPLETE_GUIDE_2025.md](./guides/DOCKER_COMPLETE_GUIDE_2025.md) - คู่มือ Docker ฉบับสมบูรณ์
  - [DOCKER_QUICKSTART.md](./guides/DOCKER_QUICKSTART.md) - เริ่มต้นใช้งาน Docker

### 🚀 Deployment
- [deployment/](./deployment/) - การ Deploy และทดสอบระบบ
  - [DOCKER_SETUP.md](./deployment/DOCKER_SETUP.md) - การตั้งค่า Docker
  - [DOCKER_TEST.md](./deployment/DOCKER_TEST.md) - การทดสอบ Docker

### 🔌 API Documentation
- [api/](./api/) - API Reference และ Postman Collections
  - Backend API endpoints
  - Request/Response examples

### 🔐 Session Implementation
- [SESSION_IMPLEMENTATION/](./SESSION_IMPLEMENTATION/) - Authentication & Session Management
  - [README.md](./SESSION_IMPLEMENTATION/README.md) - Overview และ quick links
  - [SESSION_IMPLEMENTATION_SUMMARY.md](./SESSION_IMPLEMENTATION/SESSION_IMPLEMENTATION_SUMMARY.md) - สรุปการ implement
  - [AUTHENTICATION_FLOW_COMPLETE.md](./SESSION_IMPLEMENTATION/AUTHENTICATION_FLOW_COMPLETE.md) - เอกสารเทคนิค
  - [NAVBAR_SESSION_GUIDE.md](./SESSION_IMPLEMENTATION/NAVBAR_SESSION_GUIDE.md) - คู่มือสั้น
  - [test-auth-flow.md](./SESSION_IMPLEMENTATION/test-auth-flow.md) - Test checklist
  - [LOGIN_TEST_CREDENTIALS.md](./SESSION_IMPLEMENTATION/LOGIN_TEST_CREDENTIALS.md) - Test credentials

## 🚀 Quick Start

### 1. เริ่มต้นใช้งาน

```bash
# Clone repository
git clone <repository-url>
cd booking-hotel

# อ่านคู่มือ Docker
cat docs/guides/DOCKER_QUICKSTART.md

# Start services
docker-compose up -d
```

### 2. เอกสารสำคัญ

| เอกสาร | คำอธิบาย |
|--------|----------|
| [Requirements](./architecture/REQUIREMENTS.md) | ความต้องการของระบบทั้งหมด |
| [Design](./architecture/DESIGN.md) | สถาปัตยกรรมและการออกแบบ |
| [Tasks](./tasks/README.md) | แผนการพัฒนาแบ่งตาม Phase |
| [Docker Guide](./guides/DOCKER_COMPLETE_GUIDE_2025.md) | คู่มือ Docker ฉบับสมบูรณ์ |

### 3. Module Documentation

#### Backend (Go)
- [Backend Quick Start](../backend/QUICK_START.md)
- [Backend Architecture](../backend/ARCHITECTURE.md)
- [Auth Quick Reference](../backend/AUTH_QUICK_REFERENCE.md)
- [Booking Quick Reference](../backend/BOOKING_QUICK_REFERENCE.md)

#### Frontend (Next.js)
- [Frontend Setup](../frontend/SETUP.md)
- [Frontend Quick Reference](../frontend/QUICK_REFERENCE.md)
- [NextAuth Quick Reference](../frontend/NEXTAUTH_QUICK_REFERENCE.md)
- [API Client Reference](../frontend/API_CLIENT_REFERENCE.md)

#### Database (PostgreSQL)
- [Database Quick Start](../database/migrations/QUICK_START.md)
- [Schema Diagram](../database/migrations/SCHEMA_DIAGRAM.md)
- [Bookings Schema](../database/migrations/BOOKINGS_SCHEMA_DIAGRAM.md)

## 📋 Development Workflow

### Phase 1: Setup (Tasks 1-6) ✅
- โครงสร้างโปรเจกต์
- Docker setup
- Database schema

### Phase 2: Backend Core (Tasks 7-10) ✅
- Go API setup
- Authentication
- Room search

### Phase 3: Booking Logic (Tasks 11-15) ✅
- PostgreSQL functions
- Booking module

### Phase 4: Frontend Core (Tasks 16-19) ✅
- Next.js setup
- NextAuth
- Room search UI

### Phase 5: Staff Features (Tasks 20-29) 🚧
- Check-in/out
- Housekeeping
- Room status dashboard

### Phase 6: Manager Features (Tasks 30-38) 📝
- Pricing management
- Inventory management
- Reports
- Background jobs

### Phase 7: Testing (Tasks 39-45) 📝
- Unit tests
- Integration tests
- E2E tests
- Performance optimization

### Phase 8: Deployment (Tasks 46-50) 📝
- Documentation
- Production setup
- Demo data

## 🔗 External Links

- [Main README](../README.md)
- [Spec Files](../.kiro/specs/hotel-reservation-system/)
  - [requirements.md](../.kiro/specs/hotel-reservation-system/requirements.md)
  - [design.md](../.kiro/specs/hotel-reservation-system/design.md)
  - [tasks.md](../.kiro/specs/hotel-reservation-system/tasks.md)

## 📝 Contributing

เมื่อทำงานเสร็จแต่ละ Task:
1. อัพเดท completion document ใน `docs/tasks/phase-X/`
2. อัพเดท module documentation (backend/frontend/database)
3. อัพเดท API documentation ถ้ามี endpoint ใหม่
4. Commit พร้อม meaningful message

## 📞 Support

หากมีคำถามหรือปัญหา:
1. ตรวจสอบ [Guides](./guides/)
2. ดู [Task Documentation](./tasks/)
3. อ่าน module-specific README

---

**Last Updated:** 2025-02-03
**Project:** Hotel Booking System
**Tech Stack:** Next.js 16 + Go + PostgreSQL
