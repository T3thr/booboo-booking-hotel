-- ============================================================================
-- Migration 020: Seed Check-in/Check-out Test Data
-- Description: เพิ่มข้อมูลทดสอบสำหรับ Check-in และ Check-out
-- Purpose: ให้มีข้อมูลแสดงในหน้า Check-in/Check-out
-- ============================================================================

\echo '============================================'
\echo 'Migration 020: Seeding Check-in/Check-out Test Data'
\echo '============================================'

-- ============================================================================
-- 1. สร้าง Bookings สำหรับ Check-in วันนี้
-- ============================================================================
\echo ''
\echo 'Step 1: Creating Bookings for Today Check-in...'

-- Booking 41: Confirmed - พร้อมเช็คอินวันนี้
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(41, 1, 3000.00, 'Confirmed', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '1 day')
ON CONFLICT (booking_id) DO NOTHING;

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(41, 41, 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 2)
ON CONFLICT (booking_detail_id) DO NOTHING;

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(41, 'Somchai', 'Checkin', 'Adult', true, '0812345678'),
(41, 'Suda', 'Checkin', 'Adult', false, '0823456789')
ON CONFLICT DO NOTHING;

-- Payment Proof (Approved)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, approved_at, created_at) VALUES
(41, 41, 'bank_transfer', 3000.00, 'https://placehold.co/600x400/png?text=Payment+Approved', 'approved', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_TIMESTAMP - INTERVAL '1 day')
ON CONFLICT (payment_proof_id) DO NOTHING;

-- Booking 42: Confirmed - พร้อมเช็คอินวันนี้
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(42, 2, 4500.00, 'Confirmed', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '2 days')
ON CONFLICT (booking_id) DO NOTHING;

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(42, 42, 2, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '3 days', 2)
ON CONFLICT (booking_detail_id) DO NOTHING;

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(42, 'Niran', 'Ready', 'Adult', true, '0834567890'),
(42, 'Nida', 'Ready', 'Adult', false, '0845678901')
ON CONFLICT DO NOTHING;

-- Payment Proof (Approved)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, approved_at, created_at) VALUES
(42, 42, 'qr_code', 4500.00, 'https://placehold.co/600x400/png?text=Payment+Approved', 'approved', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '2 days')
ON CONFLICT (payment_proof_id) DO NOTHING;

