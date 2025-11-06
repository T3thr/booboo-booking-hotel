@echo off
echo ========================================
echo Testing Admin Layout Refactor
echo ========================================
echo.

echo [1/4] Checking file structure...
if exist "frontend\src\app\admin\layout.tsx" (
    echo ✓ admin/layout.tsx exists
) else (
    echo ✗ admin/layout.tsx missing
)

if exist "frontend\src\components\admin-sidebar.tsx" (
    echo ✓ admin-sidebar.tsx exists
) else (
    echo ✗ admin-sidebar.tsx missing
)

if not exist "frontend\src\app\admin\(manager)\layout.tsx" (
    echo ✓ (manager)/layout.tsx removed
) else (
    echo ✗ (manager)/layout.tsx still exists
)

if not exist "frontend\src\app\admin\(staff)\layout.tsx" (
    echo ✓ (staff)/layout.tsx removed
) else (
    echo ✗ (staff)/layout.tsx still exists
)

echo.
echo [2/4] Checking TypeScript compilation...
cd frontend
call npm run build 2>nul
if %errorlevel% equ 0 (
    echo ✓ TypeScript compilation successful
) else (
    echo ✗ TypeScript compilation failed
)
cd ..

echo.
echo [3/4] Checking for syntax errors...
cd frontend
call npx tsc --noEmit 2>nul
if %errorlevel% equ 0 (
    echo ✓ No TypeScript errors
) else (
    echo ✗ TypeScript errors found
)
cd ..

echo.
echo [4/4] Summary
echo ========================================
echo Admin layout refactor complete!
echo.
echo Next steps:
echo 1. Start frontend: cd frontend ^&^& npm run dev
echo 2. Test as Manager: Login with manager credentials
echo 3. Test as Receptionist: Login with receptionist credentials
echo 4. Test as Housekeeper: Login with housekeeper credentials
echo.
echo See ADMIN_LAYOUT_REFACTOR_COMPLETE.md for details
echo ========================================

pause
