# 🚀 คู่มือ Deploy Go Backend + PostgreSQL บน Vercel

## ✅ สิ่งที่เตรียมไว้ให้แล้ว

### 1. Go Backend Configuration
- ✅ `.env` สำหรับ development
- ✅ `.env.production.example` สำหรับ production
- ✅ `vercel.json` configuration
- ✅ Setup scripts (Windows & Linux)

### 2. Database Integration
- ✅ PostgreSQL connection pool
- ✅ Neon Database ready
- ✅ Migration system

### 3. Production Features
- ✅ JWT Authentication
- ✅ CORS configuration
- ✅ Rate limiting
- ✅ Redis caching (optional)
- ✅ Health check endpoint
- ✅ Graceful shutdown

## 🎯 ขั้นตอนการ Deploy (5 นาที)

### Step 1: ตั้งค่า Neon Database
1. ไปที่ [Neon Console](https://console.neon.tech)
2. สร้าง project ใหม่ หรือใช้ที่มีอยู่
3. Copy connection string (ใช้ **Pooled connection** สำหรับ production)

### Step 2: ตั้งค่า Environment Variables
```bash
# ใน backend folder
cp .env.production.example .env.production
```

แก้ไขค่าใน `.env.production`:
```env
# Database (จาก Neon Console)
DATABASE_URL=postgresql://username:password@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require

# JWT Secret (สร้างใหม่)
JWT_SECRET=your-32-character-secret-key-here

# Frontend URL (จะได้หลัง deploy frontend)
FRONTEND_URL=https://your-frontend.vercel.app
ALLOWED_ORIGINS=https://your-frontend.vercel.app
```

### Step 3: Deploy Backend ไป Vercel
```bash
# ใน backend folder
npx vercel --prod

# หรือถ้าติดตั้ง Vercel CLI แล้ว
vercel --prod
```

### Step 4: ตั้งค่า Environment Variables ใน Vercel
ไปที่ Vercel Dashboard → Project → Settings → Environment Variables

เพิ่มตัวแปรเหล่านี้:
```
DATABASE_URL=postgresql://...
JWT_SECRET=your-secret
FRONTEND_URL=https://your-frontend.vercel.app
GIN_MODE=release
ENVIRONMENT=production
```

### Step 5: Test API
```bash
# Test health check
curl https://your-backend.vercel.app/health

# Test API endpoint
curl https://your-backend.vercel.app/api/auth/health
```

## 🔧 การใช้งาน Local Development

### เริ่มต้น Development
```bash
# ใน backend folder
go mod tidy
go run cmd/server/main.go
```

### ทดสอบ API
```bash
# Health check
curl http://localhost:8080/health

# API endpoints
curl http://localhost:8080/api/auth/health
```

## 📁 โครงสร้าง Project

```
backend/
├── cmd/server/main.go          # Entry point
├── internal/
│   ├── handlers/              # HTTP handlers
│   ├── service/               # Business logic
│   ├── repository/            # Database layer
│   ├── models/                # Data models
│   ├── middleware/            # Middleware
│   └── router/                # Route definitions
├── pkg/
│   ├── config/                # Configuration
│   ├── database/              # Database connection
│   └── utils/                 # Utilities
├── .env                       # Development config
├── .env.production.example    # Production template
├── vercel.json               # Vercel deployment config
└── go.mod                    # Go dependencies
```

## 🌐 API Endpoints

### Authentication
- `POST /api/auth/register` - สมัครสมาชิก
- `POST /api/auth/login` - เข้าสู่ระบบ
- `GET /api/auth/profile` - ข้อมูลผู้ใช้

### Booking System
- `GET /api/rooms` - ดูห้องพัก
- `POST /api/bookings` - จองห้อง
- `GET /api/bookings` - ดูการจอง
- `PUT /api/bookings/:id` - แก้ไขการจอง

### Management
- `GET /api/admin/dashboard` - Dashboard
- `GET /api/reports` - รายงาน
- `POST /api/checkin` - เช็คอิน
- `POST /api/checkout` - เช็คเอาท์

## 🔒 Security Features

- ✅ JWT Authentication
- ✅ Password hashing (bcrypt)
- ✅ Rate limiting
- ✅ CORS protection
- ✅ SQL injection prevention
- ✅ Input validation

## 📊 Monitoring & Health Check

### Health Check Endpoint
```
GET /health
```

Response:
```json
{
  "status": "ok",
  "timestamp": "2025-01-04T10:30:00Z",
  "database": "connected",
  "redis": "connected"
}
```

## 🚨 Troubleshooting

### Database Connection Issues
1. ตรวจสอบ `DATABASE_URL` ใน environment variables
2. ใช้ **Pooled connection** string จาก Neon
3. ตรวจสอบ SSL mode: `sslmode=require`

### CORS Issues
1. ตั้งค่า `ALLOWED_ORIGINS` ให้ถูกต้อง
2. ใส่ frontend domain ที่ถูกต้อง

### JWT Issues
1. ตรวจสอบ `JWT_SECRET` มีอย่างน้อย 32 ตัวอักษร
2. ใช้ secret เดียวกันทั้ง frontend และ backend

## 📞 Support

หากมีปัญหา:
1. ตรวจสอบ Vercel logs: `vercel logs`
2. ดู error ใน Vercel Dashboard
3. ทดสอบ local ก่อน deploy

---

## ✨ พร้อมส่งงานลูกค้า!

ระบบนี้พร้อมใช้งาน production แล้ว:
- ✅ Scalable architecture
- ✅ Production-ready database
- ✅ Security best practices
- ✅ Monitoring & health checks
- ✅ Complete API documentation