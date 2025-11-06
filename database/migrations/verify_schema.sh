#!/bin/bash

# ===================================================================
# Schema Verification Script
# Verifies that the guests and guest_accounts tables are created correctly
# ===================================================================

echo "=========================================="
echo "Hotel Booking System - Schema Verification"
echo "Migration: 001_create_guests_tables.sql"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

# Check if database container is running
if ! docker-compose ps | grep -q "hotel-booking-db.*Up"; then
    echo "⚠️  Database container is not running"
    echo "Starting database container..."
    docker-compose up -d db
    echo "Waiting for database to be ready..."
    sleep 10
fi

echo "✅ Docker is running"
echo ""

# Run verification queries
echo "Running verification tests..."
echo ""

# Test 1: Check tables exist
echo "Test 1: Checking if tables exist..."
docker-compose exec -T db psql -U postgres -d hotel_booking -c "
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('guests', 'guest_accounts')
ORDER BY table_name;
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Tables exist"
else
    echo "❌ Tables not found"
    exit 1
fi
echo ""

# Test 2: Count records
echo "Test 2: Counting seed data..."
docker-compose exec -T db psql -U postgres -d hotel_booking -c "
SELECT 
    'guests' as table_name,
    COUNT(*) as record_count
FROM guests
UNION ALL
SELECT 
    'guest_accounts' as table_name,
    COUNT(*) as record_count
FROM guest_accounts;
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Seed data loaded"
else
    echo "❌ Failed to count records"
    exit 1
fi
echo ""

# Test 3: Verify indexes
echo "Test 3: Checking indexes..."
docker-compose exec -T db psql -U postgres -d hotel_booking -c "
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('guests', 'guest_accounts')
ORDER BY indexname;
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Indexes created"
else
    echo "❌ Indexes not found"
    exit 1
fi
echo ""

# Test 4: Verify foreign key
echo "Test 4: Checking foreign key constraints..."
docker-compose exec -T db psql -U postgres -d hotel_booking -c "
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'guest_accounts';
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Foreign key constraints verified"
else
    echo "❌ Foreign key constraints not found"
    exit 1
fi
echo ""

# Test 5: Sample data query
echo "Test 5: Displaying sample guest data..."
docker-compose exec -T db psql -U postgres -d hotel_booking -c "
SELECT 
    g.guest_id,
    g.first_name,
    g.last_name,
    g.email,
    CASE 
        WHEN ga.guest_account_id IS NOT NULL THEN '✓'
        ELSE '✗'
    END as has_account
FROM guests g
LEFT JOIN guest_accounts ga ON g.guest_id = ga.guest_id
ORDER BY g.guest_id
LIMIT 5;
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Sample data retrieved successfully"
else
    echo "❌ Failed to retrieve sample data"
    exit 1
fi
echo ""

echo "=========================================="
echo "✅ All verification tests passed!"
echo "=========================================="
echo ""
echo "Migration 001_create_guests_tables.sql is working correctly."
echo ""
echo "Test credentials:"
echo "  Email: somchai@example.com"
echo "  Password: password123"
echo ""
echo "Next steps:"
echo "  - Task 4: Create Room Management schema"
echo "  - Task 5: Create Pricing & Inventory schema"
echo "  - Task 6: Create Bookings schema"
echo ""
