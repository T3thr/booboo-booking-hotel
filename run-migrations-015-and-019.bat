@echo off
REM ============================================================================
REM Run Migrations 015 and 019 in sequence
REM ============================================================================

echo ============================================
echo Running Migrations 015 and 019
echo ============================================
echo.

cd database\migrations

echo Step 1: Creating Payment Proof Table (Migration 015)
echo ============================================
call run_migration_015.bat

echo.
echo.
echo Step 2: Seeding Admin Demo Data (Migration 019)
echo ============================================
call run_migration_019.bat

echo.
echo ============================================
echo All migrations completed!
echo ============================================
echo.
echo You can now:
echo 1. Restart Backend: cd backend ^&^& go run cmd/server/main.go
echo 2. Open Admin Dashboard: http://localhost:3000/admin/dashboard
echo.

pause
