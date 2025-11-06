@echo off
REM Load Testing Script for Windows
REM Tests race conditions and concurrent booking scenarios

echo ========================================
echo Hotel Booking System - Load Tests
echo ========================================
echo.

REM Check if k6 is installed
where k6 >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: k6 is not installed!
    echo.
    echo Please install k6 first:
    echo   - Using Chocolatey: choco install k6
    echo   - Using Scoop: scoop install k6
    echo   - Or download from: https://k6.io/docs/getting-started/installation/
    echo.
    pause
    exit /b 1
)

REM Set default API URL if not provided
if "%API_URL%"=="" (
    set API_URL=http://localhost:8080
)

echo Using API URL: %API_URL%
echo.

REM Check if backend is running
echo Checking if backend is running...
curl -s -o nul -w "%%{http_code}" %API_URL%/api/rooms/types >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Cannot connect to backend at %API_URL%
    echo Please ensure the backend is running before continuing.
    echo.
    set /p continue="Continue anyway? (y/n): "
    if /i not "%continue%"=="y" exit /b 1
)

echo.
echo ========================================
echo Test Menu
echo ========================================
echo 1. Run Race Condition Test (50 VUs, 1 min)
echo 2. Run Concurrent Booking Test (50 users, last room)
echo 3. Run Connection Pool Test (up to 150 req/s)
echo 4. Run All Tests
echo 5. Run Smoke Test (Quick validation)
echo 6. Run Stress Test (High load)
echo 0. Exit
echo.

set /p choice="Select test to run (0-6): "

if "%choice%"=="1" goto race_condition
if "%choice%"=="2" goto concurrent_booking
if "%choice%"=="3" goto connection_pool
if "%choice%"=="4" goto all_tests
if "%choice%"=="5" goto smoke_test
if "%choice%"=="6" goto stress_test
if "%choice%"=="0" goto end

echo Invalid choice!
pause
exit /b 1

:race_condition
echo.
echo ========================================
echo Running Race Condition Test
echo ========================================
echo This test simulates 50 concurrent users attempting to book rooms.
echo Expected: Some bookings succeed, some fail, NO overbooking.
echo.
k6 run -e API_URL=%API_URL% race-condition-test.js
goto show_results

:concurrent_booking
echo.
echo ========================================
echo Running Concurrent Booking Test
echo ========================================
echo This test simulates 50 users trying to book the LAST available room.
echo Expected: Exactly 1 booking succeeds, 49 fail, NO inventory violations.
echo.
k6 run -e API_URL=%API_URL% concurrent-booking-test.js
goto show_results

:connection_pool
echo.
echo ========================================
echo Running Connection Pool Test
echo ========================================
echo This test stresses the database connection pool with high request rates.
echo Expected: System remains stable, no connection errors.
echo.
k6 run -e API_URL=%API_URL% connection-pool-test.js
goto show_results

:all_tests
echo.
echo ========================================
echo Running All Load Tests
echo ========================================
echo.
echo [1/3] Race Condition Test...
k6 run -e API_URL=%API_URL% race-condition-test.js
echo.
echo [2/3] Concurrent Booking Test...
k6 run -e API_URL=%API_URL% concurrent-booking-test.js
echo.
echo [3/3] Connection Pool Test...
k6 run -e API_URL=%API_URL% connection-pool-test.js
goto show_results

:smoke_test
echo.
echo ========================================
echo Running Smoke Test (Quick Validation)
echo ========================================
echo This is a quick test with 10 VUs for 30 seconds.
echo.
k6 run -e API_URL=%API_URL% --vus 10 --duration 30s race-condition-test.js
goto show_results

:stress_test
echo.
echo ========================================
echo Running Stress Test (High Load)
echo ========================================
echo WARNING: This test will generate high load on your system!
echo 100 VUs for 2 minutes.
echo.
set /p confirm="Continue? (y/n): "
if /i not "%confirm%"=="y" goto end
echo.
k6 run -e API_URL=%API_URL% --vus 100 --duration 2m race-condition-test.js
goto show_results

:show_results
echo.
echo ========================================
echo Test Results
echo ========================================
echo.
echo Check the output above for:
echo   - Successful Bookings count
echo   - Failed Bookings count
echo   - Overbookings Detected (MUST BE 0)
echo   - Inventory Violations (MUST BE 0)
echo.
echo Summary files have been generated in the current directory.
echo.

:end
echo.
echo ========================================
echo Load Testing Complete
echo ========================================
echo.
echo For detailed documentation, see README.md
echo.
pause
