@echo off
REM Quick restart without rebuild (use only if code hasn't changed)

taskkill /F /IM server.exe 2>nul
taskkill /F /IM hotel-booking-api.exe 2>nul
timeout /t 1 /nobreak >nul

echo Starting server...
bin\server.exe
