# แก้ไขปัญหา Admin Login Redirect และ Build Error

## ปัญหาที่พบ

### 1. Redirect Loop ใน Production
- เมื่อ Manager login ผ่าน `/auth/admin` แล้ว redirect ไปที่ `/auth/signin?callbackUrl=%2Fadmin%2Fdashboard`
- หน้าจอค้างและไม่สามารถเข้า dashboard ได้
- ทำงานปกติใน local แต่เกิดปัญหาใน Vercel production

### 2. Build Error: `ReferenceError: location is not defined`
- เกิดจากการใช้ browser API (`location`, `URL.createObjectURL`) ใน Server-Side Rendering
- ไฟล์: `frontend/src/app/(guest)/booking/payment/page.tsx`

## การแก้ไข

### 1. แก้ไข Middleware (`frontend/src/middleware.ts`)

**ปัญหา:** Middleware ไม่ได้แยก redirect สำหรับ admin routes

**แก้ไข:**
```typescript
// เพิ่มการตรวจสอบ API routes
if (pathname.startsWith('/api/')) {
  return NextResponse.next();
}

// แยก redirect สำหรับ admin routes
if (!token) {
  if (pathname.startsWith('/admin')) {
    const url = new URL('/auth/admin', request.url);
    url.searchParams.set('callbackUrl', pathname);
    return NextResponse.redirect(url);
  }
  // สำหรับ routes อื่นๆ ใช้ signin ปกติ
  const url = new URL('/auth/signin', request.url);
  url.searchParams.set('callbackUrl', pathname);
  return NextResponse.redirect(url);
}
```

### 2. แก้ไข NextAuth Redirect Callback (`frontend/src/lib/auth.ts`)

**ปัญหา:** Redirect callback ไม่ได้ป้องกันการ redirect กลับไปหน้า auth

**แก้ไข:**
```typescript
async redirect({ url, baseUrl }) {
  // ป้องกันการ redirect กลับไปหน้า auth
  if (url.includes('/auth/signin') || url.includes('/auth/admin')) {
    return baseUrl;
  }
  
  // ตรวจสอบ callbackUrl และไม่ให้เป็นหน้า auth
  const urlObj = new URL(url, baseUrl);
  const callbackUrl = urlObj.searchParams.get('callbackUrl');
  
  if (callbackUrl && callbackUrl.startsWith('/') && 
      !callbackUrl.includes('/auth/signin') && 
      !callbackUrl.includes('/auth/admin')) {
    return `${baseUrl}${callbackUrl}`;
  }
  
  // ตรวจสอบ URL ทั้งหมดไม่ให้เป็นหน้า auth
  if (url.startsWith(baseUrl) && !url.includes('/auth/')) {
    return url;
  }
  
  return baseUrl;
}
```

### 3. แก้ไข Admin Login Page (`frontend/src/app/auth/admin/page.tsx`)

**ปัญหา:** การ redirect ใน production ไม่เสถียร

**แก้ไข:**
```typescript
if (result?.ok) {
  // เพิ่มเวลารอให้ session ถูก set
  await new Promise(resolve => setTimeout(resolve, 800));
  
  // Fetch session พร้อม cache busting
  const response = await fetch('/api/auth/session?t=' + Date.now(), {
    cache: 'no-store',
    headers: {
      'Cache-Control': 'no-cache',
    }
  });
  
  const sessionData = await response.json();
  const role = sessionData.user.role;
  
  if (role === 'MANAGER' || role === 'RECEPTIONIST' || role === 'HOUSEKEEPER') {
    const redirectUrl = getRoleHomePage(role);
    
    // ใช้ window.location สำหรับ production
    if (typeof window !== 'undefined') {
      window.location.href = redirectUrl;
    } else {
      router.push(redirectUrl);
    }
    return;
  }
}
```

### 4. แก้ไข Payment Page (`frontend/src/app/(guest)/booking/payment/page.tsx`)

