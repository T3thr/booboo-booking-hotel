@echo off
REM ============================================================================
REM Script: run_migration_009.bat
REM Description: Run migration 009 - Create check_in function
REM ============================================================================

echo ========================================
echo Running Migration 009
echo Creating check_in function
echo ========================================
echo.

REM Load environment variables from backend/.env
for /f "tokens=1,2 delims==" %%a in ('type ..\..\backend\.env ^| findstr /v "^#"') do (
    set %%a=%%b
)

REM Run migration
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f 009_create_check_in_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Migration 009 completed successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Migration 009 failed!
    echo ========================================
    exit /b 1
)

pause
