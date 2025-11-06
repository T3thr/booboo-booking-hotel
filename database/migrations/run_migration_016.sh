#!/bin/bash

echo "============================================"
echo "Running Migration 016: Seed Available Inventory"
echo "============================================"
echo ""
echo "This migration will:"
echo "- Delete old inventory data"
echo "- Create new inventory for 100 days"
echo "- Set all rooms as available (booked_count = 0)"
echo "- Add sample bookings (10% occupancy) for realism"
echo ""
echo "Please enter PostgreSQL password when prompted"
echo ""

psql -U postgres -d hotel_booking -f 016_seed_available_inventory.sql

echo ""
echo "============================================"
echo "Migration 016 Completed!"
echo "============================================"
echo ""
echo "Next Steps:"
echo "1. Test Backend API"
echo "2. Test Frontend Room Search"
echo "3. Verify booking functionality"
echo ""
