#!/bin/bash
# ============================================================================
# Run Migration 015: Create Payment Proof Table
# ============================================================================

echo "============================================================================"
echo "Running Migration 015: Create Payment Proof Table"
echo "============================================================================"
echo ""

# Check if PostgreSQL is accessible
if ! command -v psql &> /dev/null; then
    echo "ERROR: PostgreSQL is not installed or not in PATH"
    echo "Please install PostgreSQL or add it to your PATH"
    exit 1
fi

# Set database connection parameters
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=hotel_booking
export PGUSER=postgres

echo "Connecting to database: $PGDATABASE"
echo ""

# Run the migration
psql -U $PGUSER -d $PGDATABASE -f 015_create_payment_proof_table.sql

if [ $? -ne 0 ]; then
    echo ""
    echo "============================================================================"
    echo "ERROR: Migration failed!"
    echo "============================================================================"
    exit 1
fi

echo ""
echo "============================================================================"
echo "Migration 015 completed successfully!"
echo "============================================================================"
echo ""
echo "Next steps:"
echo "1. Restart your backend server"
echo "2. Test payment proof upload functionality"
echo "3. Test admin payment verification"
echo "============================================================================"
