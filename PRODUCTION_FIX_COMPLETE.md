# แก้ไขปัญหา Production สำเร็จ - คู่มือ Deploy

## ปัญหาที่แก้ไข

### 1. ✅ CORS Error บน Production
- **ปัญหา**: Frontend (Vercel) ไม่สามารถเรียก API จาก Backend (Render) ได้
- **แก้ไข**: อัปเดต backend config ให้รองรับ multiple CORS origins

### 2. ✅ Check-in Page ไม่แสดงข้อมูล
- **ปัญหา**: API ไม่ส่งข้อมูล payment proof และ room_type_id
- **แก้ไข**: เพิ่มฟิลด์ใน ArrivalInfo model และ SQL query

## การแก้ไขที่ทำไปแล้ว

### Backend Changes:

1. **backend/internal/models/booking.go**
   - เพิ่มฟิลด์: `RoomTypeID`, `PaymentStatus`, `PaymentProofURL`, `PaymentProofID`

2. **backend/internal/repository/booking_repository.go**
   - อัปเดต SQL query ใน `GetArrivals()` ให้ JOIN กับ `payment_proofs` table
   - เพิ่ม SELECT fields ที่จำเป็น

3. **backend/pkg/config/config.go**
   - อัปเดตการ parse `ALLOWED_ORIGINS` ให้รองรับหลาย origins (คั่นด้วย comma)
   - เพิ่มฟังก์ชัน `splitAndTrim()` สำหรับ parse origins

## ขั้นตอนการ Deploy

### Step 1: Commit และ Push Code

```bash
# ตรวจสอบการเปลี่ยนแปลง
git status

# Add ไฟล์ที่แก้ไข
git add backend/internal/models/booking.go
git add backend/internal/repository/booking_repository.go
git add backend/pkg/config/config.go

# Commit
git commit -m "fix: Add payment proof fields to arrivals API and improve CORS config"

# Push to main branch
git push origin main
```

### Step 2: ตั้งค่า Environment Variables บน Render

1. ไปที่ https://dashboard.render.com
2. เลือก service: **booboo-booking** (backend)
3. ไปที่แท็บ **Environment**
4. เพิ่ม/แก้ไข environment variables:

```bash
# Required - CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,https://booboo-booking.vercel.app,https://booboo-booking-git-main.vercel.app

# Required - Database
DATABASE_URL=postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require

# Required - JWT
JWT_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=

# Required - Server
PORT=8080
GIN_MODE=release
ENVIRONMENT=production

# Optional
FRONTEND_URL=https://booboo-booking.vercel.app
REDIS_URL=
RATE_LIMIT_ENABLED=true
LOG_LEVEL=info
```

**สำคัญ**: 
- ใส่ทุก URL ของ Vercel ที่ต้องการให้เข้าถึง API ได้
- คั่นด้วย comma (,) ไม่มีช่องว่าง
- รวมทั้ง preview URLs ถ้าต้องการทดสอบ branches

5. กด **Save Changes**

### Step 3: รอ Backend Redeploy

- Render จะ redeploy อัตโนมัติเมื่อ push code ใหม่
- ใช้เวลาประมาณ 2-5 นาที
- ดูสถานะได้ที่แท็บ **Logs**

ตรวจสอบว่า deploy สำเร็จ:
```
Configuration loaded successfully
Database connection established
Starting server on 0.0.0.0:8080 (mode: release)
```

### Step 4: ตรวจสอบว่ามีข้อมูลใน Database

เชื่อมต่อ Neon database:
```bash
psql "postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
```

ตรวจสอบข้อมูล:
```sql
-- ดู bookings ที่ confirmed
SELECT 
    b.booking_id,
    b.status,
    bd.check_in_date,
    CONCAT(g.first_name, ' ', g.last_name) as guest_name,
    rt.name as room_type_name,
    COALESCE(pp.status, 'none') as payment_status
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE b.status IN ('Confirmed', 'CheckedIn')
ORDER BY bd.check_in_date;
```

ถ้าไม่มีข้อมูล ให้รัน seed:
```sql
\i database/migrations/020_seed_checkin_test_data.sql
```

หรือใช้ psql:
```bash
psql $DATABASE_URL -f database/migrations/020_seed_checkin_test_data.sql
```

### Step 5: ทดสอบ Production

#### 5.1 ทดสอบ CORS

เปิด browser console (F12) ที่ https://booboo-booking.vercel.app

```javascript
// ทดสอบ OPTIONS request
fetch('https://booboo-booking.onrender.com/api/health', {
  method: 'OPTIONS',
  headers: {
    'Origin': 'https://booboo-booking.vercel.app'
  }
}).then(r => console.log('CORS OK:', r.status))
```

#### 5.2 ทดสอบ Room Status API

1. Login ที่ https://booboo-booking.vercel.app/auth/admin
   - Username: `manager@hotel.com`
   - Password: `Manager123!`

2. ไปที่ https://booboo-booking.vercel.app/admin/reception

3. เปิด Developer Console (F12) และดู Network tab

