#!/bin/bash
# ============================================================================
# Script: run_test_check_in.sh
# Description: Test check_in function
# ============================================================================

echo "========================================"
echo "Testing check_in Function"
echo "========================================"
echo ""

# Load environment variables from backend/.env
if [ -f "../../backend/.env" ]; then
    export $(cat ../../backend/.env | grep -v '^#' | xargs)
else
    echo "Error: backend/.env file not found"
    exit 1
fi

# Run tests
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f test_check_in_function.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Tests completed!"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "Tests failed!"
    echo "========================================"
    exit 1
fi
