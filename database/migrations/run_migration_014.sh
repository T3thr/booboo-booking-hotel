#!/bin/bash

# ===================================================================
# Run Migration 014: Role System
# ===================================================================

echo "============================================================================"
echo "Running Migration 014: Role-Based Access Control System"
echo "============================================================================"

# Database connection details
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-hotel_booking}"
DB_USER="${DB_USER:-postgres}"

# Run migration
PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "014_create_role_system.sql"

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================================================"
    echo "Migration 014 completed successfully!"
    echo "============================================================================"
    echo ""
    echo "Demo Credentials:"
    echo "  Manager:      manager@hotel.com / staff123"
    echo "  Receptionist: receptionist1@hotel.com / staff123"
    echo "  Housekeeper:  housekeeper1@hotel.com / staff123"
    echo "  Guest:        anan.test@example.com / password123"
    echo ""
else
    echo ""
    echo "============================================================================"
    echo "Migration 014 failed!"
    echo "============================================================================"
    exit 1
fi
