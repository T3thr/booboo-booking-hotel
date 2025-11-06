# Test Redis Caching Implementation
# This script tests the Redis caching functionality

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Redis Caching Test Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Redis is running
Write-Host "1. Checking Redis connection..." -ForegroundColor Yellow
$redisCheck = docker ps | Select-String "hotel-booking-redis"
if ($redisCheck) {
    Write-Host "   ✓ Redis container is running" -ForegroundColor Green
} else {
    Write-Host "   ✗ Redis container is not running" -ForegroundColor Red
    Write-Host "   Starting Redis..." -ForegroundColor Yellow
    docker-compose up -d redis
    Start-Sleep -Seconds 5
}

# Test Redis connection
Write-Host ""
Write-Host "2. Testing Redis connection..." -ForegroundColor Yellow
$pingResult = docker exec hotel-booking-redis redis-cli ping 2>$null
if ($pingResult -eq "PONG") {
    Write-Host "   ✓ Redis is responding" -ForegroundColor Green
} else {
    Write-Host "   ✗ Redis is not responding" -ForegroundColor Red
    exit 1
}

# Run Go tests for cache package
Write-Host ""
Write-Host "3. Running cache unit tests..." -ForegroundColor Yellow
go test ./pkg/cache/... -v
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Cache unit tests passed" -ForegroundColor Green
} else {
    Write-Host "   ✗ Cache unit tests failed" -ForegroundColor Red
}

# Check Redis keys
Write-Host ""
Write-Host "4. Checking Redis keys..." -ForegroundColor Yellow
$keyCount = docker exec hotel-booking-redis redis-cli DBSIZE
Write-Host "   Current keys in Redis: $keyCount" -ForegroundColor Cyan

# Show sample keys
Write-Host ""
Write-Host "5. Sample cache keys:" -ForegroundColor Yellow
$keys = docker exec hotel-booking-redis redis-cli KEYS "*" 2>$null
if ($keys) {
    $keys | Select-Object -First 10 | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor Cyan
    }
} else {
    Write-Host "   No keys found in cache" -ForegroundColor Yellow
}

# Test cache performance
Write-Host ""
Write-Host "6. Testing cache performance..." -ForegroundColor Yellow
Write-Host "   Testing room types endpoint..." -ForegroundColor Cyan

# First request (cache miss)
Write-Host "   First request (cache miss)..." -ForegroundColor Yellow
$start1 = Get-Date
try {
    $response1 = Invoke-WebRequest -Uri "http://localhost:8080/api/rooms/types" -UseBasicParsing -TimeoutSec 5
    $end1 = Get-Date
    $time1 = ($end1 - $start1).TotalMilliseconds
    Write-Host "   ✓ Response time: $([math]::Round($time1, 2))ms" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Request failed: $_" -ForegroundColor Red
}

# Second request (cache hit)
Start-Sleep -Seconds 1
Write-Host "   Second request (cache hit)..." -ForegroundColor Yellow
$start2 = Get-Date
try {
    $response2 = Invoke-WebRequest -Uri "http://localhost:8080/api/rooms/types" -UseBasicParsing -TimeoutSec 5
    $end2 = Get-Date
    $time2 = ($end2 - $start2).TotalMilliseconds
    Write-Host "   ✓ Response time: $([math]::Round($time2, 2))ms" -ForegroundColor Green
    
    if ($time2 -lt $time1) {
        $improvement = [math]::Round((($time1 - $time2) / $time1) * 100, 2)
        Write-Host "   ✓ Performance improvement: $improvement%" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ Request failed: $_" -ForegroundColor Red
}

# Check cache statistics
Write-Host ""
Write-Host "7. Redis statistics:" -ForegroundColor Yellow
$stats = docker exec hotel-booking-redis redis-cli INFO stats 2>$null
if ($stats) {
    $hits = ($stats | Select-String "keyspace_hits:").ToString().Split(":")[1].Trim()
    $misses = ($stats | Select-String "keyspace_misses:").ToString().Split(":")[1].Trim()
    
    if ($hits -and $misses) {
        $total = [int]$hits + [int]$misses
        if ($total -gt 0) {
            $hitRate = [math]::Round(([int]$hits / $total) * 100, 2)
            Write-Host "   Cache hits: $hits" -ForegroundColor Cyan
            Write-Host "   Cache misses: $misses" -ForegroundColor Cyan
            Write-Host "   Hit rate: $hitRate%" -ForegroundColor Cyan
        }
    }
}

# Memory usage
$memory = docker exec hotel-booking-redis redis-cli INFO memory 2>$null
if ($memory) {
    $usedMemory = ($memory | Select-String "used_memory_human:").ToString().Split(":")[1].Trim()
    Write-Host "   Memory used: $usedMemory" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To monitor Redis in real-time:" -ForegroundColor Yellow
Write-Host "  docker exec -it hotel-booking-redis redis-cli MONITOR" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view all cache keys:" -ForegroundColor Yellow
Write-Host "  docker exec -it hotel-booking-redis redis-cli KEYS '*'" -ForegroundColor Cyan
Write-Host ""
Write-Host "To flush all cache:" -ForegroundColor Yellow
Write-Host "  docker exec -it hotel-booking-redis redis-cli FLUSHALL" -ForegroundColor Cyan
Write-Host ""
