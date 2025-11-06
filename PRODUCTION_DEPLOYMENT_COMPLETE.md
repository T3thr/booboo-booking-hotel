# 🚀 Production Deployment Guide - Complete

## 📋 Overview

This guide covers complete production deployment for the Hotel Booking System with:
- ✅ Sub-domain strategy
- ✅ Performance optimization
- ✅ Security hardening
- ✅ Monitoring & logging
- ✅ Backup & disaster recovery

---

## 🏗️ Architecture Options

### Option 1: Single Domain (Recommended for Start)

```
Production URL: hotel.example.com

Structure:
├── hotel.example.com/              → Guest portal
├── hotel.example.com/staff/*       → Staff portal
└── hotel.example.com/admin/*       → Admin portal
```

**Pros:**
- ✅ Single SSL certificate
- ✅ Shared session management
- ✅ Easier deployment
- ✅ Better SEO
- ✅ Lower cost

**Cons:**
- ❌ All code in one deployment
- ❌ Longer URLs

---

### Option 2: Sub-domain (Enterprise)

```
Production URLs:
├── hotel.example.com               → Guest portal
├── staff.hotel.example.com         → Staff portal
└── admin.hotel.example.com         → Admin portal
```

**Pros:**
- ✅ Clear separation
- ✅ Independent deployments
- ✅ Better security isolation
- ✅ Easier to scale

**Cons:**
- ❌ Multiple SSL certificates
- ❌ Complex session management
- ❌ More DNS configuration
- ❌ Higher cost

---

## 🎯 Recommended Stack

### Frontend Deployment
**Vercel** (Recommended)
- ✅ Automatic deployments from Git
- ✅ Edge network (CDN)
- ✅ Serverless functions
- ✅ Preview deployments
- ✅ Free SSL
- ✅ Great Next.js support

**Alternatives:**
- Netlify
- AWS Amplify
- Cloudflare Pages

### Backend Deployment
**Railway** or **Render** (Recommended)
- ✅ Easy Docker deployment
- ✅ Automatic scaling
- ✅ Built-in PostgreSQL
- ✅ Free tier available
- ✅ Simple configuration

**Alternatives:**
- AWS ECS/Fargate
- Google Cloud Run
- DigitalOcean App Platform
- Heroku

### Database
**Railway PostgreSQL** or **Supabase** (Recommended)
- ✅ Managed PostgreSQL
- ✅ Automatic backups
- ✅ Connection pooling
- ✅ Monitoring included
- ✅ Easy scaling

**Alternatives:**
- AWS RDS
- Google Cloud SQL
- Azure Database
- DigitalOcean Managed Database

---

## 📦 Deployment Steps

### Step 1: Prepare Environment

#### 1.1 Generate Secrets
```bash
# Generate JWT secret
openssl rand -base64 32

# Generate NextAuth secret
openssl rand -base64 32

# Save these securely!
```

#### 1.2 Create Environment Files

**Backend (.env.production)**
```env
# Database
DATABASE_URL=postgres://user:password@host:5432/hotel_booking?sslmode=require

# JWT
JWT_SECRET=your-generated-jwt-secret-here

# Server
PORT=8080
GIN_MODE=release

# CORS
FRONTEND_URL=https://hotel.example.com

# Optional - Redis
REDIS_URL=redis://host:6379

# Email (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

**Frontend (.env.production)**
```env
# API
NEXT_PUBLIC_API_URL=https://api.hotel.example.com

# NextAuth
NEXTAUTH_URL=https://hotel.example.com
NEXTAUTH_SECRET=your-generated-nextauth-secret-here
BACKEND_URL=https://api.hotel.example.com

# Optional - Analytics
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX
```

---

### Step 2: Deploy Database

#### Option A: Railway PostgreSQL

```bash
# 1. Create Railway account
# 2. Create new project
# 3. Add PostgreSQL service
# 4. Get connection string
# 5. Run migrations

# Connect to Railway database
psql "postgresql://user:password@host:port/railway"

# Run migrations
\i database/migrations/001_create_guests_tables.sql
\i database/migrations/002_create_room_management_tables.sql
\i database/migrations/003_create_pricing_inventory_tables.sql
\i database/migrations/004_create_bookings_tables.sql
\i database/migrations/005_create_booking_hold_function.sql
\i database/migrations/006_create_confirm_booking_function.sql
\i database/migrations/007_create_cancel_booking_function.sql
\i database/migrations/008_create_release_expired_holds_function.sql
\i database/migrations/009_create_check_in_function.sql
\i database/migrations/010_create_check_out_function.sql
\i database/migrations/011_create_move_room_function.sql
\i database/migrations/012_performance_optimization.sql
\i database/migrations/013_seed_demo_data.sql
\i database/migrations/014_create_role_system.sql
```

#### Option B: Supabase

```bash
# 1. Create Supabase project
# 2. Get connection string
# 3. Use Supabase SQL Editor to run migrations
# 4. Enable Row Level Security (RLS) if needed
```

---

### Step 3: Deploy Backend

#### Option A: Railway

```bash
# 1. Install Railway CLI
npm i -g @railway/cli

