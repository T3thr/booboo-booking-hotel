@echo off
echo ========================================
echo Test Housekeeper Login
echo ========================================
echo.

echo Testing backend login endpoint...
echo.

curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"housekeeper1@hotel.com\",\"password\":\"staff123\"}"

echo.
echo.
echo ========================================
echo Check the response above:
echo ========================================
echo.
echo Should see:
echo   "role_code": "HOUSEKEEPER"  (NOT "staff")
echo   "user_type": "staff"
echo   "accessToken": "..."
echo.
echo If you see "role_code": "HOUSEKEEPER", the fix is working!
echo.
echo Next: Copy the accessToken and test housekeeping API:
echo   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/api/housekeeping/tasks
echo.
pause
