# Quick Navigation Guide

เอกสารนำทางด่วนสำหรับโปรเจกต์

## 🚀 Quick Start

### ฉันต้องการ...

#### เริ่มต้นใช้งานโปรเจกต์
→ [Main README](../README.md) → [Docker Quickstart](./guides/DOCKER_QUICKSTART.md)

#### ดูความต้องการของระบบ
→ [Requirements](./architecture/REQUIREMENTS.md) หรือ [Full Version](../.kiro/specs/hotel-reservation-system/requirements.md)

#### เข้าใจสถาปัตยกรรม
→ [Design Document](./architecture/DESIGN.md) หรือ [Full Version](../.kiro/specs/hotel-reservation-system/design.md)

#### ดูแผนการพัฒนา
→ [Tasks Overview](./tasks/README.md) หรือ [Full Tasks](../.kiro/specs/hotel-reservation-system/tasks.md)

#### ทำงาน Backend
→ [Backend Quick Start](../backend/QUICK_START.md) → [Backend Architecture](../backend/ARCHITECTURE.md)

#### ทำงาน Frontend
→ [Frontend Setup](../frontend/SETUP.md) → [Frontend Quick Reference](../frontend/QUICK_REFERENCE.md)

#### ทำงาน Database
→ [Database Quick Start](../database/migrations/QUICK_START.md) → [Schema Diagram](../database/migrations/SCHEMA_DIAGRAM.md)

#### ดู API Documentation
→ [API Reference](./api/README.md)

#### ทำงานกับ Authentication & Session
→ [Session Implementation](./SESSION_IMPLEMENTATION/README.md) → [Quick Guide](./SESSION_IMPLEMENTATION/NAVBAR_SESSION_GUIDE.md)

#### Deploy โปรเจกต์
→ [Docker Setup](./deployment/DOCKER_SETUP.md) → [Docker Complete Guide](./guides/DOCKER_COMPLETE_GUIDE_2025.md)

## 📋 By Phase

### Phase 1: Project Setup & Database Foundation (Tasks 1-6) ✅
**Status:** Complete

**Quick Links:**
- [Phase 1 Overview](./tasks/phase-1-setup/README.md)
- [Docker Setup](./deployment/DOCKER_SETUP.md)
- [Database Schema](../database/migrations/SCHEMA_DIAGRAM.md)

**Key Documents:**
- Task 2: Docker & Docker Compose
- Task 3: Guests & Authentication Schema
- Task 4: Room Management Schema
- Task 5: Pricing & Inventory Schema
- Task 6: Bookings Schema

### Phase 2: Backend Core - Go API Setup (Tasks 7-10) ✅
**Status:** Complete

**Quick Links:**
- [Phase 2 Overview](./tasks/phase-2-backend-core/README.md)
- [Backend Quick Start](../backend/QUICK_START.md)
- [Auth Quick Reference](../backend/AUTH_QUICK_REFERENCE.md)

**Key Documents:**
- Task 7: Go Project Structure
- Task 8: Authentication Module
- Task 9: Authentication Middleware
- Task 10: Room Search Module

### Phase 3: PostgreSQL Functions & Booking Logic (Tasks 11-15) ✅
**Status:** Complete

**Quick Links:**
- [Phase 3 Overview](./tasks/phase-3-booking-logic/README.md)
- [Booking Quick Reference](../backend/BOOKING_QUICK_REFERENCE.md)
- [Booking Flow Diagram](../backend/BOOKING_FLOW_DIAGRAM.md)

**Key Documents:**
- Task 11: create_booking_hold Function
- Task 12: confirm_booking Function
- Task 13: cancel_booking Function
- Task 14: release_expired_holds Function
- Task 15: Booking Module Backend

### Phase 4: Frontend Core - Next.js & NextAuth (Tasks 16-19) ✅
**Status:** Complete

**Quick Links:**
- [Phase 4 Overview](./tasks/phase-4-frontend-core/README.md)
- [Frontend Setup](../frontend/SETUP.md)
- [NextAuth Quick Reference](../frontend/NEXTAUTH_QUICK_REFERENCE.md)

**Key Documents:**
- Task 16: Next.js 16 Project Setup
- Task 17: NextAuth.js Configuration
- Task 18: API Client & React Query
- Task 19: Room Search UI

### Phase 5: Staff Features (Tasks 20-29) 🚧
**Status:** In Progress

**Next Tasks:**
- Task 20: Booking Flow UI
- Task 21: Booking History UI
- Task 22-29: Check-in/out & Housekeeping

### Phase 6: Manager Features (Tasks 30-38) 📝
**Status:** Planned

**Upcoming:**
- Pricing Management
- Inventory Management
- Reports & Analytics
- Background Jobs

### Phase 7: Testing & Optimization (Tasks 39-45) 📝
**Status:** Planned

### Phase 8: Documentation & Deployment (Tasks 46-50) 📝
**Status:** Planned

## 🔍 By Topic

