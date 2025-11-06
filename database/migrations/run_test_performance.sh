#!/bin/bash
# ============================================================================
# Test Performance Optimization
# ============================================================================

echo "========================================"
echo "Testing Performance Optimization"
echo "========================================"
echo ""

# Load environment variables from backend/.env
if [ -f "../../backend/.env" ]; then
    export $(cat ../../backend/.env | grep -v '^#' | xargs)
fi

# Set defaults if not found
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-hotel_booking}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-postgres}

echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "User: $DB_USER"
echo ""

# Set PGPASSWORD for non-interactive execution
export PGPASSWORD=$DB_PASSWORD

echo "Running performance tests..."
echo ""
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f test_performance_optimization.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Performance tests completed!"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "Performance tests failed!"
    echo "========================================"
    exit 1
fi

# Clear password
unset PGPASSWORD
