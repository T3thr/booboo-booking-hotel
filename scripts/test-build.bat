@echo off
echo Testing Go build...
cd backend
go build -o main.exe ./cmd/server
if %ERRORLEVEL% EQU 0 (
    echo Build successful!
    del main.exe
) else (
    echo Build failed with error code %ERRORLEVEL%
)
cd ..
pause