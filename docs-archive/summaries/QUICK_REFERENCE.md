# ⚡ Quick Reference Card

## 🚀 Local Development

### Start Backend
```bash
cd backend
go run cmd/server/main.go
# Access: http://localhost:8080
```

### Start Frontend
```bash
cd frontend
npm run dev
# Access: http://localhost:3000
```

### Test API
```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/rooms
```

---

## 🌐 Production URLs

```bash
Frontend: https://your-frontend.vercel.app
Backend:  https://your-backend.vercel.app
Health:   https://your-backend.vercel.app/health
```

---

## 🔑 Generate JWT Secret

### Windows
```bash
cd backend\scripts
generate-jwt-secret.bat
```

### Mac/Linux
```bash
cd backend/scripts
./generate-jwt-secret.sh
```

### Alternative (OpenSSL)
```bash
openssl rand -base64 32
```

---

## 📝 Environment Files

### Backend Local (.env)
```bash
cd backend
cp .env.local.example .env
# Edit with your Neon credentials
```

### Backend Production (Vercel)
```bash
# Copy from .env.production.example
# Add to Vercel → Settings → Environment Variables
```

### Frontend Local (.env.local)
```bash
cd frontend
cp .env.local.example .env.local
# Edit with backend URL
```

---

## 🗄️ Database Commands

### Seed Database
```bash
cd frontend
npm run db:seed
```

### Push Schema
```bash
cd frontend
npm run db:push
```

### Test API Connection
```bash
cd frontend
npm run dev
# Visit: http://localhost:3000/api/test
```

---

## 🔧 Common Tasks

### Update Environment Variables (Vercel)
1. Go to Vercel Dashboard
2. Select Project
3. Settings → Environment Variables
4. Add/Update variables
5. Redeploy

### View Logs (Vercel)
1. Vercel Dashboard → Project
2. Deployments → Select latest
3. View Function Logs

### Redeploy
```bash
git add .
git commit -m "Update"
git push origin main
# Vercel auto-deploys
```

---

## 🧪 Test Endpoints

### Health Check
```bash
curl https://your-backend.vercel.app/health
```

### Get All Rooms
```bash
curl https://your-backend.vercel.app/api/rooms
```

### Search Rooms
```bash
curl "https://your-backend.vercel.app/api/rooms?checkIn=2024-12-01&checkOut=2024-12-05"
```

### Get Room Details
```bash
curl https://your-backend.vercel.app/api/rooms/1
```

---

## 📚 Documentation Quick Links

- **Setup**: `backend/PRODUCTION_SETUP_GUIDE.md`
- **Quick Start**: `backend/QUICK_START_PRODUCTION.md`
- **API Docs**: `backend/API_DOCUMENTATION.md`
- **Env Vars**: `backend/ENV_VARIABLES_GUIDE.md`
- **Checklist**: `DEPLOYMENT_CHECKLIST.md`
- **Ready**: `PRODUCTION_READY.md`

---

## 🐛 Quick Troubleshooting

### "Failed to connect to database"
```bash
# Check DATABASE_URL is correct
# Verify Neon database is active
# Use pooled connection for production
```

### "CORS error"
```bash
# Update ALLOWED_ORIGINS in backend
# Redeploy backend
```

### "JWT secret too short"
```bash
# Generate new secret (32+ chars)
openssl rand -base64 32
# Update in Vercel environment variables
```

---

## 📦 Project Structure

```
booking-hotel/
├── backend/          # Go Backend
│   ├── cmd/         # Main app
│   ├── internal/    # Internal packages
│   ├── pkg/         # Shared packages
│   └── .env         # Local config
├── frontend/        # Next.js Frontend
│   ├── src/         # Source code
│   ├── scripts/     # Utility scripts
│   └── .env.local   # Local config
└── docs/            # Documentation
```

---

## ⚙️ Key Configuration

### Required Environment Variables

**Backend:**
```bash
DATABASE_URL=postgresql://...
PORT=8080
GIN_MODE=release
JWT_SECRET=your-secret-32-chars
FRONTEND_URL=https://your-frontend.vercel.app
```

**Frontend:**
```bash
NEXT_PUBLIC_API_URL=https://your-backend.vercel.app
DATABASE_URL=postgresql://...
```

---

## 🎯 Deployment Steps

### 1. Local Test
```bash
# Backend
cd backend && go run cmd/server/main.go

# Frontend
cd frontend && npm run dev
```

### 2. Push to GitHub
```bash
git add .
git commit -m "Ready for production"
git push origin main
```

### 3. Deploy on Vercel
1. Import repository
2. Set root directory (backend or frontend)
3. Add environment variables
4. Deploy

### 4. Test Production
```bash
curl https://your-backend.vercel.app/health
```

---

## 📞 Get Help

- **Full Setup**: See `PRODUCTION_SETUP_GUIDE.md`
- **Checklist**: See `DEPLOYMENT_CHECKLIST.md`
- **API Docs**: See `API_DOCUMENTATION.md`

---

## ✅ Pre-Submission Checklist

- [ ] Backend deployed ✅
- [ ] Frontend deployed ✅
- [ ] Database connected ✅
- [ ] API tested ✅
- [ ] Documentation ready ✅
- [ ] URLs collected ✅

---

**You're ready! 🚀**
