#!/bin/bash
# ============================================================================
# Script: run_migration_003.sh
# Description: รันไฟล์ migration 003 สำหรับ Linux/Mac
# ============================================================================

echo "========================================"
echo "Running Migration 003: Pricing and Inventory"
echo "========================================"
echo ""

# ตรวจสอบว่ามี PostgreSQL client (psql) หรือไม่
if ! command -v psql &> /dev/null; then
    echo "ERROR: psql not found"
    echo "Please install PostgreSQL client"
    exit 1
fi

# ตั้งค่า environment variables (ปรับตามการตั้งค่าของคุณ)
export PGHOST=${PGHOST:-localhost}
export PGPORT=${PGPORT:-5432}
export PGDATABASE=${PGDATABASE:-hotel_booking}
export PGUSER=${PGUSER:-postgres}

# ถาม password ถ้ายังไม่ได้ตั้งค่า
if [ -z "$PGPASSWORD" ]; then
    read -sp "Enter PostgreSQL password: " PGPASSWORD
    export PGPASSWORD
    echo ""
fi

echo ""
echo "Connecting to database: $PGDATABASE on $PGHOST:$PGPORT"
echo ""

# รัน migration
echo "Running migration script..."
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f 003_create_pricing_inventory_tables.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Migration completed successfully!"
    echo "========================================"
    echo ""
    
    # ถามว่าต้องการรัน verification หรือไม่
    read -p "Run verification script? (Y/N): " RUN_VERIFY
    if [[ "$RUN_VERIFY" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Running verification..."
        psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f verify_pricing_inventory.sql
    fi
    
    # ถามว่าต้องการรัน tests หรือไม่
    read -p "Run test script? (Y/N): " RUN_TESTS
    if [[ "$RUN_TESTS" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Running tests..."
        psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f test_migration_003.sql
    fi
else
    echo ""
    echo "========================================"
    echo "Migration failed!"
    echo "========================================"
    exit 1
fi

echo ""
