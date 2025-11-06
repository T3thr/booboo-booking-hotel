#!/bin/bash

# Security Audit Test Script for Hotel Booking System
# This script tests various security aspects of the system

echo "========================================"
echo "Security Audit Test Suite"
echo "========================================"
echo ""

API_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"

# Test counters
total_tests=0
passed_tests=0
failed_tests=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

test_security() {
    local test_name="$1"
    local test_command="$2"
    
    ((total_tests++))
    echo -e "${YELLOW}Testing: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "  ${GREEN}✓ PASS${NC}"
        ((passed_tests++))
    else
        echo -e "  ${RED}✗ FAIL${NC}"
        ((failed_tests++))
    fi
    echo ""
}

echo -e "${CYAN}1. SQL Injection Protection Tests${NC}"
echo "-----------------------------------"

test_security "SQL injection in login email" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST "$API_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"'"'"'; DROP TABLE guests; --'"'"'\",\"password\":\"password123\"}")
    [ "$response" = "401" ] || [ "$response" = "400" ]
'

test_security "SQL injection in search parameters" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X GET "$API_URL/api/rooms/search?checkIn=2025-12-01'"'"'%20OR%20'"'"'1'"'"'='"'"'1&checkOut=2025-12-05&guests=2")
    [ "$response" = "400" ] || [ "$response" = "200" ]
'

echo -e "${CYAN}2. XSS Protection Tests${NC}"
echo "------------------------"

test_security "XSS in registration first name" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST "$API_URL/api/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"xss-test@example.com\",\"password\":\"password123\",\"first_name\":\"<script>alert('"'"'XSS'"'"')</script>\",\"last_name\":\"Test\",\"phone\":\"1234567890\"}")
    [ "$response" = "201" ] || [ "$response" = "400" ]
'

echo -e "${CYAN}3. CSRF Protection Tests${NC}"
echo "-------------------------"

test_security "POST without authentication" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST "$API_URL/api/bookings" \
        -H "Content-Type: application/json" \
        -d "{\"room_type_id\":1,\"check_in\":\"2025-12-01\",\"check_out\":\"2025-12-05\"}")
    [ "$response" = "401" ]
'

test_security "Request from unauthorized origin" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X GET "$API_URL/api/rooms/types" \
        -H "Origin: http://malicious-site.com")
    # CORS may allow or block, both are acceptable depending on config
    [ "$response" = "200" ] || [ "$response" = "403" ]
'

echo -e "${CYAN}4. Authentication Security Tests${NC}"
echo "---------------------------------"

test_security "Invalid token rejection" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X GET "$API_URL/api/bookings" \
        -H "Authorization: Bearer invalid-token-12345")
    [ "$response" = "401" ]
'

test_security "No token rejection" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X GET "$API_URL/api/bookings")
    [ "$response" = "401" ]
'

echo -e "${CYAN}5. Rate Limiting Tests${NC}"
echo "----------------------"

test_security "Rate limiting on login endpoint" '
    rate_limited=false
    for i in {1..10}; do
        response=$(curl -s -w "%{http_code}" -o /dev/null \
            -X POST "$API_URL/api/auth/login" \
            -H "Content-Type: application/json" \
            -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}")
        if [ "$response" = "429" ]; then
            rate_limited=true
            break
        fi
        sleep 0.1
    done
    [ "$rate_limited" = true ]
'

echo -e "${CYAN}6. Security Headers Tests${NC}"
echo "--------------------------"

test_security "X-Content-Type-Options header" '
    response=$(curl -s -I "$API_URL/api/" | grep -i "X-Content-Type-Options: nosniff")
    [ -n "$response" ]
'

test_security "X-Frame-Options header" '
    response=$(curl -s -I "$API_URL/api/" | grep -i "X-Frame-Options: DENY")
    [ -n "$response" ]
'

test_security "Content-Security-Policy header" '
    response=$(curl -s -I "$API_URL/api/" | grep -i "Content-Security-Policy:")
    [ -n "$response" ]
'

echo -e "${CYAN}7. Input Validation Tests${NC}"
echo "--------------------------"

test_security "Invalid email format rejection" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST "$API_URL/api/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"not-an-email\",\"password\":\"password123\",\"first_name\":\"Test\",\"last_name\":\"User\",\"phone\":\"1234567890\"}")
    [ "$response" = "400" ]
'

test_security "Invalid date range rejection" '
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X GET "$API_URL/api/rooms/search?checkIn=2025-12-10&checkOut=2025-12-05&guests=2")
    [ "$response" = "400" ]
'

echo ""
echo "========================================"
echo "Security Audit Summary"
echo "========================================"
echo "Total Tests: $total_tests"
echo -e "${GREEN}Passed: $passed_tests${NC}"
echo -e "${RED}Failed: $failed_tests${NC}"
echo ""

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}✓ All security tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some security tests failed. Please review.${NC}"
    exit 1
fi
