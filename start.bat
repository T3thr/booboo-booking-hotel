@echo off
REM Hotel Booking System - Quick Start Script (Windows)
REM This script helps you get started with the development environment

echo.
echo 🏨 Hotel Booking System - Quick Start
echo ======================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    echo    Visit: https://www.docker.com/products/docker-desktop
    exit /b 1
)

echo ✅ Docker is installed
echo.

REM Check if .env exists
if not exist .env (
    echo 📝 Creating .env file from .env.example...
    copy .env.example .env >nul
    echo ✅ .env file created
) else (
    echo ✅ .env file already exists
)
echo.

REM Start Docker containers
echo 🚀 Starting Docker containers...
echo.
docker-compose up -d

echo.
echo ⏳ Waiting for services to be ready...
timeout /t 10 /nobreak >nul

REM Check if containers are running
echo.
echo 📊 Container Status:
docker-compose ps

echo.
echo ✅ Development environment is ready!
echo.
echo 🌐 Access the application:
echo    Frontend:  http://localhost:3000
echo    Backend:   http://localhost:8080
echo    Database:  localhost:5432
echo.
echo 📖 Useful commands:
echo    View logs:        docker-compose logs -f
echo    Stop services:    docker-compose down
echo    Restart:          docker-compose restart
echo    Run migrations:   make db-migrate
echo.
echo 📚 For more information, see DOCKER_SETUP.md
echo.
pause
