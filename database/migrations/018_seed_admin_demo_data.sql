-- ============================================================================
-- Migration 018: Seed Admin Demo Data
-- Description: เพิ่มข้อมูล demo สำหรับ Admin pages
-- Purpose: ให้ Manager เห็นข้อมูลใน Dashboard, Bookings, Inventory, Reports
-- ============================================================================

\echo '============================================'
\echo 'Migration 018: Seeding Admin Demo Data'
\echo '============================================'

-- ============================================================================
-- 1. เพิ่ม Pending Bookings (สำหรับ Dashboard alerts)
-- ============================================================================
\echo ''
\echo 'Step 1: Adding pending bookings...'

INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(31, 1, 3500.00, 'Pending', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(32, 2, 4200.00, 'Pending', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(33, 3, 2800.00, 'Pending', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '30 minutes')
ON CONFLICT (booking_id) DO NOTHING;

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(31, 31, 1, 1, CURRENT_DATE + INTERVAL '3 days', CURRENT_DATE + INTERVAL '5 days', 2),
(32, 32, 2, 1, CURRENT_DATE + INTERVAL '4 days', CURRENT_DATE + INTERVAL '7 days', 2),
(33, 33, 1, 1, CURRENT_DATE + INTERVAL '2 days', CURRENT_DATE + INTERVAL '4 days', 1)
ON CONFLICT (booking_detail_id) DO NOTHING;

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, phone, type, is_primary) VALUES
(31, 'Somchai', 'Pending1', '0812345678', 'Adult', true),
(32, 'Suda', 'Pending2', '0823456789', 'Adult', true),
(33, 'Niran', 'Pending3', '0834567890', 'Adult', true)
ON CONFLICT DO NOTHING;

\echo 'Added 3 pending bookings.'

-- ============================================================================
-- 2. เพิ่ม Payment Proofs ที่รอตรวจสอบ (สำหรับ Bookings Page)
-- ============================================================================
\echo ''
\echo 'Step 2: Adding pending payment proofs...'

INSERT INTO payment_proofs (booking_id, payment_method, amount, proof_url, status, created_at) VALUES
(31, 'bank_transfer', 3500.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Payment+Proof+1', 'pending', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(32, 'qr_code', 4200.00, 'https://via.placeholder.com/400x600/2196F3/FFFFFF?text=Payment+Proof+2', 'pending', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(33, 'bank_transfer', 2800.00, 'https://via.placeholder.com/400x600/FF9800/FFFFFF?text=Payment+Proof+3', 'pending', CURRENT_TIMESTAMP - INTERVAL '30 minutes')
ON CONFLICT DO NOTHING;

\echo 'Added 3 pending payment proofs.'

-- ============================================================================
-- 3. เพิ่ม Confirmed Bookings พร้อม Approved Payments (สำหรับ Revenue Reports)
-- ============================================================================
\echo ''
\echo 'Step 3: Adding confirmed bookings with approved payments...'

INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(34, 4, 5000.00, 'Confirmed', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_DATE - INTERVAL '1 day'),
(35, 5, 6500.00, 'Confirmed', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_DATE - INTERVAL '2 days'),
(36, 6, 4800.00, 'Confirmed', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_DATE - INTERVAL '3 days')
ON CONFLICT (booking_id) DO NOTHING;

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(34, 34, 2, 1, CURRENT_DATE + INTERVAL '5 days', CURRENT_DATE + INTERVAL '8 days', 2),
(35, 35, 3, 1, CURRENT_DATE + INTERVAL '6 days', CURRENT_DATE + INTERVAL '10 days', 3),
(36, 36, 2, 1, CURRENT_DATE + INTERVAL '4 days', CURRENT_DATE + INTERVAL '6 days', 2)
ON CONFLICT (booking_detail_id) DO NOTHING;

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, phone, type, is_primary) VALUES
(34, 'Apinya', 'Confirmed1', '0845678901', 'Adult', true),
(35, 'Wichai', 'Confirmed2', '0856789012', 'Adult', true),
(36, 'Pranee', 'Confirmed3', '0867890123', 'Adult', true)
ON CONFLICT DO NOTHING;

-- เพิ่ม approved payment proofs
INSERT INTO payment_proofs (booking_id, payment_method, amount, proof_url, status, approved_at, created_at) VALUES
(34, 'bank_transfer', 5000.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Approved+1', 'approved', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_DATE - INTERVAL '1 day'),
(35, 'qr_code', 6500.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Approved+2', 'approved', CURRENT_TIMESTAMP - INTERVAL '18 hours', CURRENT_DATE - INTERVAL '2 days'),
(36, 'bank_transfer', 4800.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Approved+3', 'approved', CURRENT_TIMESTAMP - INTERVAL '24 hours', CURRENT_DATE - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

\echo 'Added 3 confirmed bookings with approved payments.'

-- ============================================================================
-- 4. Update Room Inventory
-- ============================================================================
\echo ''
\echo 'Step 4: Updating room inventory...'

-- Update for booking 31 (Standard Room, 3-5 days from now)
UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 1 
  AND date >= CURRENT_DATE + INTERVAL '3 days' 
  AND date < CURRENT_DATE + INTERVAL '5 days';

-- Update for booking 32 (Deluxe Room, 4-7 days from now)
UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 2 
  AND date >= CURRENT_DATE + INTERVAL '4 days' 
  AND date < CURRENT_DATE + INTERVAL '7 days';

-- Update for booking 33 (Standard Room, 2-4 days from now)
UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 1 
  AND date >= CURRENT_DATE + INTERVAL '2 days' 
  AND date < CURRENT_DATE + INTERVAL '4 days';

-- Update for booking 34 (Deluxe Room, 5-8 days from now)
UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 2 
  AND date >= CURRENT_DATE + INTERVAL '5 days' 
  AND date < CURRENT_DATE + INTERVAL '8 days';

-- Update for booking 35 (Suite, 6-10 days from now)
UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 3 
  AND date >= CURRENT_DATE + INTERVAL '6 days' 
  AND date < CURRENT_DATE + INTERVAL '10 days';

-- Update for booking 36 (Deluxe Room, 4-6 days from now)
UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 2 
  AND date >= CURRENT_DATE + INTERVAL '4 days' 
  AND date < CURRENT_DATE + INTERVAL '6 days';

\echo 'Room inventory updated.'

-- ============================================================================
-- 5. Verification
-- ============================================================================
\echo ''
\echo '============================================'
\echo 'Verification Results'
\echo '============================================'

\echo ''
\echo 'Pending Bookings:'
SELECT booking_id, guest_id, total_amount, status, created_at
FROM bookings
WHERE status = 'Pending'
ORDER BY created_at DESC;

\echo ''
\echo 'Pending Payment Proofs:'
SELECT pp.booking_id, pp.payment_method, pp.amount, pp.status, pp.created_at
FROM payment_proofs pp
WHERE pp.status = 'pending'
ORDER BY pp.created_at DESC;

\echo ''
\echo 'Approved Payment Proofs:'
SELECT pp.booking_id, pp.payment_method, pp.amount, pp.status, pp.approved_at
FROM payment_proofs pp
WHERE pp.status = 'approved'
ORDER BY pp.approved_at DESC;

\echo ''
\echo 'Room Inventory Summary (Next 10 Days):'
SELECT 
    ri.date,
    rt.name as room_type,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '10 days'
ORDER BY ri.date, rt.name;

\echo ''
\echo '============================================'
\echo 'Migration 018 Completed Successfully!'
\echo '============================================'
\echo ''
\echo 'Summary:'
\echo '- Added 3 pending bookings with payment proofs'
\echo '- Added 3 confirmed bookings with approved payments'
\echo '- Updated room inventory for all new bookings'
\echo ''
\echo 'You can now test:'
\echo '1. Manager Dashboard - Should show pending payments alert'
\echo '2. Manager > Bookings - Should show 3 pending payment proofs'
\echo '3. Manager > Inventory - Should show updated inventory'
\echo '4. Manager > Reports - Should show revenue from approved payments'
\echo '============================================'

COMMIT;
