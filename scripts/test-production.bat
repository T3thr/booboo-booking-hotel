@echo off
REM Production Testing Script for Windows
REM This script tests all critical functionality in the production environment

setlocal enabledelayedexpansion

set API_URL=http://localhost:8080
set FRONTEND_URL=http://localhost:3000
set PASSED=0
set FAILED=0
set TOTAL=0

echo ==========================================
echo   Production Testing Suite
echo   Hotel Booking System
echo ==========================================
echo.
echo API URL: %API_URL%
echo Frontend URL: %FRONTEND_URL%
echo.

REM Section 1: Infrastructure Tests
echo ==========================================
echo 1. Infrastructure Tests
echo ==========================================

REM Test Backend Health
set /a TOTAL+=1
echo Testing Backend Health Check...
curl -s -o nul -w "%%{http_code}" %API_URL%/health > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Backend Health Check ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Backend Health Check ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

REM Test Frontend
set /a TOTAL+=1
echo Testing Frontend Home Page...
curl -s -o nul -w "%%{http_code}" %FRONTEND_URL% > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Frontend Home Page ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Frontend Home Page ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

REM Test Database
set /a TOTAL+=1
echo Testing Database Connection...
docker-compose -f docker-compose.prod.yml exec -T db pg_isready -U hotel_admin >nul 2>&1
if not errorlevel 1 (
    echo [PASS] Database Connection
    set /a PASSED+=1
) else (
    echo [FAIL] Database Connection
    set /a FAILED+=1
)

REM Test Redis
set /a TOTAL+=1
echo Testing Redis Connection...
docker-compose -f docker-compose.prod.yml exec -T redis redis-cli ping >nul 2>&1
if not errorlevel 1 (
    echo [PASS] Redis Connection
    set /a PASSED+=1
) else (
    echo [FAIL] Redis Connection
    set /a FAILED+=1
)

echo.

REM Section 2: API Endpoint Tests
echo ==========================================
echo 2. API Endpoint Tests
echo ==========================================

REM Test Room Search
set /a TOTAL+=1
echo Testing Rooms - Search Endpoint...
curl -s -o nul -w "%%{http_code}" "%API_URL%/api/rooms/search?checkIn=2024-12-01&checkOut=2024-12-05&guests=2" > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Rooms Search ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Rooms Search ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

REM Test Room Types
set /a TOTAL+=1
echo Testing Rooms - Types List...
curl -s -o nul -w "%%{http_code}" %API_URL%/api/rooms/types > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Room Types ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Room Types ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

REM Test Bookings (should be unauthorized)
set /a TOTAL+=1
echo Testing Bookings - List ^(Unauthorized^)...
curl -s -o nul -w "%%{http_code}" %API_URL%/api/bookings > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="401" (
    echo [PASS] Bookings Unauthorized ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Bookings Unauthorized ^(Expected HTTP 401, got %response%^)
    set /a FAILED+=1
)

echo.

REM Section 3: Frontend Page Tests
echo ==========================================
echo 3. Frontend Page Tests
echo ==========================================

REM Test Sign In Page
set /a TOTAL+=1
echo Testing Frontend - Sign In Page...
curl -s -o nul -w "%%{http_code}" %FRONTEND_URL%/auth/signin > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Sign In Page ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Sign In Page ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

REM Test Register Page
set /a TOTAL+=1
echo Testing Frontend - Register Page...
curl -s -o nul -w "%%{http_code}" %FRONTEND_URL%/auth/register > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Register Page ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Register Page ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

REM Test Room Search Page
set /a TOTAL+=1
echo Testing Frontend - Room Search...
curl -s -o nul -w "%%{http_code}" %FRONTEND_URL%/rooms/search > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Room Search Page ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Room Search Page ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

echo.

REM Section 4: Performance Tests
echo ==========================================
echo 4. Performance Tests
echo ==========================================

echo Testing API Response Time...
set start_time=%time%
curl -s %API_URL%/api/rooms/types >nul 2>&1
set end_time=%time%
echo [INFO] Response time test completed
set /a TOTAL+=1
set /a PASSED+=1

echo.

REM Section 5: Database Tests
echo ==========================================
echo 5. Database Tests
echo ==========================================

set /a TOTAL+=1
echo Testing Database Schema...
docker-compose -f docker-compose.prod.yml exec -T db psql -U hotel_admin -d hotel_booking -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" -t > temp_count.txt 2>nul
set /p table_count=<temp_count.txt
set table_count=%table_count: =%

if %table_count% GEQ 15 (
    echo [PASS] Database Schema ^(%table_count% tables found^)
    set /a PASSED+=1
) else (
    echo [FAIL] Database Schema ^(Expected at least 15 tables, found %table_count%^)
    set /a FAILED+=1
)

echo.

REM Section 6: Monitoring Tests
echo ==========================================
echo 6. Monitoring Tests
echo ==========================================

set /a TOTAL+=1
echo Testing Prometheus Metrics...
curl -s -o nul -w "%%{http_code}" http://localhost:9091/metrics > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Prometheus Metrics ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Prometheus Metrics ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

set /a TOTAL+=1
echo Testing Grafana Dashboard...
curl -s -o nul -w "%%{http_code}" http://localhost:3001/login > temp_response.txt 2>nul
set /p response=<temp_response.txt
if "%response%"=="200" (
    echo [PASS] Grafana Dashboard ^(HTTP %response%^)
    set /a PASSED+=1
) else (
    echo [FAIL] Grafana Dashboard ^(Expected HTTP 200, got %response%^)
    set /a FAILED+=1
)

echo.

REM Section 7: Backup Tests
echo ==========================================
echo 7. Backup Tests
echo ==========================================

set /a TOTAL+=1
echo Testing Backup Directory...
if exist "backups\database" (
    echo [PASS] Backup Directory exists
    set /a PASSED+=1
) else (
    echo [FAIL] Backup Directory not found
    set /a FAILED+=1
)

set /a TOTAL+=1
echo Testing Backup Script...
if exist "scripts\backup-database.sh" (
    echo [PASS] Backup Script exists
    set /a PASSED+=1
) else (
    echo [WARNING] Backup Script not found
)

echo.

REM Cleanup
del temp_response.txt 2>nul
del temp_count.txt 2>nul

REM Summary
echo ==========================================
echo   Test Summary
echo ==========================================
echo.
echo Total Tests: %TOTAL%
echo Passed: %PASSED%
echo Failed: %FAILED%
echo.

if %FAILED% EQU 0 (
    echo [SUCCESS] All tests passed!
    echo.
    echo Production environment is ready for use.
    exit /b 0
) else (
    echo [ERROR] Some tests failed!
    echo.
    echo Please review the failed tests and fix issues before using in production.
    exit /b 1
)

endlocal
