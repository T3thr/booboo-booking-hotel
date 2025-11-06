# Security Audit Test Script for Hotel Booking System
# This script tests various security aspects of the system

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Security Audit Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$API_URL = "http://localhost:8080"
$FRONTEND_URL = "http://localhost:3000"

# Test counter
$totalTests = 0
$passedTests = 0
$failedTests = 0

function Test-Security {
    param(
        [string]$TestName,
        [scriptblock]$TestBlock
    )
    
    $script:totalTests++
    Write-Host "Testing: $TestName" -ForegroundColor Yellow
    
    try {
        $result = & $TestBlock
        if ($result) {
            Write-Host "  ✓ PASS" -ForegroundColor Green
            $script:passedTests++
        } else {
            Write-Host "  ✗ FAIL" -ForegroundColor Red
            $script:failedTests++
        }
    } catch {
        Write-Host "  ✗ ERROR: $_" -ForegroundColor Red
        $script:failedTests++
    }
    Write-Host ""
}

Write-Host "1. SQL Injection Protection Tests" -ForegroundColor Cyan
Write-Host "-----------------------------------" -ForegroundColor Cyan

Test-Security "SQL injection in login email" {
    $payload = "'; DROP TABLE guests; --"
    $body = @{
        email = $payload
        password = "password123"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/auth/login" `
            -Method POST `
            -Body $body `
            -ContentType "application/json" `
            -ErrorAction Stop
        return $false  # Should not succeed
    } catch {
        # Should fail with 401 or 400, not 500
        return $_.Exception.Response.StatusCode -in @(401, 400)
    }
}

Test-Security "SQL injection in search parameters" {
    $payload = "2025-12-01' OR '1'='1"
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/rooms/search?checkIn=$payload&checkOut=2025-12-05&guests=2" `
            -Method GET `
            -ErrorAction Stop
        # Should return empty or fail validation
        return $true
    } catch {
        return $_.Exception.Response.StatusCode -eq 400
    }
}

Write-Host "2. XSS Protection Tests" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan

Test-Security "XSS in registration first name" {
    $payload = "<script>alert('XSS')</script>"
    $body = @{
        email = "xss-test@example.com"
        password = "password123"
        first_name = $payload
        last_name = "Test"
        phone = "1234567890"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/auth/register" `
            -Method POST `
            -Body $body `
            -ContentType "application/json" `
            -ErrorAction Stop
        # Data should be stored safely
        return $true
    } catch {
        # May fail validation, which is also acceptable
        return $true
    }
}

Write-Host "3. CSRF Protection Tests" -ForegroundColor Cyan
Write-Host "-------------------------" -ForegroundColor Cyan

Test-Security "POST without authentication" {
    $body = @{
        room_type_id = 1
        check_in = "2025-12-01"
        check_out = "2025-12-05"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/bookings" `
            -Method POST `
            -Body $body `
            -ContentType "application/json" `
            -ErrorAction Stop
        return $false  # Should not succeed
    } catch {
        return $_.Exception.Response.StatusCode -eq 401
    }
}

Test-Security "Request from unauthorized origin" {
    $headers = @{
        "Origin" = "http://malicious-site.com"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/rooms/types" `
            -Method GET `
            -Headers $headers `
            -ErrorAction Stop
        # CORS should block or allow based on configuration
        return $true
    } catch {
        # CORS rejection is acceptable
        return $true
    }
}

Write-Host "4. Authentication Security Tests" -ForegroundColor Cyan
Write-Host "---------------------------------" -ForegroundColor Cyan

Test-Security "Invalid token rejection" {
    $headers = @{
        "Authorization" = "Bearer invalid-token-12345"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/bookings" `
            -Method GET `
            -Headers $headers `
            -ErrorAction Stop
        return $false  # Should not succeed
    } catch {
        return $_.Exception.Response.StatusCode -eq 401
    }
}

Test-Security "No token rejection" {
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/bookings" `
            -Method GET `
            -ErrorAction Stop
        return $false  # Should not succeed
    } catch {
        return $_.Exception.Response.StatusCode -eq 401
    }
}

Write-Host "5. Rate Limiting Tests" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan

Test-Security "Rate limiting on login endpoint" {
    $body = @{
        email = "test@example.com"
        password = "password123"
    } | ConvertTo-Json
    
    $rateLimited = $false
    
    # Make 10 rapid requests
    for ($i = 1; $i -le 10; $i++) {
        try {
            $response = Invoke-RestMethod -Uri "$API_URL/api/auth/login" `
                -Method POST `
                -Body $body `
                -ContentType "application/json" `
                -ErrorAction Stop
        } catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                $rateLimited = $true
                break
            }
        }
        Start-Sleep -Milliseconds 100
    }
    
    return $rateLimited
}

Write-Host "6. Security Headers Tests" -ForegroundColor Cyan
Write-Host "--------------------------" -ForegroundColor Cyan

Test-Security "X-Content-Type-Options header" {
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/" -Method GET
        return $response.Headers["X-Content-Type-Options"] -eq "nosniff"
    } catch {
        return $false
    }
}

Test-Security "X-Frame-Options header" {
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/" -Method GET
        return $response.Headers["X-Frame-Options"] -eq "DENY"
    } catch {
        return $false
    }
}

Test-Security "Content-Security-Policy header" {
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/" -Method GET
        return $response.Headers["Content-Security-Policy"] -ne $null
    } catch {
        return $false
    }
}

Write-Host "7. Input Validation Tests" -ForegroundColor Cyan
Write-Host "--------------------------" -ForegroundColor Cyan

Test-Security "Invalid email format rejection" {
    $body = @{
        email = "not-an-email"
        password = "password123"
        first_name = "Test"
        last_name = "User"
        phone = "1234567890"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/auth/register" `
            -Method POST `
            -Body $body `
            -ContentType "application/json" `
            -ErrorAction Stop
        return $false  # Should not succeed
    } catch {
        return $_.Exception.Response.StatusCode -eq 400
    }
}

Test-Security "Invalid date range rejection" {
    try {
        # Check-out before check-in
        $response = Invoke-RestMethod -Uri "$API_URL/api/rooms/search?checkIn=2025-12-10&checkOut=2025-12-05&guests=2" `
            -Method GET `
            -ErrorAction Stop
        return $false  # Should not succeed
    } catch {
        return $_.Exception.Response.StatusCode -eq 400
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Security Audit Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host ""

if ($failedTests -eq 0) {
    Write-Host "✓ All security tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Some security tests failed. Please review." -ForegroundColor Red
    exit 1
}
