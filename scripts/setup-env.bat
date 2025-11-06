@echo off
REM Global environment setup for all batch scripts
REM This script sets up PostgreSQL and other tools in PATH

REM Add PostgreSQL to PATH
SET PATH=%PATH%;C:\Program Files\PostgreSQL\16\bin
SET PATH=%PATH%;C:\Program Files\PostgreSQL\15\bin
SET PATH=%PATH%;C:\Program Files\PostgreSQL\14\bin

REM Add other common tools if needed
REM SET PATH=%PATH%;C:\Program Files\Go\bin
REM SET PATH=%PATH%;C:\Program Files\nodejs

REM Verify PostgreSQL is available
where psql >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] PostgreSQL not found in PATH
    echo Please install PostgreSQL or update the path in scripts/setup-env.bat
)

echo Environment setup complete
