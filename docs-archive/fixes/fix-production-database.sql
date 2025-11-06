-- ============================================================================
-- FIX PRODUCTION DATABASE - Run this in Neon Console
-- ============================================================================
-- คัดลอกและรันใน Neon Console SQL Editor: https://console.neon.tech

-- 1. Create release_expired_holds function
CREATE OR REPLACE FUNCTION release_expired_holds()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    expired_count INTEGER := 0;
BEGIN
    -- Update inventory to release tentative counts for expired holds
    UPDATE room_inventory ri
    SET tentative_count = tentative_count - expired_holds.hold_count
    FROM (
        SELECT 
            room_type_id, 
            date,
            COUNT(*) as hold_count
        FROM booking_holds
        WHERE hold_expiry < NOW()
        GROUP BY room_type_id, date
    ) expired_holds
    WHERE ri.room_type_id = expired_holds.room_type_id 
      AND ri.date = expired_holds.date
      AND ri.tentative_count > 0;

    -- Get count of expired holds before deletion
    SELECT COUNT(*) INTO expired_count
    FROM booking_holds
    WHERE hold_expiry < NOW();

    -- Delete expired holds
    DELETE FROM booking_holds
    WHERE hold_expiry < NOW();

    -- Log the cleanup
    RAISE NOTICE 'Released % expired booking holds', expired_count;
END;
$$;

-- 2. Create night audit function (if not exists)
CREATE OR REPLACE FUNCTION run_night_audit()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    updated_rooms INTEGER := 0;
BEGIN
    -- Update housekeeping status for occupied rooms
    UPDATE rooms
    SET housekeeping_status = 'Dirty'
    WHERE occupancy_status = 'Occupied'
      AND housekeeping_status != 'Dirty';

    GET DIAGNOSTICS updated_rooms = ROW_COUNT;

    -- Log the audit
    RAISE NOTICE 'Night audit completed: % rooms updated to Dirty status', updated_rooms;
END;
$$;

-- 3. Test the functions
SELECT release_expired_holds();
SELECT run_night_audit();

-- 4. Verify functions exist
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('release_expired_holds', 'run_night_audit');

-- Success message
SELECT 'Database functions created successfully!' as status;