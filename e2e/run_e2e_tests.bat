@echo off
REM E2E Tests Runner for Windows
REM This script runs the Playwright E2E tests for the Hotel Booking System

echo ========================================
echo Hotel Booking System - E2E Tests
echo ========================================
echo.

REM Check if node_modules exists
if not exist "node_modules\" (
    echo [ERROR] Dependencies not installed!
    echo Please run: npm install
    echo.
    pause
    exit /b 1
)

REM Check if Playwright browsers are installed
if not exist "node_modules\.playwright\" (
    echo [WARNING] Playwright browsers may not be installed
    echo Installing Playwright browsers...
    call npx playwright install chromium
    echo.
)

REM Parse command line arguments
set TEST_SUITE=%1
set MODE=%2

if "%TEST_SUITE%"=="" (
    echo Running all E2E tests...
    echo.
    call npm test
    goto :end
)

if "%TEST_SUITE%"=="booking" (
    echo Running Booking Flow tests...
    echo.
    call npm run test:booking
    goto :end
)

if "%TEST_SUITE%"=="checkin" (
    echo Running Check-in Flow tests...
    echo.
    call npm run test:checkin
    goto :end
)

if "%TEST_SUITE%"=="cancellation" (
    echo Running Cancellation Flow tests...
    echo.
    call npm run test:cancellation
    goto :end
)

if "%TEST_SUITE%"=="errors" (
    echo Running Error Scenarios tests...
    echo.
    call npm run test:errors
    goto :end
)

if "%TEST_SUITE%"=="headed" (
    echo Running tests in headed mode...
    echo.
    call npm run test:headed
    goto :end
)

if "%TEST_SUITE%"=="debug" (
    echo Running tests in debug mode...
    echo.
    call npm run test:debug
    goto :end
)

if "%TEST_SUITE%"=="ui" (
    echo Running tests in UI mode...
    echo.
    call npm run test:ui
    goto :end
)

if "%TEST_SUITE%"=="report" (
    echo Opening test report...
    echo.
    call npm run test:report
    goto :end
)

if "%TEST_SUITE%"=="help" (
    goto :help
)

echo [ERROR] Unknown test suite: %TEST_SUITE%
echo.
goto :help

:help
echo Usage: run_e2e_tests.bat [suite] [mode]
echo.
echo Test Suites:
echo   (none)        - Run all tests
echo   booking       - Run booking flow tests
echo   checkin       - Run check-in flow tests
echo   cancellation  - Run cancellation flow tests
echo   errors        - Run error scenario tests
echo.
echo Modes:
echo   headed        - Run tests with visible browser
echo   debug         - Run tests in debug mode
echo   ui            - Run tests in interactive UI mode
echo   report        - Open test report
echo.
echo Examples:
echo   run_e2e_tests.bat                    - Run all tests
echo   run_e2e_tests.bat booking            - Run booking tests
echo   run_e2e_tests.bat headed             - Run all tests with browser visible
echo   run_e2e_tests.bat report             - View test report
echo.
goto :end

:end
echo.
echo ========================================
echo Test execution completed
echo ========================================
pause
