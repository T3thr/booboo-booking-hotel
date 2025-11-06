@echo off
echo ============================================
echo Testing Login Credentials
echo ============================================
echo.
echo Testing with: anan.test@example.com / password123
echo.

curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"anan.test@example.com\",\"password\":\"password123\"}"

echo.
echo.
echo ============================================
pause
