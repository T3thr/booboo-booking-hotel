# ✅ Vercel Setup Checklist

## 📋 Pre-Deployment

### Backend (Render)
- [x] Backend deployed บน Render
- [x] Backend URL: `https://booboo-booking.onrender.com`
- [ ] Database migrations รันสำเร็จ (⚠️ ต้องทำก่อน!)
  - ดู: [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)

### Frontend (Local)
- [x] Frontend code พร้อม
- [x] `frontend/.env.production` สร้างแล้ว
- [x] `vercel.json` สร้างแล้ว
- [x] Dependencies ติดตั้งครบ

---

## 🚀 Deployment Steps

### Step 1: ติดตั้ง Vercel CLI

```bash
npm install -g vercel
```

**ตรวจสอบ**:
```bash
vercel --version
```

- [ ] Vercel CLI ติดตั้งสำเร็จ

---

### Step 2: Login to Vercel

```bash
vercel login
```

Browser จะเปิดให้ login

- [ ] Login สำเร็จ

---

### Step 3: Deploy to Production

```bash
# Option A: ใช้ script
./deploy-vercel.bat     # Windows
./deploy-vercel.sh      # Linux/Mac

# Option B: Manual
cd frontend
vercel --prod
```

**ตอบคำถาม**:
- Set up and deploy? → `Y`
- Which scope? → เลือก account ของคุณ
- Link to existing project? → `N`
- Project name? → `hotel-booking-frontend`
- Directory? → `./` (เพราะอยู่ใน frontend folder แล้ว)

**รอ 2-3 นาที...**

- [ ] Build สำเร็จ
- [ ] Deploy สำเร็จ
- [ ] ได้ URL: `https://hotel-booking-frontend.vercel.app`

---

### Step 4: ตั้งค่า Environment Variables

```bash
# NEXT_PUBLIC_API_URL
vercel env add NEXT_PUBLIC_API_URL production
# ใส่: https://booboo-booking.onrender.com/api

# BACKEND_URL
vercel env add BACKEND_URL production
# ใส่: https://booboo-booking.onrender.com

# NEXTAUTH_URL (ใช้ URL ที่ได้จาก Step 3)
vercel env add NEXTAUTH_URL production
# ใส่: https://hotel-booking-frontend.vercel.app

# NEXTAUTH_SECRET
vercel env add NEXTAUTH_SECRET production
# ใส่: IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=

# NODE_ENV
vercel env add NODE_ENV production
# ใส่: production
```

- [ ] ตั้งค่า `NEXT_PUBLIC_API_URL`
- [ ] ตั้งค่า `BACKEND_URL`
- [ ] ตั้งค่า `NEXTAUTH_URL`
- [ ] ตั้งค่า `NEXTAUTH_SECRET`
- [ ] ตั้งค่า `NODE_ENV`

---

### Step 5: Redeploy

```bash
vercel --prod
```

รอ 1-2 นาที...

- [ ] Redeploy สำเร็จ

---

## 🔗 Connect Frontend ↔ Backend

### Step 6: อัปเดต CORS บน Render

1. ไปที่ https://dashboard.render.com
2. เลือก Backend Service: `booboo-booking`
3. ไปที่ **Environment**
4. แก้ไข `ALLOWED_ORIGINS`:
   ```
   https://hotel-booking-frontend.vercel.app,https://hotel-booking-frontend-*.vercel.app
   ```
5. คลิก **Save Changes**
6. รอ Render redeploy (~2 นาที)

- [ ] อัปเดต `ALLOWED_ORIGINS`
- [ ] Render redeploy สำเร็จ

---

## 🧪 Testing

### Step 7: ทดสอบ Backend Health

```bash
curl https://booboo-booking.onrender.com/api/health
```

**Expected**:
```json
{
  "status": "ok",
  "timestamp": "2025-11-04T..."
}
```

- [ ] Backend health check OK

---

### Step 8: ทดสอบ Frontend

เปิด browser: `https://hotel-booking-frontend.vercel.app`

- [ ] Homepage โหลดสำเร็จ
- [ ] ไม่มี console errors
- [ ] Navbar แสดงถูกต้อง

---

### Step 9: ทดสอบ CORS

เปิด browser console บน frontend:

```javascript
fetch('https://booboo-booking.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log)
```

**Expected**: เห็น response ไม่มี CORS error

- [ ] CORS ทำงานถูกต้อง

---

### Step 10: ทดสอบ Authentication

1. คลิก "Login"
2. ใส่ credentials:
   - Email: `admin@hotel.com`
   - Password: `admin123`
3. คลิก "Sign In"

**Expected**: Login สำเร็จ, redirect ไป dashboard

- [ ] Login ทำงาน
- [ ] JWT token ถูกส่ง
- [ ] Redirect ถูกต้อง

---

### Step 11: ทดสอบ Booking Flow

1. **Search Rooms**
   - เลือกวันที่
   - คลิก "Search"
   - เห็นห้องว่าง

2. **Select Room**
   - คลิก "Book Now"
   - กรอกข้อมูลผู้เข้าพัก
   - คลิก "Continue"

3. **Confirm Booking**
   - ตรวจสอบข้อมูล
   - คลิก "Confirm"
   - เห็นหน้า confirmation

- [ ] Search ทำงาน
- [ ] Booking ทำงาน
- [ ] Confirmation แสดงถูกต้อง

---

## 📊 Final Checks

### Frontend (Vercel)
- [ ] Build สำเร็จ
- [ ] Deploy สำเร็จ
- [ ] Environment variables ตั้งค่าครบ
- [ ] All pages load
- [ ] No console errors

### Backend (Render)
- [ ] Service running
- [ ] CORS configured
- [ ] No errors in logs
- [ ] API endpoints respond

### Integration
- [ ] Frontend → Backend connection works
- [ ] CORS no errors
- [ ] Authentication works
- [ ] Booking flow works end-to-end

---

## 🎉 Success!

ถ้าทุกอย่างเป็น ✅ แสดงว่า deployment สำเร็จ!

**URLs**:
- Frontend: `https://hotel-booking-frontend.vercel.app`
- Backend: `https://booboo-booking.onrender.com`
- API: `https://booboo-booking.onrender.com/api`

---

## 🚨 If Something Goes Wrong

### CORS Error
➡️ ตรวจสอบ `ALLOWED_ORIGINS` บน Render

### 401 Unauthorized
➡️ ตรวจสอบ `JWT_SECRET` และ `NEXTAUTH_SECRET` ตรงกัน

### Build Failed
➡️ ตรวจสอบ `package.json` และ dependencies

### Environment Variables Not Working
➡️ Redeploy หลังเพิ่ม env vars

---

## 📚 Documentation

- [VERCEL_DEPLOYMENT_GUIDE.md](VERCEL_DEPLOYMENT_GUIDE.md) - Complete guide
- [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) - Fix migrations
- [DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md) - Full workflow
- [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) - Integration

---

**Created**: 2025-11-04  
**Estimated Time**: 15-20 minutes  
**Difficulty**: ⭐⭐☆☆☆ (Easy)
