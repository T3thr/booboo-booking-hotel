@echo off
echo Checking if v_all_users view exists...
echo.

cd backend
go run check-view.go
cd ..

pause
