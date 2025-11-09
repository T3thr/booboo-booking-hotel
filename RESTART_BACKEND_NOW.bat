@echo off
echo ========================================
echo RESTART BACKEND - Payment Proof Fix
echo ========================================
echo.
echo Backend has been REBUILT successfully!
echo.
echo Now you MUST:
echo.
echo 1. Go to backend terminal
echo 2. Press Ctrl+C to STOP backend
echo 3. Run: ./hotel-booking-api.exe
echo.
echo OR
echo.
echo Run: go run cmd/server/main.go
echo.
echo ========================================
echo After backend restarts:
echo ========================================
echo.
echo Test at: http://localhost:3000/admin/reception
echo - Click "อนุมัติ" button
echo - Should work without error!
echo.
pause
