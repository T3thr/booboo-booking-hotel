# แก้ไขปัญหา "ห้องเต็มทุกห้อง" - Solution Complete

## 🔍 สาเหตุของปัญหา

ปัญหาเกิดจาก **database ไม่มีข้อมูล `room_inventory`** หรือมีแต่ `allotment = 0`

### Database Schema ที่ถูกต้อง
```sql
room_inventory (
    room_type_id,
    date,
    allotment,          -- จำนวนห้องทั้งหมดที่เปิดขาย
    booked_count,       -- จำนวนห้องที่จองแล้ว
    tentative_count     -- จำนวนห้องที่ hold ไว้
)

-- สูตรคำนวณห้องว่าง:
available = allotment - booked_count - tentative_count
```

### ที่มาของปัญหา
1. ไฟล์ `013_seed_demo_data.sql` สร้าง inventory แต่อาจมีปัญหา:
   - วันที่ไม่ครอบคลุมวันที่ค้นหา
   - `allotment` ถูกตั้งเป็น 0
   - ข้อมูลถูกลบหรือ override

2. Backend คำนวณถูกต้องแล้ว แต่ database ไม่มีข้อมูล

## ✅ วิธีแก้ไข (3 ขั้นตอน)

### ขั้นตอนที่ 1: แก้ไข Database
```bash
# รัน script แก้ไข inventory
fix-room-availability.bat
```

Script นี้จะ:
- ✅ ตรวจสอบสถานะ inventory ปัจจุบัน
- ✅ สร้าง inventory สำหรับ 90 วันข้างหน้า
- ✅ ตั้งค่า `allotment` ตาม `default_allotment` ของแต่ละ room type
- ✅ ตรวจสอบว่าห้องว่างหรือไม่

### ขั้นตอนที่ 2: ทดสอบ API
```bash
# ทดสอบว่า API ส่งข้อมูลถูกต้อง
test-room-search-direct.bat
```

ผลลัพธ์ที่ถูกต้องควรเป็น:
```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "available_rooms": 18,  // ← ต้องมากกว่า 0
        "total_price": 3000.00
      }
    ]
  }
}
```

### ขั้นตอนที่ 3: Restart Backend
```bash
cd backend
go run cmd/server/main.go
```

## 🔧 การทำงานของระบบ

### Backend Repository (ถูกต้องแล้ว)
```go
// backend/internal/repository/room_repository.go
daily_availability AS (
    SELECT 
        rt.room_type_id,
        COALESCE(ri.allotment, rt.default_allotment) - 
        COALESCE(ri.booked_count, 0) - 
        COALESCE(ri.tentative_count, 0) as available
    FROM room_types rt
    LEFT JOIN room_inventory ri ON ...
)
```

### Frontend Component (แก้ไขแล้ว)
```typescript
// frontend/src/components/room-card.tsx
const availableRooms = room.available_rooms ?? 0;

<Button
  onClick={() => onBook(room.room_type_id)}
  disabled={availableRooms === 0}
>
  {availableRooms === 0 ? 'เต็ม' : 'จองห้องนี้'}
</Button>
```

## 📊 ตรวจสอบข้อมูล Database

### Query ตรวจสอบ Inventory
```sql
-- ดูห้องว่างสำหรับวันนี้
SELECT 
    rt.name,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_types rt
JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date = CURRENT_DATE
ORDER BY rt.name;
```

### ผลลัพธ์ที่ถูกต้อง
```
name          | date       | allotment | booked | tentative | available
--------------|------------|-----------|--------|-----------|----------
Standard Room | 2025-11-05 | 18        | 0      | 0         | 18
Deluxe Room   | 2025-11-05 | 18        | 0      | 0         | 18
Suite         | 2025-11-05 | 9         | 0      | 0         | 9
```

## 🎯 การทดสอบ

### 1. ทดสอบผ่าน Browser
```
http://localhost:3000/rooms/search
```
- เลือกวันที่ check-in และ check-out
- เลือกจำนวนผู้เข้าพัก
- กดค้นหา
- **ควรเห็นปุ่ม "จองห้องนี้" ไม่ใช่ "เต็ม"**

### 2. ทดสอบผ่าน API
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-05&checkOut=2025-11-07&guests=2"
```

### 3. ทดสอบ Database
```bash
psql -U postgres -d hotel_booking -f fix-room-availability.sql
```

## 🚨 Troubleshooting

### ปัญหา: ยังเต็มอยู่หลัง run script
**สาเหตุ:** Backend cache หรือไม่ได้ restart
**แก้ไข:**
```bash
# 1. Clear Redis cache (ถ้ามี)
redis-cli FLUSHALL

# 2. Restart backend
cd backend
go run cmd/server/main.go
```

### ปัญหา: API ส่ง available_rooms = null
**สาเหตุ:** Database ไม่มี inventory record
**แก้ไข:**
```bash
fix-room-availability.bat
```

### ปัญหา: Frontend แสดง "0 ห้อง" แม้ API ส่งถูก
**สาเหตุ:** Frontend cache
**แก้ไข:**
```bash
# Clear browser cache หรือ hard refresh
Ctrl + Shift + R (Windows)
Cmd + Shift + R (Mac)
```

## 📝 สรุป

### ไฟล์ที่สร้าง/แก้ไข
1. ✅ `fix-room-availability.sql` - SQL script แก้ไข inventory
2. ✅ `fix-room-availability.bat` - Windows batch script
3. ✅ `test-room-search-direct.bat` - ทดสอบ API
4. ✅ `frontend/src/components/room-card.tsx` - แก้ไข null handling

### การทำงานของระบบ
```
User Search
    ↓
Frontend API (/api/rooms/search)
    ↓
Backend API (/api/rooms/search)
    ↓
Database Query (room_inventory)
    ↓
Calculate: allotment - booked - tentative
    ↓
Return available_rooms
    ↓
Frontend Display (Button enabled/disabled)
```

### ตรวจสอบความสำเร็จ
- ✅ Database มี inventory records
- ✅ API ส่ง available_rooms > 0
- ✅ Frontend แสดงปุ่ม "จองห้องนี้"
- ✅ สามารถกดจองได้

---

**หมายเหตุ:** ระบบใช้ database schema ที่ออกแบบไว้ใน migrations ถูกต้องแล้ว ปัญหาอยู่ที่ข้อมูล demo ไม่ครบถ้วน
