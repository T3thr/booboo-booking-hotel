@echo off
REM ============================================================================
REM Test Performance Optimization
REM ============================================================================

echo ========================================
echo Testing Performance Optimization
echo ========================================
echo.

REM Load environment variables
if exist "..\..\backend\.env" (
    for /f "tokens=1,2 delims==" %%a in (..\..\backend\.env) do (
        if "%%a"=="DB_HOST" set DB_HOST=%%b
        if "%%a"=="DB_PORT" set DB_PORT=%%b
        if "%%a"=="DB_NAME" set DB_NAME=%%b
        if "%%a"=="DB_USER" set DB_USER=%%b
        if "%%a"=="DB_PASSWORD" set DB_PASSWORD=%%b
    )
)

REM Set defaults if not found
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432
if not defined DB_NAME set DB_NAME=hotel_booking
if not defined DB_USER set DB_USER=postgres
if not defined DB_PASSWORD set DB_PASSWORD=postgres

echo Database: %DB_NAME%
echo Host: %DB_HOST%:%DB_PORT%
echo User: %DB_USER%
echo.

REM Set PGPASSWORD for non-interactive execution
set PGPASSWORD=%DB_PASSWORD%

echo Running performance tests...
echo.
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f test_performance_optimization.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Performance tests completed!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Performance tests failed!
    echo ========================================
    exit /b 1
)

REM Clear password
set PGPASSWORD=

pause
