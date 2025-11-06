@echo off
echo ========================================
echo Testing Hold Booking Resume System
echo ========================================
echo.

echo This script will help you test the hold booking resume feature.
echo.
echo Prerequisites:
echo   1. Backend is running (port 8080)
echo   2. Frontend is running (port 3000)
echo   3. Database is running
echo.

echo ========================================
echo Test Scenarios
echo ========================================
echo.

echo 1. CREATE HOLD BOOKING
echo    - Go to http://localhost:3000
echo    - Search for rooms
echo    - Select a room and click "Book"
echo    - Watch console for:
echo      * [API] Creating hold with data
echo      * [Hold] Backend response
echo      * [Hold] Saved to localStorage
echo    - Verify HoldIndicator appears at bottom-right
echo    - Verify countdown timer is working
echo.

echo 2. RESUME BOOKING
echo    - Navigate to home page (/)
echo    - Verify HoldIndicator still shows
echo    - Click "Resume Booking" button
echo    - Should navigate to /booking/guest-info
echo    - Verify data is restored (room type, dates, timer)
echo.

echo 3. GUEST BOOKING (NO SIGN IN)
echo    - Do NOT sign in
echo    - Search for rooms
echo    - Select a room
echo    - Fill guest info:
echo      * First name: สมชาย
echo      * Last name: ใจดี
echo      * Phone: 0812345678 (IMPORTANT!)
echo    - Upload payment proof
echo    - Click "ยืนยันการชำระเงิน"
echo    - Watch console for booking creation
echo    - Should redirect to confirmation page
echo.

echo 4. SEARCH BY PHONE
echo    - Go to /bookings
echo    - Enter phone: 0812345678
echo    - Click "ค้นหา"
echo    - Should see your booking
echo    - Click "ดูรายละเอียด"
echo    - Should see full booking details
echo.

echo 5. HOLD EXPIRY
echo    - Create a hold
echo    - Wait for timer to expire (15 minutes)
echo    - Should auto redirect to search page
echo    - localStorage should be cleared
echo    - HoldIndicator should disappear
echo.

echo ========================================
echo Debugging Tips
echo ========================================
echo.
echo If hold doesn't work:
echo   1. Check browser console for errors
echo   2. Check localStorage: booking_hold
echo   3. Check sessionStorage: booking_session_id
echo   4. Check backend logs
echo   5. Check database: SELECT * FROM booking_holds;
echo.

echo If resume doesn't work:
echo   1. Check if holdData exists in localStorage
echo   2. Check if HoldIndicator is rendered
echo   3. Check console for restore logs
echo   4. Verify booking store is updated
echo.

echo If guest booking doesn't work:
echo   1. Verify phone number is provided
echo   2. Check API request body in Network tab
echo   3. Check backend logs for errors
echo   4. Verify database: SELECT * FROM booking_guests;
echo.

echo ========================================
echo Database Queries for Verification
echo ========================================
echo.
echo -- Check active holds
echo SELECT * FROM booking_holds WHERE hold_expiry ^> NOW();
echo.
echo -- Check bookings with phone
echo SELECT b.*, bg.phone 
echo FROM bookings b
echo JOIN booking_details bd ON b.booking_id = bd.booking_id
echo JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
echo WHERE bg.phone = '0812345678';
echo.
echo -- Check all guest bookings
echo SELECT * FROM bookings WHERE guest_id IS NOT NULL ORDER BY created_at DESC;
echo.

echo ========================================
echo Ready to Test!
echo ========================================
echo.
echo Press any key to open browser...
pause >nul

start http://localhost:3000

echo.
echo Browser opened. Follow the test scenarios above.
echo.
echo Press any key to exit...
pause >nul
