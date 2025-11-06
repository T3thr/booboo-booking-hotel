@echo off
echo ============================================
echo Running Migration 014: Role System
echo ============================================
echo.

cd backend\scripts
go run run-migration-014.go
cd ..\..

pause
