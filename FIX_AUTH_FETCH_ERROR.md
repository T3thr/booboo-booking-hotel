# Fix NextAuth "Failed to fetch" Error

## ปัญหา
หลังจาก restart frontend เกิด error:
```
ClientFetchError: Failed to fetch
```

## สาเหตุที่เป็นไปได้

### 1. Backend ไม่ได้รัน
ตรวจสอบว่า backend กำลังรันอยู่:
```cmd
curl http://localhost:8080/api/rooms/types
```

ถ้าไม่ได้รัน ให้เริ่ม backend:
```cmd
cd backend
go run cmd/server/main.go
```

### 2. Environment Variables ไม่ถูกโหลด
หลัง restart อาจจะต้องโหลด .env ใหม่

### 3. Cache ของ Next.js
Next.js อาจจะ cache config เก่า

## วิธีแก้ไข

### ขั้นตอนที่ 1: ตรวจสอบ Backend
```cmd
# ตรวจสอบว่า backend รันอยู่
curl http://localhost:8080/api/rooms/types

# ถ้าไม่ได้รัน ให้เริ่ม backend
cd backend
go run cmd/server/main.go
```

### ขั้นตอนที่ 2: Clear Cache และ Restart Frontend
```cmd
cd frontend

# ลบ .next cache
rmdir /s /q .next

# Restart
npm run dev
```

### ขั้นตอนที่ 3: ตรวจสอบ Environment Variables
ตรวจสอบว่า `frontend/.env` มีค่าถูกต้อง:
```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
BACKEND_URL=http://localhost:8080/api
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=
```

### ขั้นตอนที่ 4: ทดสอบ Login
1. เปิด browser ไปที่ `http://localhost:3000`
2. ลอง login ด้วย:
   - Email: `john.doe@example.com`
   - Password: `password123`
3. ตรวจสอบ console log (F12) ว่ามี error อะไร

## วิธีแก้ไขแบบเร็ว (Quick Fix)

### Windows:
```cmd
# หยุด frontend (Ctrl+C)

# Clear cache
cd frontend
rmdir /s /q .next

# Restart
npm run dev
```

### หรือใช้ script:
```cmd
restart-frontend.bat
```

## ตรวจสอบว่าแก้ไขสำเร็จ

### 1. Backend ตอบกลับ:
```cmd
curl http://localhost:8080/api/rooms/types
```
ควรเห็น JSON response

### 2. Frontend โหลดได้:
เปิด `http://localhost:3000` ควรเห็นหน้า homepage

### 3. Login ได้:
ลอง login ควรเข้าสู่ระบบได้โดยไม่มี "Failed to fetch" error

## หมายเหตุ

### เกี่ยวกับ trailingSlash
เราเพิ่งเปลี่ยน `trailingSlash: false` ใน `next.config.ts` ซึ่งต้อง restart และ clear cache:

```typescript
// next.config.ts
const nextConfig: NextConfig = {
  trailingSlash: false, // เปลี่ยนจาก true
  // ...
};
```

การเปลี่ยนนี้แก้ปัญหา trailing slash ใน API calls แต่ต้อง:
1. Restart frontend server
2. Clear .next cache
3. Hard refresh browser (Ctrl+Shift+R)

### ถ้ายังมีปัญหา
1. ตรวจสอบ browser console (F12) ดู error message
2. ตรวจสอบ frontend terminal ดู server logs
3. ตรวจสอบ backend terminal ดู API logs
4. ลอง hard refresh browser (Ctrl+Shift+R)
5. ลองใช้ incognito/private mode
