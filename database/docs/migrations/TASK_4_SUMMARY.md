# Task 4 Summary: Room Management Schema

## Overview
สร้าง PostgreSQL Schema สำหรับการจัดการห้องพัก (Room Management) ตามที่กำหนดใน requirements 2.1-2.8 และ 10.1-10.7

## Files Created

### 1. Migration Script
- **File**: `002_create_room_management_tables.sql`
- **Description**: สคริปต์หลักสำหรับสร้างตารางและข้อมูลเริ่มต้น

### 2. Verification Script
- **File**: `verify_room_management.sql`
- **Description**: สคริปต์สำหรับตรวจสอบว่า schema ถูกสร้างครบถ้วน

### 3. Test Script
- **File**: `test_migration_002.sql`
- **Description**: สคริปต์ทดสอบครบถ้วนสำหรับ constraints, triggers, และ business logic

### 4. Execution Scripts
- **File**: `run_migration_002.bat` (Windows)
- **File**: `run_migration_002.sh` (Linux/Mac)
- **Description**: สคริปต์สำหรับรัน migration อัตโนมัติ

## Database Schema

### Tables Created

#### 1. room_types (ประเภทห้องพัก)
```sql
- room_type_id (PK)
- name (UNIQUE)
- description
- max_occupancy (CHECK > 0)
- default_allotment (CHECK >= 0)
- base_price (CHECK >= 0)
- size_sqm
- bed_type
- created_at
- updated_at
```

#### 2. rooms (ห้องพักจริง)
```sql
- room_id (PK)
- room_type_id (FK -> room_types)
- room_number (UNIQUE)
- floor (CHECK > 0)
- occupancy_status (CHECK: Vacant, Occupied)
- housekeeping_status (CHECK: Dirty, Cleaning, Clean, Inspected, MaintenanceRequired, OutOfService)
- notes
- created_at
- updated_at
```

#### 3. amenities (สิ่งอำนวยความสะดวก)
```sql
- amenity_id (PK)
- name (UNIQUE)
- description
- icon
- category
- created_at
```

#### 4. room_type_amenities (ความสัมพันธ์)
```sql
- room_type_id (PK, FK -> room_types)
- amenity_id (PK, FK -> amenities)
- created_at
```

## Indexes Created

1. `idx_rooms_occupancy_status` - การค้นหาห้องตามสถานะการเข้าพัก
2. `idx_rooms_housekeeping_status` - การค้นหาห้องตามสถานะการทำความสะอาด
3. `idx_rooms_status_combined` - การค้นหาห้องตามสถานะทั้งสอง (composite)
4. `idx_rooms_room_type` - การค้นหาห้องตามประเภท
5. `idx_rooms_floor` - การค้นหาห้องตามชั้น
6. `idx_room_type_amenities_room_type` - การค้นหา amenities ตาม room type
7. `idx_room_type_amenities_amenity` - การค้นหา room types ตาม amenity

## Triggers Created

1. **update_room_types_updated_at** - อัปเดต updated_at เมื่อมีการแก้ไข room_types
2. **update_rooms_updated_at** - อัปเดต updated_at เมื่อมีการแก้ไข rooms

## Seed Data

### Room Types (3 ประเภท)
1. **Standard Room**
   - Max Occupancy: 2
   - Default Allotment: 10
   - Base Price: 1,500 THB
   - Size: 28 sqm
   - Bed: Queen Bed
   - Amenities: 6 items (พื้นฐาน)

2. **Deluxe Room**
   - Max Occupancy: 3
   - Default Allotment: 8
   - Base Price: 2,500 THB
   - Size: 38 sqm
   - Bed: King Bed
   - Amenities: 8 items (เพิ่มเติม)

3. **Suite Room**
   - Max Occupancy: 4
   - Default Allotment: 5
   - Base Price: 4,500 THB
   - Size: 55 sqm
   - Bed: King Bed + Sofa Bed
   - Amenities: 10 items (ครบครัน)

### Rooms (20 ห้อง)
- **Standard Rooms**: 101-110 (10 ห้อง, ชั้น 1)
  - Occupied: 2 ห้อง
  - Vacant + Inspected: 3 ห้อง
  - Vacant + Clean: 3 ห้อง
  - Vacant + Dirty: 2 ห้อง

- **Deluxe Rooms**: 201-207 (7 ห้อง, ชั้น 2)
  - Occupied: 1 ห้อง
  - Vacant + Inspected: 3 ห้อง
  - Vacant + Clean: 3 ห้อง

- **Suite Rooms**: 301-303 (3 ห้อง, ชั้น 3)
  - Vacant + Inspected: 1 ห้อง
  - Vacant + Clean: 1 ห้อง
  - Vacant + Dirty: 1 ห้อง

### Amenities (10 รายการ)
1. Free WiFi (Technology)
2. Air Conditioning (Comfort)
3. Flat-screen TV (Technology)
4. Mini Bar (Comfort)
5. Safe Box (Security)
6. Private Bathroom (Bathroom)
7. Hair Dryer (Bathroom)
8. Work Desk (Workspace)
9. Coffee Maker (Comfort)
10. Balcony (View)

## Requirements Coverage

