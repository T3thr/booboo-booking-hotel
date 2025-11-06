#!/bin/bash
# ============================================================================
# Script: run_test_check_out.sh
# Description: รันการทดสอบ check_out function
# ============================================================================

echo "========================================"
echo "Testing Check-out Function"
echo "========================================"
echo ""

# ตั้งค่า environment variables
export PGHOST=${PGHOST:-localhost}
export PGPORT=${PGPORT:-5432}
export PGDATABASE=${PGDATABASE:-hotel_booking}
export PGUSER=${PGUSER:-postgres}

echo "Running test suite..."
echo ""

psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f test_check_out_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "All tests completed!"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "Tests failed!"
    echo "========================================"
    exit 1
fi