# 2. Login
railway login

# 3. Initialize project
cd backend
railway init

# 4. Add environment variables
railway variables set DATABASE_URL="your-database-url"
railway variables set JWT_SECRET="your-jwt-secret"
railway variables set PORT="8080"
railway variables set GIN_MODE="release"
railway variables set FRONTEND_URL="https://hotel.example.com"

# 5. Deploy
railway up

# 6. Get deployment URL
railway domain
```

#### Option B: Render

```yaml
# render.yaml
services:
  - type: web
    name: hotel-booking-api
    env: docker
    dockerfilePath: ./backend/Dockerfile
    envVars:
      - key: DATABASE_URL
        sync: false
      - key: JWT_SECRET
        generateValue: true
      - key: PORT
        value: 8080
      - key: GIN_MODE
        value: release
    healthCheckPath: /health
```

```bash
# 1. Connect GitHub repository to Render
# 2. Create new Web Service
# 3. Select Docker environment
# 4. Add environment variables
# 5. Deploy
```

---

### Step 4: Deploy Frontend

#### Vercel Deployment

```bash
# 1. Install Vercel CLI
npm i -g vercel

# 2. Login
vercel login

# 3. Deploy
cd frontend
vercel --prod

# 4. Add environment variables in Vercel dashboard
# - NEXT_PUBLIC_API_URL
# - NEXTAUTH_URL
# - NEXTAUTH_SECRET
# - BACKEND_URL

# 5. Configure custom domain
vercel domains add hotel.example.com
```

#### Vercel Configuration

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "regions": ["sin1"],
  "env": {
    "NEXT_PUBLIC_API_URL": "@api-url",
    "NEXTAUTH_URL": "@nextauth-url",
    "NEXTAUTH_SECRET": "@nextauth-secret",
    "BACKEND_URL": "@backend-url"
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        }
      ]
    }
  ]
}
```

---

### Step 5: Configure DNS

#### Single Domain Setup

```
# A Record
hotel.example.com → Vercel IP

# CNAME Record
api.hotel.example.com → your-backend.railway.app
```

#### Sub-domain Setup

```
# A Records
hotel.example.com → Vercel IP (Guest)
staff.hotel.example.com → Vercel IP (Staff)
admin.hotel.example.com → Vercel IP (Admin)

# CNAME Record
api.hotel.example.com → your-backend.railway.app
```

---

### Step 6: SSL Certificates

#### Vercel (Automatic)
- ✅ Automatic SSL with Let's Encrypt
- ✅ Auto-renewal
- ✅ No configuration needed

#### Railway (Automatic)
- ✅ Automatic SSL
- ✅ Custom domain support

#### Manual (Cloudflare)
```bash
# 1. Add domain to Cloudflare
# 2. Update nameservers
# 3. Enable "Full (strict)" SSL mode
# 4. Enable "Always Use HTTPS"
# 5. Enable "Automatic HTTPS Rewrites"
```

---

## ⚡ Performance Optimization

### 1. Database Optimization

```sql
-- Connection pooling
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

-- Reload configuration
SELECT pg_reload_conf();
```

### 2. Backend Optimization

```go
// backend/cmd/server/main.go

// Connection pooling
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(25)
db.SetConnMaxLifetime(5 * time.Minute)

// Gin optimization
gin.SetMode(gin.ReleaseMode)
router.Use(gin.Recovery())
router.Use(middleware.Gzip())
```

### 3. Frontend Optimization

```typescript
// next.config.ts
const nextConfig = {
  // Image optimization
  images: {
    domains: ['your-cdn.com'],
    formats: ['image/avif', 'image/webp'],
  },
  
  // Compression
  compress: true,
  
  // Production optimizations
  swcMinify: true,
  
  // Caching
  headers: async () => [
    {
      source: '/:all*(svg|jpg|png)',
      headers: [
        {
          key: 'Cache-Control',
          value: 'public, max-age=31536000, immutable',
        },
      ],
    },
  ],
};
```

### 4. Redis Caching (Optional)

```bash
# Add Redis to Railway
railway add redis

# Update backend environment
REDIS_URL=redis://host:6379

# Backend will automatically use Redis for caching
```

---

## 🔒 Security Hardening

### 1. Environment Variables

```bash
# Never commit secrets to Git
echo ".env*" >> .gitignore
echo "!.env.example" >> .gitignore

# Use secret management
# - Vercel: Environment Variables
# - Railway: Variables
# - AWS: Secrets Manager
```

### 2. Rate Limiting

```go
// backend/internal/middleware/rate_limiter.go
import "github.com/ulule/limiter/v3"

func RateLimiter() gin.HandlerFunc {
    rate := limiter.Rate{
        Period: 1 * time.Minute,
        Limit:  60,
    }
    
    store := memory.NewStore()
    instance := limiter.New(store, rate)
    
    return func(c *gin.Context) {
        context, err := instance.Get(c, c.ClientIP())
        if err != nil {
            c.AbortWithStatus(http.StatusInternalServerError)
            return
        }
        
        if context.Reached {
            c.AbortWithStatus(http.StatusTooManyRequests)
            return
        }
        
        c.Next()
    }
}
```

