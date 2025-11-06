#!/bin/bash
# ============================================================================
# Integration Tests Runner for PostgreSQL Functions (Linux/Mac)
# ============================================================================

echo "============================================================"
echo "Running Integration Tests for PostgreSQL Functions"
echo "============================================================"
echo ""

# Check if PostgreSQL is accessible
if ! command -v psql &> /dev/null; then
    echo "ERROR: PostgreSQL is not installed or not in PATH"
    exit 1
fi

# Set database connection parameters
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=hotel_booking
export PGUSER=postgres

echo "Connecting to database: $PGDATABASE"
echo ""

# Run integration tests
psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -f integration_tests.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================"
    echo "Integration tests completed successfully!"
    echo "============================================================"
else
    echo ""
    echo "============================================================"
    echo "Integration tests failed!"
    echo "============================================================"
    exit 1
fi
