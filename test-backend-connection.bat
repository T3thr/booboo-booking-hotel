@echo off
echo ========================================
echo Testing Backend Connection
echo ========================================
echo.

echo 1. Testing Backend Health...
curl -s http://localhost:8080/api/rooms/types
echo.
echo.

echo 2. Testing Backend Auth Endpoint...
curl -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"john.doe@example.com\",\"password\":\"password123\"}"
echo.
echo.

echo 3. Checking if Backend is Running...
netstat -ano | findstr :8080
echo.

echo ========================================
echo Test Complete
echo ========================================
pause
