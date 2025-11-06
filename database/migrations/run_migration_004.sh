#!/bin/bash

# ============================================================================
# Run Migration 004: Create Bookings Tables
# ============================================================================

echo "========================================="
echo "Running Migration 004: Bookings Tables"
echo "========================================="
echo ""

# Check if .env file exists
if [ ! -f "../../.env" ]; then
    echo "Error: .env file not found!"
    echo "Please create .env file with database credentials."
    exit 1
fi

# Load environment variables
source ../../.env

# Set default values if not provided
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-hotel_booking}
DB_USER=${DB_USER:-postgres}

echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "User: $DB_USER"
echo ""

# Run migration
echo "Running migration..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 004_create_bookings_tables.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "Migration 004 completed successfully!"
    echo "========================================="
    echo ""
    
    # Ask if user wants to verify
    read -p "Do you want to run verification? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Running verification..."
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f verify_bookings.sql
    fi
    
    # Ask if user wants to run tests
    echo ""
    read -p "Do you want to run tests? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Running tests..."
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f test_migration_004.sql
    fi
else
    echo ""
    echo "========================================="
    echo "Migration 004 failed!"
    echo "========================================="
    exit 1
fi
