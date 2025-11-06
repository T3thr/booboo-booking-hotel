#!/bin/bash
# ============================================================================
# Script: run_test_move_room.sh
# Description: ทดสอบ move_room function (Linux/Mac)
# ============================================================================

echo "============================================================================"
echo "Testing Move Room Function"
echo "============================================================================"
echo ""

# ตั้งค่า default values
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-hotel_booking}
DB_USER=${DB_USER:-postgres}

echo "Database Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

echo "Running test script..."
echo ""

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f test_move_room_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================================"
    echo "Tests completed!"
    echo "============================================================================"
    echo "Please review the test results above."
    echo ""
else
    echo ""
    echo "============================================================================"
    echo "Tests failed!"
    echo "============================================================================"
    echo "Please check the error messages above."
    echo ""
    exit 1
fi
