@echo off
cd /d "%~dp0"
echo Cleaning cache...
if exist .next rmdir /s /q .next
if exist node_modules\.cache rmdir /s /q node_modules\.cache
echo.
echo Building...
call npm run build
pause
