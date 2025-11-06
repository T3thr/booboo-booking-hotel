# Task 5 Summary: Pricing & Inventory Schema

## Overview
สร้างตารางสำหรับการจัดการราคาและสต็อกห้องพัก (Pricing & Inventory Management) ซึ่งเป็นส่วนสำคัญของระบบจองโรงแรม

## Tables Created

### 1. cancellation_policies
นโยบายการยกเลิกการจอง
- **Columns**: policy_id, name, description, days_before_check_in, refund_percentage, is_active
- **Constraints**: 
  - UNIQUE(name)
  - CHECK(days_before_check_in >= 0)
  - CHECK(refund_percentage BETWEEN 0 AND 100)
- **Seed Data**: 3 policies (Flexible, Moderate, Non-Refundable)    

### 2. rate_tiers
ระดับราคาตามฤดูกาล
- **Columns**: rate_tier_id, name, description, display_order, color_code, is_active
- **Constraints**: UNIQUE(name)
- **Seed Data**: 4 tiers (Low Season, Standard, High Season, Peak Season)

### 3. rate_plans
แผนราคา
- **Columns**: rate_plan_id, name, description, policy_id, is_active
- **Constraints**: 
  - UNIQUE(name)
  - FOREIGN KEY(policy_id) REFERENCES cancellation_policies
- **Seed Data**: 2 plans (Standard Rate, Non-Refundable Rate)

### 4. pricing_calendar
ปฏิทินกำหนดระดับราคาสำหรับแต่ละวัน
- **Columns**: date (PK), rate_tier_id, notes
- **Constraints**: FOREIGN KEY(rate_tier_id) REFERENCES rate_tiers
- **Seed Data**: 90 days ahead with intelligent tier assignment

### 5. rate_pricing
เมทริกซ์ราคา (Rate Plan × Room Type × Rate Tier)
- **Columns**: rate_plan_id, room_type_id, rate_tier_id, price
- **Constraints**: 
  - PRIMARY KEY(rate_plan_id, room_type_id, rate_tier_id)
  - CHECK(price >= 0)
  - Foreign keys to all three dimensions
- **Seed Data**: Complete matrix for all combinations (24 records)

### 6. room_inventory
สต็อกห้องพักสำหรับแต่ละวัน
- **Columns**: room_type_id, date, allotment, booked_count, tentative_count
- **Constraints**: 
  - PRIMARY KEY(room_type_id, date)
  - CHECK(allotment >= 0)
  - CHECK(booked_count >= 0)
  - CHECK(tentative_count >= 0)
  - **CRITICAL**: CHECK(booked_count + tentative_count <= allotment)
- **Seed Data**: 90 days × 3 room types = 270 records with simulated bookings

### 7. vouchers
คูปองส่วนลด
- **Columns**: voucher_id, code, discount_type, discount_value, expiry_date, max_uses, current_uses, min_booking_amount, is_active
- **Constraints**: 
  - UNIQUE(code)
  - CHECK(discount_type IN ('Percentage', 'FixedAmount'))
  - CHECK(discount_value > 0)
  - CHECK(max_uses > 0)
  - CHECK(current_uses >= 0)
  - CHECK(current_uses <= max_uses)
- **Seed Data**: 5 vouchers with various discount types

### 8. booking_holds
การจองห้องชั่วคราว (15 นาที)
- **Columns**: hold_id, session_id, guest_account_id, room_type_id, date, hold_expiry
- **Constraints**: 
  - Foreign keys to guest_accounts and room_types
- **Purpose**: Prevent race conditions during booking process

## Indexes Created

### Performance Indexes
1. **room_inventory**:
   - `idx_room_inventory_date` - Fast date lookups
   - `idx_room_inventory_room_type` - Fast room type filtering
   - `idx_room_inventory_availability` - Partial index for available rooms only

2. **pricing_calendar**:
   - `idx_pricing_calendar_date` - Fast date lookups
   - `idx_pricing_calendar_tier` - Fast tier filtering

3. **rate_pricing**:
   - `idx_rate_pricing_room_type` - Fast room type lookups
   - `idx_rate_pricing_tier` - Fast tier lookups

4. **booking_holds**:
   - `idx_booking_holds_expiry` - Critical for cleanup job
   - `idx_booking_holds_session` - Fast session lookups
   - `idx_booking_holds_guest` - Fast guest lookups
   - `idx_booking_holds_room_date` - Fast room/date lookups

5. **vouchers**:
   - `idx_vouchers_code` - Fast code validation (active only)
   - `idx_vouchers_expiry` - Fast expiry checks (active only)

## Key Features

### 1. Dynamic Pricing System
- **Rate Tiers**: 4 seasonal pricing levels
- **Rate Plans**: Multiple pricing strategies with different cancellation policies
- **Pricing Calendar**: Daily tier assignment for 90 days
- **Rate Matrix**: Complete price configuration for all combinations

### 2. Inventory Management
- **Allotment Control**: Set available rooms per day
- **Booking Tracking**: Track confirmed bookings (booked_count)
- **Hold Tracking**: Track temporary holds (tentative_count)
- **Constraint Enforcement**: Prevent overbooking at database level

### 3. Cancellation Policies
- **Policy Snapshot**: Policies are stored with bookings (immutable)
- **Flexible Options**: Multiple refund percentages and timeframes
- **Rate Plan Integration**: Each rate plan links to a policy

