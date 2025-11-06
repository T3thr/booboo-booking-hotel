# Pricing & Inventory Quick Reference

## Common Queries

### 1. Check Room Availability for Date Range

```sql
-- Check if room type is available for all dates in range
SELECT 
    rt.name as room_type,
    COUNT(*) as days_checked,
    MIN(ri.allotment - ri.booked_count - ri.tentative_count) as min_available,
    CASE 
        WHEN MIN(ri.allotment - ri.booked_count - ri.tentative_count) > 0 
        THEN 'Available'
        ELSE 'Not Available'
    END as status
FROM room_types rt
JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date >= '2025-11-10' 
  AND ri.date < '2025-11-13'
  AND rt.name = 'Standard Room'
GROUP BY rt.name;
```

### 2. Calculate Total Price for Booking

```sql
-- Calculate total price for a booking
SELECT 
    rt.name as room_type,
    rp.name as rate_plan,
    pc.date,
    tier.name as rate_tier,
    rpr.price as price_per_night,
    SUM(rpr.price) OVER () as total_price
FROM room_types rt
CROSS JOIN rate_plans rp
JOIN rate_pricing rpr ON rt.room_type_id = rpr.room_type_id 
    AND rp.rate_plan_id = rpr.rate_plan_id
JOIN pricing_calendar pc ON rpr.rate_tier_id = pc.rate_tier_id
JOIN rate_tiers tier ON pc.rate_tier_id = tier.rate_tier_id
WHERE rt.name = 'Deluxe Room'
  AND rp.name = 'Standard Rate'
  AND pc.date >= '2025-11-10'
  AND pc.date < '2025-11-13'
ORDER BY pc.date;
```

### 3. Validate Voucher

```sql
-- Check if voucher is valid
SELECT 
    code,
    discount_type,
    discount_value,
    min_booking_amount,
    (max_uses - current_uses) as remaining_uses,
    CASE 
        WHEN expiry_date < CURRENT_DATE THEN 'Expired'
        WHEN current_uses >= max_uses THEN 'Fully Used'
        WHEN NOT is_active THEN 'Inactive'
        ELSE 'Valid'
    END as status
FROM vouchers
WHERE code = 'WELCOME10';
```

### 4. Calculate Discount

```sql
-- Calculate discount amount
WITH booking_info AS (
    SELECT 5000.00 as booking_amount
),
voucher_info AS (
    SELECT 
        discount_type,
        discount_value,
        min_booking_amount
    FROM vouchers
    WHERE code = 'WELCOME10'
)
SELECT 
    b.booking_amount,
    v.discount_type,
    v.discount_value,
    CASE v.discount_type
        WHEN 'Percentage' THEN b.booking_amount * (v.discount_value / 100)
        WHEN 'FixedAmount' THEN v.discount_value
    END as discount_amount,
    b.booking_amount - CASE v.discount_type
        WHEN 'Percentage' THEN b.booking_amount * (v.discount_value / 100)
        WHEN 'FixedAmount' THEN v.discount_value
    END as final_amount
FROM booking_info b
CROSS JOIN voucher_info v
WHERE b.booking_amount >= v.min_booking_amount;
```

### 5. Create Booking Hold

```sql
-- Create a hold (increases tentative_count)
BEGIN;

-- Check availability first
SELECT 
    (allotment - booked_count - tentative_count) as available
FROM room_inventory
WHERE room_type_id = 1
  AND date >= '2025-11-10'
  AND date < '2025-11-13'
FOR UPDATE;

-- If all dates have available > 0, proceed
UPDATE room_inventory
SET tentative_count = tentative_count + 1
WHERE room_type_id = 1
  AND date >= '2025-11-10'
  AND date < '2025-11-13'
  AND (allotment - booked_count - tentative_count) > 0;

-- Insert hold records
INSERT INTO booking_holds (
    session_id, 
    guest_account_id, 
    room_type_id, 
    date, 
    hold_expiry
)
SELECT 
    'session_123',
    1,
    1,
    date_series,
    NOW() + INTERVAL '15 minutes'
FROM generate_series(
    '2025-11-10'::DATE,
    '2025-11-12'::DATE,
    '1 day'::INTERVAL
) as date_series;

COMMIT;
```

