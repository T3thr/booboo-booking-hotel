-- ============================================================================
-- Migration: 002_create_room_management_tables.sql
-- Description: สร้างตารางสำหรับการจัดการห้องพัก (Room Management)
-- Task: 4. สร้าง PostgreSQL Schema - ส่วน Room Management
-- Requirements: 2.1-2.8, 10.1-10.7
-- ============================================================================

-- ============================================================================
-- 1. สร้างตาราง room_types (ประเภทห้องพัก)
-- ============================================================================
CREATE TABLE IF NOT EXISTS room_types (
    room_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    max_occupancy INT NOT NULL CHECK (max_occupancy > 0),
    default_allotment INT NOT NULL DEFAULT 10 CHECK (default_allotment >= 0),
    base_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (base_price >= 0),
    size_sqm DECIMAL(8, 2),
    bed_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE room_types IS 'ประเภทห้องพัก เช่น Standard, Deluxe, Suite';
COMMENT ON COLUMN room_types.name IS 'ชื่อประเภทห้อง';
COMMENT ON COLUMN room_types.max_occupancy IS 'จำนวนผู้เข้าพักสูงสุด';
COMMENT ON COLUMN room_types.default_allotment IS 'จำนวนห้องเริ่มต้นที่เปิดขาย';
COMMENT ON COLUMN room_types.base_price IS 'ราคาพื้นฐาน (สำหรับอ้างอิง)';

-- ============================================================================
-- 2. สร้างตาราง rooms (ห้องพักจริง)
-- ============================================================================
CREATE TABLE IF NOT EXISTS rooms (
    room_id SERIAL PRIMARY KEY,
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id) ON DELETE RESTRICT,
    room_number VARCHAR(10) NOT NULL UNIQUE,
    floor INT NOT NULL CHECK (floor > 0),
    occupancy_status VARCHAR(20) NOT NULL DEFAULT 'Vacant' 
        CHECK (occupancy_status IN ('Vacant', 'Occupied')),
    housekeeping_status VARCHAR(50) NOT NULL DEFAULT 'Dirty'
        CHECK (housekeeping_status IN ('Dirty', 'Cleaning', 'Clean', 
               'Inspected', 'MaintenanceRequired', 'OutOfService')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE rooms IS 'ห้องพักจริงในโรงแรม';
COMMENT ON COLUMN rooms.room_number IS 'หมายเลขห้อง เช่น 101, 201';
COMMENT ON COLUMN rooms.occupancy_status IS 'สถานะการเข้าพัก: Vacant (ว่าง), Occupied (มีผู้เข้าพัก)';
COMMENT ON COLUMN rooms.housekeeping_status IS 'สถานะการทำความสะอาด: Dirty, Cleaning, Clean, Inspected, MaintenanceRequired, OutOfService';

-- ============================================================================
-- 3. สร้างตาราง amenities (สิ่งอำนวยความสะดวก)
-- ============================================================================
CREATE TABLE IF NOT EXISTS amenities (
    amenity_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50),
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE amenities IS 'สิ่งอำนวยความสะดวกต่างๆ เช่น WiFi, TV, แอร์';
COMMENT ON COLUMN amenities.category IS 'หมวดหมู่ เช่น Technology, Comfort, Bathroom';

-- ============================================================================
-- 4. สร้างตาราง room_type_amenities (ความสัมพันธ์ระหว่างประเภทห้องและสิ่งอำนวยความสะดวก)
-- ============================================================================
CREATE TABLE IF NOT EXISTS room_type_amenities (
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id) ON DELETE CASCADE,
    amenity_id INT NOT NULL REFERENCES amenities(amenity_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (room_type_id, amenity_id)
);

COMMENT ON TABLE room_type_amenities IS 'ความสัมพันธ์ระหว่างประเภทห้องและสิ่งอำนวยความสะดวก (Many-to-Many)';

-- ============================================================================
-- 5. สร้าง Indexes เพื่อเพิ่มประสิทธิภาพ
-- ============================================================================

-- Index สำหรับการค้นหาห้องตามสถานะ (ใช้บ่อยในแดชบอร์ด)
CREATE INDEX IF NOT EXISTS idx_rooms_occupancy_status 
    ON rooms(occupancy_status);

CREATE INDEX IF NOT EXISTS idx_rooms_housekeeping_status 
    ON rooms(housekeeping_status);

-- Composite index สำหรับการค้นหาห้องว่างที่สะอาด
CREATE INDEX IF NOT EXISTS idx_rooms_status_combined 
    ON rooms(occupancy_status, housekeeping_status);

-- Index สำหรับการค้นหาห้องตามประเภท
CREATE INDEX IF NOT EXISTS idx_rooms_room_type 
    ON rooms(room_type_id);

-- Index สำหรับการค้นหาห้องตามชั้น
CREATE INDEX IF NOT EXISTS idx_rooms_floor 
    ON rooms(floor);

-- Index สำหรับการค้นหา amenities ตาม room_type
CREATE INDEX IF NOT EXISTS idx_room_type_amenities_room_type 
    ON room_type_amenities(room_type_id);

CREATE INDEX IF NOT EXISTS idx_room_type_amenities_amenity 
    ON room_type_amenities(amenity_id);

-- ============================================================================
-- 6. สร้าง Trigger สำหรับ updated_at
-- ============================================================================

-- Function สำหรับอัปเดต updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger สำหรับ room_types
DROP TRIGGER IF EXISTS update_room_types_updated_at ON room_types;
CREATE TRIGGER update_room_types_updated_at
    BEFORE UPDATE ON room_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ rooms
DROP TRIGGER IF EXISTS update_rooms_updated_at ON rooms;
CREATE TRIGGER update_rooms_updated_at
    BEFORE UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. SEED DATA - Room Types (3 ประเภทห้อง)
-- ============================================================================

INSERT INTO room_types (name, description, max_occupancy, default_allotment, base_price, size_sqm, bed_type)
VALUES 
    ('Standard Room', 
     'ห้องพักมาตรฐานพร้อมเตียงคู่หรือเตียงเดี่ยว 2 เตียง เหมาะสำหรับผู้เข้าพัก 1-2 ท่าน มีสิ่งอำนวยความสะดวกครบครัน',
     2, 10, 1500.00, 28.00, 'Queen Bed'),
    
    ('Deluxe Room', 
     'ห้องพักขนาดใหญ่พร้อมวิวสวยงาม มีพื้นที่นั่งเล่นแยกส่วน เหมาะสำหรับผู้เข้าพัก 2-3 ท่าน',
     3, 8, 2500.00, 38.00, 'King Bed'),
    
    ('Suite Room', 
     'ห้องสวีทหรูหราพร้อมห้องนอนและห้องนั่งเล่นแยกส่วน มีระเบียงส่วนตัว เหมาะสำหรับครอบครัวหรือผู้เข้าพัก 3-4 ท่าน',
     4, 5, 4500.00, 55.00, 'King Bed + Sofa Bed')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 8. SEED DATA - Amenities (10 สิ่งอำนวยความสะดวก)
-- ============================================================================

INSERT INTO amenities (name, description, icon, category)
VALUES 
    ('Free WiFi', 'อินเทอร์เน็ตไร้สายความเร็วสูงฟรี', 'wifi', 'Technology'),
    ('Air Conditioning', 'เครื่องปรับอากาศ', 'ac_unit', 'Comfort'),
    ('Flat-screen TV', 'ทีวีจอแบนพร้อมช่องรายการเคเบิล', 'tv', 'Technology'),
    ('Mini Bar', 'ตู้เย็นมินิบาร์พร้อมเครื่องดื่ม', 'local_bar', 'Comfort'),
    ('Safe Box', 'ตู้นิรภัยส่วนตัว', 'lock', 'Security'),
    ('Private Bathroom', 'ห้องน้ำส่วนตัวพร้อมฝักบัวและอ่างอาบน้ำ', 'bathtub', 'Bathroom'),
    ('Hair Dryer', 'ไดร์เป่าผม', 'air', 'Bathroom'),
    ('Work Desk', 'โต๊ะทำงานพร้อมเก้าอี้', 'desk', 'Workspace'),
    ('Coffee Maker', 'เครื่องชงกาแฟ', 'coffee', 'Comfort'),
    ('Balcony', 'ระเบียงส่วนตัว', 'balcony', 'View')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 9. SEED DATA - Room Type Amenities (กำหนดสิ่งอำนวยความสะดวกให้แต่ละประเภทห้อง)
-- ============================================================================

-- Standard Room: สิ่งอำนวยความสะดวกพื้นฐาน (6 รายการ)
INSERT INTO room_type_amenities (room_type_id, amenity_id)
SELECT rt.room_type_id, a.amenity_id
FROM room_types rt
CROSS JOIN amenities a
WHERE rt.name = 'Standard Room'
  AND a.name IN ('Free WiFi', 'Air Conditioning', 'Flat-screen TV', 
                 'Private Bathroom', 'Hair Dryer', 'Work Desk')
ON CONFLICT DO NOTHING;

-- Deluxe Room: สิ่งอำนวยความสะดวกเพิ่มเติม (8 รายการ)
INSERT INTO room_type_amenities (room_type_id, amenity_id)
SELECT rt.room_type_id, a.amenity_id
FROM room_types rt
CROSS JOIN amenities a
WHERE rt.name = 'Deluxe Room'
  AND a.name IN ('Free WiFi', 'Air Conditioning', 'Flat-screen TV', 
                 'Mini Bar', 'Safe Box', 'Private Bathroom', 
                 'Hair Dryer', 'Work Desk')
ON CONFLICT DO NOTHING;

-- Suite Room: สิ่งอำนวยความสะดวกครบครัน (10 รายการ - ทั้งหมด)
INSERT INTO room_type_amenities (room_type_id, amenity_id)
SELECT rt.room_type_id, a.amenity_id
FROM room_types rt
CROSS JOIN amenities a
WHERE rt.name = 'Suite Room'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 10. SEED DATA - Rooms (20 ห้อง กระจายตามประเภท)
-- ============================================================================

-- Standard Rooms: ห้อง 101-110 (10 ห้อง)
INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
SELECT 
    rt.room_type_id,
    '1' || LPAD(gs.room_num::TEXT, 2, '0') as room_number,
    1 as floor,
    CASE 
        WHEN gs.room_num <= 2 THEN 'Occupied'
        ELSE 'Vacant'
    END as occupancy_status,
    CASE 
        WHEN gs.room_num <= 2 THEN 'Dirty'
        WHEN gs.room_num <= 5 THEN 'Inspected'
        WHEN gs.room_num <= 8 THEN 'Clean'
        ELSE 'Dirty'
    END as housekeeping_status
FROM room_types rt
CROSS JOIN generate_series(1, 10) as gs(room_num)
WHERE rt.name = 'Standard Room'
ON CONFLICT (room_number) DO NOTHING;

-- Deluxe Rooms: ห้อง 201-207 (7 ห้อง)
INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
SELECT 
    rt.room_type_id,
    '2' || LPAD(gs.room_num::TEXT, 2, '0') as room_number,
    2 as floor,
    CASE 
        WHEN gs.room_num <= 1 THEN 'Occupied'
        ELSE 'Vacant'
    END as occupancy_status,
    CASE 
        WHEN gs.room_num <= 1 THEN 'Dirty'
        WHEN gs.room_num <= 4 THEN 'Inspected'
        ELSE 'Clean'
    END as housekeeping_status
FROM room_types rt
CROSS JOIN generate_series(1, 7) as gs(room_num)
WHERE rt.name = 'Deluxe Room'
ON CONFLICT (room_number) DO NOTHING;

-- Suite Rooms: ห้อง 301-303 (3 ห้อง)
INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
SELECT 
    rt.room_type_id,
    '3' || LPAD(gs.room_num::TEXT, 2, '0') as room_number,
    3 as floor,
    'Vacant' as occupancy_status,
    CASE 
        WHEN gs.room_num = 1 THEN 'Inspected'
        WHEN gs.room_num = 2 THEN 'Clean'
        ELSE 'Dirty'
    END as housekeeping_status
FROM room_types rt
CROSS JOIN generate_series(1, 3) as gs(room_num)
WHERE rt.name = 'Suite Room'
ON CONFLICT (room_number) DO NOTHING;

-- ============================================================================
-- 11. Verification Queries
-- ============================================================================

-- แสดงสรุปข้อมูลที่สร้าง
DO $$
DECLARE
    room_type_count INT;
    room_count INT;
    amenity_count INT;
    mapping_count INT;
BEGIN
    SELECT COUNT(*) INTO room_type_count FROM room_types;
    SELECT COUNT(*) INTO room_count FROM rooms;
    SELECT COUNT(*) INTO amenity_count FROM amenities;
    SELECT COUNT(*) INTO mapping_count FROM room_type_amenities;
    
    RAISE NOTICE '=== Room Management Schema Created Successfully ===';
    RAISE NOTICE 'Room Types: %', room_type_count;
    RAISE NOTICE 'Rooms: %', room_count;
    RAISE NOTICE 'Amenities: %', amenity_count;
    RAISE NOTICE 'Room-Amenity Mappings: %', mapping_count;
    RAISE NOTICE '====================================================';
END $$;

-- แสดงสรุปห้องตามประเภท
SELECT 
    rt.name as room_type,
    COUNT(r.room_id) as total_rooms,
    SUM(CASE WHEN r.occupancy_status = 'Occupied' THEN 1 ELSE 0 END) as occupied,
    SUM(CASE WHEN r.occupancy_status = 'Vacant' THEN 1 ELSE 0 END) as vacant,
    SUM(CASE WHEN r.housekeeping_status = 'Inspected' THEN 1 ELSE 0 END) as inspected,
    SUM(CASE WHEN r.housekeeping_status = 'Clean' THEN 1 ELSE 0 END) as clean,
    SUM(CASE WHEN r.housekeeping_status = 'Dirty' THEN 1 ELSE 0 END) as dirty
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.name
ORDER BY rt.name;

-- แสดงสิ่งอำนวยความสะดวกของแต่ละประเภทห้อง
SELECT 
    rt.name as room_type,
    COUNT(rta.amenity_id) as amenity_count,
    STRING_AGG(a.name, ', ' ORDER BY a.name) as amenities
FROM room_types rt
LEFT JOIN room_type_amenities rta ON rt.room_type_id = rta.room_type_id
LEFT JOIN amenities a ON rta.amenity_id = a.amenity_id
GROUP BY rt.name
ORDER BY rt.name;
