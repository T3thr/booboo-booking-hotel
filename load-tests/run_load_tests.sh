#!/bin/bash

# Load Testing Script for Unix/Linux/macOS
# Tests race conditions and concurrent booking scenarios

set -e

echo "========================================"
echo "Hotel Booking System - Load Tests"
echo "========================================"
echo ""

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "ERROR: k6 is not installed!"
    echo ""
    echo "Please install k6 first:"
    echo "  - macOS: brew install k6"
    echo "  - Linux: See https://k6.io/docs/getting-started/installation/"
    echo ""
    exit 1
fi

# Set default API URL if not provided
API_URL=${API_URL:-http://localhost:8080}

echo "Using API URL: $API_URL"
echo ""

# Check if backend is running
echo "Checking if backend is running..."
if ! curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/rooms/types" > /dev/null 2>&1; then
    echo "WARNING: Cannot connect to backend at $API_URL"
    echo "Please ensure the backend is running before continuing."
    echo ""
    read -p "Continue anyway? (y/n): " continue
    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "========================================"
echo "Test Menu"
echo "========================================"
echo "1. Run Race Condition Test (50 VUs, 1 min)"
echo "2. Run Concurrent Booking Test (50 users, last room)"
echo "3. Run Connection Pool Test (up to 150 req/s)"
echo "4. Run All Tests"
echo "5. Run Smoke Test (Quick validation)"
echo "6. Run Stress Test (High load)"
echo "0. Exit"
echo ""

read -p "Select test to run (0-6): " choice

case $choice in
    1)
        echo ""
        echo "========================================"
        echo "Running Race Condition Test"
        echo "========================================"
        echo "This test simulates 50 concurrent users attempting to book rooms."
        echo "Expected: Some bookings succeed, some fail, NO overbooking."
        echo ""
        k6 run -e API_URL="$API_URL" race-condition-test.js
        ;;
    2)
        echo ""
        echo "========================================"
        echo "Running Concurrent Booking Test"
        echo "========================================"
        echo "This test simulates 50 users trying to book the LAST available room."
        echo "Expected: Exactly 1 booking succeeds, 49 fail, NO inventory violations."
        echo ""
        k6 run -e API_URL="$API_URL" concurrent-booking-test.js
        ;;
    3)
        echo ""
        echo "========================================"
        echo "Running Connection Pool Test"
        echo "========================================"
        echo "This test stresses the database connection pool with high request rates."
        echo "Expected: System remains stable, no connection errors."
        echo ""
        k6 run -e API_URL="$API_URL" connection-pool-test.js
        ;;
    4)
        echo ""
        echo "========================================"
        echo "Running All Load Tests"
        echo "========================================"
        echo ""
        echo "[1/3] Race Condition Test..."
        k6 run -e API_URL="$API_URL" race-condition-test.js
        echo ""
        echo "[2/3] Concurrent Booking Test..."
        k6 run -e API_URL="$API_URL" concurrent-booking-test.js
        echo ""
        echo "[3/3] Connection Pool Test..."
        k6 run -e API_URL="$API_URL" connection-pool-test.js
        ;;
    5)
        echo ""
        echo "========================================"
        echo "Running Smoke Test (Quick Validation)"
        echo "========================================"
        echo "This is a quick test with 10 VUs for 30 seconds."
        echo ""
        k6 run -e API_URL="$API_URL" --vus 10 --duration 30s race-condition-test.js
        ;;
    6)
        echo ""
        echo "========================================"
        echo "Running Stress Test (High Load)"
        echo "========================================"
        echo "WARNING: This test will generate high load on your system!"
        echo "100 VUs for 2 minutes."
        echo ""
        read -p "Continue? (y/n): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            exit 0
        fi
        echo ""
        k6 run -e API_URL="$API_URL" --vus 100 --duration 2m race-condition-test.js
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo ""
echo "Check the output above for:"
echo "  - Successful Bookings count"
echo "  - Failed Bookings count"
echo "  - Overbookings Detected (MUST BE 0)"
echo "  - Inventory Violations (MUST BE 0)"
echo ""
echo "Summary files have been generated in the current directory."
echo ""
echo "========================================"
echo "Load Testing Complete"
echo "========================================"
echo ""
echo "For detailed documentation, see README.md"
echo ""
