@echo off
echo ========================================
echo Testing Production Build
echo ========================================
echo.

echo [1/4] Cleaning previous build...
if exist .next rmdir /s /q .next
if exist out rmdir /s /q out
echo Done!
echo.

echo [2/4] Installing dependencies...
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo Done!
echo.

echo [3/4] Building for production...
call npm run build
if errorlevel 1 (
    echo ERROR: Build failed!
    echo.
    echo Common issues:
    echo - Check for TypeScript errors
    echo - Check for SSR/CSR compatibility issues
    echo - Check environment variables
    pause
    exit /b 1
)
echo Done!
echo.

echo [4/4] Starting production server...
echo.
echo Production server will start on http://localhost:3000
echo Press Ctrl+C to stop
echo.
call npm run start

pause
