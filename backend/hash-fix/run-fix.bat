@echo off
cd /d "%~dp0"
go run fix-db-passwords.go
pause
