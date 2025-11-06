#!/bin/bash
# ============================================================================
# Script: run_test_booking_hold.sh
# Description: ทดสอบ create_booking_hold function (Linux/Mac)
# ============================================================================

echo "============================================================================"
echo "Testing Booking Hold Function"
echo "============================================================================"
echo ""

# ตั้งค่า environment variables
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=hotel_booking_db
export PGUSER=postgres
export PGPASSWORD=postgres123

echo "Connecting to database: $PGDATABASE"
echo ""

# รัน test script
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f test_booking_hold_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================================"
    echo "All tests completed!"
    echo "============================================================================"
else
    echo ""
    echo "============================================================================"
    echo "Tests failed!"
    echo "============================================================================"
    exit 1
fi
