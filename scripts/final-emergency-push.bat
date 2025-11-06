@echo off
echo FINAL EMERGENCY PUSH...

git add .
git commit -m "FINAL FIX: Update jobs to use database.DB and fix all database method calls"
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ PUSHED! RENDER WILL DEPLOY NOW!
    echo Check Render dashboard for deployment status.
) else (
    echo ❌ PUSH FAILED
)

pause