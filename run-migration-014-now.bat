@echo off
echo Running Migration 014 - Role System...
echo.

cd backend\scripts
go run run-migration-014.go
cd ..\..

echo.
echo Done!
pause
