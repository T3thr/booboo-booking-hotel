# แก้ไขปัญหา CORS สำหรับ Production (Vercel + Render)

## ปัญหา
```
Access to XMLHttpRequest at 'https://booboo-booking.onrender.com/api/rooms/status' 
from origin 'https://booboo-booking.vercel.app' has been blocked by CORS policy
```

## สาเหตุ
Backend บน Render.com ยังไม่ได้เพิ่ม Vercel domain เข้าไปใน ALLOWED_ORIGINS

## วิธีแก้ไข

### ขั้นตอนที่ 1: อัปเดต Environment Variables บน Render.com

1. ไปที่ https://dashboard.render.com
2. เลือก service: **hotel-booking-backend** (หรือ booboo-booking)
3. ไปที่แท็บ **Environment**
4. แก้ไขหรือเพิ่ม environment variable:

```bash
ALLOWED_ORIGINS=http://localhost:3000,https://booboo-booking.vercel.app,https://booboo-booking-git-main-your-username.vercel.app
```

**หมายเหตุ**: 
- เพิ่มทั้ง production URL และ preview URLs ของ Vercel
- คั่นด้วย comma (,) ไม่มีช่องว่าง
- ถ้ามี custom domain ให้เพิ่มเข้าไปด้วย

5. กด **Save Changes**
6. Render จะ redeploy backend อัตโนมัติ

### ขั้นตอนที่ 2: ตรวจสอบ Environment Variables อื่นๆ

ตรวจสอบว่ามี environment variables ต่อไปนี้:

```bash
# Required
PORT=8080
GIN_MODE=release
ENVIRONMENT=production
DATABASE_URL=postgresql://... (your Neon connection string)
JWT_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=

# CORS (สำคัญ!)
FRONTEND_URL=https://booboo-booking.vercel.app
ALLOWED_ORIGINS=http://localhost:3000,https://booboo-booking.vercel.app

# Optional
REDIS_URL=
RATE_LIMIT_ENABLED=true
LOG_LEVEL=info
```

### ขั้นตอนที่ 3: รอ Backend Redeploy

- Render จะ redeploy backend ใช้เวลาประมาณ 2-3 นาที
- ดูสถานะได้ที่แท็บ **Logs**
- รอจนเห็นข้อความ: `Starting server on 0.0.0.0:8080`

### ขั้นตอนที่ 4: ทดสอบ

1. เปิด https://booboo-booking.vercel.app/admin/reception
2. เปิด Developer Console (F12)
3. ดูว่า CORS error หายไปหรือไม่
4. ตรวจสอบว่าข้อมูลห้องโหลดขึ้นมา

## ตรวจสอบว่าแก้ไขสำเร็จ

### ทดสอบ CORS ด้วย curl:

```bash
curl -X OPTIONS https://booboo-booking.onrender.com/api/rooms/status \
  -H "Origin: https://booboo-booking.vercel.app" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

ควรเห็น response headers:
```
Access-Control-Allow-Origin: https://booboo-booking.vercel.app
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: POST, OPTIONS, GET, PUT, DELETE, PATCH
```

### ทดสอบ API endpoint:

```bash
# ต้องมี token จาก login ก่อน
curl https://booboo-booking.onrender.com/api/rooms/status \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Origin: https://booboo-booking.vercel.app"
```

## หมายเหตุสำคัญ

1. **Vercel Preview URLs**: ถ้า deploy branch ใหม่ Vercel จะสร้าง URL ใหม่ เช่น:
   - `https://booboo-booking-git-feature-branch.vercel.app`
   - ต้องเพิ่มเข้าไปใน ALLOWED_ORIGINS ด้วย

2. **Wildcard ไม่แนะนำ**: อย่าใช้ `*` ใน production เพราะไม่ปลอดภัย

3. **Custom Domain**: ถ้าใช้ custom domain ต้องเพิ่มเข้าไปด้วย:
   ```
   ALLOWED_ORIGINS=https://booboo-booking.vercel.app,https://www.yourdomain.com
   ```

## ถ้ายังไม่ได้

1. ตรวจสอบ Render Logs:
   ```
   https://dashboard.render.com/web/[your-service-id]/logs
   ```

2. ตรวจสอบว่า backend เริ่มต้นถูกต้อง:
   ```
   Configuration loaded successfully
   Database connection established
   Starting server on 0.0.0.0:8080
   ```

3. ลอง redeploy manual:
   - ไปที่ Render Dashboard
   - กด **Manual Deploy** > **Deploy latest commit**

4. Clear browser cache และ reload หน้าเว็บ

## สรุป

ปัญหา CORS เกิดจากการที่ backend ไม่รู้จัก origin ของ frontend
แก้ไขโดยการเพิ่ม Vercel URL เข้าไปใน ALLOWED_ORIGINS บน Render.com
