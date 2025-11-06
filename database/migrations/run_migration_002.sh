#!/bin/bash
# ============================================================================
# Script: run_migration_002.sh
# Description: รัน migration 002 - Room Management Schema
# ============================================================================

echo "========================================"
echo "Running Migration 002: Room Management"
echo "========================================"
echo ""

# ตรวจสอบว่า Docker container กำลังทำงานหรือไม่
if ! docker ps --filter "name=hotel-booking-db" --format "{{.Names}}" | grep -q "hotel-booking-db"; then
    echo "[ERROR] Docker is not running or container 'hotel-booking-db' is not found"
    echo "Please start Docker and run: docker-compose up -d db"
    exit 1
fi

echo "[INFO] Running migration script..."
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < 002_create_room_management_tables.sql

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Migration failed!"
    exit 1
fi

echo ""
echo "[SUCCESS] Migration completed successfully!"
echo ""
echo "========================================"
echo "Running Verification Script..."
echo "========================================"
echo ""

docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < verify_room_management.sql

echo ""
echo "========================================"
echo "Migration 002 Complete!"
echo "========================================"
