@echo off
echo ========================================
echo Test Approve/Reject Payment Proof
echo ========================================
echo.

echo What was fixed:
echo - Frontend now sends booking_id instead of payment_proof_id (0)
echo - Backend can now find the booking and process it
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
echo 5. Test APPROVE:
echo    - Click "อนุมัติ" on any booking
echo    - Should show success message
echo    - Booking should disappear from list
echo    - Go to /admin/checkin to see it in Arrivals
echo.
echo 6. Test REJECT:
echo    - Click "ปฏิเสธ" on any booking
echo    - Enter rejection reason
echo    - Click "ปฏิเสธการชำระเงิน"
echo    - Should show success message
echo    - Booking should disappear from list
echo.
echo 7. Check Network tab:
echo    - Should see: POST /api/admin/payment-proofs/[booking_id]/approve
echo    - NOT: POST /api/admin/payment-proofs/0/approve
echo.
echo 8. Check Backend logs:
echo    - Should see: [POST] 200 ^| /api/payment-proofs/[booking_id]/approve
echo    - NOT: [POST] 500 ^| /api/payment-proofs/0/approve
echo.
echo ========================================
echo Expected Results:
echo ========================================
echo.
echo ✓ Approve works - booking becomes Confirmed
echo ✓ Reject works - booking becomes Cancelled
echo ✓ Inventory is managed correctly
echo ✓ Approved bookings appear in /admin/checkin
echo ✓ No more 500 errors
echo.
pause
