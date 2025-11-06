#!/bin/bash
# ============================================================================
# Script: run_migration_010.sh
# Description: รัน migration 010 - สร้าง check_out function
# ============================================================================

echo "========================================"
echo "Running Migration 010: Check-out Function"
echo "========================================"
echo ""

# ตั้งค่า environment variables (ปรับตามการตั้งค่าของคุณ)
export PGHOST=${PGHOST:-localhost}
export PGPORT=${PGPORT:-5432}
export PGDATABASE=${PGDATABASE:-hotel_booking}
export PGUSER=${PGUSER:-postgres}

# รัน migration
echo "Running migration..."
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f 010_create_check_out_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Migration completed successfully!"
    echo "========================================"
    echo ""
    echo "Running verification..."
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f verify_check_out.sql
else
    echo ""
    echo "========================================"
    echo "Migration failed!"
    echo "========================================"
    exit 1
fi

echo ""
echo "========================================"
echo "Next Steps:"
echo "========================================"
echo "1. Run tests: ./run_test_check_out.sh"
echo "2. Review function: CHECK_OUT_REFERENCE.md"
echo "========================================"
