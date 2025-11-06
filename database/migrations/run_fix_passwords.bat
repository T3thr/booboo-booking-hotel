@echo off
REM Fix password hashes in Neon database

echo Fixing password hashes for demo accounts...
echo.

set DB_URL=postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require

psql "%DB_URL%" -f fix_passwords.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo Password hashes fixed successfully!
    echo ============================================================================
    echo.
    echo You can now login with:
    echo   Email: anan.test@example.com
    echo   Password: password123
    echo.
) else (
    echo.
    echo ERROR: Failed to fix passwords.
    echo.
)

pause
