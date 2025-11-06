@echo off
echo =================================
echo   FIXING BACKEND AND DEPLOYING
echo =================================

echo Step 1: Checking Go installation...
go version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Go is not installed or not in PATH
    echo Please install Go from https://golang.org/dl/
    pause
    exit /b 1
)

echo Step 2: Testing compilation...
cd backend
go build -o main.exe ./cmd/server
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Compilation failed
    cd ..
    pause
    exit /b 1
)

echo Step 3: Cleaning up test binary...
del main.exe

echo Step 4: Building Docker image...
cd ..
docker build -t hotel-backend ./backend
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker build failed
    pause
    exit /b 1
)

echo Step 5: Deploying to Render...
echo Please push your changes to GitHub and trigger Render deployment manually.
echo Your backend should now compile successfully!

pause