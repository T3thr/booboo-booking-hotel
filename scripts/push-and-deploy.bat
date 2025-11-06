@echo off
echo =================================
echo   PUSHING FIXES AND DEPLOYING
echo =================================

echo Step 1: Adding all changes...
git add .

echo Step 2: Committing changes...
git commit -m "Fix struct duplication and unused import errors in backend models"

echo Step 3: Pushing to GitHub...
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ Successfully pushed to GitHub!
    echo.
    echo 🚀 Render will now automatically deploy your backend.
    echo    Check your Render dashboard for deployment status.
    echo.
    echo 📋 Changes made:
    echo    - Fixed struct duplication errors
    echo    - Removed unused time import from room.go
    echo    - Backend should now compile successfully
) else (
    echo ❌ Failed to push to GitHub
    echo Please check your git configuration and try again.
)

pause