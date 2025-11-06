#!/bin/bash
# ============================================================================
# Script: run_migration_006.sh (Linux/Mac)
# Description: รัน migration 006 - สร้าง confirm_booking function
# Task: 12. สร้าง PostgreSQL Function - confirm_booking
# ============================================================================

echo "========================================"
echo "Running Migration 006: Confirm Booking Function"
echo "========================================"
echo ""

# ตรวจสอบว่ามี .env file หรือไม่
if [ ! -f "../../.env" ]; then
    echo "Error: .env file not found!"
    echo "Please create .env file in project root with database credentials."
    echo ""
    echo "Example:"
    echo "POSTGRES_HOST=localhost"
    echo "POSTGRES_PORT=5432"
    echo "POSTGRES_DB=hotel_booking"
    echo "POSTGRES_USER=postgres"
    echo "POSTGRES_PASSWORD=yourpassword"
    exit 1
fi

# โหลดค่าจาก .env
export $(cat ../../.env | grep -v '^#' | xargs)

# ตั้งค่า default ถ้าไม่มี
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-hotel_booking}
POSTGRES_USER=${POSTGRES_USER:-postgres}

echo "Connecting to database: $POSTGRES_DB at $POSTGRES_HOST:$POSTGRES_PORT"
echo ""

# รัน migration
echo "Running migration file..."
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -f 006_create_confirm_booking_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Migration 006 completed successfully!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Run tests: ./run_test_confirm_booking.sh"
    echo "2. Verify function: verify_confirm_booking.sql"
    echo ""
else
    echo ""
    echo "========================================"
    echo "Migration 006 failed!"
    echo "========================================"
    echo "Please check the error messages above."
    echo ""
    exit 1
fi
