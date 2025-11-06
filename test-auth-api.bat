@echo off
echo Testing Backend Auth API...
echo.

curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"anan.test@example.com\",\"password\":\"password123\"}"

echo.
echo.
pause
