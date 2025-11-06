# 🔍 Debug Backend 500 Error

## ปัญหา
Backend ส่ง 500 error เมื่อค้นหาห้อง

## วิธีแก้ไข

### ขั้นตอนที่ 1: ดู Backend Logs
ดูใน terminal ที่รัน backend ว่ามี error message อะไร

### ขั้นตอนที่ 2: ทดสอบ Database
```sql
-- เข้า PostgreSQL
psql -U postgres -d hotel_booking

-- ตรวจสอบ room_types table
\d room_types

-- ตรวจสอบข้อมูล
SELECT * FROM room_types LIMIT 1;

-- ตรวจสอบ room_inventory
SELECT * FROM room_inventory WHERE date >= CURRENT_DATE LIMIT 5;
```

### ขั้นตอนที่ 3: ทดสอบ Query โดยตรง
```sql
-- ทดสอบ query ที่ใช้ใน SearchAvailableRooms
WITH date_range AS (
    SELECT generate_series('2025-11-10'::date, '2025-11-13'::date - interval '1 day', interval '1 day')::date AS date
),
daily_availability AS (
    SELECT 
        rt.room_type_id,
        dr.date,
        COALESCE(ri.allotment, rt.default_allotment) as total_allotment,
        COALESCE(ri.booked_count, 0) as booked,
        COALESCE(ri.tentative_count, 0) as tentative,
        COALESCE(ri.allotment, rt.default_allotment) - 
            COALESCE(ri.booked_count, 0) - 
            COALESCE(ri.tentative_count, 0) as available
    FROM room_types rt
    CROSS JOIN date_range dr
    LEFT JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id AND ri.date = dr.date
    WHERE rt.max_occupancy >= 2
),
available_room_types AS (
    SELECT 
        room_type_id,
        MIN(available) as min_available,
        COUNT(*) as total_days
    FROM daily_availability
    GROUP BY room_type_id
    HAVING MIN(available) > 0
       AND COUNT(*) = ('2025-11-13'::date - '2025-11-10'::date)
)
SELECT 
    rt.room_type_id,
    rt.name,
    rt.description,
    rt.max_occupancy,
    rt.default_allotment,
    art.min_available as available_rooms
FROM room_types rt
INNER JOIN available_room_types art ON rt.room_type_id = art.room_type_id
ORDER BY rt.name;
```

### ขั้นตอนที่ 4: ตรวจสอบ Backend Code
ดูว่า backend compile โค้ดใหม่แล้วหรือยัง

### ขั้นตอนที่ 5: Restart Backend
```bash
# Stop backend (Ctrl+C)
# Start ใหม่
cd backend
go run cmd/server/main.go
```

## สาเหตุที่เป็นไปได้

1. **Database schema ไม่ตรง** - ตาราง room_types ไม่มี column ที่ query ต้องการ
2. **ไม่มี rate plan** - GetDefaultRatePlanID() return error
3. **ไม่มี pricing data** - GetNightlyPrices() return error
4. **Backend ไม่ได้ compile ใหม่** - ยังใช้โค้ดเก่า

## วิธีแก้ไขแบบเร็ว

### แก้ไขที่ 1: ตรวจสอบว่ามี rate plan
```sql
SELECT * FROM rate_plans LIMIT 1;
```

ถ้าไม่มี:
```sql
INSERT INTO rate_plans (rate_plan_id, name, description, policy_id) 
VALUES (1, 'Best Available Rate', 'Standard rate', 1);
```

### แก้ไขที่ 2: ตรวจสอบว่ามี pricing calendar
```sql
SELECT * FROM pricing_calendar WHERE date >= CURRENT_DATE LIMIT 5;
```

ถ้าไม่มี - รัน seed data:
```bash
cd database/migrations
run_seed_demo_data.bat
```

### แก้ไขที่ 3: Restart Backend
```bash
cd backend
go run cmd/server/main.go
```

## ทดสอบหลังแก้ไข

```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
```

ต้องเห็น:
```json
{
  "success": true,
  "data": {
    "room_types": [...]
  }
}
```
