@echo off
echo ========================================
echo Testing Guest Confirmation Access
echo ========================================
echo.

echo Test 1: Check if confirmation page is accessible
echo URL: http://localhost:3000/booking/confirmation/1
echo Expected: Should show booking details or error message
echo.

echo Test 2: Check public API endpoint
curl -X GET "http://localhost:8080/api/bookings/search?phone=0812345678" -H "Content-Type: application/json"
echo.
echo.

echo Test 3: Check if middleware allows public access
echo URL: http://localhost:3000/booking/confirmation/1
echo Expected: No redirect to signin page
echo.

echo ========================================
echo Manual Testing Steps:
echo ========================================
echo.
echo 1. Guest Booking Flow (No Sign In):
echo    - Go to http://localhost:3000/rooms/search
echo    - Select a room and book WITHOUT signing in
echo    - Fill guest info with phone number
echo    - Complete payment (mock)
echo    - Should see confirmation page
echo    - Refresh page - should still see details
echo.
echo 2. Signed-in User Booking:
echo    - Sign in first
echo    - Book a room
echo    - Should see confirmation with "View My Bookings" button
echo.
echo 3. Direct URL Access (Guest):
echo    - Open new browser/incognito
echo    - Go to http://localhost:3000/booking/confirmation/1
echo    - Should show error "Unable to verify booking"
echo.
echo 4. Search Booking by Phone:
echo    - Go to http://localhost:3000/bookings
echo    - Enter phone number used for booking
echo    - Should see booking list
echo    - Click to view details
echo.
echo ========================================
echo Testing Complete!
echo ========================================
pause
