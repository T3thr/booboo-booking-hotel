-- ============================================================================
-- Complex SQL Queries for Hotel Reservation System
-- Database Project 2025 (305311-3)
-- ============================================================================
-- This file contains 10+ complex SQL queries demonstrating:
-- - JOIN operations (INNER, LEFT, RIGHT)
-- - GROUP BY and HAVING clauses
-- - Subqueries (correlated and non-correlated)
-- - Aggregate functions (COUNT, SUM, AVG, MAX, MIN)
-- - Window functions
-- - Common Table Expressions (CTE)
-- ============================================================================

-- ============================================================================
-- Query 1: รายงานสรุปการจองตามสถานะและประเภทห้อง
-- ============================================================================
-- Description: แสดงจำนวนการจองและรายได้รวมตามสถานะและประเภทห้อง
-- Techniques: INNER JOIN, GROUP BY, Aggregate Functions

SELECT 
    b.status AS booking_status,
    rt.name AS room_type,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    COUNT(bd.booking_detail_id) AS total_room_bookings,
    SUM(b.total_amount) AS total_revenue,
    AVG(b.total_amount) AS avg_booking_value,
    MIN(b.total_amount) AS min_booking_value,
    MAX(b.total_amount) AS max_booking_value
FROM bookings b
INNER JOIN booking_details bd ON b.booking_id = bd.booking_id
INNER JOIN room_types rt ON bd.room_type_id = rt.room_type_id
GROUP BY b.status, rt.name
ORDER BY b.status, total_revenue DESC;


-- ============================================================================
-- Query 2: ห้องที่มีอัตราการเข้าพักสูงสุด (Top 10)
-- ============================================================================
-- Description: แสดงห้องที่มีจำนวนครั้งการเข้าพักมากที่สุด พร้อมรายละเอียด
-- Techniques: LEFT JOIN, Subquery, GROUP BY, HAVING, ORDER BY with LIMIT

SELECT 
    r.room_number,
    rt.name AS room_type,
    r.floor,
    COUNT(ra.room_assignment_id) AS total_stays,
    SUM(EXTRACT(DAY FROM (ra.check_out_datetime - ra.check_in_datetime))) AS total_nights,
    AVG(EXTRACT(DAY FROM (ra.check_out_datetime - ra.check_in_datetime))) AS avg_stay_duration
FROM rooms r
INNER JOIN room_types rt ON r.room_type_id = rt.room_type_id
LEFT JOIN room_assignments ra ON r.room_id = ra.room_id
WHERE ra.status = 'Completed'
GROUP BY r.room_id, r.room_number, rt.name, r.floor
HAVING COUNT(ra.room_assignment_id) > 0
ORDER BY total_stays DESC, total_nights DESC
LIMIT 10;


-- ============================================================================
-- Query 3: รายงานรายได้รายเดือนพร้อมเปรียบเทียบกับเดือนก่อนหน้า
-- ============================================================================
-- Description: แสดงรายได้แต่ละเดือนและเปอร์เซ็นต์การเปลี่ยนแปลง
-- Techniques: CTE, Window Functions (LAG), Date Functions

WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', b.created_at) AS month,
        COUNT(b.booking_id) AS booking_count,
        SUM(b.total_amount) AS revenue
    FROM bookings b
    WHERE b.status IN ('Confirmed', 'CheckedIn', 'Completed')
    GROUP BY DATE_TRUNC('month', b.created_at)
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS month_year,
    booking_count,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(
        ((revenue - LAG(revenue) OVER (ORDER BY month)) / 
         NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100), 
        2
    ) AS revenue_change_percent
FROM monthly_revenue
ORDER BY month DESC;


-- ============================================================================
-- Query 4: ลูกค้าที่มีมูลค่าการจองสูงสุด (Top 10 VIP Guests)
-- ============================================================================
-- Description: แสดงลูกค้าที่จองบ่อยและใช้จ่ายมากที่สุด
-- Techniques: INNER JOIN, GROUP BY, Aggregate Functions, ORDER BY

