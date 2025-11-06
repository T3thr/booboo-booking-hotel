# 🚀 Quick Start Guide - Production-Grade Hotel Booking System

## 📋 Prerequisites

- Docker & Docker Compose
- Node.js 20+ (for local development)
- Go 1.21+ (for local development)
- PostgreSQL 15+ (or use Docker)

---

## ⚡ Quick Start (Docker - Recommended)

### 1. Clone and Setup

```bash
# Clone repository
git clone <your-repo-url>
cd booking-hotel

# Copy environment files
cp .env.production.example .env.production
cp backend/.env.local.example backend/.env
cp frontend/.env.local.example frontend/.env
```

### 2. Configure Environment Variables

```bash
# Edit .env.production
DATABASE_URL=postgres://postgres:postgres@postgres:5432/hotel_booking?sslmode=disable
JWT_SECRET=your-super-secret-jwt-key-change-this
NEXTAUTH_SECRET=your-super-secret-nextauth-key-change-this
```

### 3. Start Everything

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Services will be available at:
# - Frontend: http://localhost:3000
# - Backend API: http://localhost:8080
# - PostgreSQL: localhost:5432
```

### 4. Run Database Migrations

```bash
# Run all migrations
docker-compose exec postgres psql -U postgres -d hotel_booking -f /docker-entrypoint-initdb.d/001_create_guests_tables.sql
docker-compose exec postgres psql -U postgres -d hotel_booking -f /docker-entrypoint-initdb.d/014_create_role_system.sql
docker-compose exec postgres psql -U postgres -d hotel_booking -f /docker-entrypoint-initdb.d/013_seed_demo_data.sql

