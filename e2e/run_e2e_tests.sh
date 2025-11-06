#!/bin/bash

# E2E Tests Runner for Linux/Mac
# This script runs the Playwright E2E tests for the Hotel Booking System

echo "========================================"
echo "Hotel Booking System - E2E Tests"
echo "========================================"
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "[ERROR] Dependencies not installed!"
    echo "Please run: npm install"
    echo ""
    exit 1
fi

# Check if Playwright browsers are installed
if [ ! -d "node_modules/.playwright" ]; then
    echo "[WARNING] Playwright browsers may not be installed"
    echo "Installing Playwright browsers..."
    npx playwright install chromium
    echo ""
fi

# Parse command line arguments
TEST_SUITE=$1
MODE=$2

show_help() {
    echo "Usage: ./run_e2e_tests.sh [suite] [mode]"
    echo ""
    echo "Test Suites:"
    echo "  (none)        - Run all tests"
    echo "  booking       - Run booking flow tests"
    echo "  checkin       - Run check-in flow tests"
    echo "  cancellation  - Run cancellation flow tests"
    echo "  errors        - Run error scenario tests"
    echo ""
    echo "Modes:"
    echo "  headed        - Run tests with visible browser"
    echo "  debug         - Run tests in debug mode"
    echo "  ui            - Run tests in interactive UI mode"
    echo "  report        - Open test report"
    echo ""
    echo "Examples:"
    echo "  ./run_e2e_tests.sh                    - Run all tests"
    echo "  ./run_e2e_tests.sh booking            - Run booking tests"
    echo "  ./run_e2e_tests.sh headed             - Run all tests with browser visible"
    echo "  ./run_e2e_tests.sh report             - View test report"
    echo ""
}

# Main execution
case "$TEST_SUITE" in
    "")
        echo "Running all E2E tests..."
        echo ""
        npm test
        ;;
    "booking")
        echo "Running Booking Flow tests..."
        echo ""
        npm run test:booking
        ;;
    "checkin")
        echo "Running Check-in Flow tests..."
        echo ""
        npm run test:checkin
        ;;
    "cancellation")
        echo "Running Cancellation Flow tests..."
        echo ""
        npm run test:cancellation
        ;;
    "errors")
        echo "Running Error Scenarios tests..."
        echo ""
        npm run test:errors
        ;;
    "headed")
        echo "Running tests in headed mode..."
        echo ""
        npm run test:headed
        ;;
    "debug")
        echo "Running tests in debug mode..."
        echo ""
        npm run test:debug
        ;;
    "ui")
        echo "Running tests in UI mode..."
        echo ""
        npm run test:ui
        ;;
    "report")
        echo "Opening test report..."
        echo ""
        npm run test:report
        ;;
    "help"|"-h"|"--help")
        show_help
        exit 0
        ;;
    *)
        echo "[ERROR] Unknown test suite: $TEST_SUITE"
        echo ""
        show_help
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "Test execution completed"
echo "========================================"
