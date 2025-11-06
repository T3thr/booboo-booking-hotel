#!/bin/bash
# Production Setup Verification Script
# This script checks if the production environment is properly configured

set -e

echo "=========================================="
echo "Production Setup Verification"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Check function
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $1"
        ((FAILED++))
    fi
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# 1. Check Docker
echo "1. Checking Docker..."
docker --version > /dev/null 2>&1
check "Docker is installed"

docker-compose --version > /dev/null 2>&1
check "Docker Compose is installed"

# 2. Check Environment Files
echo ""
echo "2. Checking Environment Files..."
[ -f .env.production ] && check ".env.production exists" || warn ".env.production not found (copy from .env.production.example)"
[ -f backend/.env.production.example ] && check "backend/.env.production.example exists"
[ -f frontend/.env.production.example ] && check "frontend/.env.production.example exists"

# 3. Check SSL Certificates
echo ""
echo "3. Checking SSL Certificates..."
[ -d nginx/ssl ] && check "nginx/ssl directory exists" || warn "nginx/ssl directory not found"
[ -f nginx/ssl/cert.pem ] && check "SSL certificate exists" || warn "SSL certificate not found"
[ -f nginx/ssl/key.pem ] && check "SSL key exists" || warn "SSL key not found"

# 4. Check Configuration Files
echo ""
echo "4. Checking Configuration Files..."
[ -f docker-compose.prod.yml ] && check "docker-compose.prod.yml exists"
[ -f nginx/nginx.prod.conf ] && check "nginx/nginx.prod.conf exists"
[ -f monitoring/prometheus.yml ] && check "monitoring/prometheus.yml exists"

# 5. Check Scripts
echo ""
echo "5. Checking Scripts..."
[ -f scripts/backup-database.sh ] && check "backup-database.sh exists"
[ -f scripts/restore-database.sh ] && check "restore-database.sh exists"
[ -x scripts/backup-database.sh ] && check "backup-database.sh is executable" || warn "backup-database.sh is not executable (run: chmod +x scripts/backup-database.sh)"
[ -x scripts/restore-database.sh ] && check "restore-database.sh is executable" || warn "restore-database.sh is not executable (run: chmod +x scripts/restore-database.sh)"

# 6. Check Directories
echo ""
echo "6. Checking Directories..."
[ -d backups ] || mkdir -p backups/database
[ -d backups/database ] && check "backups/database directory exists"
[ -d logs ] || mkdir -p logs/{backend,frontend,nginx,postgres,redis}
[ -d logs ] && check "logs directory exists"
[ -d monitoring ] && check "monitoring directory exists"

# 7. Check Documentation
echo ""
echo "7. Checking Documentation..."
[ -f docs/deployment/PRODUCTION_DEPLOYMENT.md ] && check "Production Deployment Guide exists"
[ -f docs/deployment/LOGGING_MONITORING.md ] && check "Logging & Monitoring Guide exists"
[ -f docs/deployment/BACKUP_DISASTER_RECOVERY.md ] && check "Backup & Disaster Recovery Guide exists"
[ -f docs/deployment/PRODUCTION_QUICK_REFERENCE.md ] && check "Production Quick Reference exists"

# 8. Check Environment Variables (if .env.production exists)
if [ -f .env.production ]; then
    echo ""
    echo "8. Checking Environment Variables..."
    
    grep -q "POSTGRES_PASSWORD=CHANGE" .env.production && warn "POSTGRES_PASSWORD needs to be changed" || check "POSTGRES_PASSWORD is set"
    grep -q "JWT_SECRET=CHANGE" .env.production && warn "JWT_SECRET needs to be changed" || check "JWT_SECRET is set"
    grep -q "NEXTAUTH_SECRET=CHANGE" .env.production && warn "NEXTAUTH_SECRET needs to be changed" || check "NEXTAUTH_SECRET is set"
    grep -q "REDIS_PASSWORD=CHANGE" .env.production && warn "REDIS_PASSWORD needs to be changed" || check "REDIS_PASSWORD is set"
fi

# 9. Check Docker Compose Configuration
echo ""
echo "9. Checking Docker Compose Configuration..."
docker-compose -f docker-compose.prod.yml config > /dev/null 2>&1
check "docker-compose.prod.yml is valid"

# 10. Check System Resources
echo ""
echo "10. Checking System Resources..."
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_MEM" -ge 8 ]; then
    check "System has sufficient memory (${TOTAL_MEM}GB)"
else
    warn "System has only ${TOTAL_MEM}GB memory (8GB recommended)"
fi

DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$DISK_SPACE" -ge 100 ]; then
    check "System has sufficient disk space (${DISK_SPACE}GB available)"
else
    warn "System has only ${DISK_SPACE}GB disk space (100GB recommended)"
fi

# Summary
echo ""
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Production environment is ready for deployment!${NC}"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠ Production environment has some warnings. Please review before deployment.${NC}"
    exit 0
else
    echo -e "${RED}✗ Production environment has issues. Please fix before deployment.${NC}"
    exit 1
fi
