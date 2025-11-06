@echo off
REM ============================================================================
REM Script: run_test_check_in.bat
REM Description: Test check_in function
REM ============================================================================

echo ========================================
echo Testing check_in Function
echo ========================================
echo.

REM Load environment variables from backend/.env
for /f "tokens=1,2 delims==" %%a in ('type ..\..\backend\.env ^| findstr /v "^#"') do (
    set %%a=%%b
)

REM Run tests
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f test_check_in_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Tests completed!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Tests failed!
    echo ========================================
    exit /b 1
)

pause
