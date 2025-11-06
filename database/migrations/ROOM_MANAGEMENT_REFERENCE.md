# Room Management Schema - Quick Reference

## Table Relationships

```
room_types (1) ----< (N) rooms
room_types (N) ----< (N) amenities  [through room_type_amenities]
```

## Room Status Model (2-Axis)

### Axis 1: Occupancy Status
- `Vacant` - ห้องว่าง
- `Occupied` - มีผู้เข้าพัก

### Axis 2: Housekeeping Status
- `Dirty` - รอทำความสะอาด
- `Cleaning` - กำลังทำความสะอาด
- `Clean` - ทำความสะอาดเสร็จ
- `Inspected` - ตรวจสอบแล้ว (พร้อมขายที่สุด)
- `MaintenanceRequired` - ต้องซ่อมบำรุง
- `OutOfService` - ปิดให้บริการ

### Status Priority for Check-in
1. `Vacant` + `Inspected` (สูงสุด)
2. `Vacant` + `Clean`
3. อื่นๆ (ไม่พร้อม)

## Common Queries

### 1. ค้นหาห้องว่างที่พร้อมเช็คอิน
```sql
SELECT r.room_id, r.room_number, rt.name as room_type
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.occupancy_status = 'Vacant'
  AND r.housekeeping_status IN ('Clean', 'Inspected')
ORDER BY 
  CASE r.housekeeping_status 
    WHEN 'Inspected' THEN 1 
    WHEN 'Clean' THEN 2 
  END,
  r.room_number;
```

### 2. ดูห้องตามประเภทพร้อมสิ่งอำนวยความสะดวก
```sql
SELECT 
  rt.room_type_id,
  rt.name,
  rt.description,
  rt.max_occupancy,
  rt.base_price,
  rt.size_sqm,
  rt.bed_type,
  STRING_AGG(a.name, ', ' ORDER BY a.name) as amenities
FROM room_types rt
LEFT JOIN room_type_amenities rta ON rt.room_type_id = rta.room_type_id
LEFT JOIN amenities a ON rta.amenity_id = a.amenity_id
GROUP BY rt.room_type_id
ORDER BY rt.base_price;
```

### 3. สรุปสถานะห้องทั้งหมด (Dashboard)
```sql
SELECT 
  occupancy_status,
  housekeeping_status,
  COUNT(*) as count
FROM rooms
GROUP BY occupancy_status, housekeeping_status
ORDER BY occupancy_status, housekeeping_status;
```

### 4. รายการงานทำความสะอาด (Housekeeping Task List)
```sql
SELECT 
  r.room_number,
  rt.name as room_type,
  r.floor,
  r.housekeeping_status,
  r.updated_at as last_updated
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.housekeeping_status IN ('Dirty', 'Cleaning')
ORDER BY 
  CASE r.housekeeping_status 
    WHEN 'Dirty' THEN 1 
    WHEN 'Cleaning' THEN 2 
  END,
  r.floor,
  r.room_number;
```

### 5. ห้องที่ต้องตรวจสอบ (Inspection Queue)
```sql
SELECT 
  r.room_number,
  rt.name as room_type,
  r.floor,
  r.updated_at as cleaned_at
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.housekeeping_status = 'Clean'
ORDER BY r.updated_at ASC;
```

### 6. ห้องที่มีปัญหา (Maintenance Required)
```sql
SELECT 
  r.room_number,
  rt.name as room_type,
  r.floor,
  r.notes,
  r.updated_at as reported_at
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.housekeeping_status = 'MaintenanceRequired'
ORDER BY r.updated_at ASC;
```

### 7. สรุปห้องตามชั้น
```sql
SELECT 
  r.floor,
  COUNT(*) as total_rooms,
  SUM(CASE WHEN r.occupancy_status = 'Occupied' THEN 1 ELSE 0 END) as occupied,
  SUM(CASE WHEN r.occupancy_status = 'Vacant' 
           AND r.housekeeping_status IN ('Clean', 'Inspected') THEN 1 ELSE 0 END) as ready
FROM rooms r
GROUP BY r.floor
ORDER BY r.floor;
```

### 8. ห้องว่างตามประเภท
```sql
SELECT 
  rt.name as room_type,
  COUNT(r.room_id) as total_rooms,
  SUM(CASE WHEN r.occupancy_status = 'Vacant' THEN 1 ELSE 0 END) as vacant,
  SUM(CASE WHEN r.occupancy_status = 'Vacant' 
           AND r.housekeeping_status IN ('Clean', 'Inspected') THEN 1 ELSE 0 END) as ready_to_sell
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.name
ORDER BY rt.name;
```

## Update Operations

### 1. อัปเดตสถานะการทำความสะอาด
```sql
-- เริ่มทำความสะอาด
UPDATE rooms
SET housekeeping_status = 'Cleaning'
WHERE room_id = ?;

-- ทำความสะอาดเสร็จ
UPDATE rooms
SET housekeeping_status = 'Clean'
WHERE room_id = ?;

-- ตรวจสอบแล้ว
UPDATE rooms
SET housekeeping_status = 'Inspected'
WHERE room_id = ?;

-- รายงานปัญหา
UPDATE rooms
SET housekeeping_status = 'MaintenanceRequired',
    notes = 'รายละเอียดปัญหา...'
WHERE room_id = ?;
```

### 2. อัปเดตสถานะการเข้าพัก (จะใช้ใน Task 7-9)
```sql
-- Check-in
UPDATE rooms
SET occupancy_status = 'Occupied'
WHERE room_id = ?;

-- Check-out
UPDATE rooms
SET occupancy_status = 'Vacant',
    housekeeping_status = 'Dirty'
WHERE room_id = ?;
```

