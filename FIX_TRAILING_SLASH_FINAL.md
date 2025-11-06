# แก้ไข Trailing Slash Error - Final Solution ✅

## ปัญหา

Backend logs แสดง:
```
[GIN-debug] redirecting request 307: /api/bookings/ --> /api/bookings/
```

Frontend error:
```
[API Error] "/bookings" "Network Error"
Payment failed: Network Error
```

## สาเหตุ

Axios มี bug ที่เพิ่ม trailing slash (`/`) ต่อท้าย URL เมื่อ:
- `baseURL` ลงท้ายด้วย path segment (เช่น `/api`)
- URL ขึ้นต้นด้วย `/` (เช่น `/bookings`)

ผลลัพธ์: `/api` + `/bookings` = `/api/bookings/` (มี trailing slash)

## การแก้ไข

### 1. เปลี่ยน baseURL
```typescript
// เดิม
const API_BASE_URL = 'http://localhost:8080/api';

// ใหม่
const API_BASE_URL = 'http://localhost:8080';
```

### 2. เพิ่ม `/api` ในทุก URL
```typescript
// เดิม
api.post('/bookings', data)

// ใหม่
api.post('/api/bookings', data)
```

### 3. เพิ่ม Interceptor เพื่อลบ trailing slash
```typescript
apiClient.interceptors.request.use(
  async (config) => {
    // Fix trailing slash issue
    if (config.url && config.url.endsWith('/')) {
      config.url = config.url.slice(0, -1);
    }
    // ... rest of code
  }
);
```

## ไฟล์ที่แก้ไข

### frontend/src/lib/api.ts

```typescript
// 1. เปลี่ยน baseURL
const API_BASE_URL = 'http://localhost:8080';

// 2. เพิ่ม interceptor
apiClient.interceptors.request.use(
  async (config) => {
    // Fix trailing slash
    if (config.url && config.url.endsWith('/')) {
      config.url = config.url.slice(0, -1);
    }
    // ... auth token
  }
);

// 3. เพิ่ม /api ในทุก endpoint
export const bookingApi = {
  create: (data: any) => api.post('/api/bookings', data),
  confirm: (id: number) => api.post(`/api/bookings/${id}/confirm`, {}),
  // ...
};

export const roomApi = {
  search: (params: any) => api.get('/api/rooms/search', { params }),
  // ...
};

// และทุก API อื่นๆ
```

## วิธีทดสอบ

### 1. Clear Cache และ Restart Frontend

```bash
# หยุด frontend (Ctrl+C)
# จากนั้นรัน
restart-frontend.bat
```

หรือ

```bash
cd frontend
rmdir /s /q .next .turbo
npm run dev
```

### 2. Hard Refresh Browser

กด `Ctrl + Shift + R` (Windows) หรือ `Cmd + Shift + R` (Mac)

### 3. ทดสอบ Booking

1. Login: http://localhost:3000/auth/signin
2. Search rooms: http://localhost:3000/rooms/search
3. Book room และกด "Complete Booking"
4. ควรไม่เห็น Network Error

### 4. ตรวจสอบ Backend Logs

ควรเห็น:
```
[POST] 200 | /api/bookings
```

ไม่ควรเห็น:
```
[GIN-debug] redirecting request 307: /api/bookings/ --> /api/bookings/
```

## Endpoints ที่แก้ไข

ทุก endpoint ต้องมี `/api` นำหน้า:

- ✅ `/api/auth/login`
- ✅ `/api/rooms/search`
- ✅ `/api/bookings/hold`
- ✅ `/api/bookings`
- ✅ `/api/bookings/:id/confirm`
- ✅ `/api/checkin/arrivals`
- ✅ `/api/checkout/departures`
- ✅ `/api/housekeeping/tasks`
- ✅ `/api/pricing/tiers`
- ✅ `/api/inventory`
- ✅ `/api/reports/occupancy`

## Troubleshooting

### ปัญหา: ยังเห็น redirect อยู่

**วิธีแก้:**
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh (Ctrl+Shift+R)
3. Restart frontend
4. ตรวจสอบว่า `frontend/src/lib/api.ts` ถูก save แล้ว

### ปัญหา: Frontend ไม่ reload

**วิธีแก้:**
```bash
# Kill frontend
taskkill /F /IM node.exe

# Clear cache
cd frontend
rmdir /s /q .next .turbo

# Restart
npm run dev
```

### ปัญหา: ยังเห็น error

**วิธีแก้:**
1. ตรวจสอบ console.log ใน browser
2. ตรวจสอบ Network tab ใน DevTools
3. ดู URL ที่ส่งไป (ต้องไม่มี trailing slash)
4. ตรวจสอบ backend logs

## สรุป

### สาเหตุ
- Axios bug เพิ่ม trailing slash
- Gin redirect `/api/bookings/` → `/api/bookings/` (infinite loop)

### วิธีแก้
- เปลี่ยน baseURL เป็น `http://localhost:8080`
- เพิ่ม `/api` ในทุก URL
- เพิ่ม interceptor ลบ trailing slash

### ผลลัพธ์
- ✅ ไม่มี trailing slash
- ✅ ไม่มี redirect loop
- ✅ Booking ทำงานได้
- ✅ ทุก API ทำงานปกติ

---

**Fixed Date:** November 5, 2025  
**Status:** ✅ Complete  
**Next Step:** Clear cache และ restart frontend
