#!/bin/bash
# ============================================================================
# Run Demo Data Seed Script via Docker (Linux/Mac)
# ============================================================================

echo "============================================================================"
echo "Hotel Reservation System - Demo Data Seed (Docker)"
echo "============================================================================"
echo ""

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo "ERROR: Docker is not running or not installed."
    echo "Please start Docker and try again."
    exit 1
fi

echo "Checking if database container is running..."
if ! docker ps --filter "name=postgres" --format "{{.Names}}" | grep -q "postgres"; then
    echo "ERROR: PostgreSQL container is not running."
    echo "Please start the database with: docker-compose up -d postgres"
    exit 1
fi

echo ""
echo "Running demo data seed script via Docker..."
echo ""

# Run the seed script through Docker
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < 013_seed_demo_data.sql

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
    echo "Staff Account:"
    echo "  Email: staff@hotel.com"
    echo "  Password: staff123"
    echo ""
    echo "Housekeeper Account:"
    echo "  Email: housekeeper@hotel.com"
    echo "  Password: housekeeper123"
    echo ""
    echo "Manager Account:"
    echo "  Email: manager@hotel.com"
    echo "  Password: manager123"
    echo ""
    echo "============================================================================"
else
    echo ""
    echo "ERROR: Failed to seed demo data."
    echo ""
    echo "Troubleshooting:"
    echo "1. Make sure PostgreSQL container is running: docker ps"
    echo "2. Check container name: docker ps --filter 'name=postgres'"
    echo "3. Try: docker exec -it booking-hotel-postgres-1 psql -U postgres -d hotel_booking"
    echo ""
    exit 1
fi