## Data Validation Rules

### room_types
- `name` ต้องไม่ซ้ำ (UNIQUE)
- `max_occupancy` ต้อง > 0
- `default_allotment` ต้อง >= 0
- `base_price` ต้อง >= 0

### rooms
- `room_number` ต้องไม่ซ้ำ (UNIQUE)
- `floor` ต้อง > 0
- `occupancy_status` ต้องเป็น: Vacant, Occupied
- `housekeeping_status` ต้องเป็น: Dirty, Cleaning, Clean, Inspected, MaintenanceRequired, OutOfService
- `room_type_id` ต้องมีอยู่ใน room_types (FK)

### amenities
- `name` ต้องไม่ซ้ำ (UNIQUE)

### room_type_amenities
- `(room_type_id, amenity_id)` ต้องไม่ซ้ำ (PK)
- ทั้งสอง FK ต้องมีอยู่ในตารางต้นทาง

## Index Usage

### Performance Tips
1. ใช้ `idx_rooms_status_combined` เมื่อค้นหาทั้ง occupancy และ housekeeping status
2. ใช้ `idx_rooms_room_type` เมื่อกรองตามประเภทห้อง
3. ใช้ `idx_rooms_floor` เมื่อกรองตามชั้น
4. ใช้ `idx_room_type_amenities_room_type` เมื่อดึง amenities ของห้อง

## Business Rules

### Check-in Rules (จะใช้ใน Task 7)
- ห้องต้องมีสถานะ `Vacant` + (`Clean` หรือ `Inspected`)
- ห้อง `Inspected` มีลำดับความสำคัญสูงกว่า `Clean`

### Housekeeping Workflow
1. Check-out → `Dirty`
2. แม่บ้านเริ่มทำงาน → `Cleaning`
3. ทำความสะอาดเสร็จ → `Clean`
4. หัวหน้าตรวจสอบ → `Inspected`
5. พร้อมขาย → สามารถ Check-in ได้

### Night Audit (จะใช้ใน Task 37)
- ทุกวันเวลา 02:00 น.
- ห้องที่ `Occupied` จะถูกเปลี่ยนเป็น `Dirty` อัตโนมัติ

## Color Coding (สำหรับ UI)

### Dashboard Colors
- 🟢 Green: `Vacant` + `Inspected` (พร้อมขายที่สุด)
- 🟡 Yellow: `Vacant` + `Clean` (พร้อมขาย)
- 🔴 Red: `Occupied` (มีผู้เข้าพัก)
- 🟠 Orange: `Vacant` + `Dirty` (รอทำความสะอาด)
- 🔵 Blue: `Vacant` + `Cleaning` (กำลังทำความสะอาด)
- ⚫ Gray: `OutOfService` (ปิดให้บริการ)
- 🟣 Purple: `MaintenanceRequired` (ต้องซ่อมบำรุง)

## API Endpoints (จะสร้างใน Task 10)

```
GET  /api/rooms/search         - ค้นหาห้องว่าง
GET  /api/rooms/types          - ดึงรายการประเภทห้อง
GET  /api/rooms/types/:id      - ดึงรายละเอียดประเภทห้อง
GET  /api/rooms/:id            - ดึงรายละเอียดห้อง
PUT  /api/housekeeping/rooms/:id/status - อัปเดตสถานะห้อง
GET  /api/housekeeping/tasks   - รายการงานทำความสะอาด
```

## Testing Queries

### ตรวจสอบว่า indexes ถูกใช้
```sql
EXPLAIN ANALYZE
SELECT r.room_id, r.room_number
FROM rooms r
WHERE r.occupancy_status = 'Vacant'
  AND r.housekeeping_status = 'Inspected';
```

### ตรวจสอบ trigger
```sql
-- ดู updated_at ก่อนอัปเดต
SELECT room_id, updated_at FROM rooms WHERE room_id = 1;

-- อัปเดต
UPDATE rooms SET notes = 'Test' WHERE room_id = 1;

-- ดู updated_at หลังอัปเดต (ควรเปลี่ยน)
SELECT room_id, updated_at FROM rooms WHERE room_id = 1;
```

## Sample Data Overview

### Room Distribution
- Floor 1: Standard Rooms (101-110) - 10 ห้อง
- Floor 2: Deluxe Rooms (201-207) - 7 ห้อง
- Floor 3: Suite Rooms (301-303) - 3 ห้อง
- **Total: 20 ห้อง**

### Status Distribution
- Occupied: 3 ห้อง (2 Standard, 1 Deluxe)
- Vacant + Inspected: 7 ห้อง
- Vacant + Clean: 7 ห้อง
- Vacant + Dirty: 3 ห้อง

### Amenities Distribution
- Standard Room: 6 amenities (พื้นฐาน)
- Deluxe Room: 8 amenities (เพิ่มเติม)
- Suite Room: 10 amenities (ครบครัน)

## Migration History

- **001**: Guest & Authentication tables
- **002**: Room Management tables ← **Current**
- **003**: Pricing & Inventory tables (Next)
- **004**: Booking tables (Future)

## Related Tasks

- ✅ Task 3: Guests & Authentication Schema
- ✅ Task 4: Room Management Schema (Current)
- ⏳ Task 5: Pricing & Inventory Schema
- ⏳ Task 6: Booking Schema
- ⏳ Task 10: Room Search Module - Backend
- ⏳ Task 25: Housekeeping Module - Backend
- ⏳ Task 27: Room Status Dashboard - Frontend
