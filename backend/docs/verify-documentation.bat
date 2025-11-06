@echo off
REM Verify API Documentation - Task 46
REM This script checks that all documentation files are in place and valid

echo =========================================
echo API Documentation Verification
echo =========================================
echo.

set ERRORS=0
set WARNINGS=0

REM Check if swagger.yaml exists
echo Checking documentation files...
if exist "backend\docs\swagger.yaml" (
    echo [OK] swagger.yaml found
) else (
    echo [ERROR] swagger.yaml NOT found
    set /a ERRORS+=1
)

REM Check if README exists
if exist "backend\docs\README.md" (
    echo [OK] README.md found
) else (
    echo [ERROR] README.md NOT found
    set /a ERRORS+=1
)

REM Check if examples directory exists
if exist "backend\docs\examples" (
    echo [OK] examples\ directory found
    
    REM Check example files
    if exist "backend\docs\examples\auth-examples.md" (
        echo   [OK] auth-examples.md found
    ) else (
        echo   [ERROR] auth-examples.md NOT found
        set /a ERRORS+=1
    )
    
    if exist "backend\docs\examples\booking-examples.md" (
        echo   [OK] booking-examples.md found
    ) else (
        echo   [ERROR] booking-examples.md NOT found
        set /a ERRORS+=1
    )
    
    if exist "backend\docs\examples\room-examples.md" (
        echo   [OK] room-examples.md found
    ) else (
        echo   [ERROR] room-examples.md NOT found
        set /a ERRORS+=1
    )
) else (
    echo [ERROR] examples\ directory NOT found
    set /a ERRORS+=1
)

REM Check setup scripts
if exist "backend\docs\setup-swagger-ui.sh" (
    echo [OK] setup-swagger-ui.sh found
) else (
    echo [WARN] setup-swagger-ui.sh NOT found
    set /a WARNINGS+=1
)

if exist "backend\docs\setup-swagger-ui.bat" (
    echo [OK] setup-swagger-ui.bat found
) else (
    echo [WARN] setup-swagger-ui.bat NOT found
    set /a WARNINGS+=1
)

REM Check testing guide
if exist "backend\docs\TESTING_GUIDE.md" (
    echo [OK] TESTING_GUIDE.md found
) else (
    echo [WARN] TESTING_GUIDE.md NOT found
    set /a WARNINGS+=1
)

echo.
echo Checking swagger.yaml content...

REM Check if swagger.yaml has required sections
findstr /C:"openapi: 3.0" backend\docs\swagger.yaml >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] OpenAPI version specified
) else (
    echo [ERROR] OpenAPI version NOT specified
    set /a ERRORS+=1
)

findstr /C:"info:" backend\docs\swagger.yaml >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Info section found
) else (
    echo [ERROR] Info section NOT found
    set /a ERRORS+=1
)

findstr /C:"paths:" backend\docs\swagger.yaml >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Paths section found
) else (
    echo [ERROR] Paths section NOT found
    set /a ERRORS+=1
)

findstr /C:"components:" backend\docs\swagger.yaml >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Components section found
) else (
    echo [ERROR] Components section NOT found
    set /a ERRORS+=1
)

findstr /C:"securitySchemes:" backend\docs\swagger.yaml >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Security schemes defined
) else (
    echo [ERROR] Security schemes NOT defined
    set /a ERRORS+=1
)

echo.
echo Checking router integration...

REM Check if router has documentation routes
findstr /C:"/docs" backend\internal\router\router.go >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Documentation routes found in router
) else (
    echo [ERROR] Documentation routes NOT found in router
    set /a ERRORS+=1
)

echo.
echo =========================================
echo Verification Summary
echo =========================================
echo Errors: %ERRORS%
echo Warnings: %WARNINGS%
echo.

if %ERRORS% EQU 0 (
    echo [OK] All critical checks passed!
    echo.
    echo Next steps:
    echo 1. Start the backend server: cd backend ^&^& go run cmd/server/main.go
    echo 2. View documentation: http://localhost:8080/docs
    echo 3. Test endpoints using Swagger UI
    echo.
    exit /b 0
) else (
    echo [ERROR] %ERRORS% critical issues found
    echo Please fix the errors above before proceeding.
    echo.
    exit /b 1
)
