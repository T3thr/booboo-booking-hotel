#!/bin/bash
# ============================================================================
# Script: run_test_release_expired_holds.sh
# Description: Test release_expired_holds function
# Task: 14. สร้าง PostgreSQL Function - release_expired_holds
# ============================================================================

echo ""
echo "========================================"
echo "Testing release_expired_holds Function"
echo "========================================"
echo ""

# Load environment variables
if [ -f "../../.env" ]; then
    export $(cat ../../.env | grep -v '^#' | xargs)
fi

# Set default values if not in .env
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-hotel_booking}
DB_USER=${DB_USER:-postgres}

echo "Connecting to: $DB_HOST:$DB_PORT/$DB_NAME"
echo ""

# Run tests
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f test_release_expired_holds_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Tests completed!"
    echo "========================================"
    echo ""
else
    echo ""
    echo "========================================"
    echo "Tests FAILED!"
    echo "========================================"
    echo ""
    exit 1
fi
