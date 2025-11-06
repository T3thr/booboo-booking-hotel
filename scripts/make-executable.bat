@echo off
REM Make shell scripts executable on Windows (Git Bash)

echo Making scripts executable...

git update-index --chmod=+x backup-database.sh
git update-index --chmod=+x restore-database.sh

echo Done! Scripts are now executable.
echo.
echo To use these scripts in production (Linux):
echo   chmod +x scripts/backup-database.sh
echo   chmod +x scripts/restore-database.sh
