@echo off
echo FIXING DATABASE_URL SUPPORT...

git add .
git commit -m "Add DATABASE_URL support for production deployment"
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ PUSHED! Backend will now use DATABASE_URL!
    echo.
    echo Next steps:
    echo 1. Wait for Render to redeploy (2-3 minutes)
    echo 2. Check deployment logs
    echo 3. Backend should connect to Neon database successfully
) else (
    echo ❌ PUSH FAILED
)

pause