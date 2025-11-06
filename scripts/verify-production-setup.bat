@echo off
REM Production Setup Verification Script for Windows
REM This script checks if the production environment is properly configured

echo ==========================================
echo Production Setup Verification
echo ==========================================
echo.

set PASSED=0
set FAILED=0
set WARNINGS=0

REM 1. Check Docker
echo 1. Checking Docker...
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Docker is installed
    set /a PASSED+=1
) else (
    echo [FAIL] Docker is not installed
    set /a FAILED+=1
)

docker-compose --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Docker Compose is installed
    set /a PASSED+=1
) else (
    echo [FAIL] Docker Compose is not installed
    set /a FAILED+=1
)

REM 2. Check Environment Files
echo.
echo 2. Checking Environment Files...
if exist .env.production (
    echo [OK] .env.production exists
    set /a PASSED+=1
) else (
    echo [WARN] .env.production not found ^(copy from .env.production.example^)
    set /a WARNINGS+=1
)

if exist backend\.env.production.example (
    echo [OK] backend/.env.production.example exists
    set /a PASSED+=1
) else (
    echo [FAIL] backend/.env.production.example not found
    set /a FAILED+=1
)

if exist frontend\.env.production.example (
    echo [OK] frontend/.env.production.example exists
    set /a PASSED+=1
) else (
    echo [FAIL] frontend/.env.production.example not found
    set /a FAILED+=1
)

REM 3. Check SSL Certificates
echo.
echo 3. Checking SSL Certificates...
if exist nginx\ssl (
    echo [OK] nginx/ssl directory exists
    set /a PASSED+=1
) else (
    echo [WARN] nginx/ssl directory not found
    set /a WARNINGS+=1
)

if exist nginx\ssl\cert.pem (
    echo [OK] SSL certificate exists
    set /a PASSED+=1
) else (
    echo [WARN] SSL certificate not found
    set /a WARNINGS+=1
)

if exist nginx\ssl\key.pem (
    echo [OK] SSL key exists
    set /a PASSED+=1
) else (
    echo [WARN] SSL key not found
    set /a WARNINGS+=1
)

REM 4. Check Configuration Files
echo.
echo 4. Checking Configuration Files...
if exist docker-compose.prod.yml (
    echo [OK] docker-compose.prod.yml exists
    set /a PASSED+=1
) else (
    echo [FAIL] docker-compose.prod.yml not found
    set /a FAILED+=1
)

if exist nginx\nginx.prod.conf (
    echo [OK] nginx/nginx.prod.conf exists
    set /a PASSED+=1
) else (
    echo [FAIL] nginx/nginx.prod.conf not found
    set /a FAILED+=1
)

if exist monitoring\prometheus.yml (
    echo [OK] monitoring/prometheus.yml exists
    set /a PASSED+=1
) else (
    echo [FAIL] monitoring/prometheus.yml not found
    set /a FAILED+=1
)

REM 5. Check Scripts
echo.
echo 5. Checking Scripts...
if exist scripts\backup-database.sh (
    echo [OK] backup-database.sh exists
    set /a PASSED+=1
) else (
    echo [FAIL] backup-database.sh not found
    set /a FAILED+=1
)

if exist scripts\restore-database.sh (
    echo [OK] restore-database.sh exists
    set /a PASSED+=1
) else (
    echo [FAIL] restore-database.sh not found
    set /a FAILED+=1
)

REM 6. Check Directories
echo.
echo 6. Checking Directories...
if not exist backups\database mkdir backups\database
if exist backups\database (
    echo [OK] backups/database directory exists
    set /a PASSED+=1
)

if not exist logs mkdir logs
if not exist logs\backend mkdir logs\backend
if not exist logs\frontend mkdir logs\frontend
if not exist logs\nginx mkdir logs\nginx
if not exist logs\postgres mkdir logs\postgres
if not exist logs\redis mkdir logs\redis
if exist logs (
    echo [OK] logs directory exists
    set /a PASSED+=1
)

if exist monitoring (
    echo [OK] monitoring directory exists
    set /a PASSED+=1
) else (
    echo [FAIL] monitoring directory not found
    set /a FAILED+=1
)

REM 7. Check Documentation
echo.
echo 7. Checking Documentation...
if exist docs\deployment\PRODUCTION_DEPLOYMENT.md (
    echo [OK] Production Deployment Guide exists
    set /a PASSED+=1
) else (
    echo [FAIL] Production Deployment Guide not found
    set /a FAILED+=1
)

if exist docs\deployment\LOGGING_MONITORING.md (
    echo [OK] Logging ^& Monitoring Guide exists
    set /a PASSED+=1
) else (
    echo [FAIL] Logging ^& Monitoring Guide not found
    set /a FAILED+=1
)

if exist docs\deployment\BACKUP_DISASTER_RECOVERY.md (
    echo [OK] Backup ^& Disaster Recovery Guide exists
    set /a PASSED+=1
) else (
    echo [FAIL] Backup ^& Disaster Recovery Guide not found
    set /a FAILED+=1
)

if exist docs\deployment\PRODUCTION_QUICK_REFERENCE.md (
    echo [OK] Production Quick Reference exists
    set /a PASSED+=1
) else (
    echo [FAIL] Production Quick Reference not found
    set /a FAILED+=1
)

REM 8. Check Environment Variables
if exist .env.production (
    echo.
    echo 8. Checking Environment Variables...
    findstr /C:"POSTGRES_PASSWORD=CHANGE" .env.production >nul 2>&1
    if %errorlevel% equ 0 (
        echo [WARN] POSTGRES_PASSWORD needs to be changed
        set /a WARNINGS+=1
    ) else (
        echo [OK] POSTGRES_PASSWORD is set
        set /a PASSED+=1
    )
    
    findstr /C:"JWT_SECRET=CHANGE" .env.production >nul 2>&1
    if %errorlevel% equ 0 (
        echo [WARN] JWT_SECRET needs to be changed
        set /a WARNINGS+=1
    ) else (
        echo [OK] JWT_SECRET is set
        set /a PASSED+=1
    )
    
    findstr /C:"NEXTAUTH_SECRET=CHANGE" .env.production >nul 2>&1
    if %errorlevel% equ 0 (
        echo [WARN] NEXTAUTH_SECRET needs to be changed
        set /a WARNINGS+=1
    ) else (
        echo [OK] NEXTAUTH_SECRET is set
        set /a PASSED+=1
    )
)

REM 9. Check Docker Compose Configuration
echo.
echo 9. Checking Docker Compose Configuration...
docker-compose -f docker-compose.prod.yml config >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] docker-compose.prod.yml is valid
    set /a PASSED+=1
) else (
    echo [FAIL] docker-compose.prod.yml has errors
    set /a FAILED+=1
)

REM Summary
echo.
echo ==========================================
echo Verification Summary
echo ==========================================
echo Passed: %PASSED%
echo Warnings: %WARNINGS%
echo Failed: %FAILED%
echo.

if %FAILED% equ 0 (
    if %WARNINGS% equ 0 (
        echo [OK] Production environment is ready for deployment!
        exit /b 0
    ) else (
        echo [WARN] Production environment has some warnings. Please review before deployment.
        exit /b 0
    )
) else (
    echo [FAIL] Production environment has issues. Please fix before deployment.
    exit /b 1
)
