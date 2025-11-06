@echo off
REM ============================================================================
REM Script: run-migrations-go.bat
REM Description: Run database migrations using Go (no psql required)
REM Usage: run-migrations-go.bat
REM ============================================================================

setlocal enabledelayedexpansion

echo === Database Migration Tool (Go) ===
echo.

REM Load DATABASE_URL from .env if not set
if "%DATABASE_URL%"=="" (
    echo Loading DATABASE_URL from .env file...
    
    for /f "tokens=1,* delims==" %%a in ('findstr /r "^DATABASE_URL=" ..\.env 2^>nul') do (
        set DATABASE_URL=%%b
    )
    
    if "!DATABASE_URL!"=="" (
        echo ERROR: DATABASE_URL not found in environment or .env file
        echo Please set DATABASE_URL or create backend/.env file
        pause
        exit /b 1
    )
)

REM Run the Go migration script from backend directory
cd /d "%~dp0\.."
go run scripts/migrate.go

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Migrations completed successfully!
) else (
    echo.
    echo ✗ Migrations failed with error code %ERRORLEVEL%
)

echo.
pause
