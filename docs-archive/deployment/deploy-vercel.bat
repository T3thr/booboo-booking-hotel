@echo off
REM ============================================================================
REM Script: deploy-vercel.bat
REM Description: Deploy frontend to Vercel (Windows)
REM ============================================================================

echo ========================================
echo   Vercel Deployment Script
echo ========================================
echo.

REM Check if Vercel CLI is installed
where vercel >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Vercel CLI not found!
    echo.
    echo Installing Vercel CLI...
    npm install -g vercel
    echo.
)

echo [1/5] Checking Vercel CLI...
vercel --version
echo.

echo [2/5] Logging in to Vercel...
echo (If not logged in, browser will open)
vercel login
echo.

echo [3/5] Deploying to Vercel...
echo.
echo This will:
echo - Build your Next.js application
echo - Deploy to Vercel production
echo - Give you a production URL
echo.
pause

cd frontend
vercel --prod
cd ..

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Copy your Vercel URL (e.g., https://your-app.vercel.app)
echo 2. Update environment variables:
echo    - NEXTAUTH_URL = your Vercel URL
echo 3. Update CORS on Render backend:
echo    - ALLOWED_ORIGINS = your Vercel URL
echo.
echo Run: vercel env add NEXTAUTH_URL production
echo Then: vercel --prod (to redeploy)
echo.
echo See: VERCEL_DEPLOYMENT_GUIDE.md for details
echo.

pause
