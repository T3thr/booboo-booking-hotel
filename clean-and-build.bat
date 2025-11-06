@echo off
echo ========================================
echo Cleaning and Reinstalling Frontend
echo ========================================

cd frontend

echo.
echo [1/5] Removing node_modules...
if exist node_modules rmdir /s /q node_modules

echo [2/5] Removing lock files...
if exist package-lock.json del package-lock.json
if exist bun.lockb del bun.lockb

echo [3/5] Removing .next build cache...
if exist .next rmdir /s /q .next

echo [4/5] Installing dependencies with bun...
bun install

echo [5/5] Building project...
bun run build

echo.
echo ========================================
echo Done!
echo ========================================
