@echo off
echo ========================================
echo แก้ไข Room Search - Environment Fix
echo ========================================
echo.

echo [1/2] Stopping frontend...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/2] Starting frontend with new environment...
cd frontend
start cmd /k "npm run dev"

echo.
echo ========================================
echo เสร็จสิ้น!
echo ========================================
echo.
echo Frontend กำลังเริ่มต้น...
echo รอสักครู่แล้วลองค้นหาห้องอีกครั้ง
echo.
pause
