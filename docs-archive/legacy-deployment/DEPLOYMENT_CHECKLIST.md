# ✅ Production Deployment Checklist

Use this checklist before submitting your project to ensure everything is production-ready.

---

## 📋 Pre-Deployment Checklist

### 1. Database Setup (Neon PostgreSQL)

- [ ] Neon account created
- [ ] Database project created
- [ ] Database schema migrated/seeded
- [ ] Connection string copied (both direct and pooled)
- [ ] Database is active (not paused)
- [ ] Test queries work

**Verify:**
```bash
# Test connection from local
psql "postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require"
```

---

### 2. Backend Configuration

- [ ] `.env` file created from `.env.local.example`
- [ ] All database credentials updated in `.env`
- [ ] JWT secret generated (32+ characters)
- [ ] Local server runs successfully
- [ ] Health check endpoint works: `http://localhost:8080/health`
- [ ] API endpoints tested locally
- [ ] No sensitive data in git repository
- [ ] `vercel.json` configured correctly

**Verify:**
```bash
cd backend
go run cmd/server/main.go
curl http://localhost:8080/health
curl http://localhost:8080/api/rooms
```

---

### 3. Frontend Configuration

- [ ] `.env.local` created with correct API URL
- [ ] Frontend runs successfully
- [ ] Can connect to backend API
- [ ] All pages load without errors
- [ ] Forms submit correctly
- [ ] Authentication works (if implemented)

**Verify:**
```bash
cd frontend
npm run dev
# Open http://localhost:3000 and test
```

---

### 4. GitHub Repository

- [ ] Repository created on GitHub
- [ ] All code committed
- [ ] `.gitignore` configured (excludes `.env` files)
- [ ] README.md updated
- [ ] No sensitive data committed
- [ ] Latest changes pushed

**Verify:**
```bash
git status
git log -1
git remote -v
```

---

### 5. Vercel Backend Deployment

- [ ] Vercel account created
- [ ] Backend project created
- [ ] Root directory set to `backend`
- [ ] All environment variables added:
  - [ ] `DATABASE_URL` (pooled connection)
  - [ ] `DB_HOST` (with `-pooler`)
  - [ ] `DB_PORT`
  - [ ] `DB_USER`
  - [ ] `DB_PASSWORD`
  - [ ] `DB_NAME`
  - [ ] `DB_SSLMODE=require`
  - [ ] `PORT=8080`
  - [ ] `GIN_MODE=release`
  - [ ] `ENVIRONMENT=production`
  - [ ] `JWT_SECRET` (strong, 32+ chars)
  - [ ] `JWT_EXPIRATION=24h`
  - [ ] `FRONTEND_URL` (your frontend domain)
  - [ ] `ALLOWED_ORIGINS` (your frontend domain)
  - [ ] `RATE_LIMIT_ENABLED=true`
  - [ ] `LOG_LEVEL=warn`
  - [ ] `LOG_FORMAT=json`
- [ ] First deployment successful
- [ ] Backend URL noted

**Verify:**
```bash
curl https://your-backend.vercel.app/health
curl https://your-backend.vercel.app/api/rooms
```

---

### 6. Vercel Frontend Deployment

- [ ] Frontend project created on Vercel
- [ ] Root directory set to `frontend`
- [ ] Environment variables added:
  - [ ] `NEXT_PUBLIC_API_URL` (backend URL)
  - [ ] `DATABASE_URL` (Neon connection)
  - [ ] `NEXTAUTH_SECRET` (if using NextAuth)
  - [ ] `NEXTAUTH_URL` (frontend URL)
- [ ] Build successful
- [ ] Frontend URL noted
- [ ] Website loads correctly

**Verify:**
- Open frontend URL in browser
- Check all pages load
- Test API calls work
- Check browser console for errors

---

### 7. Integration Testing

- [ ] Frontend can connect to backend
- [ ] API calls return correct data
- [ ] CORS configured correctly (no CORS errors)
- [ ] Authentication works (if implemented)
- [ ] Database queries work
- [ ] Forms submit successfully
- [ ] Error handling works
- [ ] Loading states work

**Test Scenarios:**
1. Load homepage
2. View room list
3. View room details
4. Search for available rooms
5. Create a booking (if implemented)
6. Check booking details

---

### 8. Environment Variables Sync

- [ ] Backend `.env.production.example` updated
- [ ] Frontend `.env.production.example` updated
- [ ] All Vercel environment variables match examples
- [ ] No placeholder values in production
- [ ] Secrets are strong and unique

---

### 9. Security Check

- [ ] JWT secret is strong (32+ characters)
- [ ] Database password is strong
- [ ] No API keys in frontend code
- [ ] CORS origins restricted to your domains
- [ ] Rate limiting enabled
- [ ] HTTPS enforced
- [ ] No sensitive data in logs
- [ ] `.env` files in `.gitignore`

