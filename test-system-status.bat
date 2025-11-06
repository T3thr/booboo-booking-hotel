@echo off
echo ============================================
echo ตรวจสอบสถานะระบบ
echo ============================================
echo.

echo [1] ตรวจสอบ Backend...
curl -s http://localhost:8080/health 2>nul
if %errorlevel% equ 0 (
    echo ✅ Backend ทำงานอยู่
) else (
    echo ❌ Backend ไม่ทำงาน - กรุณา start backend
    echo    cd backend
    echo    go run cmd/server/main.go
)
echo.

echo [2] ทดสอบ Room Search API...
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2" 2>nul
echo.
echo.

echo [3] ตรวจสอบ Frontend...
curl -s http://localhost:3000 2>nul >nul
if %errorlevel% equ 0 (
    echo ✅ Frontend ทำงานอยู่
) else (
    echo ❌ Frontend ไม่ทำงาน - กรุณา start frontend
    echo    cd frontend
    echo    npm run dev
)
echo.

echo ============================================
echo เสร็จสิ้น
echo ============================================
pause
