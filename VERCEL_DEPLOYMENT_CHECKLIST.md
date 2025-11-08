# Vercel Deployment Checklist

## ก่อน Deploy

### 1. ตรวจสอบ Environment Variables ใน Vercel

ไปที่ Vercel Dashboard → Project Settings → Environment Variables

ตั้งค่าตัวแปรต่อไปนี้:

#### Required Variables
```
NEXT_PUBLIC_API_URL=https://your-backend.onrender.com
BACKEND_URL=https://your-backend.onrender.com
NEXTAUTH_URL=https://your-frontend.vercel.app
NEXTAUTH_SECRET=<your-secret-key>
NODE_ENV=production
```

#### Generate NEXTAUTH_SECRET
```bash
# Windows (PowerShell)
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))

# Linux/Mac
openssl rand -base64 32
```

### 2. ตรวจสอบ Backend API

ตรวจสอบว่า backend API ทำงานได้:
```bash
curl https://your-backend.onrender.com/api/health
```

ควรได้ response:
```json
{
  "status": "ok",
  "timestamp": "..."
}
```

### 3. ทดสอบ Build ใน Local

```bash
cd frontend
npm run build
```

ถ้า build สำเร็จ ไม่มี error → พร้อม deploy!

## การ Deploy

### Option 1: Auto Deploy (แนะนำ)

1. Commit และ push code:
```bash
git add .
git commit -m "fix: แก้ไข admin redirect และ SSR error"
git push
```

2. Vercel จะ auto deploy ทันที
3. ตรวจสอบ deployment status ที่ Vercel Dashboard

### Option 2: Manual Deploy

```bash
cd frontend
npm run deploy-vercel-fix.bat
```

## หลัง Deploy

### 1. ทดสอบ Guest Flow

1. ไปที่ `https://your-frontend.vercel.app`
2. ค้นหาห้องพัก
3. ทำการจอง
4. ตรวจสอบว่าทุกขั้นตอนทำงานได้

### 2. ทดสอบ Admin Login (Manager)

1. ไปที่ `https://your-frontend.vercel.app/auth/admin`
2. Login ด้วย:
   - Email: `manager@hotel.com`
   - Password: `Manager123!`
3. ✅ ควร redirect ไปที่ `/admin/dashboard`
4. ✅ ไม่ควรเกิด redirect loop
5. ✅ ไม่ควรไปที่ `/auth/signin?callbackUrl=...`

### 3. ทดสอบ Admin Login (Receptionist)

1. ไปที่ `https://your-frontend.vercel.app/auth/admin`
2. Login ด้วย:
   - Email: `receptionist@hotel.com`
   - Password: `Reception123!`
3. ✅ ควร redirect ไปที่ `/admin/reception`

### 4. ทดสอบ Admin Login (Housekeeper)

1. ไปที่ `https://your-frontend.vercel.app/auth/admin`
2. Login ด้วย:
   - Email: `housekeeper@hotel.com`
   - Password: `Housekeeper123!`
3. ✅ ควร redirect ไปที่ `/admin/housekeeping`

### 5. ทดสอบ Payment Page

1. ทำการจองห้องพัก
2. ไปที่หน้า Payment
3. ✅ หน้าควรโหลดได้ไม่มี error
4. ✅ สามารถอัปโหลดรูปภาพได้
5. ✅ Timer countdown ทำงานได้

## Troubleshooting

### ปัญหา: Redirect Loop

**อาการ:**
- Login แล้ว redirect กลับไปที่ `/auth/signin?callbackUrl=...`
- หน้าจอค้าง

**แก้ไข:**
1. ตรวจสอบ `NEXTAUTH_URL` ใน Vercel ว่าตรงกับ domain จริง
2. ตรวจสอบ `NEXTAUTH_SECRET` ว่าตั้งค่าแล้ว
3. Clear cookies และลองใหม่
4. ตรวจสอบ Vercel logs:
   ```
   Vercel Dashboard → Deployments → Latest → Logs
   ```

### ปัญหา: Build Error

**อาการ:**
- Vercel build failed
- Error: `ReferenceError: location is not defined`

**แก้ไข:**
1. ตรวจสอบว่าไฟล์ทั้งหมดใช้ `useEffect` สำหรับ browser API
2. ตรวจสอบว่าไม่มีการใช้ `window`, `document`, `location` นอก useEffect
3. ดู build logs ใน Vercel

### ปัญหา: API Connection Failed

**อาการ:**
- Frontend โหลดได้ แต่ไม่สามารถดึงข้อมูลจาก backend

**แก้ไข:**
1. ตรวจสอบ `NEXT_PUBLIC_API_URL` ใน Vercel
2. ตรวจสอบว่า backend ทำงานอยู่:
   ```bash
   curl https://your-backend.onrender.com/api/health
   ```
3. ตรวจสอบ CORS settings ใน backend
4. ตรวจสอบ Network tab ใน browser DevTools

### ปัญหา: Session Not Persisting

**อาการ:**
- Login สำเร็จแต่ refresh แล้ว logout

**แก้ไข:**
1. ตรวจสอบ `NEXTAUTH_SECRET` ว่าตั้งค่าแล้ว
2. ตรวจสอบ cookie settings:
   - ใน production ต้องใช้ HTTPS
   - Cookie `Secure` flag ต้องเป็น true
3. ตรวจสอบ browser cookies ว่ามี `next-auth.session-token`

## Monitoring

### Vercel Analytics

1. ไปที่ Vercel Dashboard → Analytics
2. ตรวจสอบ:
   - Page load time
   - Error rate
   - Traffic

### Vercel Logs

1. ไปที่ Vercel Dashboard → Deployments → Latest → Logs
2. ดู real-time logs:
   - API calls
   - Errors
   - Warnings

### Browser DevTools

1. เปิด DevTools (F12)
2. ตรวจสอบ:
   - Console: JavaScript errors
   - Network: API calls
   - Application: Cookies, Local Storage

## Rollback

ถ้าเกิดปัญหาหลัง deploy:

1. ไปที่ Vercel Dashboard → Deployments
2. เลือก deployment ก่อนหน้า
3. คลิก "Promote to Production"
4. Vercel จะ rollback ทันที

## Performance Optimization

### 1. Enable Caching

ใน `next.config.ts`:
```typescript
const nextConfig = {
  // ... existing config
  headers: async () => [
    {
      source: '/:path*',
      headers: [
        {
          key: 'Cache-Control',
          value: 'public, max-age=3600, must-revalidate',
        },
      ],
    },
  ],
};
```

### 2. Enable Compression

Vercel เปิด gzip/brotli compression โดยอัตโนมัติ

### 3. Image Optimization

ใช้ Next.js Image component:
```tsx
import Image from 'next/image';

<Image 
  src="/image.jpg" 
  width={500} 
  height={300} 
  alt="Description"
/>
```

## Security Checklist

- ✅ `NEXTAUTH_SECRET` ตั้งค่าแล้วและมีความยาวอย่างน้อย 32 ตัวอักษร
- ✅ `NODE_ENV=production`
- ✅ ไม่มี sensitive data ใน client-side code
- ✅ API endpoints ใช้ authentication
- ✅ CORS ตั้งค่าถูกต้อง
- ✅ Rate limiting เปิดใช้งาน
- ✅ HTTPS เปิดใช้งาน (Vercel เปิดโดยอัตโนมัติ)

## Support

หากพบปัญหา:

1. ตรวจสอบ Vercel logs
2. ตรวจสอบ browser console
3. ตรวจสอบ Network tab
4. ดู documentation: https://nextjs.org/docs
5. ดู Vercel docs: https://vercel.com/docs
