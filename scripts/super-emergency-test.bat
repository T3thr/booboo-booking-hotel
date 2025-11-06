@echo off
echo SUPER EMERGENCY TEST...
cd backend
docker build -t final-test .
if %ERRORLEVEL% EQU 0 (
    echo ✅ SUCCESS! READY TO DEPLOY!
    docker rmi final-test
    echo.
    echo PUSH NOW:
    echo git add .
    echo git commit -m "FINAL FIX: Update jobs to use database.DB"
    echo git push origin main
) else (
    echo ❌ STILL FAILED - CHECK ERRORS ABOVE
)
cd ..
pause