### Authentication & Session
- [Requirements](./architecture/REQUIREMENTS.md#authentication)
- [Session Implementation](./SESSION_IMPLEMENTATION/README.md) ⭐ NEW
- [Backend Auth](../backend/AUTH_QUICK_REFERENCE.md)
- [Frontend Auth](../frontend/NEXTAUTH_QUICK_REFERENCE.md)
- [API Endpoints](./api/README.md#authentication)
- [Test Credentials](./SESSION_IMPLEMENTATION/LOGIN_TEST_CREDENTIALS.md)

### Room Management
- [Requirements](./architecture/REQUIREMENTS.md#room-management)
- [Database Schema](../database/migrations/ROOM_MANAGEMENT_REFERENCE.md)
- [Backend API](../backend/ROOM_SEARCH_QUICK_REFERENCE.md)
- [Frontend UI](../frontend/TASK_19_QUICKSTART.md)

### Booking System
- [Requirements](./architecture/REQUIREMENTS.md#booking)
- [Database Functions](../database/migrations/BOOKING_HOLD_REFERENCE.md)
- [Backend API](../backend/BOOKING_QUICK_REFERENCE.md)
- [API Endpoints](./api/README.md#bookings)

### Pricing & Inventory
- [Requirements](./architecture/REQUIREMENTS.md#pricing)
- [Database Schema](../database/migrations/PRICING_INVENTORY_REFERENCE.md)
- Coming soon: Backend & Frontend

### Housekeeping
- [Requirements](./architecture/REQUIREMENTS.md#housekeeping)
- Coming soon: Implementation

## 🛠️ By Role

### Developer (New to Project)
1. Read [Main README](../README.md)
2. Read [Requirements](./architecture/REQUIREMENTS.md)
3. Read [Design Document](./architecture/DESIGN.md)
4. Follow [Docker Quickstart](./guides/DOCKER_QUICKSTART.md)
5. Choose your area:
   - Backend: [Backend Quick Start](../backend/QUICK_START.md)
   - Frontend: [Frontend Setup](../frontend/SETUP.md)
   - Database: [Database Quick Start](../database/migrations/QUICK_START.md)

### Backend Developer
1. [Backend Architecture](../backend/ARCHITECTURE.md)
2. [Project Structure](../backend/PROJECT_STRUCTURE.md)
3. [Auth Quick Reference](../backend/AUTH_QUICK_REFERENCE.md)
4. [Booking Quick Reference](../backend/BOOKING_QUICK_REFERENCE.md)
5. [API Reference](./api/README.md)

### Frontend Developer
1. [Frontend Setup](../frontend/SETUP.md)
2. [Frontend Quick Reference](../frontend/QUICK_REFERENCE.md)
3. [NextAuth Quick Reference](../frontend/NEXTAUTH_QUICK_REFERENCE.md)
4. [API Client Reference](../frontend/API_CLIENT_REFERENCE.md)
5. [Theme Reference](../frontend/THEME_REFERENCE.md)

### Database Developer
1. [Database Quick Start](../database/migrations/QUICK_START.md)
2. [Schema Diagram](../database/migrations/SCHEMA_DIAGRAM.md)
3. [Bookings Schema](../database/migrations/BOOKINGS_SCHEMA_DIAGRAM.md)
4. [Function References](../database/migrations/)

### DevOps Engineer
1. [Docker Complete Guide](./guides/DOCKER_COMPLETE_GUIDE_2025.md)
2. [Docker Setup](./deployment/DOCKER_SETUP.md)
3. [Docker Test](./deployment/DOCKER_TEST.md)
4. [Makefile](../Makefile)

### Project Manager
1. [Requirements](./architecture/REQUIREMENTS.md)
2. [Design Document](./architecture/DESIGN.md)
3. [Tasks Overview](./tasks/README.md)
4. [Phase Progress](./tasks/)

## 📚 Documentation Types

### 📖 Guides (How-to)
- [Docker Complete Guide](./guides/DOCKER_COMPLETE_GUIDE_2025.md)
- [Docker Quickstart](./guides/DOCKER_QUICKSTART.md)
- [Backend Quick Start](../backend/QUICK_START.md)
- [Frontend Setup](../frontend/SETUP.md)

### 📋 References (What)
- [API Reference](./api/README.md)
- [Auth Quick Reference](../backend/AUTH_QUICK_REFERENCE.md)
- [Booking Quick Reference](../backend/BOOKING_QUICK_REFERENCE.md)
- [Schema References](../database/migrations/)

### 🏗️ Architecture (Why)
- [Requirements](./architecture/REQUIREMENTS.md)
- [Design Document](./architecture/DESIGN.md)
- [Backend Architecture](../backend/ARCHITECTURE.md)

### ✅ Tasks (Progress)
- [Tasks Overview](./tasks/README.md)
- [Phase 1](./tasks/phase-1-setup/)
- [Phase 2](./tasks/phase-2-backend-core/)
- [Phase 3](./tasks/phase-3-booking-logic/)
- [Phase 4](./tasks/phase-4-frontend-core/)

## 🔗 External Resources

### Technology Documentation
- [Next.js 16](https://nextjs.org/docs)
- [Go](https://go.dev/doc/)
- [PostgreSQL](https://www.postgresql.org/docs/)
- [Docker](https://docs.docker.com/)

### Libraries
- [NextAuth.js](https://next-auth.js.org/)
- [TanStack Query](https://tanstack.com/query/latest)
- [Gin Framework](https://gin-gonic.com/docs/)
- [Tailwind CSS](https://tailwindcss.com/docs)

## 💡 Tips

### Finding Documents
1. Start with [docs/README.md](./README.md)
2. Use phase folders for task-specific docs
3. Check module folders (backend/, frontend/, database/) for technical docs
4. Use this guide for quick navigation

### Updating Documentation
1. Keep task completion docs in phase folders
2. Update module-specific docs in their folders
3. Update API docs when adding endpoints
4. Keep README files up to date

### Best Practices
- Always check README.md first
- Follow the documentation structure
- Link related documents
- Keep docs close to code when possible

---

**Last Updated:** 2025-02-03
**Maintained by:** Development Team
