# 🚀 Production Setup Guide - Go Backend + Neon PostgreSQL

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Production Deployment (Vercel)](#production-deployment-vercel)
4. [Environment Variables](#environment-variables)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

### Required Accounts
- ✅ [Neon PostgreSQL](https://console.neon.tech) - Free tier available
- ✅ [Vercel](https://vercel.com) - Free tier available
- ✅ [GitHub](https://github.com) - For deployment

### Required Tools
- Go 1.21 or higher
- Git
- Text editor (VS Code recommended)

---

## 🏠 Local Development Setup

### Step 1: Get Neon PostgreSQL Connection String

1. Go to [Neon Console](https://console.neon.tech)
2. Create a new project or select existing one
3. Click "Connection Details"
4. Copy the **Direct connection** string:
   ```
   postgresql://username:password@ep-xxx-xxx.region.aws.neon.tech/neondb?sslmode=require
   ```

### Step 2: Create `.env` File

```bash
# In backend folder
cd backend
cp .env.local.example .env
```

### Step 3: Configure `.env` File

Open `backend/.env` and update these values:

```bash
# Replace with your Neon connection details
DB_HOST=ep-xxx-xxx.region.aws.neon.tech
DB_USER=your_neon_username
DB_PASSWORD=your_neon_password
DB_NAME=neondb

# Or use the full DATABASE_URL
DATABASE_URL=postgresql://username:password@ep-xxx-xxx.region.aws.neon.tech/neondb?sslmode=require

# Generate a JWT secret (run this command):
# openssl rand -base64 32
JWT_SECRET=your-generated-secret-here
```

### Step 4: Install Dependencies

```bash
go mod download
go mod tidy
```

### Step 5: Run Database Migrations

```bash
# If you have migration files
go run cmd/migrate/main.go up

# Or use your migration tool
```

### Step 6: Run the Server

```bash
# Option 1: Direct run
go run cmd/server/main.go

# Option 2: With hot reload (if you have air installed)
air

# Option 3: Build and run
go build -o server cmd/server/main.go
./server
```

Server should start on: `http://localhost:8080`

### Step 7: Test the API

```bash
# Health check
curl http://localhost:8080/health

# Test API endpoint
curl http://localhost:8080/api/rooms
```

---

## 🌐 Production Deployment (Vercel)

### Step 1: Prepare Your Repository

```bash
# Make sure all changes are committed
git add .
git commit -m "Ready for production deployment"
git push origin main
```

### Step 2: Connect to Vercel

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "Add New" → "Project"
3. Import your GitHub repository
4. Select the `backend` folder as the root directory

### Step 3: Configure Build Settings

Vercel should auto-detect Go, but verify:

- **Framework Preset**: Other
- **Root Directory**: `backend`
- **Build Command**: (leave empty - Vercel handles Go builds)
- **Output Directory**: (leave empty)

### Step 4: Add Environment Variables

In Vercel project settings → Environment Variables, add:

#### Required Variables:

```bash
# Database (Neon Pooled Connection)
DATABASE_URL=postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
DB_HOST=ep-xxx-xxx-pooler.region.aws.neon.tech
DB_PORT=5432
DB_USER=your_neon_username
DB_PASSWORD=your_neon_password
DB_NAME=neondb
DB_SSLMODE=require

# Server
PORT=8080
GIN_MODE=release
ENVIRONMENT=production

# JWT (Generate with: openssl rand -base64 32)
JWT_SECRET=your-production-secret-minimum-32-characters
JWT_EXPIRATION=24h

# CORS (Replace with your frontend URL)
FRONTEND_URL=https://your-frontend.vercel.app
ALLOWED_ORIGINS=https://your-frontend.vercel.app

# Optional: Redis (Upstash)
REDIS_URL=redis://default:password@upstash.io:6379

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=1m

# Logging
LOG_LEVEL=warn
LOG_FORMAT=json

# Jobs
NIGHT_AUDIT_ENABLED=true
HOLD_CLEANUP_ENABLED=true
```

#### Important Notes:
- ⚠️ Use **Pooled connection** string for production (not direct)
- ⚠️ Generate a strong JWT_SECRET (minimum 32 characters)
- ⚠️ Update FRONTEND_URL with your actual frontend domain

### Step 5: Deploy

1. Click "Deploy"
2. Wait for build to complete (2-3 minutes)
3. Your backend will be live at: `https://your-backend.vercel.app`

### Step 6: Test Production API

```bash
# Health check
curl https://your-backend.vercel.app/health

# Test API
curl https://your-backend.vercel.app/api/rooms
```

### Step 7: Update Frontend Configuration

Update your frontend `.env.production`:

```bash
NEXT_PUBLIC_API_URL=https://your-backend.vercel.app
```

---

## 🔐 Environment Variables Reference

### Local Development (`.env`)
Copy from `.env.local.example` and update:
- Neon direct connection string
- Simple JWT secret for testing
- `GIN_MODE=debug`
- `ENVIRONMENT=development`

### Production (Vercel Environment Variables)
Copy from `.env.production.example` and update:
- Neon **pooled** connection string
- Strong JWT secret (32+ characters)
- `GIN_MODE=release`
- `ENVIRONMENT=production`
- Actual frontend domain

---

## 🧪 Testing

### Test Local Server

```bash
# Health check
curl http://localhost:8080/health

# Get all rooms
curl http://localhost:8080/api/rooms

# Search available rooms
curl "http://localhost:8080/api/rooms?checkIn=2024-12-01&checkOut=2024-12-05"

# Create booking (requires auth)
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "guestId": 1,
    "roomTypeId": 1,
    "checkIn": "2024-12-01",
    "checkOut": "2024-12-05"
  }'
```

### Test Production Server

Replace `localhost:8080` with your Vercel URL:
```bash
curl https://your-backend.vercel.app/health
```

---

## 🐛 Troubleshooting

### Issue: "Failed to connect to database"

**Solution:**
1. Check if DATABASE_URL is correct
2. Verify Neon database is active (not paused)
3. Check if IP is whitelisted (Neon allows all by default)
4. Use **pooled connection** for production

### Issue: "JWT secret too short"

**Solution:**
Generate a proper secret:
```bash
openssl rand -base64 32
```
Update JWT_SECRET in environment variables.

### Issue: "CORS error"

**Solution:**
1. Check FRONTEND_URL matches your frontend domain
2. Update ALLOWED_ORIGINS to include all frontend URLs
3. Make sure protocol (http/https) matches

### Issue: "Vercel build failed"

**Solution:**
1. Check `go.mod` and `go.sum` are committed
2. Verify `vercel.json` is in backend folder
3. Check Vercel logs for specific error
4. Ensure Go version is 1.21+

### Issue: "Database connection pool exhausted"

**Solution:**
Adjust pool settings in production:
```bash
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=10
DB_CONN_MAX_LIFETIME=10m
```

### Issue: "Night audit job not running"

**Solution:**
1. Check `NIGHT_AUDIT_ENABLED=true`
2. Verify `NIGHT_AUDIT_TIME=00:00` format
3. Check server logs for errors
4. Note: Vercel serverless may not support long-running jobs

---

## 📚 Additional Resources

- [Neon Documentation](https://neon.tech/docs)
- [Vercel Go Documentation](https://vercel.com/docs/functions/serverless-functions/runtimes/go)
- [Gin Framework](https://gin-gonic.com/docs/)
- [Project API Documentation](./API_DOCUMENTATION.md)

---

## 🎯 Quick Commands Cheat Sheet

```bash
# Local Development
cd backend
cp .env.local.example .env
# Edit .env with your Neon credentials
go mod download
go run cmd/server/main.go

# Test
curl http://localhost:8080/health

# Production Deploy
git add .
git commit -m "Deploy to production"
git push origin main
# Then deploy via Vercel dashboard

# Generate JWT Secret
openssl rand -base64 32
```

---

## ✅ Pre-Deployment Checklist

- [ ] Neon PostgreSQL database created
- [ ] Database schema migrated
- [ ] `.env` configured for local development
- [ ] Local server runs successfully
- [ ] API endpoints tested locally
- [ ] GitHub repository created and pushed
- [ ] Vercel account created
- [ ] Environment variables added to Vercel
- [ ] JWT_SECRET generated (32+ characters)
- [ ] FRONTEND_URL updated with production domain
- [ ] Pooled connection string used for production
- [ ] CORS origins configured correctly
- [ ] First deployment successful
- [ ] Production API tested
- [ ] Frontend connected to backend

---

## 🆘 Need Help?

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Vercel deployment logs
3. Check Neon database status
4. Verify all environment variables are set correctly

---

**Good luck with your deployment! 🚀**