---

### 10. Performance Check

- [ ] Database connection pooling configured
- [ ] API response times acceptable (<500ms)
- [ ] Frontend loads quickly (<3s)
- [ ] Images optimized
- [ ] No memory leaks
- [ ] Proper error handling

---

### 11. Documentation

- [ ] README.md updated with:
  - [ ] Project description
  - [ ] Setup instructions
  - [ ] Deployment instructions
  - [ ] API documentation
  - [ ] Environment variables list
- [ ] API endpoints documented
- [ ] Database schema documented
- [ ] Deployment guide available

---

### 12. Final Verification

- [ ] All features work in production
- [ ] No console errors
- [ ] No broken links
- [ ] Mobile responsive (if required)
- [ ] Cross-browser compatible
- [ ] Logs show no critical errors
- [ ] Health check passes
- [ ] Database queries work

---

## 🚀 Deployment Commands

### Backend
```bash
cd backend

# Local test
go run cmd/server/main.go

# Deploy to Vercel (via GitHub)
git add .
git commit -m "Deploy backend"
git push origin main
```

### Frontend
```bash
cd frontend

# Local test
npm run dev

# Build test
npm run build

# Deploy to Vercel (via GitHub)
git add .
git commit -m "Deploy frontend"
git push origin main
```

---

## 🔍 Testing URLs

### Local
- Backend: `http://localhost:8080`
- Frontend: `http://localhost:3000`

### Production
- Backend: `https://your-backend.vercel.app`
- Frontend: `https://your-frontend.vercel.app`

### Test Endpoints
```bash
# Health check
curl https://your-backend.vercel.app/health

# Get rooms
curl https://your-backend.vercel.app/api/rooms

# Search rooms
curl "https://your-backend.vercel.app/api/rooms?checkIn=2024-12-01&checkOut=2024-12-05"
```

---

## 📊 Success Criteria

Your deployment is successful when:

✅ Backend health check returns 200 OK
✅ Frontend loads without errors
✅ API calls work from frontend
✅ Database queries execute successfully
✅ No CORS errors in browser console
✅ Authentication works (if implemented)
✅ All main features functional
✅ Response times are acceptable
✅ No critical errors in logs

---

## 🐛 Common Issues & Solutions

### Issue: "Failed to connect to database"
**Solution:**
- Check DATABASE_URL is correct
- Verify using **pooled** connection for production
- Check Neon database is active

### Issue: "CORS error"
**Solution:**
- Update `ALLOWED_ORIGINS` in backend
- Include protocol (https://)
- Redeploy backend after changes

### Issue: "JWT secret too short"
**Solution:**
```bash
openssl rand -base64 32
```
Update JWT_SECRET in Vercel

### Issue: "Vercel build failed"
**Solution:**
- Check build logs
- Verify all dependencies in package.json/go.mod
- Check for syntax errors

### Issue: "API returns 500 error"
**Solution:**
- Check Vercel function logs
- Verify database connection
- Check environment variables

---

## 📝 Submission Checklist

Before submitting to client:

- [ ] All features working
- [ ] Production URLs documented
- [ ] Admin credentials provided (if any)
- [ ] API documentation included
- [ ] Setup guide included
- [ ] Source code on GitHub
- [ ] Environment variables documented
- [ ] Known issues documented (if any)
- [ ] Future improvements noted (if any)

---

## 📦 Deliverables

Provide to client:

1. **URLs**
   - Frontend: `https://your-frontend.vercel.app`
   - Backend: `https://your-backend.vercel.app`
   - GitHub: `https://github.com/your-username/your-repo`

2. **Documentation**
   - README.md
   - API_DOCUMENTATION.md
   - PRODUCTION_SETUP_GUIDE.md
   - ENV_VARIABLES_GUIDE.md

3. **Credentials** (if applicable)
   - Admin login
   - Database access
   - Vercel project access

4. **Source Code**
   - GitHub repository link
   - Branch: `main`
   - Latest commit

---

## 🎯 Quick Final Check

Run these commands before submission:

```bash
# 1. Test backend
curl https://your-backend.vercel.app/health
curl https://your-backend.vercel.app/api/rooms

# 2. Open frontend
open https://your-frontend.vercel.app

# 3. Check git status
git status
git log -1

# 4. Verify no sensitive data
grep -r "password" .env* || echo "No .env files (good!)"
```

---

## ✨ You're Ready!

If all checkboxes are checked, your project is ready for submission! 🎉

**Good luck! 🚀**

---

## 📞 Support

If you encounter issues:
1. Check [PRODUCTION_SETUP_GUIDE.md](./backend/PRODUCTION_SETUP_GUIDE.md)
2. Review [ENV_VARIABLES_GUIDE.md](./backend/ENV_VARIABLES_GUIDE.md)
3. Check Vercel deployment logs
4. Verify Neon database status
