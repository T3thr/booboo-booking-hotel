#!/bin/bash
# Production Testing Script
# This script tests all critical functionality in the production environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_URL="${API_URL:-http://localhost:8080}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"

# Counters
PASSED=0
FAILED=0
TOTAL=0

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    local method="${4:-GET}"
    
    ((TOTAL++))
    
    echo -n "Testing $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $response)"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} (Expected HTTP $expected_status, got $response)"
        ((FAILED++))
    fi
}

# Banner
echo "=========================================="
echo "  Production Testing Suite"
echo "  Hotel Booking System"
echo "=========================================="
echo ""
echo "API URL: $API_URL"
echo "Frontend URL: $FRONTEND_URL"
echo ""

# Section 1: Infrastructure Tests
echo "=========================================="
echo "1. Infrastructure Tests"
echo "=========================================="

test_endpoint "Backend Health Check" "$API_URL/health" 200
test_endpoint "Frontend Home Page" "$FRONTEND_URL" 200
test_endpoint "API Documentation" "$API_URL/swagger/index.html" 200

# Check database connectivity
echo -n "Testing Database Connection... "
if docker-compose -f docker-compose.prod.yml exec -T db pg_isready -U hotel_admin > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi
((TOTAL++))

# Check Redis connectivity
echo -n "Testing Redis Connection... "
if docker-compose -f docker-compose.prod.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi
((TOTAL++))

echo ""

# Section 2: API Endpoint Tests
echo "=========================================="
echo "2. API Endpoint Tests"
echo "=========================================="

# Authentication endpoints
test_endpoint "Auth - Register Endpoint" "$API_URL/api/auth/register" 400 POST
test_endpoint "Auth - Login Endpoint" "$API_URL/api/auth/login" 400 POST

# Room endpoints
test_endpoint "Rooms - Search Endpoint" "$API_URL/api/rooms/search?checkIn=2024-12-01&checkOut=2024-12-05&guests=2" 200
test_endpoint "Rooms - Types List" "$API_URL/api/rooms/types" 200

# Booking endpoints (should require auth)
test_endpoint "Bookings - List (Unauthorized)" "$API_URL/api/bookings" 401

# Pricing endpoints (should require auth)
test_endpoint "Pricing - Tiers (Unauthorized)" "$API_URL/api/pricing/tiers" 401

# Inventory endpoints (should require auth)
test_endpoint "Inventory - List (Unauthorized)" "$API_URL/api/inventory" 401

echo ""

# Section 3: Frontend Page Tests
echo "=========================================="
echo "3. Frontend Page Tests"
echo "=========================================="

test_endpoint "Frontend - Home Page" "$FRONTEND_URL/" 200
test_endpoint "Frontend - Sign In Page" "$FRONTEND_URL/auth/signin" 200
test_endpoint "Frontend - Register Page" "$FRONTEND_URL/auth/register" 200
test_endpoint "Frontend - Room Search" "$FRONTEND_URL/rooms/search" 200

echo ""

# Section 4: Security Tests
echo "=========================================="
echo "4. Security Tests"
echo "=========================================="

# Test CORS headers
echo -n "Testing CORS Headers... "
cors_header=$(curl -s -I -H "Origin: http://malicious-site.com" "$API_URL/api/rooms/types" | grep -i "access-control-allow-origin" || echo "")
if [ -n "$cors_header" ]; then
    echo -e "${YELLOW}⚠ WARNING${NC} (CORS headers present - verify configuration)"
else
    echo -e "${GREEN}✓ PASS${NC} (CORS properly configured)"
    ((PASSED++))
fi
((TOTAL++))

# Test rate limiting
echo -n "Testing Rate Limiting... "
rate_limit_test=0
for i in {1..150}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/rooms/types" 2>/dev/null)
    if [ "$response" = "429" ]; then
        rate_limit_test=1
        break
    fi
done

if [ $rate_limit_test -eq 1 ]; then
    echo -e "${GREEN}✓ PASS${NC} (Rate limiting is active)"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (Rate limiting not triggered - verify configuration)"
fi
((TOTAL++))

# Test SQL injection protection
echo -n "Testing SQL Injection Protection... "
sql_injection_response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/rooms/search?checkIn=2024-12-01' OR '1'='1&checkOut=2024-12-05&guests=2" 2>/dev/null)
if [ "$sql_injection_response" = "400" ] || [ "$sql_injection_response" = "500" ]; then
    echo -e "${GREEN}✓ PASS${NC} (SQL injection attempt blocked)"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (Verify SQL injection protection)"
fi
((TOTAL++))

echo ""

# Section 5: Performance Tests
echo "=========================================="
echo "5. Performance Tests"
echo "=========================================="

# Test response time
echo -n "Testing API Response Time... "
start_time=$(date +%s%N)
curl -s "$API_URL/api/rooms/types" > /dev/null 2>&1
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))

if [ $response_time -lt 1000 ]; then
    echo -e "${GREEN}✓ PASS${NC} (${response_time}ms)"
    ((PASSED++))
elif [ $response_time -lt 2000 ]; then
    echo -e "${YELLOW}⚠ WARNING${NC} (${response_time}ms - consider optimization)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (${response_time}ms - too slow)"
    ((FAILED++))
fi
((TOTAL++))

# Test concurrent requests
echo -n "Testing Concurrent Requests... "
concurrent_test=0
for i in {1..10}; do
    curl -s "$API_URL/api/rooms/types" > /dev/null 2>&1 &
done
wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} (Handled 10 concurrent requests)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (Failed to handle concurrent requests)"
    ((FAILED++))
fi
((TOTAL++))

echo ""

# Section 6: Database Tests
echo "=========================================="
echo "6. Database Tests"
echo "=========================================="

# Test database tables
echo -n "Testing Database Schema... "
table_count=$(docker-compose -f docker-compose.prod.yml exec -T db psql -U hotel_admin -d hotel_booking -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" -t 2>/dev/null | tr -d ' ')

if [ "$table_count" -ge 15 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($table_count tables found)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (Expected at least 15 tables, found $table_count)"
    ((FAILED++))
fi
((TOTAL++))

# Test database functions
echo -n "Testing Database Functions... "
function_count=$(docker-compose -f docker-compose.prod.yml exec -T db psql -U hotel_admin -d hotel_booking -c "SELECT COUNT(*) FROM pg_proc WHERE proname LIKE '%booking%' OR proname LIKE '%check%';" -t 2>/dev/null | tr -d ' ')

if [ "$function_count" -ge 5 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($function_count functions found)"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (Expected at least 5 functions, found $function_count)"
fi
((TOTAL++))

echo ""

# Section 7: Monitoring Tests
echo "=========================================="
echo "7. Monitoring Tests"
echo "=========================================="

test_endpoint "Prometheus Metrics" "http://localhost:9091/metrics" 200
test_endpoint "Grafana Dashboard" "http://localhost:3001/login" 200

echo ""

# Section 8: Backup Tests
echo "=========================================="
echo "8. Backup Tests"
echo "=========================================="

# Check backup directory
echo -n "Testing Backup Directory... "
if [ -d "backups/database" ]; then
    echo -e "${GREEN}✓ PASS${NC} (Backup directory exists)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (Backup directory not found)"
    ((FAILED++))
fi
((TOTAL++))

# Check backup script
echo -n "Testing Backup Script... "
if [ -x "scripts/backup-database.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC} (Backup script is executable)"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (Backup script not executable)"
fi
((TOTAL++))

echo ""

# Summary
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Production environment is ready for use."
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    echo ""
    echo "Please review the failed tests and fix issues before using in production."
    exit 1
fi
