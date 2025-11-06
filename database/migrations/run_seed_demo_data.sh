#!/bin/bash
# ============================================================================
# Run Demo Data Seed Script (Linux/Mac)
# ============================================================================

echo "============================================================================"
echo "Hotel Reservation System - Demo Data Seed"
echo "============================================================================"
echo ""

# Check if PostgreSQL is accessible
if ! command -v psql &> /dev/null; then
    echo "ERROR: psql command not found. Please install PostgreSQL."
    exit 1
fi

# Set database connection parameters
export PGHOST=${PGHOST:-localhost}
export PGPORT=${PGPORT:-5432}
export PGDATABASE=${PGDATABASE:-hotel_booking}
export PGUSER=${PGUSER:-postgres}

echo "Database: $PGDATABASE"
echo "Host: $PGHOST"
echo "Port: $PGPORT"
echo "User: $PGUSER"
echo ""

# Prompt for password if not set
if [ -z "$PGPASSWORD" ]; then
    echo "Please enter PostgreSQL password:"
    read -s PGPASSWORD
    export PGPASSWORD
fi

echo ""
echo "Running demo data seed script..."
echo ""

# Run the seed script
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f 013_seed_demo_data.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================================"
    echo "Demo data seeded successfully!"
    echo "============================================================================"
    echo ""
    echo "You can now use the following credentials to test the system:"
    echo ""
    echo "Guest Account:"
    echo "  Email: somchai@example.com"
    echo "  Password: password123"
    echo ""
    echo "============================================================================"
else
    echo ""
    echo "ERROR: Failed to seed demo data."
    echo "Please check the error messages above."
    echo ""
    exit 1
fi
