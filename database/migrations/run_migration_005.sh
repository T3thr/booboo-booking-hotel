#!/bin/bash
# ============================================================================
# Script: run_migration_005.sh
# Description: รัน migration 005 - create_booking_hold function (Linux/Mac)
# ============================================================================

echo "============================================================================"
echo "Running Migration 005: Create Booking Hold Function"
echo "============================================================================"
echo ""

# ตั้งค่า environment variables (ปรับตามการตั้งค่าของคุณ)
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=hotel_booking_db
export PGUSER=postgres
export PGPASSWORD=postgres123

echo "Connecting to database: $PGDATABASE"
echo ""

# รัน migration
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f 005_create_booking_hold_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================================"
    echo "Migration 005 completed successfully!"
    echo "============================================================================"
    echo ""
    echo "You can now run tests with: ./run_test_booking_hold.sh"
else
    echo ""
    echo "============================================================================"
    echo "Migration 005 failed!"
    echo "============================================================================"
    exit 1
fi