-- Booking 43: Confirmed - พร้อมเช็คอินวันนี้
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(43, 3, 9000.00, 'Confirmed', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT (booking_id) DO NOTHING;

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(43, 43, 3, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '3 days', 4)
ON CONFLICT (booking_detail_id) DO NOTHING;

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(43, 'Prasert', 'Suite', 'Adult', true, '0856789012'),
(43, 'Pranee', 'Suite', 'Adult', false, '0867890123'),
(43, 'Pim', 'Suite', 'Child', false, '0878901234'),
(43, 'Ploy', 'Suite', 'Child', false, '0889012345')
ON CONFLICT DO NOTHING;

-- Payment Proof (Approved)
INSERT INTO payment_proofs (payment_proof_id, booking_id, payment_method, amount, proof_url, status, approved_at, created_at) VALUES
(43, 43, 'bank_transfer', 9000.00, 'https://placehold.co/600x400/png?text=Payment+Approved', 'approved', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT (payment_proof_id) DO NOTHING;

\echo 'Created 3 bookings ready for check-in today'

-- ============================================================================
-- 2. สร้าง Bookings ที่เช็คอินแล้ว (สำหรับ Check-out วันนี้)
-- ============================================================================
\echo ''
\echo 'Step 2: Creating Checked-in Bookings for Today Check-out...'

-- Booking 44: CheckedIn - พร้อมเช็คเอาท์วันนี้
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(44, 1, 3000.00, 'CheckedIn', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '2 days')
ON CONFLICT (booking_id) DO NOTHING;

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(44, 44, 1, 1, CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE, 2)
ON CONFLICT (booking_detail_id) DO NOTHING;

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(44, 'Wichai', 'Checkout', 'Adult', true, '0890123456'),
(44, 'Wilai', 'Checkout', 'Adult', false, '0901234567')
ON CONFLICT DO NOTHING;

-- Room Assignment (ห้อง 101)
INSERT INTO room_assignments (room_assignment_id, booking_detail_id, room_id, check_in_datetime, status) VALUES
(44, 44, 1, CURRENT_TIMESTAMP - INTERVAL '2 days', 'Active')
ON CONFLICT (room_assignment_id) DO NOTHING;

-- อัพเดทสถานะห้อง 101 เป็น Occupied
UPDATE rooms SET occupancy_status = 'Occupied' WHERE room_id = 1;

-- Booking 45: CheckedIn - พร้อมเช็คเอาท์วันนี้
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(45, 2, 4500.00, 'CheckedIn', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT (booking_id) DO NOTHING;

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(45, 45, 2, 1, CURRENT_DATE - INTERVAL '3 days', CURRENT_DATE, 2)
ON CONFLICT (booking_detail_id) DO NOTHING;

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary, phone) VALUES
(45, 'Surasak', 'Leaving', 'Adult', true, '0912345678'),
(45, 'Suwanna', 'Leaving', 'Adult', false, '0923456789')
ON CONFLICT DO NOTHING;

-- Room Assignment (ห้อง 201)
INSERT INTO room_assignments (room_assignment_id, booking_detail_id, room_id, check_in_datetime, status) VALUES
(45, 45, 11, CURRENT_TIMESTAMP - INTERVAL '3 days', 'Active')
ON CONFLICT (room_assignment_id) DO NOTHING;

-- อัพเดทสถานะห้อง 201 เป็น Occupied
UPDATE rooms SET occupancy_status = 'Occupied' WHERE room_id = 11;

\echo 'Created 2 checked-in bookings ready for check-out today'

-- ============================================================================
-- 3. สร้าง Nightly Logs
-- ============================================================================
\echo ''
\echo 'Step 3: Creating Nightly Logs...'

-- Nightly logs สำหรับ Booking 41
INSERT INTO booking_nightly_logs (booking_detail_id, date, quoted_price) VALUES
(41, CURRENT_DATE, 1500.00),
(41, CURRENT_DATE + INTERVAL '1 day', 1500.00)
ON CONFLICT DO NOTHING;

-- Nightly logs สำหรับ Booking 42
INSERT INTO booking_nightly_logs (booking_detail_id, date, quoted_price) VALUES
(42, CURRENT_DATE, 1500.00),
(42, CURRENT_DATE + INTERVAL '1 day', 1500.00),
(42, CURRENT_DATE + INTERVAL '2 days', 1500.00)
ON CONFLICT DO NOTHING;

-- Nightly logs สำหรับ Booking 43
INSERT INTO booking_nightly_logs (booking_detail_id, date, quoted_price) VALUES
(43, CURRENT_DATE, 3000.00),
(43, CURRENT_DATE + INTERVAL '1 day', 3000.00),
(43, CURRENT_DATE + INTERVAL '2 days', 3000.00)
ON CONFLICT DO NOTHING;

-- Nightly logs สำหรับ Booking 44
INSERT INTO booking_nightly_logs (booking_detail_id, date, quoted_price) VALUES
(44, CURRENT_DATE - INTERVAL '2 days', 1500.00),
(44, CURRENT_DATE - INTERVAL '1 day', 1500.00)
ON CONFLICT DO NOTHING;

-- Nightly logs สำหรับ Booking 45
INSERT INTO booking_nightly_logs (booking_detail_id, date, quoted_price) VALUES
(45, CURRENT_DATE - INTERVAL '3 days', 1500.00),
(45, CURRENT_DATE - INTERVAL '2 days', 1500.00),
(45, CURRENT_DATE - INTERVAL '1 day', 1500.00)
ON CONFLICT DO NOTHING;

\echo 'Created nightly logs for all bookings'

-- ============================================================================
-- 4. ตรวจสอบข้อมูล
-- ============================================================================
\echo ''
\echo 'Step 4: Verifying Data...'

-- ตรวจสอบ Arrivals วันนี้
\echo ''
\echo 'Arrivals for today:'
SELECT 
    b.booking_id,
    CONCAT(bg.first_name, ' ', bg.last_name) as guest_name,
    rt.name as room_type,
    bd.check_in_date,
    bd.check_out_date,
    b.status,
    pp.status as payment_status
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id AND bg.is_primary = true
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE bd.check_in_date = CURRENT_DATE
  AND b.status = 'Confirmed'
ORDER BY b.booking_id;

-- ตรวจสอบ Departures วันนี้
\echo ''
\echo 'Departures for today:'
SELECT 
    b.booking_id,
    CONCAT(bg.first_name, ' ', bg.last_name) as guest_name,
    r.room_number,
    bd.check_out_date,
    b.total_amount,
    b.status
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id AND bg.is_primary = true
JOIN room_assignments ra ON bd.booking_detail_id = ra.booking_detail_id
JOIN rooms r ON ra.room_id = r.room_id
WHERE bd.check_out_date = CURRENT_DATE
  AND b.status = 'CheckedIn'
  AND ra.check_out_datetime IS NULL
ORDER BY b.booking_id;

-- ตรวจสอบห้องที่ Occupied
\echo ''
\echo 'Occupied rooms:'
SELECT 
    r.room_number,
    r.occupancy_status,
    r.housekeeping_status,
    CONCAT(bg.first_name, ' ', bg.last_name) as guest_name
FROM rooms r
JOIN room_assignments ra ON r.room_id = ra.room_id
JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id AND bg.is_primary = true
WHERE r.occupancy_status = 'Occupied'
  AND ra.check_out_datetime IS NULL
ORDER BY r.room_number;

\echo ''
\echo '============================================'
\echo 'Migration 020 completed successfully!'
\echo '============================================'
\echo ''
\echo 'Summary:'
\echo '- 3 bookings ready for check-in today'
\echo '- 2 bookings ready for check-out today'
\echo '- All payment proofs approved'
\echo '- Nightly logs created'
\echo ''
\echo 'Next steps:'
\echo '1. Start backend: cd backend && go run cmd/server/main.go'
\echo '2. Start frontend: cd frontend && npm run dev'
\echo '3. Login as receptionist@hotel.com / password123'
\echo '4. Go to /admin/checkin or /admin/checkout'
\echo ''