**ปัญหา:** ใช้ browser API ใน SSR ทำให้ build error

**แก้ไข:**
```typescript
// เพิ่ม state สำหรับตรวจสอบว่า component ถูก mount แล้ว
const [isMounted, setIsMounted] = useState(false);

useEffect(() => {
  setIsMounted(true);
}, []);

// Redirect เฉพาะฝั่ง client
useEffect(() => {
  if (isMounted && (!searchParams || !selectedRoomType || !guestInfo || !holdExpiry)) {
    router.push('/rooms/search');
  }
}, [isMounted, searchParams, selectedRoomType, guestInfo, holdExpiry, router]);

// แสดง loading ระหว่าง SSR
if (!isMounted || !searchParams || !selectedRoomType || !guestInfo || !holdExpiry) {
  return <LoadingSpinner />;
}

// ลบการตรวจสอบ typeof window ออกจาก URL.createObjectURL
// เพราะ function นี้ทำงานใน event handler (client-side เท่านั้น)
const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  const file = e.target.files?.[0];
  if (file) {
    try {
      const objectUrl = URL.createObjectURL(file);
      setPreviewUrl(objectUrl);
    } catch (err) {
      console.error('Failed to create object URL:', err);
    }
  }
};
```

## วิธีทดสอบ

### Local Testing
```bash
cd frontend
npm run build
npm run start
```

### Production Testing (Vercel)
1. Commit และ push การเปลี่ยนแปลง
2. รอ Vercel deploy เสร็จ
3. ทดสอบ login ด้วย Manager account:
   - Email: `manager@hotel.com`
   - Password: `Manager123!`
4. ตรวจสอบว่า redirect ไปที่ `/admin/dashboard` สำเร็จ

## สาเหตุของปัญหา

### Redirect Loop
1. **Session Timing**: ใน production, session ใช้เวลานานกว่าในการ set
2. **Middleware Check**: Middleware ตรวจสอบก่อน session พร้อม
3. **Redirect Chain**: NextAuth redirect → Middleware redirect → Loop

### Build Error
1. **SSR vs CSR**: Next.js render component ทั้งฝั่ง server และ client
2. **Browser API**: `location`, `URL.createObjectURL` มีเฉพาะใน browser
3. **Early Return**: Component return ก่อน hydration เสร็จ

## Best Practices

### 1. Client-Side Only Code
```typescript
// ใช้ useEffect สำหรับ client-side code
useEffect(() => {
  // Code ที่ใช้ browser API
}, []);

// หรือใช้ dynamic import
const ClientComponent = dynamic(() => import('./ClientComponent'), {
  ssr: false
});
```

### 2. Session Handling
```typescript
// รอให้ session พร้อมก่อน redirect
await new Promise(resolve => setTimeout(resolve, 800));

// ใช้ cache busting
fetch('/api/auth/session?t=' + Date.now(), {
  cache: 'no-store'
});
```

### 3. Redirect Strategy
```typescript
// ใช้ window.location สำหรับ production
if (typeof window !== 'undefined') {
  window.location.href = redirectUrl;
} else {
  router.push(redirectUrl);
}
```

## ไฟล์ที่แก้ไข

1. ✅ `frontend/src/middleware.ts` - แยก redirect สำหรับ admin
2. ✅ `frontend/src/lib/auth.ts` - ป้องกัน redirect loop
3. ✅ `frontend/src/app/auth/admin/page.tsx` - ปรับปรุงการ redirect
4. ✅ `frontend/src/app/(guest)/booking/payment/page.tsx` - แก้ SSR error

## ผลลัพธ์

- ✅ Manager สามารถ login และเข้า dashboard ได้ใน production
- ✅ ไม่มี redirect loop
- ✅ Build สำเร็จไม่มี error
- ✅ Payment page ทำงานได้ทั้ง SSR และ CSR
