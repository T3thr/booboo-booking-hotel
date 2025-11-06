@echo off
echo Testing final build...
cd backend

echo Building Docker image...
docker build -t hotel-backend .

if %ERRORLEVEL% EQU 0 (
    echo ✅ Docker build successful!
    echo Cleaning up...
    docker rmi hotel-backend
    echo.
    echo 🎉 Backend is ready for deployment!
    echo.
    echo Next steps:
    echo 1. git add .
    echo 2. git commit -m "Fix all database method calls"
    echo 3. git push origin main
    echo 4. Render will auto-deploy
) else (
    echo ❌ Docker build failed
    echo Please check the error messages above
)

cd ..
pause