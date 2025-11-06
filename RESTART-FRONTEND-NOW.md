# ⚠️ ต้อง RESTART FRONTEND ทันที!

## ปัญหา
Room search ยังได้ 404 error เพราะ frontend ยังใช้ environment variable เก่า

## สาเหตุ
แก้ไข `frontend/.env` แล้ว แต่ยังไม่ได้ restart frontend
- Frontend ต้อง restart เพื่อโหลด environment variables ใหม่
- Next.js ไม่ hot reload environment variables

## วิธีแก้ (ทำทันที!)

### 1. หยุด Frontend
กด `Ctrl + C` ใน terminal ที่รัน frontend

### 2. Restart Frontend
```bash
cd frontend
npm run dev
```

### 3. รอจนเห็น
```
✓ Ready in X.Xs
○ Local:   http://localhost:3000
```

### 4. ทดสอบ
1. เปิด http://localhost:3000/rooms/search
2. เลือกวันที่:
   - Check-in: พรุ่งนี้ (2025-11-05)
   - Check-out: มะรืนนี้ (2025-11-06)
   - จำนวนผู้เข้าพัก: 2
3. กดปุ่ม "ค้นหา"
4. ควรเห็นห้อง 3 ประเภท:
   - Standard Room - ฿1,500/คืน
   - Deluxe Room - ฿2,500/คืน
   - Suite Room - ฿4,500/คืน

## ตรวจสอบว่า Backend ทำงาน ✅
```bash
curl http://localhost:8080/health
# ควรเห็น: {"status":"ok","message":"Hotel Booking System API is running"}

curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-05&checkOut=2025-11-06&guests=2"
# ควรเห็นข้อมูลห้อง 3 ประเภท
```

## ถ้ายังไม่ได้

### ตรวจสอบ .env
```bash
cd frontend
type .env
```
ควรเห็น:
```
NEXT_PUBLIC_API_URL=http://localhost:8080/api
BACKEND_URL=http://localhost:8080/api
```

### ตรวจสอบ Console Log
เปิด Browser DevTools (F12) → Console
ควรเห็น:
```
[Room Search Proxy] Calling backend: http://localhost:8080/api/rooms/search?...
[Room Search Proxy] Success, found rooms: 3
```

### ถ้ายังเห็น Error
1. Clear browser cache (Ctrl + Shift + Delete)
2. Hard refresh (Ctrl + Shift + R)
3. Restart browser

## สรุป
✅ Backend ทำงานปกติ (มีข้อมูลห้อง 3 ประเภท)
✅ Environment variable แก้ไขแล้ว
⚠️ **ต้อง RESTART FRONTEND เท่านั้น!**