### 6. Confirm Booking (Convert Hold to Booking)

```sql
-- Convert tentative to booked
BEGIN;

UPDATE room_inventory
SET 
    booked_count = booked_count + 1,
    tentative_count = tentative_count - 1
WHERE room_type_id = 1
  AND date >= '2025-11-10'
  AND date < '2025-11-13';

-- Delete holds
DELETE FROM booking_holds
WHERE session_id = 'session_123';

COMMIT;
```

### 7. Release Expired Holds

```sql
-- Release holds that have expired
BEGIN;

-- Decrease tentative_count
UPDATE room_inventory ri
SET tentative_count = tentative_count - 1
FROM (
    SELECT room_type_id, date
    FROM booking_holds
    WHERE hold_expiry < NOW()
    GROUP BY room_type_id, date
) expired
WHERE ri.room_type_id = expired.room_type_id 
  AND ri.date = expired.date
  AND ri.tentative_count > 0;

-- Delete expired holds
DELETE FROM booking_holds
WHERE hold_expiry < NOW();

COMMIT;
```

### 8. Get Cancellation Policy for Rate Plan

```sql
-- Get policy details for a rate plan
SELECT 
    rp.name as rate_plan,
    cp.name as policy_name,
    cp.description as policy_description,
    cp.days_before_check_in,
    cp.refund_percentage
FROM rate_plans rp
JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
WHERE rp.name = 'Standard Rate';
```

### 9. Calculate Refund Amount

```sql
-- Calculate refund based on policy
WITH booking_info AS (
    SELECT 
        '2025-11-10'::DATE as check_in_date,
        5000.00 as total_amount,
        7 as days_before_check_in,
        50.00 as refund_percentage
)
SELECT 
    total_amount,
    days_before_check_in,
    refund_percentage,
    total_amount * (refund_percentage / 100) as refund_amount,
    total_amount - (total_amount * (refund_percentage / 100)) as penalty_amount
FROM booking_info;
```

### 10. Get Pricing Calendar for Month

```sql
-- View pricing calendar for a month
SELECT 
    pc.date,
    TO_CHAR(pc.date, 'Day') as day_of_week,
    tier.name as rate_tier,
    tier.color_code,
    pc.notes
FROM pricing_calendar pc
JOIN rate_tiers tier ON pc.rate_tier_id = tier.rate_tier_id
WHERE pc.date >= DATE_TRUNC('month', CURRENT_DATE)
  AND pc.date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
ORDER BY pc.date;
```

### 11. Get Price Matrix

```sql
-- View complete price matrix
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
```

### 12. Get Inventory Summary

```sql
-- Summary of inventory for next 7 days
SELECT 
    rt.name as room_type,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available,
    ROUND(ri.booked_count * 100.0 / ri.allotment, 2) as occupancy_pct
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
  AND ri.date < CURRENT_DATE + INTERVAL '7 days'
ORDER BY rt.name, ri.date;
```

### 13. Update Pricing Calendar (Bulk)

```sql
-- Set all weekends in December to High Season
UPDATE pricing_calendar
SET rate_tier_id = (SELECT rate_tier_id FROM rate_tiers WHERE name = 'High Season')
WHERE EXTRACT(MONTH FROM date) = 12
  AND EXTRACT(DOW FROM date) IN (0, 6)  -- Sunday = 0, Saturday = 6
  AND date >= CURRENT_DATE;
```

### 14. Update Inventory (Bulk)

```sql
-- Increase allotment for all room types for a date range
UPDATE room_inventory
SET allotment = allotment + 2
WHERE date >= '2025-12-01'
  AND date <= '2025-12-31'
  AND (allotment - booked_count - tentative_count) >= 0;
```

### 15. Search Available Rooms with Pricing

