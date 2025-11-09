@echo off
echo ========================================
echo Test Payment Status Fix
echo ========================================
echo.

echo What was fixed:
echo - Changed UPDATE to UPSERT in payment_proof_repository.go
echo - Now creates payment_proof record if it doesn't exist
echo - Payment status will always show correctly after approve
echo.
echo ========================================
echo Test Scenarios:
echo ========================================
echo.
echo Scenario 1: Approve booking WITH payment proof
echo -----------------------------------------------
echo 1. Guest books + uploads payment proof
echo 2. Go to /admin/reception → "รอตรวจสอบการชำระเงิน"
echo 3. Click "อนุมัติ"
echo 4. Go to /admin/checkin
echo Expected: Shows "💰 ชำระเงินแล้ว" ✓
echo.
echo Scenario 2: Approve booking WITHOUT payment proof (THE FIX)
echo ------------------------------------------------------------
echo 1. Guest books (no payment proof uploaded)
echo 2. Go to /admin/reception → "รอตรวจสอบการชำระเงิน"
echo 3. Click "อนุมัติ" (admin confirms payment)
echo 4. Go to /admin/checkin
echo Expected: Shows "💰 ชำระเงินแล้ว" ✓ (FIXED!)
echo.
echo Scenario 3: Reject booking
echo ---------------------------
echo 1. Guest books + uploads payment proof
echo 2. Go to /admin/reception
echo 3. Click "ปฏิเสธ" + enter reason
echo 4. Booking should be cancelled
echo Expected: Not shown in /admin/checkin ✓
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
echo 3. Test Scenario 1:
echo    - Create a booking with payment proof
echo    - Approve it in reception
echo    - Check in check-in page
echo.
echo 4. Test Scenario 2 (THE IMPORTANT ONE):
echo    - Create a booking WITHOUT payment proof
echo    - Approve it directly in reception
echo    - Check in check-in page
echo    - Should show "ชำระเงินแล้ว" now!
echo.
echo ========================================
echo Expected Results:
echo ========================================
echo.
echo ✓ Payment status shows "ชำระเงินแล้ว" after approve
echo ✓ Works with or without payment proof upload
echo ✓ Check-in page shows correct payment status
echo ✓ Receptionist can see payment status clearly
echo.
pause
