# Migration 016: Seed Available Room Inventory

## 📋 Overview

Migration นี้สร้าง `room_inventory` records สำหรับ 100 วันข้างหน้า โดยตั้งค่าให้ห้องว่างทั้งหมด เพื่อแก้ไขปัญหา "ห้องเต็มทุกห้อง" ที่เกิดจาก demo data ใน migration 013

## 🎯 Purpose

แก้ไขปัญหา:
- Frontend แสดง "ห้องว่าง 0 ห้อง"
- ปุ่ม "จองห้องนี้" disabled
- Backend API ไม่ส่ง `available_rooms` หรือส่งเป็น 0

## 🔧 What This Migration Does

### 1. Clean Old Data
```sql
DELETE FROM room_inventory WHERE date >= CURRENT_DATE;
```
ลบ inventory เก่าที่อาจมีปัญหา (booked_count สูงเกินไป)

### 2. Create New Inventory (100 Days)
```sql
INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
SELECT 
    rt.room_type_id,
    d::date,
    rt.default_allotment,
    0,  -- ห้องว่างทั้งหมด
    0   -- ไม่มี hold
FROM room_types rt
CROSS JOIN generate_series(
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '100 days',
    INTERVAL '1 day'
) AS d;
```

สร้าง inventory สำหรับ:
- **Standard Room**: 10 ห้อง × 100 วัน = 1,000 room-nights
- **Deluxe Room**: 8 ห้อง × 100 วัน = 800 room-nights
- **Suite Room**: 5 ห้อง × 100 วัน = 500 room-nights
- **รวม**: 2,300 room-nights ที่พร้อมให้จอง

### 3. Add Sample Bookings (Optional)
```sql
UPDATE room_inventory
SET booked_count = FLOOR(allotment * 0.1)::INT
WHERE date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '10 days';
```

เพิ่มการจองตัวอย่าง 10% สำหรับ 10 วันแรก เพื่อให้ดูเหมือนจริง

## 📊 Expected Results

### Database Level
```sql
-- Standard Room
allotment: 10
booked_count: 0-1
tentative_count: 0
available: 9-10 ✅

-- Deluxe Room
allotment: 8
booked_count: 0-1
tentative_count: 0
available: 7-8 ✅

-- Suite Room
allotment: 5
booked_count: 0
tentative_count: 0
available: 5 ✅
```

### Backend API Response
```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "available_rooms": 9,  // ✅ > 0
        "total_price": 3300.00
      },
      {
        "room_type_id": 2,
        "name": "Deluxe Room",
        "available_rooms": 7,  // ✅ > 0
        "total_price": 5500.00
      },
      {
        "room_type_id": 3,
        "name": "Suite Room",
        "available_rooms": 5,  // ✅ > 0
        "total_price": 10000.00
      }
    ]
  }
}
```

### Frontend Display
- ✅ แสดงห้องทั้งหมด
- ✅ แสดง "ห้องว่าง X ห้อง" (X > 0)
- ✅ ปุ่ม "จองห้องนี้" สีเขียว (enabled)
- ✅ สามารถกดจองได้

## 🚀 How to Run

### Windows
```batch
cd database\migrations
run_migration_016.bat
```

### Linux/Mac
```bash
cd database/migrations
chmod +x run_migration_016.sh
./run_migration_016.sh
```

### Direct SQL
```bash
psql -U postgres -d hotel_booking -f 016_seed_available_inventory.sql
```

## ✅ Verification

### 1. Run Verification Script
```bash
psql -U postgres -d hotel_booking -f verify_migration_016.sql
```

### 2. Test Backend API
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"
```

ตรวจสอบว่า response มี `available_rooms > 0`

### 3. Test Frontend
1. เปิด http://localhost:3000/rooms/search
2. เลือกวันที่และจำนวนผู้เข้าพัก
3. กดค้นหา
4. ควรเห็นปุ่ม "จองห้องนี้" (ไม่ disabled)

## 📝 Notes

### Why 100 Days?
- ครอบคลุมช่วงเวลาที่ผู้ใช้มักจองล่วงหน้า (3-4 เดือน)
- เพียงพอสำหรับการทดสอบและ demo
- ไม่มากเกินไปจนทำให้ database ช้า

### Why Set booked_count = 0?
- เพื่อให้แน่ใจว่าทุกห้องว่าง
- แก้ไขปัญหาจาก migration 013 ที่สุ่มค่า booked_count
- ทำให้ `available = allotment - 0 - 0 = allotment`

### Sample Bookings (10%)
- เพิ่มความสมจริงให้กับ demo data
- แสดงให้เห็นว่าระบบรองรับการจองได้
- ยังคงมีห้องว่างเพียงพอ (90%)

## 🔄 Rollback

หากต้องการ rollback:

```sql
-- ลบ inventory ที่สร้างใหม่
DELETE FROM room_inventory WHERE date >= CURRENT_DATE;

-- รัน migration 013 อีกครั้ง (ถ้าต้องการ)
\i 013_seed_demo_data.sql
```

## 🐛 Troubleshooting

### ปัญหา: ยังเต็มอยู่หลัง run migration

**สาเหตุ**: Backend cache หรือไม่ได้ restart

**แก้ไข**:
```bash
# Restart backend
cd backend
go run cmd/server/main.go

# Clear browser cache
Ctrl + Shift + R (Windows)
Cmd + Shift + R (Mac)
```

### ปัญหา: API ไม่ส่ง available_rooms

**สาเหตุ**: Backend query กรอง `WHERE available > 0` และไม่เจอห้องว่าง

**แก้ไข**:
```sql
-- ตรวจสอบ database
SELECT 
    rt.name,
    ri.allotment - ri.booked_count - ri.tentative_count as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date = CURRENT_DATE;

-- ถ้า available = 0 → รัน migration 016 อีกครั้ง
```

## 📚 Related Files

- `013_seed_demo_data.sql` - Original seed data (มีปัญหา)
- `fix-inventory-reset.sql` - Alternative fix script
- `FIX_BOOKING_NOW.bat` - Quick fix batch file
- `สรุป_แก้ไข_ห้องเต็ม.md` - Detailed problem analysis

## ✨ Summary

Migration นี้แก้ไขปัญหาห้องเต็มโดย:
1. ✅ ลบ inventory เก่าที่มีปัญหา
2. ✅ สร้าง inventory ใหม่ 100 วัน (ห้องว่างทั้งหมด)
3. ✅ เพิ่ม sample bookings 10% เพื่อความสมจริง
4. ✅ ทำให้ Frontend แสดงปุ่ม "จองห้องนี้" ได้

หลังจากรัน migration นี้ ระบบจะทำงานได้ปกติและพร้อมใช้งาน!
