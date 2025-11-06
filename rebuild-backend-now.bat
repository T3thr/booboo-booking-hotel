@echo off
echo Rebuilding Backend...
cd backend
go build -o hotel-booking-api.exe cmd/server/main.go
echo.
echo Backend rebuilt! Now restart the backend server.
pause