### 3. Security Headers

```go
// backend/internal/middleware/security.go
func SecurityHeaders() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("X-Content-Type-Options", "nosniff")
        c.Header("X-Frame-Options", "DENY")
        c.Header("X-XSS-Protection", "1; mode=block")
        c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        c.Header("Content-Security-Policy", "default-src 'self'")
        c.Next()
    }
}
```

### 4. Database Security

```sql
-- Create read-only user for reports
CREATE USER report_user WITH PASSWORD 'secure-password';
GRANT CONNECT ON DATABASE hotel_booking TO report_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_user;

-- Revoke unnecessary permissions
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
```

---

## 📊 Monitoring & Logging

### 1. Application Monitoring

```bash
# Add Sentry for error tracking
npm install @sentry/nextjs @sentry/node

# Configure Sentry
SENTRY_DSN=your-sentry-dsn
```

### 2. Database Monitoring

```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Monitor slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 3. Logging

```go
// backend/pkg/logger/logger.go
import "go.uber.org/zap"

func NewLogger() *zap.Logger {
    if os.Getenv("GIN_MODE") == "release" {
        return zap.NewProduction()
    }
    return zap.NewDevelopment()
}
```

---

## 💾 Backup & Disaster Recovery

### 1. Database Backups

```bash
# Automated daily backups (Railway/Render include this)

# Manual backup
pg_dump -h host -U user -d hotel_booking > backup_$(date +%Y%m%d).sql

# Restore
psql -h host -U user -d hotel_booking < backup_20251104.sql
```

### 2. Backup Strategy

```
Daily:   Full database backup (retained 7 days)
Weekly:  Full backup (retained 4 weeks)
Monthly: Full backup (retained 12 months)
```

### 3. Disaster Recovery Plan

```markdown
1. Database failure
   - Restore from latest backup
   - Verify data integrity
   - Update connection strings

2. Backend failure
   - Redeploy from Git
   - Verify environment variables
   - Run health checks

3. Frontend failure
   - Redeploy from Git
   - Clear CDN cache
   - Verify DNS

4. Complete failure
   - Restore database
   - Redeploy all services
   - Update DNS if needed
   - Notify users
```

---

## ✅ Post-Deployment Checklist

### Functionality
- [ ] Guest can register and login
- [ ] Guest can search and book rooms
- [ ] Guest can view booking history
- [ ] Staff can check-in/check-out
- [ ] Staff can view room status
- [ ] Housekeeper can update room status
- [ ] Manager can manage pricing
- [ ] Manager can view reports

### Performance
- [ ] Page load < 3 seconds
- [ ] API response < 500ms
- [ ] Database queries optimized
- [ ] Images optimized
- [ ] CDN configured

### Security
- [ ] HTTPS enabled
- [ ] Secrets not in code
- [ ] Rate limiting active
- [ ] Security headers set
- [ ] CORS configured
- [ ] SQL injection prevented

### Monitoring
- [ ] Error tracking setup
- [ ] Logging configured
- [ ] Uptime monitoring
- [ ] Performance monitoring
- [ ] Backup automated

---

## 🆘 Troubleshooting

### Issue: Database Connection Timeout

```bash
# Check connection string
echo $DATABASE_URL

# Test connection
psql "$DATABASE_URL" -c "SELECT 1;"

# Check firewall rules
# Check IP whitelist
```

### Issue: CORS Errors

```go
// backend - Update CORS middleware
router.Use(cors.New(cors.Config{
    AllowOrigins:     []string{os.Getenv("FRONTEND_URL")},
    AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
    AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
    AllowCredentials: true,
}))
```

### Issue: NextAuth Session Not Working

```typescript
// frontend - Check NEXTAUTH_URL
// Must match exact domain (including https://)
NEXTAUTH_URL=https://hotel.example.com

// Check cookie settings
cookies: {
  sessionToken: {
    name: `__Secure-next-auth.session-token`,
    options: {
      httpOnly: true,
      sameSite: 'lax',
      path: '/',
      secure: true, // Must be true in production
    },
  },
}
```

---

## 📈 Scaling Strategy

### Phase 1: Single Server (0-1000 users)
- ✅ Current setup
- ✅ Vercel + Railway
- ✅ Single database

### Phase 2: Horizontal Scaling (1000-10000 users)
- Add Redis caching
- Add read replicas
- Enable CDN
- Add load balancer

### Phase 3: Microservices (10000+ users)
- Separate booking service
- Separate payment service
- Message queue (RabbitMQ/Kafka)
- Kubernetes orchestration

---

**Status:** ✅ Production Ready  
**Deployment Time:** ~2 hours  
**Maintenance:** Minimal  
**Cost:** $20-50/month (starter)

---

**Last Updated:** November 4, 2025