### 4. Voucher System
- **Discount Types**: Percentage or fixed amount
- **Usage Limits**: Max uses and current uses tracking
- **Expiry Management**: Date-based expiration
- **Minimum Amount**: Enforce minimum booking amount

### 5. Booking Hold System
- **Race Condition Prevention**: Temporary inventory reservation
- **Session Tracking**: Track holds by session ID
- **Expiry Management**: 15-minute hold duration
- **Cleanup Ready**: Indexed for efficient cleanup job

## Seed Data Summary

| Table | Records | Description |
|-------|---------|-------------|
| cancellation_policies | 3 | Flexible, Moderate, Non-Refundable |
| rate_tiers | 4 | Low, Standard, High, Peak seasons |
| rate_plans | 2 | Standard Rate, Non-Refundable Rate |
| rate_pricing | 24 | 2 plans × 3 room types × 4 tiers |
| pricing_calendar | 90 | 90 days with intelligent tier assignment |
| room_inventory | 270 | 90 days × 3 room types with simulated data |
| vouchers | 5 | Various discount types and amounts |

## Price Examples

### Standard Room Pricing (Standard Rate)
- Low Season: ฿1,200
- Standard: ฿1,500
- High Season: ฿1,800
- Peak Season: ฿2,200

### Deluxe Room Pricing (Standard Rate)
- Low Season: ฿2,000
- Standard: ฿2,500
- High Season: ฿3,000
- Peak Season: ฿3,800

### Suite Room Pricing (Standard Rate)
- Low Season: ฿3,600
- Standard: ฿4,500
- High Season: ฿5,500
- Peak Season: ฿7,000

**Non-Refundable Rate**: 15% discount from Standard Rate

## Critical Constraints

### 1. Inventory Capacity Constraint
```sql
CHECK (booked_count + tentative_count <= allotment)
```
**Purpose**: Prevent overbooking at database level

### 2. Voucher Usage Constraint
```sql
CHECK (current_uses <= max_uses)
```
**Purpose**: Prevent voucher overuse

### 3. Refund Percentage Constraint
```sql
CHECK (refund_percentage >= 0 AND refund_percentage <= 100)
```
**Purpose**: Ensure valid refund percentages

## Files Created

1. **003_create_pricing_inventory_tables.sql** - Main migration script
2. **verify_pricing_inventory.sql** - Comprehensive verification script
3. **test_migration_003.sql** - Test suite with 10 test cases
4. **run_migration_003.bat** - Windows run script
5. **run_migration_003.sh** - Linux/Mac run script
6. **TASK_5_SUMMARY.md** - This documentation

## How to Run

### Windows
```cmd
cd database/migrations
run_migration_003.bat
```

### Linux/Mac
```bash
cd database/migrations
chmod +x run_migration_003.sh
./run_migration_003.sh
```

### Docker
```bash
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -f /docker-entrypoint-initdb.d/003_create_pricing_inventory_tables.sql
```

## Verification

Run the verification script to check:
- ✓ All tables created
- ✓ All constraints enforced
- ✓ All indexes created
- ✓ All foreign keys valid
- ✓ Seed data complete
- ✓ Price matrix complete
- ✓ No constraint violations

```bash
psql -U postgres -d hotel_booking -f verify_pricing_inventory.sql
```

## Testing

Run the test script to verify:
- ✓ Price calculation
- ✓ Room availability check
- ✓ Voucher validation
- ✓ Inventory constraint enforcement
- ✓ Multi-day availability
- ✓ Rate plan relationships
- ✓ Pricing calendar coverage
- ✓ Price comparisons
- ✓ Voucher usage limits

```bash
psql -U postgres -d hotel_booking -f test_migration_003.sql
```

## Integration with Previous Tasks

This migration builds upon:
- **Task 3**: Uses `guests` and `guest_accounts` tables
- **Task 4**: Uses `room_types` table for pricing and inventory

## Next Steps (Task 6)

The next migration will create:
- `bookings` table
- `booking_details` table
- `room_assignments` table
- `booking_guests` table
- `booking_nightly_log` table

These tables will use the pricing and inventory tables created in this task.

## Requirements Covered

This migration satisfies requirements:
- **2.1-2.8**: Room search and pricing
- **13.1-13.7**: Inventory management
- **14.1-14.7**: Rate tiers and pricing calendar
- **15.1-15.7**: Rate plans and pricing configuration
- **16.1-16.7**: Cancellation policy management
- **17.1-17.7**: Voucher management

## Notes

1. **Pricing Calendar Logic**: 
   - Peak Season: New Year (Jan 1-7), Songkran (Apr 13-17)
   - High Season: Weekends (Fri-Sat) or December
   - Low Season: Tue-Wed in May-September
   - Standard: All other days

2. **Inventory Simulation**:
   - Booked: 0-30% of allotment (random)
   - Tentative: 0-10% of allotment (random)
   - Ensures constraint compliance

3. **Non-Refundable Discount**:
   - Automatically calculated as 85% of Standard Rate
   - Applied to all room types and tiers

4. **Hold Expiry**:
   - Default: 15 minutes
   - Requires background cleanup job (Task 38)

## Success Criteria

✅ All 8 tables created successfully
✅ All constraints enforced
✅ All indexes created
✅ Complete seed data (90 days)
✅ Price matrix complete (24 combinations)
✅ Verification script passes
✅ Test script passes (10/10 tests)
✅ No constraint violations
✅ Ready for booking system integration
