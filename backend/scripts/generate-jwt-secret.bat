@echo off
REM Generate JWT Secret Script for Windows
REM This script generates a secure random JWT secret

echo.
echo 🔐 Generating JWT Secret...
echo.

REM Check if OpenSSL is available
where openssl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ OpenSSL not found!
    echo.
    echo Please install OpenSSL or use one of these alternatives:
    echo.
    echo 1. Install Git for Windows (includes OpenSSL)
    echo 2. Use online generator: https://generate-secret.vercel.app/32
    echo 3. Use Node.js: node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
    echo.
    pause
    exit /b 1
)

REM Generate secret
for /f "delims=" %%i in ('openssl rand -base64 32') do set SECRET=%%i

echo ✅ Your JWT Secret:
echo.
echo %SECRET%
echo.
echo 📝 Add this to your .env file:
echo JWT_SECRET=%SECRET%
echo.
echo ⚠️  Keep this secret safe and never commit it to git!
echo.
pause
