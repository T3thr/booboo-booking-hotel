# 🏨 Hotel Booking System - Complete Architecture Guide

## 📋 Table of Contents
1. [System Overview](#system-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture Layers](#architecture-layers)
4. [Role-Based Access Control](#role-based-access-control)
5. [API Endpoints](#api-endpoints)
6. [Database Design](#database-design)
7. [Performance Optimization](#performance-optimization)
8. [Security Implementation](#security-implementation)

---

## 🎯 System Overview

ระบบจองโรงแรมแบบ full-stack ที่ออกแบบมาเพื่อรองรับ:
- ✅ **4 User Roles**: Guest, Receptionist, Housekeeper, Manager
- ✅ **Production-Ready**: Security, Performance, Scalability
- ✅ **Real-time Updates**: Room status, Inventory management
- ✅ **Race Condition Prevention**: Booking holds, Atomic operations
- ✅ **Audit Trail**: Complete history tracking

### Key Features
- 🔐 **Unified Authentication**: Single login for guests and staff
- 🏠 **Room Management**: 2-axis status (Occupancy + Housekeeping)
- 💰 **Dynamic Pricing**: Rate tiers, Seasonal pricing
- 📊 **Reporting**: Occupancy, Revenue, Analytics
- 🔄 **Background Jobs**: Night audit, Hold cleanup

---

## 🛠️ Technology Stack

### Frontend (Next.js 16)
```
- Framework: Next.js 16 (App Router)
- Language: TypeScript
- Styling: Tailwind CSS
- State: Zustand + React Query
- Auth: NextAuth.js v5
- Forms: React Hook Form + Zod
```

### Backend (Go)
```
- Language: Go 1.21+
- Framework: Gin Web Framework
- Database Driver: pgx v5
- JWT: golang-jwt/jwt
- Password: bcrypt
- Caching: Redis (optional)
```

### Database
```
- RDBMS: PostgreSQL 15+
- Functions: PL/pgSQL
- Migrations: SQL scripts
- Indexing: Optimized for queries
```

---

## 🏗️ Architecture Layers

### 1. Frontend Layer (Next.js)
```
frontend/
├── src/
│   ├── app/
│   │   ├── (guest)/          # Guest routes
│   │   ├── (staff)/          # Staff routes  
│   │   ├── (manager)/        # Manager routes
│   │   └── api/auth/         # NextAuth API
│   ├── components/           # Reusable components
│   ├── lib/                  # Utilities
│   └── types/                # TypeScript types
```

### 2. Backend Layer (Go)
```
backend/
├── cmd/server/               # Entry point
├── internal/
│   ├── handlers/             # HTTP handlers
│   ├── service/              # Business logic
│   ├── repository/           # Data access
│   ├── middleware/           # Auth, CORS, Rate limit
│   └── models/               # Data models
└── pkg/
    ├── database/             # DB connection
    ├── cache/                # Redis cache
    └── utils/                # JWT, helpers
```

### 3. Database Layer (PostgreSQL)
```
database/
├── migrations/
│   ├── 001_create_guests_tables.sql
│   ├── 002_create_room_management_tables.sql
│   ├── 003_create_pricing_inventory_tables.sql
│   ├── 004_create_bookings_tables.sql
│   ├── 005_create_booking_hold_function.sql
│   ├── 006_create_confirm_booking_function.sql
│   ├── 007_create_cancel_booking_function.sql
│   ├── 008_create_release_expired_holds_function.sql
│   ├── 009_create_check_in_function.sql
│   ├── 010_create_check_out_function.sql
│   ├── 011_create_move_room_function.sql
│   ├── 012_performance_optimization.sql
│   ├── 013_seed_demo_data.sql
│   └── 014_create_role_system.sql
```

