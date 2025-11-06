@echo off
REM Install Redis Go client

cd /d "%~dp0"
go get github.com/redis/go-redis/v9
go mod tidy

echo Redis client installed successfully
pause
