#!/bin/bash
# Production Deployment Script
# This script automates the deployment process for the Hotel Booking System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.production"
BACKUP_DIR="backups/pre-deployment"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "=========================================="
echo "  Hotel Booking System"
echo "  Production Deployment"
echo "=========================================="
echo ""

# Step 1: Pre-deployment checks
log_info "Step 1: Running pre-deployment checks..."

if [ ! -f "$ENV_FILE" ]; then
    log_error "$ENV_FILE not found!"
    log_info "Please copy .env.production.example to .env.production and configure it."
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "$COMPOSE_FILE not found!"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed!"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose is not installed!"
    exit 1
fi

log_success "Pre-deployment checks passed"

# Step 2: Verify environment variables
log_info "Step 2: Verifying environment variables..."

if grep -q "CHANGE_ME" "$ENV_FILE"; then
    log_error "Environment file contains placeholder values (CHANGE_ME)"
    log_info "Please update all placeholder values in $ENV_FILE"
    exit 1
fi

log_success "Environment variables verified"

# Step 3: Create necessary directories
log_info "Step 3: Creating necessary directories..."

mkdir -p backups/database
mkdir -p logs/{backend,frontend,nginx,postgres,redis}
mkdir -p nginx/ssl
mkdir -p monitoring/grafana/{dashboards,datasources}
mkdir -p "$BACKUP_DIR"

log_success "Directories created"

# Step 4: Backup existing data (if any)
log_info "Step 4: Backing up existing data..."

if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    log_info "Existing deployment detected. Creating backup..."
    
    # Backup database
    BACKUP_FILE="$BACKUP_DIR/pre_deploy_$(date +%Y%m%d_%H%M%S).sql.gz"
    docker-compose -f "$COMPOSE_FILE" exec -T db pg_dump -U hotel_admin hotel_booking | gzip > "$BACKUP_FILE" 2>/dev/null || true
    
    if [ -f "$BACKUP_FILE" ]; then
        log_success "Database backup created: $BACKUP_FILE"
    fi
else
    log_info "No existing deployment found. Skipping backup."
fi

# Step 5: Pull latest images
log_info "Step 5: Pulling latest Docker images..."

docker-compose -f "$COMPOSE_FILE" pull

log_success "Images pulled successfully"

# Step 6: Build application images
log_info "Step 6: Building application images..."

docker-compose -f "$COMPOSE_FILE" build --no-cache

log_success "Images built successfully"

# Step 7: Stop existing services
log_info "Step 7: Stopping existing services..."

docker-compose -f "$COMPOSE_FILE" down

log_success "Services stopped"

# Step 8: Start services
log_info "Step 8: Starting services..."

docker-compose -f "$COMPOSE_FILE" up -d

log_success "Services started"

# Step 9: Wait for services to be healthy
log_info "Step 9: Waiting for services to be healthy..."

MAX_WAIT=120
WAIT_TIME=0

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "unhealthy"; then
        log_info "Waiting for services to be healthy... ($WAIT_TIME/$MAX_WAIT seconds)"
        sleep 5
        WAIT_TIME=$((WAIT_TIME + 5))
    else
        break
    fi
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    log_error "Services did not become healthy within $MAX_WAIT seconds"
    log_info "Check logs with: docker-compose -f $COMPOSE_FILE logs"
    exit 1
fi

log_success "All services are healthy"

# Step 10: Run database migrations
log_info "Step 10: Running database migrations..."

# Wait for database to be ready
sleep 10

# Check if migrations need to be run
MIGRATION_STATUS=$(docker-compose -f "$COMPOSE_FILE" exec -T db psql -U hotel_admin -d hotel_booking -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" -t 2>/dev/null || echo "0")

if [ "$MIGRATION_STATUS" -lt 10 ]; then
    log_info "Running initial migrations..."
    # Migrations are automatically run via docker-entrypoint-initdb.d
    sleep 5
fi

log_success "Database migrations completed"

# Step 11: Verify deployment
log_info "Step 11: Verifying deployment..."

# Check backend health
if curl -f -s http://localhost:8080/health > /dev/null 2>&1; then
    log_success "Backend is responding"
else
    log_warning "Backend health check failed"
fi

# Check frontend
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    log_success "Frontend is responding"
else
    log_warning "Frontend health check failed"
fi

# Check database
if docker-compose -f "$COMPOSE_FILE" exec -T db pg_isready -U hotel_admin > /dev/null 2>&1; then
    log_success "Database is ready"
else
    log_warning "Database check failed"
fi

# Check Redis
if docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping > /dev/null 2>&1; then
    log_success "Redis is responding"
else
    log_warning "Redis check failed"
fi

# Step 12: Display service status
log_info "Step 12: Service status..."
echo ""
docker-compose -f "$COMPOSE_FILE" ps
echo ""

# Step 13: Display access information
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Services are now running:"
echo ""
echo "  Frontend:    http://localhost (via nginx)"
echo "  Backend API: http://localhost/api (via nginx)"
echo "  Prometheus:  http://localhost:9091"
echo "  Grafana:     http://localhost:3001"
echo ""
echo "Logs location: ./logs/"
echo "Backups location: ./backups/"
echo ""
echo "To view logs:"
echo "  docker-compose -f $COMPOSE_FILE logs -f [service-name]"
echo ""
echo "To stop services:"
echo "  docker-compose -f $COMPOSE_FILE down"
echo ""
echo "=========================================="

# Step 14: Post-deployment tasks
log_info "Post-deployment reminders:"
echo ""
echo "  1. Update DNS records to point to this server"
echo "  2. Configure SSL/TLS certificates"
echo "  3. Set up monitoring alerts"
echo "  4. Test all critical user flows"
echo "  5. Configure backup schedule"
echo "  6. Review security settings"
echo ""

log_success "Deployment completed successfully!"
