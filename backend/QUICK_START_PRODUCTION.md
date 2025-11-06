# ⚡ Quick Start - Production Ready in 10 Minutes

## 🎯 Goal
Get your Go backend + Neon PostgreSQL running locally and deployed to production on Vercel.

---

## 📦 What You'll Need (5 minutes to setup)

1. **Neon PostgreSQL Account** (Free)
   - Sign up: https://console.neon.tech
   - Create a new project
   - Copy your connection string

2. **Vercel Account** (Free)
   - Sign up: https://vercel.com
   - Connect your GitHub account

3. **GitHub Repository**
   - Push your code to GitHub

---

## 🚀 Local Setup (3 minutes)

### Step 1: Copy Environment File
```bash
cd backend
cp .env.local.example .env
```

### Step 2: Update `.env` with Neon Credentials

Open `backend/.env` and replace these lines:

```bash
# Get from Neon Console → Connection Details → Direct Connection
DB_HOST=ep-xxx-xxx.region.aws.neon.tech
DB_USER=your_neon_username
DB_PASSWORD=your_neon_password
DB_NAME=neondb

# Generate JWT secret
JWT_SECRET=your-secret-here-minimum-32-characters
```

### Step 3: Run Server
```bash
go mod download
go run cmd/server/main.go
```

✅ Server running on: `http://localhost:8080`

### Step 4: Test
```bash
curl http://localhost:8080/health
```

---

## 🌐 Production Deployment (2 minutes)

### Step 1: Push to GitHub
```bash
git add .
git commit -m "Ready for production"
git push origin main
```

### Step 2: Deploy on Vercel

1. Go to https://vercel.com/new
2. Import your GitHub repository
3. Set **Root Directory**: `backend`
4. Click "Deploy"

### Step 3: Add Environment Variables

In Vercel → Project → Settings → Environment Variables:

```bash
# Database (Use POOLED connection from Neon)
DATABASE_URL=postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
DB_HOST=ep-xxx-xxx-pooler.region.aws.neon.tech
DB_USER=your_neon_username
DB_PASSWORD=your_neon_password
DB_NAME=neondb
DB_SSLMODE=require

# Server
PORT=8080
GIN_MODE=release
ENVIRONMENT=production

# JWT (Generate with: openssl rand -base64 32)
JWT_SECRET=your-production-secret-32-chars-minimum

# CORS (Replace with your frontend URL)
FRONTEND_URL=https://your-frontend.vercel.app
ALLOWED_ORIGINS=https://your-frontend.vercel.app
```

### Step 4: Redeploy

Click "Redeploy" in Vercel dashboard.

✅ Your API is live at: `https://your-backend.vercel.app`

---

## ✅ Verification Checklist

- [ ] Local server runs: `http://localhost:8080/health` returns OK
- [ ] Production API works: `https://your-backend.vercel.app/health` returns OK
- [ ] Frontend can connect to backend
- [ ] Database queries work (test with `/api/rooms`)

---

## 🔑 Important Notes

### For Local Development:
- Use **Direct Connection** string from Neon
- `GIN_MODE=debug`
- `DB_SSLMODE=require`

### For Production:
- Use **Pooled Connection** string from Neon (has `-pooler` in URL)
- `GIN_MODE=release`
- Strong JWT_SECRET (32+ characters)
- Update CORS origins with actual frontend domain

---

## 🐛 Quick Troubleshooting

### "Failed to connect to database"
→ Check if Neon database is active (not paused)
→ Verify connection string is correct

### "CORS error"
→ Update `FRONTEND_URL` and `ALLOWED_ORIGINS` in Vercel environment variables

### "JWT secret too short"
→ Generate new secret: `openssl rand -base64 32`

---

## 📚 Next Steps

1. ✅ Test all API endpoints
2. ✅ Connect frontend to backend
3. ✅ Setup monitoring (optional)
4. ✅ Configure custom domain (optional)

---

## 📖 Full Documentation

For detailed setup instructions, see:
- [PRODUCTION_SETUP_GUIDE.md](./PRODUCTION_SETUP_GUIDE.md)
- [ENV_VARIABLES_GUIDE.md](./ENV_VARIABLES_GUIDE.md)

---

**You're ready to go! 🎉**