4. ตรวจสอบว่า:
   - ✅ Request ไป `/api/rooms/status` สำเร็จ (status 200)
   - ✅ ไม่มี CORS error
   - ✅ ข้อมูลห้องแสดงขึ้นมา

#### 5.3 ทดสอบ Check-in API

1. ไปที่ https://booboo-booking.vercel.app/admin/checkin

2. เลือกวันที่ที่มีการจอง (เช่น วันนี้หรือพรุ่งนี้)

3. ตรวจสอบว่า:
   - ✅ แสดงรายการแขกที่จะมาถึง
   - ✅ แสดงข้อมูล payment status
   - ✅ สามารถดูหลักฐานการชำระเงินได้ (ถ้ามี)
   - ✅ สามารถเลือกห้องและเช็คอินได้

## การทดสอบด้วย curl

### ทดสอบ Health Check:
```bash
curl https://booboo-booking.onrender.com/health
```

### ทดสอบ CORS:
```bash
curl -X OPTIONS https://booboo-booking.onrender.com/api/rooms/status \
  -H "Origin: https://booboo-booking.vercel.app" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

ควรเห็น headers:
```
< Access-Control-Allow-Origin: https://booboo-booking.vercel.app
< Access-Control-Allow-Credentials: true
< Access-Control-Allow-Methods: POST, OPTIONS, GET, PUT, DELETE, PATCH
```

### ทดสอบ Arrivals API:
```bash
# Get token first by logging in
TOKEN="your_jwt_token"

curl "https://booboo-booking.onrender.com/api/checkin/arrivals?date=2025-01-15" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Origin: https://booboo-booking.vercel.app"
```

Expected response:
```json
{
  "arrivals": [
    {
      "booking_id": 1,
      "booking_detail_id": 1,
      "guest_name": "John Doe",
      "room_type_name": "Deluxe Room",
      "room_type_id": 1,
      "check_in_date": "2025-01-15T00:00:00Z",
      "check_out_date": "2025-01-17T00:00:00Z",
      "num_guests": 2,
      "status": "Confirmed",
      "payment_status": "approved",
      "payment_proof_url": "https://...",
      "payment_proof_id": 1
    }
  ],
  "count": 1
}
```

## Troubleshooting

### ถ้ายังมี CORS Error:

1. ตรวจสอบ Render Logs:
   ```
   https://dashboard.render.com/web/[service-id]/logs
   ```

2. ตรวจสอบว่า `ALLOWED_ORIGINS` ถูกต้อง:
   - ไม่มีช่องว่างระหว่าง URLs
   - มี `https://` prefix
   - ไม่มี trailing slash

3. ลอง Manual Deploy:
   - ไปที่ Render Dashboard
   - กด **Manual Deploy** > **Deploy latest commit**

4. Clear browser cache:
   - กด Ctrl+Shift+Delete
   - Clear cache และ reload

### ถ้า Check-in ไม่แสดงข้อมูล:

1. ตรวจสอบว่ามี bookings ใน database:
   ```sql
   SELECT COUNT(*) FROM bookings WHERE status = 'Confirmed';
   ```

2. ตรวจสอบว่า payment_proofs table มีอยู่:
   ```sql
   \dt payment_proofs
   ```

3. ถ้าไม่มี ให้รัน migration:
   ```bash
   psql $DATABASE_URL -f database/migrations/015_create_payment_proof_table.sql
   ```

4. Seed test data:
   ```bash
   psql $DATABASE_URL -f database/migrations/020_seed_checkin_test_data.sql
   ```

### ถ้า Backend ไม่ start:

1. ตรวจสอบ Render Logs หา error messages

2. ตรวจสอบว่า DATABASE_URL ถูกต้อง:
   - ต้องเป็น pooled connection string จาก Neon
   - มี `?sslmode=require` ท้าย URL

3. ตรวจสอบว่า Go build สำเร็จ:
   ```
   go build -o main ./cmd/server
   ```

## สรุป

### ✅ สิ่งที่แก้ไขแล้ว:

1. **CORS Configuration**: Backend รองรับหลาย origins แล้ว
2. **Arrivals API**: ส่งข้อมูล payment proof และ room_type_id แล้ว
3. **Code Quality**: ปรับปรุง config parsing ให้ robust ขึ้น

### 📋 Checklist สำหรับ Production:

- [ ] Push code ไป GitHub
- [ ] ตั้งค่า ALLOWED_ORIGINS บน Render
- [ ] รอ backend redeploy สำเร็จ
- [ ] ตรวจสอบว่ามีข้อมูลใน database
- [ ] ทดสอบ CORS ด้วย browser console
- [ ] ทดสอบ Room Status page
- [ ] ทดสอบ Check-in page
- [ ] ทดสอบ Check-in workflow ทั้งหมด

### 🎯 Next Steps:

1. Monitor Render logs สำหรับ errors
2. ทดสอบ user workflows ทั้งหมด
3. เพิ่ม test data ถ้าจำเป็น
4. Setup monitoring/alerting (optional)

## ติดต่อ Support

ถ้ามีปัญหา:
1. ตรวจสอบ Render Logs
2. ตรวจสอบ Browser Console
3. ตรวจสอบ Network tab ใน DevTools
4. ดู error messages ใน database logs
