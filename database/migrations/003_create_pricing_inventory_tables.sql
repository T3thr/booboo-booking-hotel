-- ============================================================================
-- Migration: 003_create_pricing_inventory_tables.sql
-- Description: สร้างตารางสำหรับการจัดการราคาและสต็อกห้องพัก (Pricing & Inventory)
-- Task: 5. สร้าง PostgreSQL Schema - ส่วน Pricing & Inventory
-- Requirements: 2.1-2.8, 13.1-13.7, 14.1-14.7, 15.1-15.7, 16.1-16.7, 17.1-17.7
-- ============================================================================

-- ============================================================================
-- 1. สร้างตาราง cancellation_policies (นโยบายการยกเลิก)
-- ============================================================================
CREATE TABLE IF NOT EXISTS cancellation_policies (
    policy_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    days_before_check_in INT NOT NULL CHECK (days_before_check_in >= 0),
    refund_percentage DECIMAL(5, 2) NOT NULL DEFAULT 0.00 
        CHECK (refund_percentage >= 0 AND refund_percentage <= 100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE cancellation_policies IS 'นโยบายการยกเลิกการจอง';
COMMENT ON COLUMN cancellation_policies.days_before_check_in IS 'จำนวนวันก่อนเช็คอินที่สามารถยกเลิกได้';
COMMENT ON COLUMN cancellation_policies.refund_percentage IS 'เปอร์เซ็นต์เงินคืน (0-100)';

-- ============================================================================
-- 2. สร้างตาราง rate_tiers (ระดับราคาตามฤดูกาล)
-- ============================================================================
CREATE TABLE IF NOT EXISTS rate_tiers (
    rate_tier_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    display_order INT NOT NULL DEFAULT 0,
    color_code VARCHAR(7),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE rate_tiers IS 'ระดับราคาตามฤดูกาล เช่น Low Season, High Season, Peak Season';
COMMENT ON COLUMN rate_tiers.display_order IS 'ลำดับการแสดงผล';
COMMENT ON COLUMN rate_tiers.color_code IS 'รหัสสีสำหรับแสดงในปฏิทิน (HEX format)';

-- ============================================================================
-- 3. สร้างตาราง rate_plans (แผนราคา)
-- ============================================================================
CREATE TABLE IF NOT EXISTS rate_plans (
    rate_plan_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    policy_id INT NOT NULL REFERENCES cancellation_policies(policy_id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE rate_plans IS 'แผนราคา เช่น Standard Rate, Non-Refundable Rate';
COMMENT ON COLUMN rate_plans.policy_id IS 'นโยบายการยกเลิกที่เชื่อมโยงกับแผนราคานี้';

-- ============================================================================
-- 4. สร้างตาราง pricing_calendar (ปฏิทินราคา)
-- ============================================================================
CREATE TABLE IF NOT EXISTS pricing_calendar (
    date DATE PRIMARY KEY,
    rate_tier_id INT NOT NULL REFERENCES rate_tiers(rate_tier_id) ON DELETE RESTRICT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE pricing_calendar IS 'ปฏิทินกำหนดระดับราคาสำหรับแต่ละวัน';
COMMENT ON COLUMN pricing_calendar.notes IS 'หมายเหตุ เช่น วันหยุดพิเศษ, เทศกาล';

-- ============================================================================
-- 5. สร้างตาราง rate_pricing (เมทริกซ์ราคา)
-- ============================================================================
CREATE TABLE IF NOT EXISTS rate_pricing (
    rate_plan_id INT NOT NULL REFERENCES rate_plans(rate_plan_id) ON DELETE CASCADE,
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id) ON DELETE CASCADE,
    rate_tier_id INT NOT NULL REFERENCES rate_tiers(rate_tier_id) ON DELETE CASCADE,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (rate_plan_id, room_type_id, rate_tier_id)
);

COMMENT ON TABLE rate_pricing IS 'เมทริกซ์ราคา: แผนราคา x ประเภทห้อง x ระดับราคา';
COMMENT ON COLUMN rate_pricing.price IS 'ราคาต่อคืน (บาท)';

-- ============================================================================
-- 6. สร้างตาราง room_inventory (สต็อกห้องพัก)
-- ============================================================================
CREATE TABLE IF NOT EXISTS room_inventory (
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id) ON DELETE CASCADE,
    date DATE NOT NULL,
    allotment INT NOT NULL CHECK (allotment >= 0),
    booked_count INT NOT NULL DEFAULT 0 CHECK (booked_count >= 0),
    tentative_count INT NOT NULL DEFAULT 0 CHECK (tentative_count >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (room_type_id, date),
    CONSTRAINT chk_inventory_capacity CHECK (booked_count + tentative_count <= allotment)
);

COMMENT ON TABLE room_inventory IS 'สต็อกห้องพักสำหรับแต่ละวัน';
COMMENT ON COLUMN room_inventory.allotment IS 'จำนวนห้องที่เปิดขาย';
COMMENT ON COLUMN room_inventory.booked_count IS 'จำนวนห้องที่จองแล้ว (Confirmed)';
COMMENT ON COLUMN room_inventory.tentative_count IS 'จำนวนห้องที่กำลังจอง (Hold)';

-- ============================================================================
-- 7. สร้างตาราง vouchers (คูปองส่วนลด)
-- ============================================================================
CREATE TABLE IF NOT EXISTS vouchers (
    voucher_id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_type VARCHAR(20) NOT NULL 
        CHECK (discount_type IN ('Percentage', 'FixedAmount')),
    discount_value DECIMAL(10, 2) NOT NULL CHECK (discount_value > 0),
    expiry_date DATE NOT NULL,
    max_uses INT NOT NULL DEFAULT 100 CHECK (max_uses > 0),
    current_uses INT NOT NULL DEFAULT 0 CHECK (current_uses >= 0),
    min_booking_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (min_booking_amount >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_voucher_uses CHECK (current_uses <= max_uses)
);

COMMENT ON TABLE vouchers IS 'คูปองส่วนลดสำหรับการจอง';
COMMENT ON COLUMN vouchers.discount_type IS 'ประเภทส่วนลด: Percentage (%) หรือ FixedAmount (บาท)';
COMMENT ON COLUMN vouchers.discount_value IS 'มูลค่าส่วนลด (% หรือ บาท)';
COMMENT ON COLUMN vouchers.min_booking_amount IS 'ยอดจองขั้นต่ำที่สามารถใช้คูปองได้';

-- ============================================================================
-- 8. สร้างตาราง booking_holds (การจองชั่วคราว)
-- ============================================================================
CREATE TABLE IF NOT EXISTS booking_holds (
    hold_id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    guest_account_id INT REFERENCES guest_accounts(guest_account_id) ON DELETE CASCADE,
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id) ON DELETE CASCADE,
    date DATE NOT NULL,
    hold_expiry TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE booking_holds IS 'การจองห้องชั่วคราว (15 นาที) ระหว่างกรอกข้อมูลและชำระเงิน';
COMMENT ON COLUMN booking_holds.session_id IS 'Session ID ของผู้ใช้';
COMMENT ON COLUMN booking_holds.hold_expiry IS 'เวลาหมดอายุของ hold';

-- ============================================================================
-- 9. สร้าง Indexes เพื่อเพิ่มประสิทธิภาพ
-- ============================================================================

-- Indexes สำหรับ room_inventory (ใช้บ่อยมากในการค้นหาห้องว่าง)
CREATE INDEX IF NOT EXISTS idx_room_inventory_date 
    ON room_inventory(date);

CREATE INDEX IF NOT EXISTS idx_room_inventory_room_type 
    ON room_inventory(room_type_id);

CREATE INDEX IF NOT EXISTS idx_room_inventory_availability 
    ON room_inventory(room_type_id, date) 
    WHERE (allotment - booked_count - tentative_count) > 0;

-- Indexes สำหรับ pricing_calendar
CREATE INDEX IF NOT EXISTS idx_pricing_calendar_date 
    ON pricing_calendar(date);

CREATE INDEX IF NOT EXISTS idx_pricing_calendar_tier 
    ON pricing_calendar(rate_tier_id);

-- Indexes สำหรับ rate_pricing
CREATE INDEX IF NOT EXISTS idx_rate_pricing_room_type 
    ON rate_pricing(room_type_id);

CREATE INDEX IF NOT EXISTS idx_rate_pricing_tier 
    ON rate_pricing(rate_tier_id);

-- Indexes สำหรับ booking_holds (สำคัญมากสำหรับ cleanup job)
CREATE INDEX IF NOT EXISTS idx_booking_holds_expiry 
    ON booking_holds(hold_expiry);

CREATE INDEX IF NOT EXISTS idx_booking_holds_session 
    ON booking_holds(session_id);

CREATE INDEX IF NOT EXISTS idx_booking_holds_guest 
    ON booking_holds(guest_account_id);

CREATE INDEX IF NOT EXISTS idx_booking_holds_room_date 
    ON booking_holds(room_type_id, date);

-- Indexes สำหรับ vouchers
CREATE INDEX IF NOT EXISTS idx_vouchers_code 
    ON vouchers(code) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_vouchers_expiry 
    ON vouchers(expiry_date) WHERE is_active = TRUE;

-- ============================================================================
-- 10. สร้าง Triggers สำหรับ updated_at
-- ============================================================================

-- Trigger สำหรับ cancellation_policies
DROP TRIGGER IF EXISTS update_cancellation_policies_updated_at ON cancellation_policies;
CREATE TRIGGER update_cancellation_policies_updated_at
    BEFORE UPDATE ON cancellation_policies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ rate_tiers
DROP TRIGGER IF EXISTS update_rate_tiers_updated_at ON rate_tiers;
CREATE TRIGGER update_rate_tiers_updated_at
    BEFORE UPDATE ON rate_tiers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ rate_plans
DROP TRIGGER IF EXISTS update_rate_plans_updated_at ON rate_plans;
CREATE TRIGGER update_rate_plans_updated_at
    BEFORE UPDATE ON rate_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ pricing_calendar
DROP TRIGGER IF EXISTS update_pricing_calendar_updated_at ON pricing_calendar;
CREATE TRIGGER update_pricing_calendar_updated_at
    BEFORE UPDATE ON pricing_calendar
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ rate_pricing
DROP TRIGGER IF EXISTS update_rate_pricing_updated_at ON rate_pricing;
CREATE TRIGGER update_rate_pricing_updated_at
    BEFORE UPDATE ON rate_pricing
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ room_inventory
DROP TRIGGER IF EXISTS update_room_inventory_updated_at ON room_inventory;
CREATE TRIGGER update_room_inventory_updated_at
    BEFORE UPDATE ON room_inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ vouchers
DROP TRIGGER IF EXISTS update_vouchers_updated_at ON vouchers;
CREATE TRIGGER update_vouchers_updated_at
    BEFORE UPDATE ON vouchers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 11. SEED DATA - Cancellation Policies (3 นโยบาย)
-- ============================================================================

INSERT INTO cancellation_policies (name, description, days_before_check_in, refund_percentage)
VALUES 
    ('Flexible', 
     'ยกเลิกฟรีได้จนถึง 24 ชั่วโมงก่อนเช็คอิน คืนเงิน 100%',
     1, 100.00),
    
    ('Moderate', 
     'ยกเลิกฟรีได้จนถึง 7 วันก่อนเช็คอิน คืนเงิน 100% หากยกเลิกภายใน 7 วัน คืนเงิน 50%',
     7, 50.00),
    
    ('Non-Refundable', 
     'ไม่สามารถยกเลิกได้ ไม่คืนเงิน แต่ราคาถูกกว่า 15-20%',
     0, 0.00)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 12. SEED DATA - Rate Tiers (4 ระดับราคา)
-- ============================================================================

INSERT INTO rate_tiers (name, description, display_order, color_code)
VALUES 
    ('Low Season', 
     'ฤดูต่ำ - ราคาพิเศษสำหรับช่วงที่มีผู้เข้าพักน้อย',
     1, '#4CAF50'),
    
    ('Standard', 
     'ราคามาตรฐาน - ช่วงปกติ',
     2, '#2196F3'),
    
    ('High Season', 
     'ฤดูสูง - ช่วงวันหยุดยาวและเทศกาล',
     3, '#FF9800'),
    
    ('Peak Season', 
     'ฤดูสูงสุด - ช่วงปีใหม่ สงกรานต์',
     4, '#F44336')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 13. SEED DATA - Rate Plans (2 แผนราคา)
-- ============================================================================

INSERT INTO rate_plans (name, description, policy_id)
SELECT 
    'Standard Rate',
    'แผนราคามาตรฐาน - ยกเลิกฟรีได้จนถึง 24 ชั่วโมงก่อนเช็คอิน',
    cp.policy_id
FROM cancellation_policies cp
WHERE cp.name = 'Flexible'
ON CONFLICT (name) DO NOTHING;

INSERT INTO rate_plans (name, description, policy_id)
SELECT 
    'Non-Refundable Rate',
    'แผนราคาไม่คืนเงิน - ราคาถูกกว่า 15% แต่ไม่สามารถยกเลิกได้',
    cp.policy_id
FROM cancellation_policies cp
WHERE cp.name = 'Non-Refundable'
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 14. SEED DATA - Rate Pricing (เมทริกซ์ราคา)
-- ============================================================================

-- Standard Rate - Standard Room
INSERT INTO rate_pricing (rate_plan_id, room_type_id, rate_tier_id, price)
SELECT 
    rp.rate_plan_id,
    rt.room_type_id,
    tier.rate_tier_id,
    CASE tier.name
        WHEN 'Low Season' THEN 1200.00
        WHEN 'Standard' THEN 1500.00
        WHEN 'High Season' THEN 1800.00
        WHEN 'Peak Season' THEN 2200.00
    END as price
FROM rate_plans rp
CROSS JOIN room_types rt
CROSS JOIN rate_tiers tier
WHERE rp.name = 'Standard Rate'
  AND rt.name = 'Standard Room'
ON CONFLICT DO NOTHING;

-- Standard Rate - Deluxe Room
INSERT INTO rate_pricing (rate_plan_id, room_type_id, rate_tier_id, price)
SELECT 
    rp.rate_plan_id,
    rt.room_type_id,
    tier.rate_tier_id,
    CASE tier.name
        WHEN 'Low Season' THEN 2000.00
        WHEN 'Standard' THEN 2500.00
        WHEN 'High Season' THEN 3000.00
        WHEN 'Peak Season' THEN 3800.00
    END as price
FROM rate_plans rp
CROSS JOIN room_types rt
CROSS JOIN rate_tiers tier
WHERE rp.name = 'Standard Rate'
  AND rt.name = 'Deluxe Room'
ON CONFLICT DO NOTHING;

-- Standard Rate - Suite Room
INSERT INTO rate_pricing (rate_plan_id, room_type_id, rate_tier_id, price)
SELECT 
    rp.rate_plan_id,
    rt.room_type_id,
    tier.rate_tier_id,
    CASE tier.name
        WHEN 'Low Season' THEN 3600.00
        WHEN 'Standard' THEN 4500.00
        WHEN 'High Season' THEN 5500.00
        WHEN 'Peak Season' THEN 7000.00
    END as price
FROM rate_plans rp
CROSS JOIN room_types rt
CROSS JOIN rate_tiers tier
WHERE rp.name = 'Standard Rate'
  AND rt.name = 'Suite Room'
ON CONFLICT DO NOTHING;

-- Non-Refundable Rate (ลด 15% จาก Standard Rate)
INSERT INTO rate_pricing (rate_plan_id, room_type_id, rate_tier_id, price)
SELECT 
    rp_nr.rate_plan_id,
    rp_std.room_type_id,
    rp_std.rate_tier_id,
    ROUND(rp_std.price * 0.85, 2) as price
FROM rate_pricing rp_std
JOIN rate_plans rp_std_plan ON rp_std.rate_plan_id = rp_std_plan.rate_plan_id
CROSS JOIN rate_plans rp_nr
WHERE rp_std_plan.name = 'Standard Rate'
  AND rp_nr.name = 'Non-Refundable Rate'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 15. SEED DATA - Pricing Calendar (90 วันข้างหน้า)
-- ============================================================================

-- สร้างปฏิทินราคา 90 วันข้างหน้า
-- กำหนดระดับราคาตามวันในสัปดาห์และเดือน
INSERT INTO pricing_calendar (date, rate_tier_id, notes)
SELECT 
    date_series.date,
    CASE 
        -- Peak Season: ช่วงปีใหม่ (1-7 ม.ค.) และสงกรานต์ (13-17 เม.ย.)
        WHEN (EXTRACT(MONTH FROM date_series.date) = 1 AND EXTRACT(DAY FROM date_series.date) <= 7)
          OR (EXTRACT(MONTH FROM date_series.date) = 4 AND EXTRACT(DAY FROM date_series.date) BETWEEN 13 AND 17)
        THEN (SELECT rate_tier_id FROM rate_tiers WHERE name = 'Peak Season')
        
        -- High Season: วันศุกร์-เสาร์ หรือช่วงเดือนธันวาคม
        WHEN EXTRACT(DOW FROM date_series.date) IN (5, 6)
          OR EXTRACT(MONTH FROM date_series.date) = 12
        THEN (SELECT rate_tier_id FROM rate_tiers WHERE name = 'High Season')
        
        -- Low Season: วันอังคาร-พุธ ในเดือนพฤษภาคม-กันยายน
        WHEN EXTRACT(DOW FROM date_series.date) IN (2, 3)
         AND EXTRACT(MONTH FROM date_series.date) BETWEEN 5 AND 9
        THEN (SELECT rate_tier_id FROM rate_tiers WHERE name = 'Low Season')
        
        -- Standard: วันอื่นๆ
        ELSE (SELECT rate_tier_id FROM rate_tiers WHERE name = 'Standard')
    END as rate_tier_id,
    CASE 
        WHEN (EXTRACT(MONTH FROM date_series.date) = 1 AND EXTRACT(DAY FROM date_series.date) <= 7)
        THEN 'ช่วงปีใหม่'
        WHEN (EXTRACT(MONTH FROM date_series.date) = 4 AND EXTRACT(DAY FROM date_series.date) BETWEEN 13 AND 17)
        THEN 'ช่วงสงกรานต์'
        WHEN EXTRACT(DOW FROM date_series.date) IN (5, 6)
        THEN 'วันหยุดสุดสัปดาห์'
        ELSE NULL
    END as notes
FROM generate_series(
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '90 days',
    INTERVAL '1 day'
) as date_series(date)
ON CONFLICT (date) DO NOTHING;

-- ============================================================================
-- 16. SEED DATA - Room Inventory (90 วันข้างหน้า)
-- ============================================================================

-- สร้าง inventory สำหรับทุกประเภทห้องสำหรับ 90 วันข้างหน้า
INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
SELECT 
    rt.room_type_id,
    date_series.date,
    rt.default_allotment as allotment,
    -- จำลองการจองบางส่วน (สุ่ม 0-30% ของ allotment)
    FLOOR(RANDOM() * rt.default_allotment * 0.3)::INT as booked_count,
    -- จำลอง tentative (สุ่ม 0-10% ของ allotment)
    FLOOR(RANDOM() * rt.default_allotment * 0.1)::INT as tentative_count
FROM room_types rt
CROSS JOIN generate_series(
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '90 days',
    INTERVAL '1 day'
) as date_series(date)
ON CONFLICT (room_type_id, date) DO NOTHING;

-- ปรับให้แน่ใจว่า booked_count + tentative_count <= allotment
UPDATE room_inventory
SET tentative_count = GREATEST(0, allotment - booked_count - tentative_count)
WHERE booked_count + tentative_count > allotment;

-- ============================================================================
-- 17. SEED DATA - Vouchers (5 คูปอง)
-- ============================================================================

INSERT INTO vouchers (code, discount_type, discount_value, expiry_date, max_uses, description, min_booking_amount)
VALUES 
    ('WELCOME10', 
     'Percentage', 
     10.00, 
     CURRENT_DATE + INTERVAL '90 days',
     100,
     'ส่วนลด 10% สำหรับลูกค้าใหม่',
     1000.00),
    
    ('WEEKEND20', 
     'Percentage', 
     20.00, 
     CURRENT_DATE + INTERVAL '60 days',
     50,
     'ส่วนลด 20% สำหรับการจองวันหยุดสุดสัปดาห์',
     2000.00),
    
    ('SAVE500', 
     'FixedAmount', 
     500.00, 
     CURRENT_DATE + INTERVAL '30 days',
     30,
     'ส่วนลด 500 บาท สำหรับการจองขั้นต่ำ 3000 บาท',
     3000.00),
    
    ('LONGSTAY', 
     'Percentage', 
     25.00, 
     CURRENT_DATE + INTERVAL '120 days',
     20,
     'ส่วนลด 25% สำหรับการจอง 5 คืนขึ้นไป',
     5000.00),
    
    ('FLASH1000', 
     'FixedAmount', 
     1000.00, 
     CURRENT_DATE + INTERVAL '7 days',
     10,
     'Flash Sale! ส่วนลด 1000 บาท (จำกัด 10 สิทธิ์)',
     5000.00)
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- 18. Verification Queries
-- ============================================================================

DO $$
DECLARE
    policy_count INT;
    tier_count INT;
    plan_count INT;
    pricing_count INT;
    calendar_count INT;
    inventory_count INT;
    voucher_count INT;
BEGIN
    SELECT COUNT(*) INTO policy_count FROM cancellation_policies;
    SELECT COUNT(*) INTO tier_count FROM rate_tiers;
    SELECT COUNT(*) INTO plan_count FROM rate_plans;
    SELECT COUNT(*) INTO pricing_count FROM rate_pricing;
    SELECT COUNT(*) INTO calendar_count FROM pricing_calendar;
    SELECT COUNT(*) INTO inventory_count FROM room_inventory;
    SELECT COUNT(*) INTO voucher_count FROM vouchers;
    
    RAISE NOTICE '=== Pricing & Inventory Schema Created Successfully ===';
    RAISE NOTICE 'Cancellation Policies: %', policy_count;
    RAISE NOTICE 'Rate Tiers: %', tier_count;
    RAISE NOTICE 'Rate Plans: %', plan_count;
    RAISE NOTICE 'Rate Pricing Matrix: %', pricing_count;
    RAISE NOTICE 'Pricing Calendar Days: %', calendar_count;
    RAISE NOTICE 'Room Inventory Records: %', inventory_count;
    RAISE NOTICE 'Vouchers: %', voucher_count;
    RAISE NOTICE '==========================================================';
END $$;

-- แสดงสรุปเมทริกซ์ราคา
SELECT 
    rp.name as rate_plan,
    rt.name as room_type,
    tier.name as rate_tier,
    rpr.price
FROM rate_pricing rpr
JOIN rate_plans rp ON rpr.rate_plan_id = rp.rate_plan_id
JOIN room_types rt ON rpr.room_type_id = rt.room_type_id
JOIN rate_tiers tier ON rpr.rate_tier_id = tier.rate_tier_id
ORDER BY rp.name, rt.name, tier.display_order;

-- แสดงสรุป inventory ตามประเภทห้อง
SELECT 
    rt.name as room_type,
    COUNT(*) as total_days,
    ROUND(AVG(ri.allotment), 2) as avg_allotment,
    ROUND(AVG(ri.booked_count), 2) as avg_booked,
    ROUND(AVG(ri.tentative_count), 2) as avg_tentative,
    ROUND(AVG(ri.allotment - ri.booked_count - ri.tentative_count), 2) as avg_available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
GROUP BY rt.name
ORDER BY rt.name;

-- แสดงสรุปปฏิทินราคา
SELECT 
    tier.name as rate_tier,
    COUNT(*) as days_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM pricing_calendar), 2) as percentage
FROM pricing_calendar pc
JOIN rate_tiers tier ON pc.rate_tier_id = tier.rate_tier_id
GROUP BY tier.name, tier.display_order
ORDER BY tier.display_order;

-- แสดงคูปองที่ active
SELECT 
    code,
    discount_type,
    discount_value,
    expiry_date,
    max_uses,
    current_uses,
    (max_uses - current_uses) as remaining_uses
FROM vouchers
WHERE is_active = TRUE
  AND expiry_date >= CURRENT_DATE
ORDER BY expiry_date;
