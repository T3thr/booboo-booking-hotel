@echo off
echo Testing Docker build...
cd backend
docker build -t test-backend .
if %ERRORLEVEL% EQU 0 (
    echo ✅ Docker build successful!
    docker rmi test-backend
) else (
    echo ❌ Docker build failed with error code %ERRORLEVEL%
)
cd ..
pause