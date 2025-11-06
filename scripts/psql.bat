@echo off
REM Wrapper script for psql command
REM Automatically finds PostgreSQL installation

REM Try common PostgreSQL installation paths
SET PSQL_PATH=

if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" (
    SET PSQL_PATH=C:\Program Files\PostgreSQL\16\bin\psql.exe
) else if exist "C:\Program Files\PostgreSQL\15\bin\psql.exe" (
    SET PSQL_PATH=C:\Program Files\PostgreSQL\15\bin\psql.exe
) else if exist "C:\Program Files\PostgreSQL\14\bin\psql.exe" (
    SET PSQL_PATH=C:\Program Files\PostgreSQL\14\bin\psql.exe
) else (
    echo [ERROR] PostgreSQL not found. Please install PostgreSQL or update paths in scripts\psql.bat
    exit /b 1
)

REM Execute psql with all arguments passed to this script
"%PSQL_PATH%" %*
