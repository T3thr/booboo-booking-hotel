#!/bin/bash
# ============================================================================
# Script: run_test_confirm_booking.sh (Linux/Mac)
# Description: รัน test suite สำหรับ confirm_booking function
# Task: 12. สร้าง PostgreSQL Function - confirm_booking
# ============================================================================

echo "========================================"
echo "Testing Confirm Booking Function"
echo "========================================"
echo ""

# ตรวจสอบว่ามี .env file หรือไม่
if [ ! -f "../../.env" ]; then
    echo "Error: .env file not found!"
    exit 1
fi

# โหลดค่าจาก .env
export $(cat ../../.env | grep -v '^#' | xargs)

# ตั้งค่า default
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-hotel_booking}
POSTGRES_USER=${POSTGRES_USER:-postgres}

echo "Running test suite..."
echo ""

# รัน tests
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -f test_confirm_booking_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "All tests completed!"
    echo "========================================"
    echo ""
    echo "Check the output above for test results."
    echo "All tests should show: ✓ TEST X PASSED"
    echo ""
else
    echo ""
    echo "========================================"
    echo "Tests failed!"
    echo "========================================"
    echo "Please check the error messages above."
    echo ""
    exit 1
fi
