@echo off
setlocal enabledelayedexpansion

echo Reading database credentials from backend/.env...

REM Parse .env file
for /f "usebackq tokens=1,2 delims==" %%a in ("..\..\backend\.env") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" if not "%%a"=="" (
        set "%%a=%%b"
    )
)

REM Set PGPASSWORD for psql authentication
set PGPASSWORD=%DB_PASSWORD%

echo.
echo Database Configuration:
echo Host: %DB_HOST%
echo Port: %DB_PORT%
echo User: %DB_USER%
echo Database: %DB_NAME%
echo.

echo Running migration: 020_allow_null_guest_id.sql
echo.

REM Run psql with Neon credentials
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f 020_allow_null_guest_id.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Migration completed successfully!
) else (
    echo.
    echo Migration failed with error code: %ERRORLEVEL%
)

REM Clear password
set PGPASSWORD=

pause
