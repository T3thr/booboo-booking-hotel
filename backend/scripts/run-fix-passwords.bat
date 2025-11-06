@echo off
REM Fix password hashes using Go script

echo === Fixing Password Hashes ===
echo.

set DATABASE_URL=postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require

REM Change to backend directory
pushd %~dp0..

go run scripts\fix-passwords.go

popd

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
