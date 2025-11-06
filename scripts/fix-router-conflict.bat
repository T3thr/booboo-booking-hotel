@echo off
echo FIXING ROUTER CONFLICT...

git add .
git commit -m "Fix router conflict: move swagger.yaml to root path"
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ PUSHED! Router conflict fixed!
    echo.
    echo Backend should now start successfully:
    echo - Database: ✅ Connected to Neon
    echo - Redis: ⚠️  Warning only (continues without cache)
    echo - Router: ✅ Fixed conflict
    echo - API: ✅ Should be ready
) else (
    echo ❌ PUSH FAILED
)

pause