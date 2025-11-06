-- ============================================================================
-- Migration 019: Seed Complete Admin Demo Data
-- Description: เพิ่มข้อมูลที่จำเป็นสำหรับ Admin Pages ทั้งหมด
-- Purpose: แก้ปัญหาไม่มีข้อมูลแสดงใน Admin Dashboard
-- ============================================================================

\echo '============================================'
\echo 'Migration 019: Seeding Complete Admin Demo Data'
\echo '============================================'

-- ============================================================================
-- 1. เพิ่ม Pending Bookings สำหรับ Dashboard
-- ============================================================================
\echo ''
\echo 'Step 1: Creating Pending Bookings...'

-- Booking 31: PendingPayment - รอตรวจสอบ
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(31, 1, 3500.00, 'PendingPayment', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '2 hours');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(31, 31, 2, 1, CURRENT_DATE + INTERVAL '3 days', CURRENT_DATE + INTERVAL '5 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(31, 'Somchai', 'Pending', 'Adult', true, '0812345678'),
(31, 'Suda', 'Pending', 'Adult', false, '0823456789');

-- Booking 32: PendingPayment - รอตรวจสอบ
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(32, 2, 2800.00, 'PendingPayment', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_TIMESTAMP - INTERVAL '1 hour');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(32, 32, 1, 1, CURRENT_DATE + INTERVAL '7 days', CURRENT_DATE + INTERVAL '9 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(32, 'Niran', 'Waiting', 'Adult', true, '0834567890'),
(32, 'Nida', 'Waiting', 'Adult', false, '0845678901');

-- Booking 33: PendingPayment - รอตรวจสอบ
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(33, 3, 7500.00, 'PendingPayment', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '30 minutes');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(33, 33, 3, 1, CURRENT_DATE + INTERVAL '10 days', CURRENT_DATE + INTERVAL '13 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(33, 'Prasert', 'Review', 'Adult', true, '0856789012'),
(33, 'Pranee', 'Review', 'Adult', false, '0867890123');

\echo 'Created 3 pending bookings'

-- ============================================================================
-- 2. เพิ่ม Payment Proofs สำหรับ Bookings Page
-- ============================================================================
\echo ''
\echo 'Step 2: Creating Payment Proofs...'

-- Payment Proof สำหรับ Booking 31 (Pending)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, created_at) VALUES
(1, 31, 'bank_transfer', 3500.00, 'https://placehold.co/600x400/png?text=Payment+Proof+1', 'pending', CURRENT_TIMESTAMP - INTERVAL '2 hours');

-- Payment Proof สำหรับ Booking 32 (Pending)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, created_at) VALUES
(2, 32, 'qr_code', 2800.00, 'https://placehold.co/600x400/png?text=Payment+Proof+2', 'pending', CURRENT_TIMESTAMP - INTERVAL '1 hour');

-- Payment Proof สำหรับ Booking 33 (Pending)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, created_at) VALUES
(3, 33, 'bank_transfer', 7500.00, 'https://placehold.co/600x400/png?text=Payment+Proof+3', 'pending', CURRENT_TIMESTAMP - INTERVAL '30 minutes');

-- Payment Proof ที่อนุมัติแล้ว (สำหรับ Booking 1)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, approved_at, created_at) VALUES
(4, 1, 'bank_transfer', 3000.00, 'https://placehold.co/600x400/png?text=Payment+Proof+4', 'approved', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '2 days');

-- Payment Proof ที่ปฏิเสธ (สำหรับ Booking 5 ที่ถูก Cancel)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, rejection_reason, rejected_at, created_at) VALUES
(5, 5, 'bank_transfer', 2400.00, 'https://placehold.co/600x400/png?text=Payment+Proof+5', 'rejected', 'ภาพไม่ชัดเจน กรุณาส่งใหม่', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '4 days');

\echo 'Created 5 payment proofs (3 pending, 1 approved, 1 rejected)'

-- ============================================================================
-- 3. เพิ่ม Nightly Logs สำหรับ Pending Bookings
-- ============================================================================
\echo ''
\echo 'Step 3: Creating Nightly Logs for Pending Bookings...'

-- Nightly logs สำหรับ Booking 31
DO $$
DECLARE
    v_date DATE;
    v_price DECIMAL(10,2);
BEGIN
    v_date := CURRENT_DATE + INTERVAL '3 days';
    
    WHILE v_date < CURRENT_DATE + INTERVAL '5 days' LOOP
        -- Get price from rate_pricing
        SELECT rp.price INTO v_price
        FROM rate_pricing rp
        JOIN pricing_calendar pc ON pc.date = v_date
        WHERE rp.rate_plan_id = 1
          AND rp.room_type_id = 2
          AND rp.rate_tier_id = pc.rate_tier_id
        LIMIT 1;
        
        IF v_price IS NULL THEN
            v_price := 1500.00;
        END IF;
        
        INSERT INTO booking_nightly_log (booking_detail_id, date, quoted_price)
        VALUES (31, v_date, v_price);
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
END $$;

-- Nightly logs สำหรับ Booking 32
DO $$
DECLARE
    v_date DATE;
    v_price DECIMAL(10,2);
BEGIN
    v_date := CURRENT_DATE + INTERVAL '7 days';
    
    WHILE v_date < CURRENT_DATE + INTERVAL '9 days' LOOP
        SELECT rp.price INTO v_price
        FROM rate_pricing rp
        JOIN pricing_calendar pc ON pc.date = v_date
        WHERE rp.rate_plan_id = 1
          AND rp.room_type_id = 1
          AND rp.rate_tier_id = pc.rate_tier_id
        LIMIT 1;
        
        IF v_price IS NULL THEN
            v_price := 1000.00;
        END IF;
        
        INSERT INTO booking_nightly_log (booking_detail_id, date, quoted_price)
        VALUES (32, v_date, v_price);
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
END $$;

