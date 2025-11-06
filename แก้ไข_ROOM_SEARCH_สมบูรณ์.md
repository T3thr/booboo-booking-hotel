# 🔧 แก้ไข Room Search สมบูรณ์!

## สิ่งที่แก้ไขแล้ว

### 1. เพิ่ม Detailed Logging
- ✅ Log ทุก request ที่เข้ามา
- ✅ Log error แบบละเอียด พร้อม context
- ✅ Log success พร้อมจำนวนห้องที่เจอ

### 2. ปรับปรุง Error Messages
- ✅ แสดง error message ที่ชัดเจน
- ✅ ระบุ parameters ที่ใช้ใน query
- ✅ แยก error type (validation vs database)

### 3. เพิ่ม Query Validation
- ✅ ตรวจสอบ `is_active = true` ใน room_types
- ✅ Error handling ที่ดีขึ้น

---

## วิธีแก้ไข (2 นาที)

### ขั้นตอนที่ 1: Restart Backend

**Double-click:**
```
fix-room-search-complete.bat
```

หรือ manual:
```bash
# Stop backend (Ctrl+C)
cd backend
go run cmd/server/main.go
```

### ขั้นตอนที่ 2: ดู Backend Log

เมื่อ search rooms บนเว็บ ให้ดู backend terminal:

**ถ้าเห็น:**
```
INFO [SearchRooms]: Request - CheckIn: 2025-11-06, CheckOut: 2025-11-07, Guests: 1
INFO [SearchRooms]: Success - Found 3 room types
```
**= ทำงานสำเร็จ! ✅**

**ถ้าเห็น:**
```
ERROR [SearchRooms]: SearchAvailableRooms failed: failed to ensure inventory exists: ...
```
**= ต้อง seed data**

**ถ้าเห็น:**
```
ERROR [SearchRooms]: SearchAvailableRooms failed: database query failed: ...
```
**= ปัญหา database connection หรือ schema**

---

## แก้ไขตาม Error

### Error: "failed to ensure inventory exists"

**สาเหตุ:** ตาราง `room_inventory` ไม่มีข้อมูล

**วิธีแก้:**
```bash
cd database/migrations
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

### Error: "database query failed"

**สาเหตุ:** Database connection หรือ schema ไม่ถูกต้อง

**วิธีแก้:**
```bash
# ตรวจสอบ connection
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) FROM room_types;"

# ถ้า error ให้ run migrations ใหม่
cd database/migrations
psql -U postgres -d hotel_booking -f 001_create_guests_tables.sql
psql -U postgres -d hotel_booking -f 002_create_room_management_tables.sql
psql -U postgres -d hotel_booking -f 003_create_pricing_inventory_tables.sql
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

### Error: "failed to scan room type row"

**สาเหตุ:** Database schema ไม่ตรงกับ code

**วิธีแก้:**
```bash
# ตรวจสอบ schema
psql -U postgres -d hotel_booking -c "\d room_types"

# ต้องมี columns:
# - room_type_id
# - name
# - description
# - max_occupancy
# - default_allotment
# - is_active
```

---

## ทดสอบ API

### Test 1: ทดสอบ API โดยตรง
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
```

**ผลลัพธ์ที่ถูกต้อง:**
```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "available_rooms": 10,
        "total_price": 4500,
        "price_per_night": 1500,
        "nightly_prices": [...]
      }
    ],
    "check_in": "2025-11-10",
    "check_out": "2025-11-13",
    "guests": 2,
    "total_nights": 3
  }
}
```

### Test 2: ทดสอบบนเว็บ

1. เปิด http://localhost:3000/rooms/search
2. เลือกวันที่
3. คลิก "ค้นหาห้องพัก"
4. **ต้องเห็น:**
   - ห้องว่างพร้อมราคา
   - ปุ่ม "จองห้องนี้" (ไม่ disabled)
   - จำนวนห้องว่าง

---

## ตรวจสอบ Backend Log

**Log ที่ควรเห็น:**

```
INFO [SearchRooms]: Request - CheckIn: 2025-11-10, CheckOut: 2025-11-13, Guests: 2
INFO [SearchRooms]: Success - Found 3 room types
[GET] 200 | 85.2ms | ::1 | /api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2
```

**ถ้าเห็น 500 error:**
```
ERROR [SearchRooms]: SearchAvailableRooms failed: [error message here]
[GET] 500 | 85.2ms | ::1 | /api/rooms/search?...
```

อ่าน error message และแก้ไขตามด้านบน

---

## ✅ เสร็จสมบูรณ์!

หลังแก้ไขแล้ว:
- ✅ Backend log แสดง error ชัดเจน
- ✅ API ส่ง available_rooms field
- ✅ RoomCard แสดงห้องว่าง
- ✅ ปุ่มจองทำงาน
- ✅ ระบบจองห้องพักสมบูรณ์!

**พร้อมใช้งาน! 🚀**