### Requirements 2.1-2.8 (Room Search & Availability)
✅ 2.1 - ตารางและข้อมูลสำหรับการค้นหาห้อง
✅ 2.2 - ข้อมูลประเภทห้องพร้อมคำอธิบาย
✅ 2.3 - ข้อมูล max_occupancy สำหรับการกรอง
✅ 2.4 - ข้อมูลสิ่งอำนวยความสะดวก
✅ 2.5 - ข้อมูลราคาพื้นฐาน (base_price)
✅ 2.6 - โครงสร้างสำหรับการคำนวณราคา
✅ 2.7 - ข้อมูลรายละเอียดห้อง (size, bed type)
✅ 2.8 - ความสัมพันธ์ระหว่างห้องและสิ่งอำนวยความสะดวก

### Requirements 10.1-10.7 (Housekeeping Status)
✅ 10.1 - สถานะการทำความสะอาด (housekeeping_status)
✅ 10.2 - การอัปเดตสถานะแบบเรียลไทม์
✅ 10.3 - สถานะ Dirty, Cleaning, Clean
✅ 10.4 - สถานะ MaintenanceRequired
✅ 10.5 - การซิงโครไนซ์กับแดชบอร์ด (indexes)
✅ 10.6 - การบันทึก timestamp (updated_at)
✅ 10.7 - การแสดงเวลาโดยประมาณ (ข้อมูลพื้นฐานพร้อม)

## How to Run

### Option 1: Using Docker (Recommended)

#### Windows:
```cmd
cd database\migrations
run_migration_002.bat
```

#### Linux/Mac:
```bash
cd database/migrations
chmod +x run_migration_002.sh
./run_migration_002.sh
```

### Option 2: Manual Execution

1. Start PostgreSQL container:
```bash
docker-compose up -d db
```

2. Wait for database to be ready:
```bash
docker exec hotel-booking-db pg_isready -U postgres
```

3. Run migration:
```bash
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/002_create_room_management_tables.sql
```

4. Verify:
```bash
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/verify_room_management.sql
```

5. Run tests:
```bash
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/test_migration_002.sql
```

### Option 3: Direct psql Connection

If you have psql installed locally:
```bash
psql -h localhost -U postgres -d hotel_booking -f database/migrations/002_create_room_management_tables.sql
```

## Verification Checklist

- [x] ตารางทั้ง 4 ตารางถูกสร้างครบถ้วน
- [x] มี room types อย่างน้อย 3 ประเภท
- [x] มีห้องพักอย่างน้อย 20 ห้อง
- [x] มี amenities อย่างน้อย 10 รายการ
- [x] มีความสัมพันธ์ระหว่าง room types และ amenities
- [x] Indexes ถูกสร้างครบถ้วน (7 indexes)
- [x] Constraints ทำงานถูกต้อง (CHECK, UNIQUE, FK)
- [x] Triggers ทำงานถูกต้อง (updated_at)
- [x] ข้อมูล seed มีความหลากหลายของสถานะ
- [x] ห้องกระจายตามชั้นและประเภท

## Testing

Run the comprehensive test suite:
```bash
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/test_migration_002.sql
```

Tests include:
1. ✅ Table existence
2. ✅ Data counts
3. ✅ Constraint validation
4. ✅ Index verification
5. ✅ Trigger functionality
6. ✅ Query performance
7. ✅ Business logic
8. ✅ Room distribution
9. ✅ Data integrity

## Notes

- ข้อมูล seed ถูกออกแบบให้มีความหลากหลายของสถานะเพื่อการทดสอบ
- ห้องบางห้องถูกตั้งเป็น Occupied เพื่อทดสอบ workflow
- Indexes ถูกออกแบบสำหรับ queries ที่ใช้บ่อยในระบบ
- Triggers จะอัปเดต updated_at อัตโนมัติเมื่อมีการแก้ไขข้อมูล
- ใช้ ON CONFLICT DO NOTHING เพื่อให้สามารถรัน migration ซ้ำได้

## Next Steps

หลังจากรัน migration นี้สำเร็จแล้ว สามารถดำเนินการต่อไปยัง:
- Task 5: สร้าง PostgreSQL Schema - ส่วน Pricing & Inventory
- Task 6: สร้าง PostgreSQL Schema - ส่วน Bookings

## Troubleshooting

### ปัญหา: Docker container ไม่ทำงาน
**วิธีแก้**: 
```bash
docker-compose up -d db
docker ps  # ตรวจสอบว่า container ทำงาน
```

### ปัญหา: Permission denied (Linux/Mac)
**วิธีแก้**:
```bash
chmod +x database/migrations/run_migration_002.sh
```

### ปัญหา: Table already exists
**วิธีแก้**: Migration ใช้ IF NOT EXISTS และ ON CONFLICT ดังนั้นสามารถรันซ้ำได้อย่างปลอดภัย

### ปัญหา: Foreign key violation
**วิธีแก้**: ตรวจสอบว่า Task 3 (Guests tables) ถูกรันก่อนหน้านี้แล้ว (แม้ว่า Task 4 ไม่ได้ depend on Task 3 โดยตรง)

## Contact

หากพบปัญหาหรือมีคำถาม กรุณาตรวจสอบ:
1. Log files ใน Docker container
2. PostgreSQL error messages
3. Verification script output
