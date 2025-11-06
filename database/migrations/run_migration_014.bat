@echo off
echo ============================================
echo Running Migration 014: Role System
echo ============================================
echo.

REM Set database connection details
set PGHOST=ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech
set PGPORT=5432
set PGUSER=neondb_owner
set PGPASSWORD=npg_8kHamXSLKg1x
set PGDATABASE=neondb

echo Running migration...
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f 014_create_role_system.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo Migration 014 completed successfully!
    echo ============================================
) else (
    echo.
    echo ============================================
    echo Migration 014 failed!
    echo ============================================
)

pause