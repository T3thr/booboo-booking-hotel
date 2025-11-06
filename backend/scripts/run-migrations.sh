#!/bin/bash
# ============================================================================
# Script: run-migrations.sh
# Description: รัน database migrations ทั้งหมดบน production database
# Usage: ./run-migrations.sh
# ============================================================================

set -e

echo "=== Starting Database Migrations ==="

# ตรวจสอบว่ามี DATABASE_URL หรือไม่
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL environment variable is not set"
    exit 1
fi

echo "Database URL: ${DATABASE_URL:0:30}..."

# Array ของ migration files ตามลำดับ
MIGRATIONS=(
    "001_create_guests_tables.sql"
    "002_create_room_management_tables.sql"
    "003_create_pricing_inventory_tables.sql"
    "004_create_bookings_tables.sql"
    "005_create_booking_hold_function.sql"
    "006_create_confirm_booking_function.sql"
    "007_create_cancel_booking_function.sql"
    "008_create_release_expired_holds_function.sql"
    "009_create_check_in_function.sql"
    "010_create_check_out_function.sql"
    "011_create_move_room_function.sql"
    "012_performance_optimization.sql"
)

# รัน migrations ทีละไฟล์
for migration in "${MIGRATIONS[@]}"; do
    echo ""
    echo "Running migration: $migration"
    
    if [ -f "../database/migrations/$migration" ]; then
        psql "$DATABASE_URL" -f "../database/migrations/$migration"
        echo "✓ $migration completed successfully"
    else
        echo "⚠ Warning: Migration file not found: $migration"
    fi
done

echo ""
echo "=== All Migrations Completed Successfully ==="
echo ""
echo "Verifying critical functions..."

# ตรวจสอบว่า functions สำคัญถูกสร้างแล้ว
psql "$DATABASE_URL" -c "
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_booking_hold',
        'confirm_booking',
        'cancel_booking',
        'release_expired_holds',
        'check_in_booking',
        'check_out_booking',
        'move_room'
    )
ORDER BY routine_name;
"

echo ""
echo "=== Migration Verification Complete ==="
