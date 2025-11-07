# ✅ Checklist การ Deploy ไปยัง Vercel

## ก่อน Deploy

- [ ] ตรวจสอบว่าโค้ดทำงานได้ถูกต้องใน local environment
- [ ] ตรวจสอบว่า backend API (Render) ทำงานปกติ
- [ ] ตรวจสอบว่าไฟล์ `.env.production` มีค่าที่ถูกต้อง

## ตั้งค่า Vercel Environment Variables

ไปที่: **Vercel Dashboard → booboo-booking → Settings → Environment Variables**

### Required Variables (ต้องมี)

- [ ] `NEXTAUTH_URL` = `https://booboo-booking.vercel.app`
- [ ] `NEXTAUTH_SECRET` = `IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=`
- [ ] `NEXT_PUBLIC_API_URL` = `https://booboo-booking.onrender.com`
- [ ] `BACKEND_URL` = `https://booboo-booking.onrender.com`
- [ ] `NODE_ENV` = `production`

### Optional Variables (ไม่บังคับ)

- [ ] `NEXT_PUBLIC_DEBUG` = `false`
- [ ] `NEXT_PUBLIC_LOG_API` = `false`

## Deploy

### Option 1: Auto Deploy (แนะนำ)

```bash
# Commit และ push โค้ด
git add .
git commit -m "fix: แก้ไขปัญหา manager login redirect"
git push origin main
```

Vercel จะ auto-deploy ภายใน 1-2 นาที

### Option 2: Manual Deploy

```bash
# ติดตั้ง Vercel CLI (ถ้ายังไม่มี)
npm install -g vercel

# Login
vercel login

# Deploy
cd frontend
vercel --prod
```

## หลัง Deploy

### ทดสอบ Manager Login

- [ ] ไปที่ `https://booboo-booking.vercel.app/auth/admin`
- [ ] Login ด้วย manager account:
  - Email: `manager@hotel.com`
  - Password: `Manager123!`
- [ ] ตรวจสอบว่า redirect ไป `/admin/dashboard` ทันที (ไม่ค้าง)
- [ ] ตรวจสอบว่า dashboard แสดงข้อมูลถูกต้อง

### ทดสอบ Receptionist Login

- [ ] Login ด้วย receptionist account:
  - Email: `receptionist@hotel.com`
  - Password: `Receptionist123!`
- [ ] ตรวจสอบว่า redirect ไป `/admin/reception`

### ทดสอบ Housekeeper Login

- [ ] Login ด้วย housekeeper account:
  - Email: `housekeeper@hotel.com`
  - Password: `Housekeeper123!`
- [ ] ตรวจสอบว่า redirect ไป `/admin/housekeeping`

### ทดสอบ Guest Login

- [ ] ไปที่ `https://booboo-booking.vercel.app/auth/signin`
- [ ] Login ด้วย guest account หรือสร้างบัญชีใหม่
- [ ] ตรวจสอบว่า redirect ไป `/` (home page)

### ตรวจสอบ Console Logs

- [ ] เปิด Browser DevTools (F12)
- [ ] ดู Console tab
- [ ] ตรวจสอบว่าไม่มี error สีแดง
- [ ] ควรเห็น logs:
  ```
  [Admin Login] Valid staff role: MANAGER redirecting to: /admin/dashboard
  [Middleware] User role: MANAGER
  [Middleware] Access granted
  ```

### ทดสอบ Functionality

- [ ] ทดสอบการจองห้อง (Guest)
- [ ] ทดสอบการอนุมัติการจอง (Manager)
- [ ] ทดสอบการเช็คอิน (Receptionist)
- [ ] ทดสอบการอัปเดตสถานะห้อง (Housekeeper)

## หากมีปัญหา

### ปัญหา: ยังค้างที่หน้า signin

**แก้ไข:**
1. ตรวจสอบว่า `NEXTAUTH_URL` ตั้งค่าถูกต้องบน Vercel
2. Clear browser cache (Ctrl + Shift + Delete)
3. ลองใน Incognito/Private mode
4. ตรวจสอบ Vercel Function Logs

### ปัญหา: Error 500 หรือ API ไม่ทำงาน

**แก้ไข:**
1. ตรวจสอบว่า backend (Render) ทำงานปกติ
2. ตรวจสอบ `NEXT_PUBLIC_API_URL` และ `BACKEND_URL`
3. ดู Vercel Function Logs เพื่อหา error

### ปัญหา: Session หาย

**แก้ไข:**
1. ตรวจสอบ `NEXTAUTH_SECRET` ตั้งค่าถูกต้อง
2. ตรวจสอบว่า cookie ไม่ถูก block
3. ลอง logout และ login ใหม่

## ดู Logs

### Vercel Logs
1. ไปที่ Vercel Dashboard
2. เลือก project `booboo-booking`
3. คลิก **Deployments**
4. คลิกที่ deployment ล่าสุด
5. คลิก **View Function Logs**

### Browser Console
1. เปิด Browser DevTools (F12)
2. ไปที่ **Console** tab
3. ดู logs และ errors

## เสร็จสิ้น

เมื่อทดสอบทุกอย่างเรียบร้อยแล้ว:

- [ ] แจ้งทีมว่า deploy เสร็จแล้ว
- [ ] อัปเดตเอกสาร (ถ้าจำเป็น)
- [ ] Monitor logs เป็นเวลา 24 ชั่วโมงแรก

---

**หมายเหตุ:** ถ้ามีปัญหาใดๆ ให้ดูรายละเอียดเพิ่มเติมที่ `frontend/VERCEL_REDIRECT_FIX.md`
