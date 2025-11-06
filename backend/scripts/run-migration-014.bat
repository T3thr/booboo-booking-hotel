@echo off
echo ============================================
echo Running Migration 014: Role System
echo ============================================
echo.

cd %~dp0
go run run-migration-014.go

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo Migration completed successfully!
    echo ============================================
) else (
    echo.
    echo ============================================
    echo Migration failed!
    echo ============================================
)

pause
