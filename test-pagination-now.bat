@echo off
echo ========================================
echo Quick Pagination Test
echo ========================================
echo.

echo Testing pagination fix...
echo.
echo What was fixed:
echo 1. Frontend API route now forwards page and limit params to backend
echo 2. Backend receives and processes pagination correctly
echo 3. UI pagination buttons now work properly
echo.
echo ========================================
echo How to test:
echo ========================================
echo.
echo 1. Make sure backend is running:
echo    cd backend
echo    go run cmd/server/main.go
echo.
echo 2. Make sure frontend is running:
echo    cd frontend
echo    npm run dev
echo.
echo 3. Open browser:
echo    http://localhost:3000/admin/reception
echo.
echo 4. Go to "รอตรวจสอบการชำระเงิน" tab
echo.
echo 5. Check:
echo    - Shows "แสดง X จาก Y รายการ"
echo    - If Y ^> 20, pagination buttons appear
echo    - Click "ถัดไป" to see next 20 items
echo    - Click "ก่อนหน้า" to go back
echo.
echo 6. Open DevTools ^> Network:
echo    - Should see: /api/admin/payment-proofs?status=pending^&page=1^&limit=20
echo    - When click next: page=2
echo    - When click prev: page=1
echo.
echo ========================================
echo Expected Results:
echo ========================================
echo.
echo ✓ Shows all 61 bookings (not just 35)
echo ✓ Pagination buttons work
echo ✓ Can navigate through all pages
echo ✓ Each page shows up to 20 items
echo.
pause
