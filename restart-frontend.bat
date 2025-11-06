@echo off
echo ========================================
echo Restart Frontend (Clear Cache)
echo ========================================
echo.

cd frontend

echo Killing frontend processes...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo Clearing Next.js cache...
if exist .next rmdir /s /q .next
if exist .turbo rmdir /s /q .turbo

echo.
echo Starting frontend...
echo URL: http://localhost:3000
echo.
echo Press Ctrl+C to stop
echo.

npm run dev