-- Nightly logs สำหรับ Booking 33
DO $$
DECLARE
    v_date DATE;
    v_price DECIMAL(10,2);
BEGIN
    v_date := CURRENT_DATE + INTERVAL '10 days';
    
    WHILE v_date < CURRENT_DATE + INTERVAL '13 days' LOOP
        SELECT rp.price INTO v_price
        FROM rate_pricing rp
        JOIN pricing_calendar pc ON pc.date = v_date
        WHERE rp.rate_plan_id = 1
          AND rp.room_type_id = 3
          AND rp.rate_tier_id = pc.rate_tier_id
        LIMIT 1;
        
        IF v_price IS NULL THEN
            v_price := 2500.00;
        END IF;
        
        INSERT INTO booking_nightly_log (booking_detail_id, date, quoted_price)
        VALUES (33, v_date, v_price);
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
END $$;

\echo 'Created nightly logs for pending bookings'

-- ============================================================================
-- 4. อัปเดต Inventory สำหรับ Pending Bookings (tentative_count)
-- ============================================================================
\echo ''
\echo 'Step 4: Updating Inventory for Pending Bookings...'

-- Update inventory สำหรับ Booking 31 (Deluxe Room)
UPDATE room_inventory 
SET tentative_count = tentative_count + 1
WHERE room_type_id = 2 
  AND date >= CURRENT_DATE + INTERVAL '3 days' 
  AND date < CURRENT_DATE + INTERVAL '5 days';

-- Update inventory สำหรับ Booking 32 (Standard Room)
UPDATE room_inventory 
SET tentative_count = tentative_count + 1
WHERE room_type_id = 1 
  AND date >= CURRENT_DATE + INTERVAL '7 days' 
  AND date < CURRENT_DATE + INTERVAL '9 days';

-- Update inventory สำหรับ Booking 33 (Suite)
UPDATE room_inventory 
SET tentative_count = tentative_count + 1
WHERE room_type_id = 3 
  AND date >= CURRENT_DATE + INTERVAL '10 days' 
  AND date < CURRENT_DATE + INTERVAL '13 days';

\echo 'Updated inventory with tentative counts'

-- ============================================================================
-- 5. เพิ่มห้องที่ต้องทำความสะอาดและซ่อมบำรุง
-- ============================================================================
\echo ''
\echo 'Step 5: Adding Housekeeping Tasks...'

-- เพิ่มห้องที่ต้องทำความสะอาด (Dirty)
UPDATE rooms SET housekeeping_status = 'Dirty' WHERE room_id IN (107, 207, 308);

-- เพิ่มห้องที่กำลังทำความสะอาด (Cleaning)
UPDATE rooms SET housekeeping_status = 'Cleaning' WHERE room_id IN (109, 407);

-- เพิ่มห้องที่ต้องซ่อมบำรุง (MaintenanceRequired)
UPDATE rooms SET housekeeping_status = 'MaintenanceRequired' WHERE room_id IN (110, 210);

\echo 'Updated housekeeping status for demo'

-- ============================================================================
-- 6. ตรวจสอบผลลัพธ์
-- ============================================================================
\echo ''
\echo '============================================'
\echo 'Verification Results'
\echo '============================================'

-- แสดงสรุป Bookings ตาม Status
\echo ''
\echo 'Booking Status Summary:'
SELECT 
    status,
    COUNT(*) as count,
    SUM(total_amount) as total_revenue
FROM bookings
GROUP BY status
ORDER BY 
    CASE status
        WHEN 'Pending' THEN 1
        WHEN 'Confirmed' THEN 2
        WHEN 'CheckedIn' THEN 3
        WHEN 'Completed' THEN 4
        WHEN 'Cancelled' THEN 5
    END;

-- แสดงสรุป Payment Proofs
\echo ''
\echo 'Payment Proofs Summary:'
SELECT 
    status,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM payment_proofs
GROUP BY status
ORDER BY 
    CASE status
        WHEN 'pending' THEN 1
        WHEN 'approved' THEN 2
        WHEN 'rejected' THEN 3
    END;

-- แสดงสรุป Housekeeping Status
\echo ''
\echo 'Housekeeping Status Summary:'
SELECT 
    housekeeping_status,
    COUNT(*) as count
FROM rooms
GROUP BY housekeeping_status
ORDER BY housekeeping_status;

-- แสดง Pending Bookings พร้อม Payment Proofs
\echo ''
\echo 'Pending Bookings with Payment Proofs:'
SELECT 
    b.booking_id,
    b.total_amount as booking_amount,
    b.status as booking_status,
    pp.payment_proof_id,
    pp.amount as payment_amount,
    pp.payment_method,
    pp.status as payment_status,
    pp.created_at
FROM bookings b
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE b.status = 'PendingPayment'
ORDER BY b.booking_id;

\echo ''
\echo '============================================'
\echo 'Migration 019 Completed Successfully!'
\echo '============================================'
\echo ''
\echo 'Summary:'
\echo '- Added 3 Pending Bookings'
\echo '- Added 5 Payment Proofs (3 pending, 1 approved, 1 rejected)'
\echo '- Updated Inventory with tentative counts'
\echo '- Added Housekeeping tasks for demo'
\echo ''
\echo 'Next Steps:'
\echo '1. Restart Backend: cd backend && go run cmd/server/main.go'
\echo '2. Open Admin Dashboard: http://localhost:3000/admin/dashboard'
\echo '3. Check Bookings Page: http://localhost:3000/admin/bookings'
\echo '4. Check Housekeeping: http://localhost:3000/admin/housekeeping'
\echo '============================================'

COMMIT;
