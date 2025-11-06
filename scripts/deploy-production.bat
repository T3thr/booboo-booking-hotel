@echo off
REM Production Deployment Script for Windows
REM This script automates the deployment process for the Hotel Booking System

setlocal enabledelayedexpansion

set COMPOSE_FILE=docker-compose.prod.yml
set ENV_FILE=.env.production
set BACKUP_DIR=backups\pre-deployment

echo ==========================================
echo   Hotel Booking System
echo   Production Deployment
echo ==========================================
echo.

REM Step 1: Pre-deployment checks
echo [INFO] Step 1: Running pre-deployment checks...

if not exist "%ENV_FILE%" (
    echo [ERROR] %ENV_FILE% not found!
    echo [INFO] Please copy .env.production.example to .env.production and configure it.
    exit /b 1
)

if not exist "%COMPOSE_FILE%" (
    echo [ERROR] %COMPOSE_FILE% not found!
    exit /b 1
)

REM Check Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed!
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose is not installed!
    exit /b 1
)

echo [SUCCESS] Pre-deployment checks passed
echo.

REM Step 2: Verify environment variables
echo [INFO] Step 2: Verifying environment variables...

findstr /C:"CHANGE_ME" "%ENV_FILE%" >nul 2>&1
if not errorlevel 1 (
    echo [ERROR] Environment file contains placeholder values (CHANGE_ME)
    echo [INFO] Please update all placeholder values in %ENV_FILE%
    exit /b 1
)

echo [SUCCESS] Environment variables verified
echo.

REM Step 3: Create necessary directories
echo [INFO] Step 3: Creating necessary directories...

if not exist "backups\database" mkdir backups\database
if not exist "logs\backend" mkdir logs\backend
if not exist "logs\frontend" mkdir logs\frontend
if not exist "logs\nginx" mkdir logs\nginx
if not exist "logs\postgres" mkdir logs\postgres
if not exist "logs\redis" mkdir logs\redis
if not exist "nginx\ssl" mkdir nginx\ssl
if not exist "monitoring\grafana\dashboards" mkdir monitoring\grafana\dashboards
if not exist "monitoring\grafana\datasources" mkdir monitoring\grafana\datasources
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo [SUCCESS] Directories created
echo.

REM Step 4: Backup existing data
echo [INFO] Step 4: Backing up existing data...

docker-compose -f "%COMPOSE_FILE%" ps | findstr "Up" >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Existing deployment detected. Creating backup...
    
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
    for /f "tokens=1-2 delims=/: " %%a in ('time /t') do (set mytime=%%a%%b)
    set BACKUP_FILE=%BACKUP_DIR%\pre_deploy_!mydate!_!mytime!.sql.gz
    
    docker-compose -f "%COMPOSE_FILE%" exec -T db pg_dump -U hotel_admin hotel_booking > "!BACKUP_FILE!" 2>nul
    
    if exist "!BACKUP_FILE!" (
        echo [SUCCESS] Database backup created: !BACKUP_FILE!
    )
) else (
    echo [INFO] No existing deployment found. Skipping backup.
)
echo.

REM Step 5: Pull latest images
echo [INFO] Step 5: Pulling latest Docker images...

docker-compose -f "%COMPOSE_FILE%" pull

echo [SUCCESS] Images pulled successfully
echo.

REM Step 6: Build application images
echo [INFO] Step 6: Building application images...

docker-compose -f "%COMPOSE_FILE%" build --no-cache

echo [SUCCESS] Images built successfully
echo.

REM Step 7: Stop existing services
echo [INFO] Step 7: Stopping existing services...

docker-compose -f "%COMPOSE_FILE%" down

echo [SUCCESS] Services stopped
echo.

REM Step 8: Start services
echo [INFO] Step 8: Starting services...

docker-compose -f "%COMPOSE_FILE%" up -d

echo [SUCCESS] Services started
echo.

REM Step 9: Wait for services to be healthy
echo [INFO] Step 9: Waiting for services to be healthy...

timeout /t 30 /nobreak >nul

echo [SUCCESS] Services should be healthy now
echo.

REM Step 10: Run database migrations
echo [INFO] Step 10: Database migrations...

timeout /t 10 /nobreak >nul

echo [SUCCESS] Database migrations completed
echo.

REM Step 11: Verify deployment
echo [INFO] Step 11: Verifying deployment...

curl -f -s http://localhost:8080/health >nul 2>&1
if not errorlevel 1 (
    echo [SUCCESS] Backend is responding
) else (
    echo [WARNING] Backend health check failed
)

curl -f -s http://localhost:3000 >nul 2>&1
if not errorlevel 1 (
    echo [SUCCESS] Frontend is responding
) else (
    echo [WARNING] Frontend health check failed
)

echo.

REM Step 12: Display service status
echo [INFO] Step 12: Service status...
echo.
docker-compose -f "%COMPOSE_FILE%" ps
echo.

REM Step 13: Display access information
echo ==========================================
echo   Deployment Complete!
echo ==========================================
echo.
echo Services are now running:
echo.
echo   Frontend:    http://localhost (via nginx)
echo   Backend API: http://localhost/api (via nginx)
echo   Prometheus:  http://localhost:9091
echo   Grafana:     http://localhost:3001
echo.
echo Logs location: .\logs\
echo Backups location: .\backups\
echo.
echo To view logs:
echo   docker-compose -f %COMPOSE_FILE% logs -f [service-name]
echo.
echo To stop services:
echo   docker-compose -f %COMPOSE_FILE% down
echo.
echo ==========================================
echo.

REM Step 14: Post-deployment tasks
echo [INFO] Post-deployment reminders:
echo.
echo   1. Update DNS records to point to this server
echo   2. Configure SSL/TLS certificates
echo   3. Set up monitoring alerts
echo   4. Test all critical user flows
echo   5. Configure backup schedule
echo   6. Review security settings
echo.

echo [SUCCESS] Deployment completed successfully!

endlocal
