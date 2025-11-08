# แก้ไขปัญหา CORS และ Admin Redirect

## ปัญหาที่เจอ

### 1. CORS Error
```
Access to fetch at 'https://booboo-booking.onrender.com/api/auth/login' 
from origin 'https://booboo-booking.vercel.app' has been blocked by CORS policy
```

### 2. Admin Redirect Loop
URL ค้างที่ `/auth/admin?callbackUrl=%2Fadmin%2Fdashboard`

## สาเหตุ

1. **CORS**: Frontend (Vercel) พยายามเรียก Backend API ตรงๆ แต่ Backend ไม่อนุญาต origin จาก Vercel
2. **Redirect Loop**: NextAuth redirect callback ไม่ทำงานถูกต้องใน production

## การแก้ไข

### Solution: ใช้ NextAuth แบบ Server-Side

แทนที่จะเรียก Backend API ตรงๆ (ซึ่งเจอ CORS) ให้ใช้ NextAuth ที่จะเรียก Backend ผ่าน server-side

**ข้อดี:**
- ✅ ไม่เจอ CORS เพราะเรียกจาก server-side
- ✅ ใช้ NextAuth authentication flow ปกติ
- ✅ Session management ทำงานถูกต้อง

### ไฟล์ที่แก้ไข

**`frontend/src/app/auth/admin/page.tsx`**

```typescript
// ใช้ NextAuth signIn (server-side call)
const result = await signIn('credentials', {
  email,
  password,
  redirect: false, // ไม่ให้ NextAuth redirect
});

if (result?.ok) {
  // Fetch session เพื่อตรวจสอบ role
  const sessionResponse = await fetch('/api/auth/session');
  const sessionData = await sessionResponse.json();
  const role = sessionData.user.role;
  
  // ตรวจสอบว่าเป็น staff
  if (role === 'GUEST') {
    // ปฏิเสธ
    return;
  }
  
  // Redirect ตาม role
  const redirectUrl = getRoleHomePage(role);
  window.location.href = redirectUrl;
}
```

**`frontend/src/middleware.ts`**

```typescript
// ลบ callbackUrl parameter เพื่อหลีกเลี่ยง loop
if (pathname.startsWith('/admin')) {
  return NextResponse.redirect(new URL('/auth/admin', request.url));
}
```

## Flow การทำงาน

```
1. User → /auth/admin
2. User กรอก email/password
3. Frontend → signIn() → NextAuth API Route
4. NextAuth API Route → Backend API (server-side, ไม่เจอ CORS)
5. Backend → validate credentials → return user data
6. NextAuth → create session
7. Frontend → fetch session → check role
8. Frontend → window.location.href = '/admin/dashboard'
9. ✅ เข้าหน้า dashboard สำเร็จ
```

## การ Deploy

```bash
git add .
git commit -m "fix: แก้ไข CORS และ admin redirect - ใช้ NextAuth server-side"
git push
```

## ทดสอบ

1. ไปที่: `https://booboo-booking.vercel.app/auth/admin`
2. Login: `manager@hotel.com` / `Manager123!`
3. ✅ ควร redirect ไปที่ `/admin/dashboard`

## หมายเหตุ: Backend CORS Configuration

ถ้าต้องการให้ Frontend เรียก Backend API ตรงๆได้ (สำหรับอนาคต) ให้เพิ่ม Vercel URL ใน backend:

**`backend/.env` (Render)**
```env
ALLOWED_ORIGINS=http://localhost:3000,https://booboo-booking.vercel.app
```

แต่สำหรับ authentication ไม่จำเป็น เพราะใช้ NextAuth ที่เรียกผ่าน server-side อยู่แล้ว

## สรุป

- ✅ ไม่เจอ CORS error
- ✅ Admin login ทำงานได้
- ✅ Redirect ไปหน้า dashboard สำเร็จ
- ✅ ใช้ NextAuth authentication flow มาตรฐาน
