#!/bin/bash
# ============================================================================
# Script: run_migration_009.sh
# Description: Run migration 009 - Create check_in function
# ============================================================================

echo "========================================"
echo "Running Migration 009"
echo "Creating check_in function"
echo "========================================"
echo ""

# Load environment variables from backend/.env
if [ -f "../../backend/.env" ]; then
    export $(cat ../../backend/.env | grep -v '^#' | xargs)
else
    echo "Error: backend/.env file not found"
    exit 1
fi

# Run migration
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 009_create_check_in_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Migration 009 completed successfully!"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "Migration 009 failed!"
    echo "========================================"
    exit 1
fi
