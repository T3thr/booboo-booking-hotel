-- ============================================================================
-- Clean Old Test Bookings
-- ============================================================================
-- ลบ booking ทดสอบเก่าที่มี nightly log อยู่แล้ว
-- เพื่อให้สามารถทดสอบ confirm booking ใหม่ได้

-- ลบ nightly logs ของ bookings ที่ยังไม่ confirm
DELETE FROM booking_nightly_log
WHERE booking_detail_id IN (
    SELECT bd.booking_detail_id
    FROM booking_details bd
    JOIN bookings b ON bd.booking_id = b.booking_id
    WHERE b.status = 'PendingPayment'
);

-- แสดงผลลัพธ์
SELECT 
    'Cleaned nightly logs for PendingPayment bookings' as message,
    COUNT(*) as remaining_logs
FROM booking_nightly_log;

-- แสดง bookings ที่เหลือ
SELECT 
    booking_id,
    status,
    total_amount,
    created_at
FROM bookings
ORDER BY booking_id DESC
LIMIT 10;