# Or use the migration script
cd database/migrations
./run_all_migrations.sh
```

### 5. Access the System

```
Guest Portal:     http://localhost:3000
Staff Portal:     http://localhost:3000/staff
Admin Portal:     http://localhost:3000/admin
API Docs:         http://localhost:8080/swagger
```

---

## 🔐 Demo Accounts

### Guest Account
```
Email:    anan.test@example.com
Password: password123
Access:   /, /bookings, /profile
```

### Receptionist Account
```
Email:    receptionist1@hotel.com
Password: staff123
Access:   /staff/* (check-in, check-out, bookings)
```

### Housekeeper Account
```
Email:    housekeeper1@hotel.com
Password: staff123
Access:   /staff/housekeeping/* (cleaning tasks, inspection)
```

### Manager Account
```
Email:    manager@hotel.com
Password: staff123
Access:   /admin/* (pricing, inventory, reports)
```

---

## 🛠️ Local Development (Without Docker)

### 1. Setup PostgreSQL

```bash
# Install PostgreSQL 15+
# Create database
createdb hotel_booking

# Run migrations
cd database/migrations
psql -U postgres -d hotel_booking -f 001_create_guests_tables.sql
psql -U postgres -d hotel_booking -f 014_create_role_system.sql
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

### 2. Setup Backend (Go)

```bash
cd backend

# Install depend
encies
go mod download

# Copy environment file
cp .env.local.example .env

# Edit .env with your database credentials
DATABASE_URL=postgres://postgres:postgres@localhost:5432/hotel_booking?sslmode=disable
JWT_SECRET=your-jwt-secret
PORT=8080

# Run backend
go run cmd/server/main.go

# Or with hot reload (install Air first)
go install github.com/cosmtrek/air@latest
air
```

### 3. Setup Frontend (Next.js)

```bash
cd frontend

# Install dependencies
npm install

# Copy environment file
cp .env.local.example .env.local

# Edit .env.local
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-nextauth-secret
BACKEND_URL=http://localhost:8080

# Run frontend
npm run dev
```

---

## 📊 URL Structure

### Guest Portal (Public + Protected)
```
/                           → Home page (public)
/rooms                      → Room catalog (public)
/rooms/search               → Search rooms (public)
/bookings                   → My bookings (protected - GUEST)
/booking/new                → New booking flow (protected - GUEST)
/profile                    → User profile (protected - GUEST)
```

### Staff Portal (Protected - RECEPTIONIST, MANAGER)
```
/staff                      → Staff dashboard
/staff/checkin              → Check-in page
/staff/checkout             → Check-out page
/staff/bookings             → All bookings
/staff/rooms                → Room status
/staff/move-room            → Move guest to another room
/staff/no-show              → Handle no-show
```

### Housekeeping Portal (Protected - HOUSEKEEPER, MANAGER)
```
/staff/housekeeping         → Housekeeping dashboard
/staff/housekeeping/tasks   → Cleaning tasks
/staff/housekeeping/inspection → Room inspection
```

### Admin Portal (Protected - MANAGER only)
```
/admin                      → Manager dashboard
/admin/pricing              → Pricing management
/admin/pricing/tiers        → Rate tiers
/admin/pricing/calendar     → Pricing calendar
/admin/pricing/matrix       → Rate matrix
/admin/inventory            → Room inventory
/admin/reports              → Reports & analytics
/admin/settings             → System settings
```

---

## 🔧 API Endpoints

### Authentication
```
POST /api/auth/register     → Register new guest
POST /api/auth/login        → Login (guest or staff)
GET  /api/auth/me           → Get current user
POST /api/auth/logout       → Logout
```

### Rooms (Public)
```
GET  /api/rooms/search      → Search available rooms
GET  /api/rooms/types       → Get room types
GET  /api/rooms/types/:id   → Get room type details
```

### Bookings (Protected)
```
POST /api/bookings/hold     → Create booking hold (15 min)
POST /api/bookings          → Create booking
POST /api/bookings/:id/confirm → Confirm booking
POST /api/bookings/:id/cancel  → Cancel booking
GET  /api/bookings          → Get user bookings
GET  /api/bookings/:id      → Get booking details
```

### Check-in/Check-out (Staff only)
```
POST /api/checkin           → Check-in guest
POST /api/checkout          → Check-out guest
POST /api/checkin/move-room → Move guest to another room
POST /api/bookings/:id/no-show → Mark as no-show
GET  /api/checkin/arrivals  → Today's arrivals
GET  /api/checkout/departures → Today's departures
```

### Housekeeping (Housekeeper + Manager)
```
GET  /api/housekeeping/tasks → Get cleaning tasks
PUT  /api/housekeeping/rooms/:id/status → Update room status
POST /api/housekeeping/rooms/:id/inspect → Inspect room
POST /api/housekeeping/rooms/:id/maintenance → Report maintenance
```

### Pricing (Manager only)
```
GET  /api/pricing/tiers     → Get rate tiers
POST /api/pricing/tiers     → Create rate tier
PUT  /api/pricing/tiers/:id → Update rate tier
GET  /api/pricing/calendar  → Get pricing calendar
PUT  /api/pricing/calendar  → Update pricing calendar
GET  /api/pricing/rates     → Get rate matrix
PUT  /api/pricing/rates     → Update rates
```

### Inventory (Manager only)
```
GET  /api/inventory         → Get room inventory
PUT  /api/inventory         → Update allotment
```

### Reports (Manager only)
```
GET  /api/reports/occupancy → Occupancy report
GET  /api/reports/revenue   → Revenue report
GET  /api/reports/vouchers  → Voucher usage report
GET  /api/reports/export    → Export report (CSV/PDF)
```

---

## 🧪 Testing

### Run Backend Tests
```bash
cd backend
go test ./... -v
```

### Run Frontend Tests
```bash
cd frontend
npm test
```

### Run E2E Tests
```bash
cd e2e
npm install
npx playwright test
```

### Load Testing
```bash
cd load-tests
npm install
npm run test:concurrent-booking
npm run test:race-condition
```

---

## 📈 Performance Optimization

### Database Indexes (Already created in migrations)
```sql
-- Booking lookups
CREATE INDEX idx_bookings_guest_status ON bookings(guest_id, status);

-- Inventory lookups
CREATE INDEX idx_inventory_lookup ON room_inventory(room_type_id, date);

-- Room status
CREATE INDEX idx_rooms_status ON rooms(occupancy_status, housekeeping_status);
```

### Caching Strategy (Optional - Redis)
```bash
# Add Redis to docker-compose.yml
docker-compose up -d redis

# Backend will automatically use Redis if REDIS_URL is set
REDIS_URL=localhost:6379
```

### Frontend Optimization
- Server Components for static content
- Client Components only when needed
- React Query for data caching
- Image optimization with Next.js Image
- Code splitting by route groups

---

## 🔒 Security Features

### Backend
- ✅ JWT authentication with role-based access
- ✅ Password hashing with bcrypt
- ✅ SQL injection prevention (prepared statements)
- ✅ CORS configuration
- ✅ Rate limiting (optional)
- ✅ Security headers

### Frontend
- ✅ NextAuth.js for secure authentication
- ✅ CSRF protection
- ✅ XSS prevention
- ✅ Secure cookie handling
- ✅ Role-based route protection

### Database
- ✅ Row-level security (RLS)
- ✅ Stored procedures for critical operations
- ✅ Transaction isolation
- ✅ Constraint enforcement
- ✅ Audit logging

---

## 📦 Deployment

### Vercel (Frontend)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd frontend
vercel --prod
```

### Railway/Render (Backend + Database)
```bash
# Push to GitHub
git push origin main

# Connect to Railway/Render
# Set environment variables
# Deploy automatically
```

### Docker Production
```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Start production
docker-compose -f docker-compose.prod.yml up -d
```

---

## 🐛 Troubleshooting

### Database Connection Issues
```bash
# Check PostgreSQL is running
docker-compose ps

# Check logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### Backend Not Starting
```bash
# Check logs
docker-compose logs backend

# Rebuild
docker-compose build backend
docker-compose up -d backend
```

### Frontend Build Errors
```bash
# Clear cache
cd frontend
rm -rf .next node_modules
npm install
npm run build
```

### Migration Errors
```bash
# Check migration status
psql -U postgres -d hotel_booking -c "SELECT * FROM schema_migrations;"

# Rollback and retry
psql -U postgres -d hotel_booking -f database/migrations/rollback.sql
psql -U postgres -d hotel_booking -f database/migrations/001_create_guests_tables.sql
```

---

## 📚 Documentation

- [Architecture Design](docs/architecture/DESIGN.md)
- [Database Schema](database/docs/README.md)
- [API Documentation](backend/docs/swagger.yaml)
- [User Guides](docs/user-guides/README.md)
- [Deployment Guide](docs/deployment/PRODUCTION_DEPLOYMENT.md)

---

## 🎯 Next Steps

1. ✅ System is running
2. ✅ Demo accounts work
3. ✅ Role-based access works
4. 📝 Customize branding
5. 📝 Configure email notifications
6. 📝 Setup payment gateway
7. 📝 Configure backup strategy
8. 📝 Setup monitoring (Prometheus/Grafana)
9. 📝 Load testing
10. 📝 Production deployment

---

## 💡 Tips

### Development
- Use `air` for Go hot reload
- Use `npm run dev` for Next.js hot reload
- Check logs with `docker-compose logs -f`
- Use Postman collection for API testing

### Performance
- Enable Redis caching for production
- Use CDN for static assets
- Enable gzip compression
- Monitor database query performance
- Use connection pooling

### Security
- Change all default secrets
- Use HTTPS in production
- Enable rate limiting
- Regular security audits
- Keep dependencies updated

---

## 🆘 Support

- GitHub Issues: [Create an issue](https://github.com/your-repo/issues)
- Documentation: [Read the docs](docs/README.md)
- Email: support@your-hotel.com

---

**Status:** ✅ Production Ready  
**Version:** 1.0.0  
**Last Updated:** November 4, 2025
