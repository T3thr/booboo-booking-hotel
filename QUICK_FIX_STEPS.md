# วิธีแก้ปัญหา Housekeeper 403 Forbidden - ทำตามนี้เลย!

## ปัญหา
Housekeeper login สำเร็จ แต่เข้าหน้า `/housekeeping` แล้วได้ 403 Forbidden

## สาเหตุ
Backend ส่ง JWT token ที่มี `role: "staff"` แทนที่จะเป็น `role: "HOUSEKEEPER"`

## วิธีแก้ (3 ขั้นตอน)

### ขั้นตอนที่ 1: Rebuild Backend ⚙️

```bash
# รัน command นี้
fix-housekeeper-auth.bat
```

หรือ manual:
```bash
cd backend
go build -o server.exe ./cmd/server
cd ..
```

### ขั้นตอนที่ 2: Restart Backend 🔄

1. ไปที่ terminal ที่รัน backend
2. กด `Ctrl+C` เพื่อหยุด
3. รันใหม่:
```bash
cd backend
server.exe
```

### ขั้นตอนที่ 3: ทดสอบ ✅

1. เปิด browser ไปที่: `http://localhost:3000/auth/admin`
2. Login ด้วย:
   - Email: `housekeeper1@hotel.com`
   - Password: `staff123`
3. ควร redirect ไปที่ `/housekeeping` และเห็นรายการงานทำความสะอาด

## ตรวจสอบว่าแก้สำเร็จ

### วิธีที่ 1: ดู Network Tab
1. เปิด DevTools (F12)
2. ไปที่ Network tab
3. Refresh หน้า `/housekeeping`
4. ดู request `/api/housekeeping/tasks`
5. **ต้องได้ Status 200 OK** (ไม่ใช่ 403)

### วิธีที่ 2: ทดสอบด้วย curl
```bash
test-housekeeper-login.bat
```

ดู response ต้องมี:
```json
{
  "success": true,
  "data": {
    "role_code": "HOUSEKEEPER",  // ✅ ต้องเป็น HOUSEKEEPER
    "user_type": "staff",
    "accessToken": "..."
  }
}
```

## ถ้ายังไม่ได้

### 1. ตรวจสอบว่า rebuild แล้วจริงๆ
```bash
cd backend
dir server.exe
```
ดูวันที่ modified ต้องเป็นวันนี้

### 2. ตรวจสอบว่า restart แล้วจริงๆ
ดู backend terminal ต้องเห็น:
```
Starting server on :8080
```

### 3. Logout และ Login ใหม่
- ไปที่ `http://localhost:3000`
- Logout
- Login ใหม่ที่ `/auth/admin`

### 4. Clear Browser Cache
- กด F12
- Right-click Refresh button
- เลือก "Empty Cache and Hard Reload"

## ไฟล์ที่แก้ไขแล้ว

✅ `backend/internal/service/auth_service.go` - ส่ง role_code แทน user_type
✅ `frontend/src/utils/role-redirect.ts` - redirect ไป /housekeeping
✅ `frontend/src/middleware.ts` - ใช้ path ที่ถูกต้อง
✅ `frontend/src/lib/auth.ts` - ใช้ path ที่ถูกต้อง

## ต้องการความช่วยเหลือ?

อ่านเอกสารเพิ่มเติม: `HOUSEKEEPER_AUTH_FIX.md`
