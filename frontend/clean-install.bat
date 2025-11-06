@echo off
echo Cleaning node_modules and lock files...
cd frontend
if exist node_modules rmdir /s /q node_modules
if exist package-lock.json del package-lock.json
if exist bun.lockb del bun.lockb
if exist .next rmdir /s /q .next

echo Installing dependencies with bun...
bun install

echo Done! Now you can run: bun run build
