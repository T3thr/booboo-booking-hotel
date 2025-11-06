#!/bin/bash
# ============================================================================
# Script: run_migration_011.sh
# Description: รัน migration 011 - สร้าง move_room function (Linux/Mac)
# ============================================================================

echo "============================================================================"
echo "Running Migration 011: Create Move Room Function"
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

# รัน migration
echo "Running migration script..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f 011_create_move_room_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================================"
    echo "Migration 011 completed successfully!"
    echo "============================================================================"
    echo ""
    echo "Next steps:"
    echo "  1. Run verification: ./run_migration_011.sh verify"
    echo "  2. Run tests: ./run_test_move_room.sh"
    echo ""
else
    echo ""
    echo "============================================================================"
    echo "Migration 011 failed!"
    echo "============================================================================"
    echo "Please check the error messages above."
    echo ""
    exit 1
fi

# ถ้ามี argument "verify" ให้รัน verification
if [ "$1" = "verify" ]; then
    echo ""
    echo "Running verification..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f verify_move_room.sql
fi