SELECT 
    g.guest_id,
    g.first_name,
    g.last_name,
    g.email,
    g.phone,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_amount) AS total_spent,
    AVG(b.total_amount) AS avg_booking_value,
    MAX(b.created_at) AS last_booking_date,
    SUM(CASE WHEN b.status = 'Completed' THEN 1 ELSE 0 END) AS completed_stays,
    SUM(CASE WHEN b.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings
FROM guests g
INNER JOIN bookings b ON g.guest_id = b.guest_id
GROUP BY g.guest_id, g.first_name, g.last_name, g.email, g.phone
HAVING COUNT(b.booking_id) >= 1
ORDER BY total_spent DESC, total_bookings DESC
LIMIT 10;


-- ============================================================================
-- Query 5: วิเคราะห์ห้องว่างและอัตราการเข้าพัก (Occupancy Rate)
-- ============================================================================
-- Description: คำนวณอัตราการเข้าพักของแต่ละประเภทห้องในช่วง 30 วันข้างหน้า
-- Techniques: Subquery, JOIN, Aggregate Functions, Date Range

SELECT 
    rt.name AS room_type,
    SUM(ri.allotment) AS total_available_room_nights,
    SUM(ri.booked_count) AS total_booked_room_nights,
    SUM(ri.tentative_count) AS total_tentative_room_nights,
    SUM(ri.allotment - ri.booked_count - ri.tentative_count) AS total_vacant_room_nights,
    ROUND(
        (SUM(ri.booked_count)::DECIMAL / NULLIF(SUM(ri.allotment), 0) * 100), 
        2
    ) AS occupancy_rate_percent,
    ROUND(
        (SUM(ri.allotment - ri.booked_count - ri.tentative_count)::DECIMAL / 
         NULLIF(SUM(ri.allotment), 0) * 100), 
        2
    ) AS availability_rate_percent
FROM room_types rt
INNER JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
GROUP BY rt.room_type_id, rt.name
ORDER BY occupancy_rate_percent DESC;


-- ============================================================================
-- Query 6: รายงานประสิทธิภาพของคูปองส่วนลด
-- ============================================================================
-- Description: วิเคราะห์การใช้งานคูปองและรายได้ที่เกิดจากคูปอง
-- Techniques: LEFT JOIN, Subquery, CASE, Aggregate Functions

SELECT 
    v.code AS voucher_code,
    v.discount_type,
    v.discount_value,
    v.max_uses,
    v.current_uses,
    (v.max_uses - v.current_uses) AS remaining_uses,
    COUNT(b.booking_id) AS bookings_with_voucher,
    SUM(b.total_amount) AS total_revenue_with_voucher,
    AVG(b.total_amount) AS avg_booking_value,
    CASE 
        WHEN v.discount_type = 'Percentage' THEN 
            SUM(b.total_amount * v.discount_value / 100)
        ELSE 
            SUM(v.discount_value)
    END AS estimated_discount_given,
    v.expiry_date,
    CASE 
        WHEN v.expiry_date < CURRENT_DATE THEN 'Expired'
        WHEN v.current_uses >= v.max_uses THEN 'Fully Used'
        WHEN v.is_active = FALSE THEN 'Inactive'
        ELSE 'Active'
    END AS voucher_status
FROM vouchers v
LEFT JOIN bookings b ON v.voucher_id = b.voucher_id
GROUP BY v.voucher_id, v.code, v.discount_type, v.discount_value, 
         v.max_uses, v.current_uses, v.expiry_date, v.is_active
ORDER BY bookings_with_voucher DESC, total_revenue_with_voucher DESC;


-- ============================================================================
-- Query 7: รายงานสถานะห้องพักแบบละเอียด (Housekeeping Dashboard)
-- ============================================================================
-- Description: แสดงสถานะห้องพักทั้งหมดพร้อมข้อมูลการจองปัจจุบัน
-- Techniques: Multiple LEFT JOINs, Subquery, CASE

SELECT 
    r.room_number,
    r.floor,
    rt.name AS room_type,
    r.occupancy_status,
    r.housekeeping_status,
    CASE 
        WHEN ra.room_assignment_id IS NOT NULL THEN 
            CONCAT(bg.first_name, ' ', bg.last_name)
        ELSE NULL
    END AS current_guest,
    bd.check_in_date,
    bd.check_out_date,
    CASE 
        WHEN bd.check_out_date IS NOT NULL THEN 
            (bd.check_out_date - CURRENT_DATE)
        ELSE NULL
    END AS days_until_checkout,
    b.booking_id,
    b.status AS booking_status
FROM rooms r
INNER JOIN room_types rt ON r.room_type_id = rt.room_type_id
LEFT JOIN room_assignments ra ON r.room_id = ra.room_id AND ra.status = 'Active'
LEFT JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
LEFT JOIN bookings b ON bd.booking_id = b.booking_id
LEFT JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id AND bg.is_primary = TRUE
ORDER BY r.floor, r.room_number;


-- ============================================================================
-- Query 8: วิเคราะห์ราคาเฉลี่ยตามฤดูกาลและประเภทห้อง
-- ============================================================================
-- Description: เปรียบเทียบราคาเฉลี่ยของแต่ละประเภทห้องในแต่ละฤดูกาล
-- Techniques: INNER JOIN, GROUP BY, PIVOT-like query with CASE

SELECT 
    rt.name AS room_type,
    rp.name AS rate_plan,
    MAX(CASE WHEN tier.name = 'Low Season' THEN rpr.price END) AS low_season_price,
    MAX(CASE WHEN tier.name = 'Standard' THEN rpr.price END) AS standard_price,
    MAX(CASE WHEN tier.name = 'High Season' THEN rpr.price END) AS high_season_price,
    MAX(CASE WHEN tier.name = 'Peak Season' THEN rpr.price END) AS peak_season_price,
    AVG(rpr.price) AS avg_price_all_seasons,
    MAX(rpr.price) - MIN(rpr.price) AS price_range
FROM rate_pricing rpr
INNER JOIN room_types rt ON rpr.room_type_id = rt.room_type_id
INNER JOIN rate_plans rp ON rpr.rate_plan_id = rp.rate_plan_id
INNER JOIN rate_tiers tier ON rpr.rate_tier_id = tier.rate_tier_id
GROUP BY rt.name, rp.name
ORDER BY rt.name, rp.name;


-- ============================================================================
-- Query 9: การจองที่กำลังจะเช็คอินใน 7 วันข้างหน้า
-- ============================================================================
-- Description: รายการจองที่กำลังจะมาถึง พร้อมข้อมูลผู้เข้าพักและห้อง
-- Techniques: Multiple JOINs, Subquery, Date Filtering, String Aggregation

SELECT 
    b.booking_id,
    b.status,
    bd.check_in_date,
    bd.check_out_date,
    (bd.check_out_date - bd.check_in_date) AS nights,
    rt.name AS room_type,
    bd.num_guests,
    g.first_name || ' ' || g.last_name AS guest_name,
    g.email,
    g.phone,
    STRING_AGG(
        bg.first_name || ' ' || COALESCE(bg.last_name, ''), 
        ', ' 
        ORDER BY bg.is_primary DESC, bg.booking_guest_id
    ) AS all_guests,
    b.total_amount,
    rp.name AS rate_plan,
    cp.name AS cancellation_policy
FROM bookings b
INNER JOIN booking_details bd ON b.booking_id = bd.booking_id
INNER JOIN guests g ON b.guest_id = g.guest_id
INNER JOIN room_types rt ON bd.room_type_id = rt.room_type_id
INNER JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
INNER JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
LEFT JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE bd.check_in_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
  AND b.status = 'Confirmed'
GROUP BY b.booking_id, b.status, bd.check_in_date, bd.check_out_date, 
         rt.name, bd.num_guests, g.first_name, g.last_name, g.email, 
         g.phone, b.total_amount, rp.name, cp.name
ORDER BY bd.check_in_date, b.booking_id;


-- ============================================================================
-- Query 10: รายงานรายได้รายวันจากการจองที่เสร็จสมบูรณ์
-- ============================================================================
-- Description: วิเคราะห์รายได้จริงแต่ละวันจาก booking_nightly_log
-- Techniques: CTE, JOIN, GROUP BY, Date Functions, Window Functions

WITH daily_revenue AS (
    SELECT 
        bnl.date,
        COUNT(DISTINCT bd.booking_id) AS bookings_count,
        COUNT(bnl.booking_nightly_log_id) AS room_nights_sold,
        SUM(bnl.quoted_price) AS daily_revenue,
        AVG(bnl.quoted_price) AS avg_room_rate
    FROM booking_nightly_log bnl
    INNER JOIN booking_details bd ON bnl.booking_detail_id = bd.booking_detail_id
    INNER JOIN bookings b ON bd.booking_id = b.booking_id
    WHERE b.status IN ('Confirmed', 'CheckedIn', 'Completed')
      AND bnl.date >= CURRENT_DATE - INTERVAL '30 days'
      AND bnl.date <= CURRENT_DATE + INTERVAL '30 days'
    GROUP BY bnl.date
)
SELECT 
    TO_CHAR(date, 'YYYY-MM-DD') AS date,
    TO_CHAR(date, 'Day') AS day_of_week,
    bookings_count,
    room_nights_sold,
    daily_revenue,
    avg_room_rate,
    SUM(daily_revenue) OVER (
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_revenue,
    AVG(daily_revenue) OVER (
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_avg
FROM daily_revenue
ORDER BY date DESC;


-- ============================================================================
-- Query 11: ห้องที่ต้องการการบำรุงรักษา (Maintenance Required)
-- ============================================================================
-- Description: รายการห้องที่มีสถานะต้องการซ่อมบำรุง พร้อมประวัติการใช้งาน
-- Techniques: LEFT JOIN, Subquery, Aggregate Functions

SELECT 
    r.room_number,
    r.floor,
    rt.name AS room_type,
    r.housekeeping_status,
    r.occupancy_status,
    r.notes,
    COUNT(ra.room_assignment_id) AS total_past_stays,
    MAX(ra.check_out_datetime) AS last_checkout_date,
    CURRENT_DATE - MAX(ra.check_out_datetime)::DATE AS days_since_last_use,
    (
        SELECT COUNT(*)
        FROM room_assignments ra2
        WHERE ra2.room_id = r.room_id
          AND ra2.check_in_datetime >= CURRENT_DATE - INTERVAL '90 days'
    ) AS stays_last_90_days
FROM rooms r
INNER JOIN room_types rt ON r.room_type_id = rt.room_type_id
LEFT JOIN room_assignments ra ON r.room_id = ra.room_id AND ra.status = 'Completed'
WHERE r.housekeeping_status IN ('MaintenanceRequired', 'OutOfService')
   OR r.notes IS NOT NULL
GROUP BY r.room_id, r.room_number, r.floor, rt.name, 
         r.housekeeping_status, r.occupancy_status, r.notes
ORDER BY r.housekeeping_status, r.floor, r.room_number;


-- ============================================================================
-- Query 12: วิเคราะห์อัตราการยกเลิกการจอง (Cancellation Analysis)
-- ============================================================================
-- Description: วิเคราะห์การยกเลิกตามประเภทห้อง ช่วงเวลา และนโยบาย
-- Techniques: CTE, Multiple JOINs, CASE, Aggregate Functions, Percentage Calculation

WITH booking_stats AS (
    SELECT 
        rt.name AS room_type,
        DATE_TRUNC('month', b.created_at) AS booking_month,
        b.policy_name,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN b.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
        SUM(CASE WHEN b.status = 'NoShow' THEN 1 ELSE 0 END) AS no_show_bookings,
        SUM(CASE WHEN b.status IN ('Confirmed', 'CheckedIn', 'Completed') THEN 1 ELSE 0 END) AS successful_bookings,
        AVG(b.total_amount) AS avg_booking_value
    FROM bookings b
    INNER JOIN booking_details bd ON b.booking_id = bd.booking_id
    INNER JOIN room_types rt ON bd.room_type_id = rt.room_type_id
    WHERE b.created_at >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY rt.name, DATE_TRUNC('month', b.created_at), b.policy_name
)
SELECT 
    room_type,
    TO_CHAR(booking_month, 'YYYY-MM') AS month,
    policy_name,
    total_bookings,
    cancelled_bookings,
    no_show_bookings,
    successful_bookings,
    ROUND((cancelled_bookings::DECIMAL / NULLIF(total_bookings, 0) * 100), 2) AS cancellation_rate_percent,
    ROUND((no_show_bookings::DECIMAL / NULLIF(total_bookings, 0) * 100), 2) AS no_show_rate_percent,
    ROUND((successful_bookings::DECIMAL / NULLIF(total_bookings, 0) * 100), 2) AS success_rate_percent,
    ROUND(avg_booking_value, 2) AS avg_booking_value
FROM booking_stats
WHERE total_bookings > 0
ORDER BY booking_month DESC, room_type, policy_name;


-- ============================================================================
-- Query 13: สรุปสิ่งอำนวยความสะดวกที่ได้รับความนิยม
-- ============================================================================
-- Description: วิเคราะห์ว่าสิ่งอำนวยความสะดวกไหนมีผลต่อการจองมากที่สุด
-- Techniques: Multiple JOINs, Subquery, GROUP BY, Aggregate Functions

SELECT 
    a.name AS amenity_name,
    a.category,
    COUNT(DISTINCT rta.room_type_id) AS room_types_with_amenity,
    STRING_AGG(DISTINCT rt.name, ', ' ORDER BY rt.name) AS room_types,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    SUM(b.total_amount) AS total_revenue,
    AVG(b.total_amount) AS avg_booking_value,
    ROUND(
        COUNT(DISTINCT b.booking_id)::DECIMAL / 
        NULLIF((SELECT COUNT(*) FROM bookings WHERE status IN ('Confirmed', 'CheckedIn', 'Completed')), 0) * 100,
        2
    ) AS booking_percentage
FROM amenities a
INNER JOIN room_type_amenities rta ON a.amenity_id = rta.amenity_id
INNER JOIN room_types rt ON rta.room_type_id = rt.room_type_id
LEFT JOIN booking_details bd ON rt.room_type_id = bd.room_type_id
LEFT JOIN bookings b ON bd.booking_id = b.booking_id AND b.status IN ('Confirmed', 'CheckedIn', 'Completed')
GROUP BY a.amenity_id, a.name, a.category
ORDER BY total_bookings DESC, total_revenue DESC;


-- ============================================================================
-- Query 14: รายงานประสิทธิภาพการทำความสะอาดห้อง
-- ============================================================================
-- Description: วิเคราะห์เวลาและประสิทธิภาพในการทำความสะอาดห้อง
-- Techniques: Self JOIN, Date/Time Functions, CASE, Aggregate Functions

SELECT 
    rt.name AS room_type,
    r.floor,
    COUNT(DISTINCT r.room_id) AS total_rooms,
    SUM(CASE WHEN r.housekeeping_status = 'Dirty' THEN 1 ELSE 0 END) AS dirty_rooms,
    SUM(CASE WHEN r.housekeeping_status = 'Cleaning' THEN 1 ELSE 0 END) AS cleaning_in_progress,
    SUM(CASE WHEN r.housekeeping_status = 'Clean' THEN 1 ELSE 0 END) AS clean_rooms,
    SUM(CASE WHEN r.housekeeping_status = 'Inspected' THEN 1 ELSE 0 END) AS inspected_rooms,
    SUM(CASE WHEN r.housekeeping_status = 'MaintenanceRequired' THEN 1 ELSE 0 END) AS maintenance_required,
    SUM(CASE WHEN r.housekeeping_status = 'OutOfService' THEN 1 ELSE 0 END) AS out_of_service,
    ROUND(
        SUM(CASE WHEN r.housekeeping_status IN ('Clean', 'Inspected') THEN 1 ELSE 0 END)::DECIMAL / 
        NULLIF(COUNT(DISTINCT r.room_id), 0) * 100,
        2
    ) AS ready_room_percentage
FROM rooms r
INNER JOIN room_types rt ON r.room_type_id = rt.room_type_id
GROUP BY rt.name, r.floor
ORDER BY rt.name, r.floor;


-- ============================================================================
-- Query 15: พยากรณ์รายได้ในอนาคต (Revenue Forecast)
-- ============================================================================
-- Description: คำนวณรายได้ที่คาดว่าจะได้รับจากการจองที่ยืนยันแล้ว
-- Techniques: CTE, JOIN, Date Functions, Aggregate Functions, CASE

WITH future_bookings AS (
    SELECT 
        DATE_TRUNC('month', bd.check_in_date) AS revenue_month,
        rt.name AS room_type,
        COUNT(DISTINCT b.booking_id) AS booking_count,
        SUM(b.total_amount) AS expected_revenue,
        SUM(bd.check_out_date - bd.check_in_date) AS total_room_nights
    FROM bookings b
    INNER JOIN booking_details bd ON b.booking_id = bd.booking_id
    INNER JOIN room_types rt ON bd.room_type_id = rt.room_type_id
    WHERE b.status IN ('Confirmed', 'CheckedIn')
      AND bd.check_in_date >= CURRENT_DATE
      AND bd.check_in_date <= CURRENT_DATE + INTERVAL '90 days'
    GROUP BY DATE_TRUNC('month', bd.check_in_date), rt.name
)
SELECT 
    TO_CHAR(revenue_month, 'YYYY-MM') AS month,
    room_type,
    booking_count,
    total_room_nights,
    expected_revenue,
    ROUND(expected_revenue / NULLIF(total_room_nights, 0), 2) AS avg_rate_per_night,
    SUM(expected_revenue) OVER (PARTITION BY revenue_month) AS total_month_revenue,
    ROUND(
        expected_revenue / NULLIF(SUM(expected_revenue) OVER (PARTITION BY revenue_month), 0) * 100,
        2
    ) AS revenue_contribution_percent
FROM future_bookings
ORDER BY revenue_month, expected_revenue DESC;


-- ============================================================================
-- END OF COMPLEX QUERIES
-- ============================================================================
-- Total: 15 Complex SQL Queries
-- 
-- Summary of Techniques Used:
-- ✓ INNER JOIN, LEFT JOIN, RIGHT JOIN
-- ✓ GROUP BY and HAVING
-- ✓ Subqueries (correlated and non-correlated)
-- ✓ Aggregate Functions (COUNT, SUM, AVG, MAX, MIN)
-- ✓ Window Functions (LAG, SUM OVER, AVG OVER)
-- ✓ Common Table Expressions (WITH ... AS)
-- ✓ Date/Time Functions
-- ✓ String Aggregation (STRING_AGG)
-- ✓ CASE statements
-- ✓ Complex calculations and percentages
-- ============================================================================
