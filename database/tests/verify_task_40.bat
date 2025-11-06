@echo off
REM ============================================================================
REM Task 40 Verification Script (Windows)
REM ============================================================================

echo ============================================================
echo Task 40: Integration Tests Verification
echo ============================================================
echo.

echo Checking files...
echo.

REM Check main test file
if exist integration_tests.sql (
    echo [OK] integration_tests.sql
) else (
    echo [MISSING] integration_tests.sql
    exit /b 1
)

REM Check runner scripts
if exist run_integration_tests.bat (
    echo [OK] run_integration_tests.bat
) else (
    echo [MISSING] run_integration_tests.bat
    exit /b 1
)

if exist run_integration_tests.sh (
    echo [OK] run_integration_tests.sh
) else (
    echo [MISSING] run_integration_tests.sh
    exit /b 1
)

REM Check documentation
if exist INTEGRATION_TESTS_README.md (
    echo [OK] INTEGRATION_TESTS_README.md
) else (
    echo [MISSING] INTEGRATION_TESTS_README.md
    exit /b 1
)

if exist INTEGRATION_TESTS_QUICK_REFERENCE.md (
    echo [OK] INTEGRATION_TESTS_QUICK_REFERENCE.md
) else (
    echo [MISSING] INTEGRATION_TESTS_QUICK_REFERENCE.md
    exit /b 1
)

if exist TASK_40_VERIFICATION_CHECKLIST.md (
    echo [OK] TASK_40_VERIFICATION_CHECKLIST.md
) else (
    echo [MISSING] TASK_40_VERIFICATION_CHECKLIST.md
    exit /b 1
)

if exist TASK_40_COMPLETION_SUMMARY.md (
    echo [OK] TASK_40_COMPLETION_SUMMARY.md
) else (
    echo [MISSING] TASK_40_COMPLETION_SUMMARY.md
    exit /b 1
)

if exist TASK_40_INDEX.md (
    echo [OK] TASK_40_INDEX.md
) else (
    echo [MISSING] TASK_40_INDEX.md
    exit /b 1
)

if exist QUICKSTART.md (
    echo [OK] QUICKSTART.md
) else (
    echo [MISSING] QUICKSTART.md
    exit /b 1
)

echo.
echo ============================================================
echo All files present!
echo ============================================================
echo.
echo To run the tests:
echo   run_integration_tests.bat
echo.
echo To read documentation:
echo   start QUICKSTART.md
echo.

pause
