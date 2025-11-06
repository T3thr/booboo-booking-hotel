@echo off
echo EMERGENCY PUSH TO GITHUB...

echo Adding all files...
git add .

echo Committing...
git commit -m "URGENT: Fix database method calls for deployment"

echo Pushing to GitHub...
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ PUSHED SUCCESSFULLY!
    echo Render will now deploy automatically.
    echo Check your Render dashboard for deployment status.
) else (
    echo ❌ PUSH FAILED
    echo Check your git configuration
)

pause