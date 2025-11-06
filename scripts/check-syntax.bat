@echo off
echo Checking Go syntax...
cd backend

echo Checking models...
go fmt ./internal/models/...
if %ERRORLEVEL% NEQ 0 (
    echo Syntax error in models
    pause
    exit /b 1
)

echo Checking repository...
go fmt ./internal/repository/...
if %ERRORLEVEL% NEQ 0 (
    echo Syntax error in repository
    pause
    exit /b 1
)

echo Checking service...
go fmt ./internal/service/...
if %ERRORLEVEL% NEQ 0 (
    echo Syntax error in service
    pause
    exit /b 1
)

echo Checking handlers...
go fmt ./internal/handlers/...
if %ERRORLEVEL% NEQ 0 (
    echo Syntax error in handlers
    pause
    exit /b 1
)

echo All syntax checks passed!
cd ..
pause