```sql
-- Complete search query (availability + pricing)
WITH date_range AS (
    SELECT generate_series(
        '2025-11-10'::DATE,
        '2025-11-12'::DATE,
        '1 day'::INTERVAL
    )::DATE as check_date
),
availability AS (
    SELECT 
        ri.room_type_id,
        COUNT(*) as days_available
    FROM date_range dr
    JOIN room_inventory ri ON dr.check_date = ri.date
    WHERE (ri.allotment - ri.booked_count - ri.tentative_count) > 0
    GROUP BY ri.room_type_id
    HAVING COUNT(*) = (SELECT COUNT(*) FROM date_range)
),
pricing AS (
    SELECT 
        rpr.room_type_id,
        rp.rate_plan_id,
        SUM(rpr.price) as total_price
    FROM date_range dr
    JOIN pricing_calendar pc ON dr.check_date = pc.date
    JOIN rate_pricing rpr ON pc.rate_tier_id = rpr.rate_tier_id
    JOIN rate_plans rp ON rpr.rate_plan_id = rp.rate_plan_id
    WHERE rp.name = 'Standard Rate'
    GROUP BY rpr.room_type_id, rp.rate_plan_id
)
SELECT 
    rt.name as room_type,
    rt.description,
    rt.max_occupancy,
    p.total_price,
    rp.name as rate_plan,
    cp.name as cancellation_policy
FROM availability a
JOIN room_types rt ON a.room_type_id = rt.room_type_id
JOIN pricing p ON rt.room_type_id = p.room_type_id
JOIN rate_plans rp ON p.rate_plan_id = rp.rate_plan_id
JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
WHERE rt.max_occupancy >= 2  -- Guest count filter
ORDER BY p.total_price;
```

## Important Notes

### Inventory Management
1. **Always use transactions** when updating inventory
2. **Check availability before hold** to prevent race conditions
3. **Use FOR UPDATE** when checking availability in transactions
4. **Constraint prevents overbooking** at database level

### Hold Management
1. **Default expiry**: 15 minutes from creation
2. **Cleanup required**: Background job should run every 5 minutes
3. **Session tracking**: Use unique session IDs
4. **Guest association**: Optional but recommended

### Pricing Calculation
1. **Join order matters**: room_type → rate_plan → pricing_calendar → rate_pricing
2. **Date range**: Use >= check_in AND < check_out (exclude checkout date)
3. **Missing prices**: Always check for NULL prices
4. **Tier assignment**: Every date must have a tier

### Voucher Usage
1. **Validate before use**: Check expiry, uses, and minimum amount
2. **Atomic increment**: Use UPDATE with WHERE clause
3. **Prevent overuse**: Constraint enforces max_uses
4. **Discount calculation**: Handle both percentage and fixed amount

### Policy Snapshot
1. **Store with booking**: Copy policy name and description
2. **Immutable**: Never use current policy for old bookings
3. **Refund calculation**: Always use snapshot values

## Performance Tips

1. **Use indexes**: All critical queries are indexed
2. **Limit date ranges**: Don't query more than necessary
3. **Use partial indexes**: Availability index only includes available rooms
4. **Batch operations**: Use bulk updates for date ranges
5. **Connection pooling**: Reuse database connections

## Common Pitfalls

1. ❌ **Don't** update inventory without checking constraint
2. ❌ **Don't** forget to delete holds after confirmation
3. ❌ **Don't** use current policy for refund calculation
4. ❌ **Don't** forget to validate voucher before applying
5. ❌ **Don't** query inventory without date range limit

## Best Practices

1. ✅ **Always use transactions** for multi-row updates
2. ✅ **Check availability** before creating holds
3. ✅ **Validate vouchers** before applying discounts
4. ✅ **Store policy snapshot** with bookings
5. ✅ **Use prepared statements** to prevent SQL injection
6. ✅ **Index foreign keys** for better join performance
7. ✅ **Monitor hold expiry** with background job
8. ✅ **Log all pricing changes** for audit trail
