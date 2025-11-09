@echo off
echo ========================================
echo Fix Mock Guest Data in Existing Bookings
echo ========================================
echo.

echo Loading database credentials from backend/.env...
echo.

REM Read environment variables from backend/.env
for /f "usebackq tokens=1,* delims==" %%a in ("..\..\backend\.env") do (
    set "line=%%a"
    REM Skip comments and empty lines
    if not "!line:~0,1!"=="#" if not "%%a"=="" (
        if "%%a"=="DB_HOST" set "DB_HOST=%%b"
        if "%%a"=="DB_PORT" set "DB_PORT=%%b"
        if "%%a"=="DB_USER" set "DB_USER=%%b"
        if "%%a"=="DB_PASSWORD" set "PGPASSWORD=%%b"
        if "%%a"=="DB_NAME" set "DB_NAME=%%b"
    )
)

REM Enable delayed expansion for variable usage
setlocal enabledelayedexpansion

echo Database Configuration:
echo - Host: %DB_HOST%
echo - Port: %DB_PORT%
echo - User: %DB_USER%
echo - Database: %DB_NAME%
echo.

echo Running fix script...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f fix_mock_guest_data.sql

endlocal

if errorlevel 1 (
    echo.
    echo ERROR: Failed to run fix script!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Fix completed successfully!
echo ========================================
echo.
echo Check the output above to see:
echo - How many records were updated
echo - Verification of matched data
echo - Summary statistics
echo.
pause
