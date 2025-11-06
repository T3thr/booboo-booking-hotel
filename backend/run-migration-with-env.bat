@echo off
REM Script to run PostgreSQL migrations using credentials from backend/.env

echo Reading database credentials from backend/.env...

REM Parse .env file and set environment variables
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    set "line=%%a"
    REM Skip comments and empty lines
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
echo SSL Mode: %DB_SSLMODE%
echo.

REM Check if migration file is provided
if "%1"=="" (
    echo Usage: run-migration-with-env.bat [migration-file.sql]
    echo Example: run-migration-with-env.bat 020_allow_null_guest_id.sql
    exit /b 1
)

REM Check if file exists
if not exist "%1" (
    echo Error: Migration file "%1" not found
    exit /b 1
)

echo Running migration: %1
echo.

REM Run psql with credentials from .env
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "%1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Migration completed successfully!
) else (
    echo.
    echo Migration failed with error code: %ERRORLEVEL%
)

REM Clear password from environment
set PGPASSWORD=
