@echo off
echo ========================================
echo Test Payment Proof System Fix
echo ========================================
echo.

echo Step 1: Check database connection...
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) as total_bookings FROM bookings;" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Cannot connect to database!
    echo Please make sure PostgreSQL is running.
    pause
    exit /b 1
)

echo.
echo Step 2: Check PendingPayment bookings...
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) as pending_payment FROM bookings WHERE status = 'PendingPayment';"

echo.
echo Step 3: Check all booking statuses...
psql -U postgres -d hotel_booking -c "SELECT status, COUNT(*) as count FROM bookings GROUP BY status ORDER BY status;"

echo.
echo Step 4: Test confirm_booking function exists...
psql -U postgres -d hotel_booking -c "SELECT proname FROM pg_proc WHERE proname = 'confirm_booking';"

echo.
echo Step 5: Test cancel_pending_booking function exists...
psql -U postgres -d hotel_booking -c "SELECT proname FROM pg_proc WHERE proname = 'cancel_pending_booking';"

echo.
echo ========================================
echo Database Check Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Start backend: cd backend ^&^& go run cmd/server/main.go
echo 2. Start frontend: cd frontend ^&^& npm run dev
echo 3. Test at: http://localhost:3000/admin/reception
echo.
pause
