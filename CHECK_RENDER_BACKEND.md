# ตรวจสอบ Render Backend

## 🔴 ปัญหา

- **Localhost**: ทำงานได้ปกติ ✅
- **Production**: Error 500 ❌

**สาเหตุ**: Backend บน Render ยังไม่ได้ deploy code ใหม่

## 🔍 วิธีตรวจสอบ

### 1. เข้า Render Dashboard

```
URL: https://dashboard.render.com
```

### 2. เลือก Service

- คลิกที่ service: **booboo-booking** (หรือชื่อที่คุณตั้ง)

### 3. ตรวจสอบ Deploy Status

**ดูที่ "Events" tab:**
- ✅ **Deploy live** - deploy สำเร็จ
- 🟡 **In progress** - กำลัง deploy
- ❌ **Deploy failed** - deploy ล้มเหลว

### 4. ตรวจสอบ Logs

**คลิก "Logs" tab:**

**Logs ที่ถูกต้อง:**
```
==> Building...
==> go build -o main ./cmd/server
==> Build successful
==> Starting server...
==> Server listening on :8080
```

**Logs ที่มีปัญหา:**
```
ERROR: build failed
ERROR: cannot find package
ERROR: syntax error
```

### 5. ตรวจสอบ Environment Variables

**คลิก "Environment" tab:**

ต้องมี:
```
DATABASE_URL=postgresql://...
JWT_SECRET=...
ALLOWED_ORIGINS=http://localhost:3000,https://booboo-booking.vercel.app
PORT=8080
```

## 🔧 วิธีแก้ไข

### ถ้า Deploy ล้มเหลว

#### Option 1: Manual Deploy

1. ไปที่ Render Dashboard
2. เลือก service
3. คลิก **"Manual Deploy"**
4. เลือก **"Deploy latest commit"**
5. รอ 2-5 นาที

#### Option 2: Trigger Deploy จาก Git

```bash
# Push empty commit เพื่อ trigger deploy
git commit --allow-empty -m "trigger deploy"
git push origin main
```

### ถ้า Build Error

1. **ตรวจสอบ Logs** - ดู error message
2. **ตรวจสอบ go.mod** - dependencies ครบหรือไม่
3. **ตรวจสอบ Build Command**:
   ```
   go build -o main ./cmd/server
   ```

### ถ้า Runtime Error

1. **ตรวจสอบ Environment Variables**
2. **ตรวจสอบ Database Connection**:
   ```sql
   -- ทดสอบ connection
   psql "postgresql://..."
   ```
3. **ตรวจสอบ CORS Settings**:
   ```
   ALLOWED_ORIGINS=http://localhost:3000,https://booboo-booking.vercel.app
   ```

## 🧪 ทดสอบ Backend

### Test 1: Health Check

```bash
curl https://your-backend.onrender.com/health
```

**Expected:**
```json
{
  "status": "ok",
  "timestamp": "2025-11-09T..."
}
```

### Test 2: Approve API

```bash
curl -X POST https://your-backend.onrender.com/api/payment-proofs/32/approve \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

**Expected:**
```json
{
  "success": true,
  "message": "Booking approved successfully"
}
```

### Test 3: Arrivals API

```bash
curl "https://your-backend.onrender.com/api/checkin/arrivals?date=2025-11-09" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:**
```json
{
  "arrivals": [...],
  "count": 5
}
```

## 📊 Checklist

### Pre-Deploy
- [ ] Code ถูกต้องใน localhost
- [ ] Commit และ push to GitHub
- [ ] ตรวจสอบ GitHub มี commit ล่าสุด

### Deploy
- [ ] Render auto-deploy triggered
- [ ] Build successful (ดู Logs)
- [ ] Service running (status: live)
- [ ] No errors in Logs

### Post-Deploy
- [ ] ทดสอบ health check
- [ ] ทดสอบ approve API
- [ ] ทดสอบ arrivals API
- [ ] ทดสอบ frontend integration

## 🚨 Common Issues

### Issue 1: Build Timeout

**Error**: `Build exceeded time limit`

**Fix**:
1. ไปที่ Render Dashboard
2. Settings → Build & Deploy
3. เพิ่ม Build Timeout เป็น 10 minutes

### Issue 2: Database Connection Failed

**Error**: `failed to connect to database`

**Fix**:
1. ตรวจสอบ `DATABASE_URL` ใน Environment Variables
2. ตรวจสอบ database ยัง active อยู่
3. ทดสอบ connection:
   ```bash
   psql "postgresql://..."
   ```

### Issue 3: CORS Error

**Error**: `CORS policy blocked`

**Fix**:
1. ตรวจสอบ `ALLOWED_ORIGINS` ใน Environment Variables
2. ต้องมี: `https://booboo-booking.vercel.app`
3. ไม่มี `/` ท้าย URL
4. ไม่มีช่องว่าง

## 📝 Notes

- Render free tier อาจ sleep หลัง 15 นาที ไม่ใช้งาน
- First request หลัง sleep จะใช้เวลา 30-60 วินาที
- ถ้า deploy ล้มเหลว ลอง manual deploy
- ถ้ายังไม่ได้ ลอง redeploy from scratch

---

**อัพเดทล่าสุด**: 9 พฤศจิกายน 2025
