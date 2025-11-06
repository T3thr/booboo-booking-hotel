#!/bin/bash

# Test Redis Caching Implementation
# This script tests the Redis caching functionality

echo "========================================"
echo "Redis Caching Test Script"
echo "========================================"
echo ""

# Check if Redis is running
echo "1. Checking Redis connection..."
if docker ps | grep -q "hotel-booking-redis"; then
    echo "   ✓ Redis container is running"
else
    echo "   ✗ Redis container is not running"
    echo "   Starting Redis..."
    docker-compose up -d redis
    sleep 5
fi

# Test Redis connection
echo ""
echo "2. Testing Redis connection..."
PING_RESULT=$(docker exec hotel-booking-redis redis-cli ping 2>/dev/null)
if [ "$PING_RESULT" = "PONG" ]; then
    echo "   ✓ Redis is responding"
else
    echo "   ✗ Redis is not responding"
    exit 1
fi

# Run Go tests for cache package
echo ""
echo "3. Running cache unit tests..."
go test ./pkg/cache/... -v
if [ $? -eq 0 ]; then
    echo "   ✓ Cache unit tests passed"
else
    echo "   ✗ Cache unit tests failed"
fi

# Check Redis keys
echo ""
echo "4. Checking Redis keys..."
KEY_COUNT=$(docker exec hotel-booking-redis redis-cli DBSIZE 2>/dev/null)
echo "   Current keys in Redis: $KEY_COUNT"

# Show sample keys
echo ""
echo "5. Sample cache keys:"
KEYS=$(docker exec hotel-booking-redis redis-cli KEYS "*" 2>/dev/null)
if [ -n "$KEYS" ]; then
    echo "$KEYS" | head -10 | while read key; do
        echo "   - $key"
    done
else
    echo "   No keys found in cache"
fi

# Test cache performance
echo ""
echo "6. Testing cache performance..."
echo "   Testing room types endpoint..."

# Check if backend is running
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "   ⚠ Backend is not running. Start it with: go run cmd/server/main.go"
else
    # First request (cache miss)
    echo "   First request (cache miss)..."
    START1=$(date +%s%N)
    curl -s http://localhost:8080/api/rooms/types > /dev/null 2>&1
    END1=$(date +%s%N)
    TIME1=$(echo "scale=2; ($END1 - $START1) / 1000000" | bc)
    echo "   ✓ Response time: ${TIME1}ms"

    # Second request (cache hit)
    sleep 1
    echo "   Second request (cache hit)..."
    START2=$(date +%s%N)
    curl -s http://localhost:8080/api/rooms/types > /dev/null 2>&1
    END2=$(date +%s%N)
    TIME2=$(echo "scale=2; ($END2 - $START2) / 1000000" | bc)
    echo "   ✓ Response time: ${TIME2}ms"
    
    # Calculate improvement
    if (( $(echo "$TIME2 < $TIME1" | bc -l) )); then
        IMPROVEMENT=$(echo "scale=2; (($TIME1 - $TIME2) / $TIME1) * 100" | bc)
        echo "   ✓ Performance improvement: ${IMPROVEMENT}%"
    fi
fi

# Check cache statistics
echo ""
echo "7. Redis statistics:"
STATS=$(docker exec hotel-booking-redis redis-cli INFO stats 2>/dev/null)
if [ -n "$STATS" ]; then
    HITS=$(echo "$STATS" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
    MISSES=$(echo "$STATS" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')
    
    if [ -n "$HITS" ] && [ -n "$MISSES" ]; then
        TOTAL=$((HITS + MISSES))
        if [ $TOTAL -gt 0 ]; then
            HIT_RATE=$(echo "scale=2; ($HITS / $TOTAL) * 100" | bc)
            echo "   Cache hits: $HITS"
            echo "   Cache misses: $MISSES"
            echo "   Hit rate: ${HIT_RATE}%"
        fi
    fi
fi

# Memory usage
MEMORY=$(docker exec hotel-booking-redis redis-cli INFO memory 2>/dev/null)
if [ -n "$MEMORY" ]; then
    USED_MEMORY=$(echo "$MEMORY" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    echo "   Memory used: $USED_MEMORY"
fi

echo ""
echo "========================================"
echo "Test completed!"
echo "========================================"
echo ""
echo "To monitor Redis in real-time:"
echo "  docker exec -it hotel-booking-redis redis-cli MONITOR"
echo ""
echo "To view all cache keys:"
echo "  docker exec -it hotel-booking-redis redis-cli KEYS '*'"
echo ""
echo "To flush all cache:"
echo "  docker exec -it hotel-booking-redis redis-cli FLUSHALL"
echo ""
