# Quick Fix Reference Card

## 🚀 Deploy ไปยัง Production

```bash
cd frontend
npm run build          # ทดสอบ build
git add .
git commit -m "fix: admin redirect และ SSR error"
git push              # Vercel auto deploy
```

## 🧪 ทดสอบ Admin Login

### Manager
```
URL: /auth/admin
Email: manager@hotel.com
Password: Manager123!
Expected: → /admin/dashboard
```

### Receptionist
```
URL: /auth/admin
Email: receptionist@hotel.com
Password: Reception123!
Expected: → /admin/reception
```

### Housekeeper
```
URL: /auth/admin
Email: housekeeper@hotel.com
Password: Housekeeper123!
Expected: → /admin/housekeeping
```

## 🔧 Environment Variables (Vercel)

```env
NEXT_PUBLIC_API_URL=https://your-backend.onrender.com
BACKEND_URL=https://your-backend.onrender.com
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=<generate-with-openssl>
NODE_ENV=production
```

Generate secret:
```bash
openssl rand -base64 32
```

## 🐛 Troubleshooting

### Redirect Loop
1. ตรวจสอบ `NEXTAUTH_URL` ใน Vercel
2. ตรวจสอบ `NEXTAUTH_SECRET` ตั้งค่าแล้ว
3. Clear cookies
4. ดู Vercel logs

### Build Error
1. ตรวจสอบ TypeScript errors
2. ตรวจสอบ SSR compatibility
3. ดู build logs ใน Vercel

### API Connection Failed
1. ตรวจสอบ `NEXT_PUBLIC_API_URL`
2. Test backend: `curl https://backend/api/health`
3. ตรวจสอบ CORS settings
4. ดู Network tab

## 📝 ไฟล์ที่แก้ไข

- ✅ `frontend/src/middleware.ts`
- ✅ `frontend/src/lib/auth.ts`
- ✅ `frontend/src/app/auth/admin/page.tsx`
- ✅ `frontend/src/app/(guest)/booking/payment/page.tsx`

## 📚 เอกสารเพิ่มเติม

- `PRODUCTION_REDIRECT_FIX.md` - รายละเอียดเต็ม
- `VERCEL_DEPLOYMENT_CHECKLIST.md` - deployment checklist
- `แก้ไขปัญหา_Admin_Redirect_สำเร็จ.md` - สรุปภาษาไทย
