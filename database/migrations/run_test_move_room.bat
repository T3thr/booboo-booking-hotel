@echo off
REM ============================================================================
REM Script: run_test_move_room.bat
REM Description: ทดสอบ move_room function (Windows)
REM ============================================================================

echo ============================================================================
echo Testing Move Room Function
echo ============================================================================
echo.

REM ตรวจสอบว่ามี environment variables หรือไม่
if "%DB_HOST%"=="" set DB_HOST=localhost
if "%DB_PORT%"=="" set DB_PORT=5432
if "%DB_NAME%"=="" set DB_NAME=hotel_booking
if "%DB_USER%"=="" set DB_USER=postgres

echo Database Configuration:
echo   Host: %DB_HOST%
echo   Port: %DB_PORT%
echo   Database: %DB_NAME%
echo   User: %DB_USER%
echo.

echo Running test script...
echo.

psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f test_move_room_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo Tests completed!
    echo ============================================================================
    echo Please review the test results above.
    echo.
) else (
    echo.
    echo ============================================================================
    echo Tests failed!
    echo ============================================================================
    echo Please check the error messages above.
    echo.
    exit /b 1
)

pause
