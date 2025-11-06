#!/bin/bash
# ============================================================================
# Run Migration 007: Create Cancel Booking Function
# ============================================================================

echo ""
echo "========================================"
echo "Running Migration 007"
echo "========================================"
echo ""

# Check if PostgreSQL is accessible
if ! psql -U postgres -d hotel_booking -c "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Cannot connect to PostgreSQL database"
    echo "Please ensure:"
    echo "  1. PostgreSQL is running"
    echo "  2. Database 'hotel_booking' exists"
    echo "  3. User 'postgres' has access"
    exit 1
fi

echo "Running migration script..."
psql -U postgres -d hotel_booking -f 007_create_cancel_booking_function.sql

if [ $? -ne 0 ]; then
    echo ""
    echo "========================================"
    echo "Migration 007 FAILED"
    echo "========================================"
    exit 1
fi

echo ""
echo "========================================"
echo "Migration 007 Completed Successfully"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Run tests: ./run_test_cancel_booking.sh"
echo "  2. Verify function: psql -U postgres -d hotel_booking -f verify_cancel_booking.sql"
echo ""
