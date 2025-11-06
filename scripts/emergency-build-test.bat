@echo off
echo EMERGENCY BUILD TEST...
cd backend
docker build -t emergency-test .
if %ERRORLEVEL% EQU 0 (
    echo ✅ SUCCESS! Ready to deploy!
    docker rmi emergency-test
) else (
    echo ❌ STILL FAILED
)
cd ..
pause