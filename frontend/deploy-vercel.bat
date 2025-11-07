@echo off
REM ========================================
REM Deploy Frontend to Vercel
REM ========================================

echo.
echo ========================================
echo   Deploy Frontend to Vercel
echo ========================================
echo.

REM Check if in frontend directory
if not exist "package.json" (
    echo Error: package.json not found!
    echo Please run this script from the frontend directory
    pause
    exit /b 1
)

echo Step 1: Checking environment variables...
if not exist ".env.production" (
    echo Warning: .env.production not found!
    echo Please create .env.production before deploying
    pause
    exit /b 1
)

echo.
echo Step 2: Installing dependencies...
call npm install
if errorlevel 1 (
    echo Error: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Step 3: Building project...
call npm run build
if errorlevel 1 (
    echo Error: Build failed
    pause
    exit /b 1
)

echo.
echo Step 4: Deploying to Vercel...
echo.
echo Please make sure you have:
echo 1. Installed Vercel CLI: npm install -g vercel
echo 2. Logged in to Vercel: vercel login
echo 3. Set environment variables on Vercel Dashboard
echo.
echo Required environment variables on Vercel:
echo - NEXTAUTH_URL=https://booboo-booking.vercel.app
echo - NEXTAUTH_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=
echo - NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com
echo - BACKEND_URL=https://booboo-booking.onrender.com
echo - NODE_ENV=production
echo.

set /p CONTINUE="Continue with deployment? (y/n): "
if /i not "%CONTINUE%"=="y" (
    echo Deployment cancelled
    pause
    exit /b 0
)

echo.
echo Deploying to production...
call vercel --prod
if errorlevel 1 (
    echo Error: Deployment failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Your app should be available at:
echo https://booboo-booking.vercel.app
echo.
echo Next steps:
echo 1. Test manager login at /auth/admin
echo 2. Check browser console for any errors
echo 3. Verify redirect works correctly
echo.

pause
