#!/bin/bash

# Verify API Documentation - Task 46
# This script checks that all documentation files are in place and valid

echo "========================================="
echo "API Documentation Verification"
echo "========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check if swagger.yaml exists
echo "Checking documentation files..."
if [ -f "backend/docs/swagger.yaml" ]; then
    echo "✓ swagger.yaml found"
else
    echo "✗ swagger.yaml NOT found"
    ERRORS=$((ERRORS+1))
fi

# Check if README exists
if [ -f "backend/docs/README.md" ]; then
    echo "✓ README.md found"
else
    echo "✗ README.md NOT found"
    ERRORS=$((ERRORS+1))
fi

# Check if examples directory exists
if [ -d "backend/docs/examples" ]; then
    echo "✓ examples/ directory found"
    
    # Check example files
    if [ -f "backend/docs/examples/auth-examples.md" ]; then
        echo "  ✓ auth-examples.md found"
    else
        echo "  ✗ auth-examples.md NOT found"
        ERRORS=$((ERRORS+1))
    fi
    
    if [ -f "backend/docs/examples/booking-examples.md" ]; then
        echo "  ✓ booking-examples.md found"
    else
        echo "  ✗ booking-examples.md NOT found"
        ERRORS=$((ERRORS+1))
    fi
    
    if [ -f "backend/docs/examples/room-examples.md" ]; then
        echo "  ✓ room-examples.md found"
    else
        echo "  ✗ room-examples.md NOT found"
        ERRORS=$((ERRORS+1))
    fi
else
    echo "✗ examples/ directory NOT found"
    ERRORS=$((ERRORS+1))
fi

# Check setup scripts
if [ -f "backend/docs/setup-swagger-ui.sh" ]; then
    echo "✓ setup-swagger-ui.sh found"
else
    echo "✗ setup-swagger-ui.sh NOT found"
    WARNINGS=$((WARNINGS+1))
fi

if [ -f "backend/docs/setup-swagger-ui.bat" ]; then
    echo "✓ setup-swagger-ui.bat found"
else
    echo "✗ setup-swagger-ui.bat NOT found"
    WARNINGS=$((WARNINGS+1))
fi

# Check testing guide
if [ -f "backend/docs/TESTING_GUIDE.md" ]; then
    echo "✓ TESTING_GUIDE.md found"
else
    echo "✗ TESTING_GUIDE.md NOT found"
    WARNINGS=$((WARNINGS+1))
fi

echo ""
echo "Checking swagger.yaml content..."

# Check if swagger.yaml has required sections
if grep -q "openapi: 3.0" backend/docs/swagger.yaml 2>/dev/null; then
    echo "✓ OpenAPI version specified"
else
    echo "✗ OpenAPI version NOT specified"
    ERRORS=$((ERRORS+1))
fi

if grep -q "info:" backend/docs/swagger.yaml 2>/dev/null; then
    echo "✓ Info section found"
else
    echo "✗ Info section NOT found"
    ERRORS=$((ERRORS+1))
fi

if grep -q "paths:" backend/docs/swagger.yaml 2>/dev/null; then
    echo "✓ Paths section found"
else
    echo "✗ Paths section NOT found"
    ERRORS=$((ERRORS+1))
fi

if grep -q "components:" backend/docs/swagger.yaml 2>/dev/null; then
    echo "✓ Components section found"
else
    echo "✗ Components section NOT found"
    ERRORS=$((ERRORS+1))
fi

if grep -q "securitySchemes:" backend/docs/swagger.yaml 2>/dev/null; then
    echo "✓ Security schemes defined"
else
    echo "✗ Security schemes NOT defined"
    ERRORS=$((ERRORS+1))
fi

# Count documented endpoints
ENDPOINT_COUNT=$(grep -c "^  /api/" backend/docs/swagger.yaml 2>/dev/null || echo "0")
echo "✓ Found $ENDPOINT_COUNT documented endpoints"

if [ $ENDPOINT_COUNT -lt 10 ]; then
    echo "⚠ Warning: Less than 10 endpoints documented"
    WARNINGS=$((WARNINGS+1))
fi

echo ""
echo "Checking router integration..."

# Check if router has documentation routes
if grep -q "/docs" backend/internal/router/router.go 2>/dev/null; then
    echo "✓ Documentation routes found in router"
else
    echo "✗ Documentation routes NOT found in router"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "========================================="
echo "Verification Summary"
echo "========================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✓ All critical checks passed!"
    echo ""
    echo "Next steps:"
    echo "1. Start the backend server: cd backend && go run cmd/server/main.go"
    echo "2. View documentation: http://localhost:8080/docs"
    echo "3. Test endpoints using Swagger UI"
    echo ""
    exit 0
else
    echo "✗ $ERRORS critical issues found"
    echo "Please fix the errors above before proceeding."
    echo ""
    exit 1
fi
