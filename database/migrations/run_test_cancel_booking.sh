#!/bin/bash
# ============================================================================
# Test Script: Cancel Booking Function
# ============================================================================

echo ""
echo "========================================"
echo "Testing cancel_booking Function"
echo "========================================"
echo ""

# Check if PostgreSQL is accessible
if ! psql -U postgres -d hotel_booking -c "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Cannot connect to PostgreSQL database"
    exit 1
fi

echo "Running comprehensive tests..."
echo ""
psql -U postgres -d hotel_booking -f test_cancel_booking_function.sql

if [ $? -ne 0 ]; then
    echo ""
    echo "========================================"
    echo "Tests FAILED"
    echo "========================================"
    exit 1
fi

echo ""
echo "========================================"
echo "All Tests Passed!"
echo "========================================"
echo ""
