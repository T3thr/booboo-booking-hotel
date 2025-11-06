# Task 49: Production Deployment - Quick Reference

## Quick Start Commands

### 1. Verify Setup
```bash
# Linux/Mac
./scripts/verify-production-setup.sh

# Windows
scripts\verify-production-setup.bat
```

### 2. Deploy to Production
```bash
# Linux/Mac
./scripts/deploy-production.sh

# Windows
scripts\deploy-production.bat
```

### 3. Test Production
```bash
# Linux/Mac
./scripts/test-production.sh

# Windows
scripts\test-production.bat
```

## Pre-deployment Checklist

- [ ] Copy `.env.production.example` to `.env.production`
- [ ] Generate and set all secrets (JWT_SECRET, NEXTAUTH_SECRET, passwords)
- [ ] Configure domain names (NEXT_PUBLIC_API_URL, NEXTAUTH_URL)
- [ ] Obtain SSL/TLS certificates
- [ ] Configure SMTP for email notifications
- [ ] Review and update CORS settings
- [ ] Set up DNS records
- [ ] Configure firewall rules

## Environment Variables to Set

### Critical Variables
```bash
# Database
POSTGRES_PASSWORD=<strong-password>

# JWT & Auth
JWT_SECRET=<generate-with-openssl-rand-base64-32>
NEXTAUTH_SECRET=<generate-with-openssl-rand-base64-32>

# Redis
REDIS_PASSWORD=<strong-password>

# Domains
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api
NEXTAUTH_URL=https://yourdomain.com
DOMAIN=yourdomain.com
```

## Generate Secrets

```bash
# JWT Secret
openssl rand -base64 32

# NextAuth Secret
openssl rand -base64 32

# Database Password
openssl rand -base64 24

# Redis Password
openssl rand -base64 24
```

## Service Management

### Start Services
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Stop Services
```bash
docker-compose -f docker-compose.prod.yml down
```

### Restart Services
```bash
docker-compose -f docker-compose.prod.yml restart
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f db
```

### Check Status
```bash
docker-compose -f docker-compose.prod.yml ps
```

## Health Checks

### Backend
```bash
curl http://localhost:8080/health
```

### Frontend
```bash
curl http://localhost:3000
```

### Database
```bash
docker-compose -f docker-compose.prod.yml exec db pg_isready -U hotel_admin
```

### Redis
```bash
docker-compose -f docker-compose.prod.yml exec redis redis-cli ping
```

## Backup & Restore

### Create Backup
```bash
# Automated (runs daily at 2 AM)
# Manual backup
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh
```

### List Backups
```bash
ls -lh backups/database/
```

### Restore Backup
```bash
# Restore latest
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# Restore specific backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh /backups/hotel_booking_20240101_020000.sql.gz
```

## Monitoring

### Access Monitoring Tools
- **Prometheus**: http://localhost:9091
- **Grafana**: http://localhost:3001 (default: admin/admin)
- **Backend Metrics**: http://localhost:9090/metrics

### View Metrics
```bash
# CPU and Memory usage
docker stats

# Disk usage
df -h

# Network connections
netstat -an | grep LISTEN
```

## Troubleshooting

### Service Won't Start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs [service-name]

# Verify configuration
docker-compose -f docker-compose.prod.yml config

# Restart service
docker-compose -f docker-compose.prod.yml restart [service-name]
```

### Database Issues
```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking

# Check tables
\dt

# Check connections
SELECT count(*) FROM pg_stat_activity;
```

### Clear Cache
```bash
# Clear Redis cache
docker-compose -f docker-compose.prod.yml exec redis redis-cli FLUSHALL
```

### Reset Everything
```bash
# Stop and remove all containers, volumes
docker-compose -f docker-compose.prod.yml down -v

# Rebuild and start
docker-compose -f docker-compose.prod.yml up -d --build
```

## Performance Optimization

### Check Response Times
```bash
# Test API response time
time curl http://localhost:8080/api/rooms/types
```

### Database Performance
```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking

# Check slow queries
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

# Check index usage
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
ORDER BY idx_scan;
```

## Security

### Update Passwords
```bash
# Update in .env.production
nano .env.production

# Restart services
docker-compose -f docker-compose.prod.yml restart
```

### Check Security
```bash
# Run security audit
./scripts/test-production.sh

# Check for vulnerabilities
docker scan hotel-booking-backend-prod
docker scan hotel-booking-frontend-prod
```

## Scaling

### Scale Services
```bash
# Scale backend to 3 instances
docker-compose -f docker-compose.prod.yml up -d --scale backend=3

# Scale frontend to 2 instances
docker-compose -f docker-compose.prod.yml up -d --scale frontend=2
```

## Maintenance

### Update Application
```bash
# Pull latest code
git pull origin main

# Rebuild and deploy
./scripts/deploy-production.sh
```

### Clean Up
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune
```

### Log Rotation
```bash
# Logs are automatically rotated by Docker
# Manual cleanup of old logs
find logs/ -name "*.log" -mtime +30 -delete
```

## Important URLs

### Production
- Frontend: https://yourdomain.com
- Backend API: https://api.yourdomain.com/api
- API Docs: https://api.yourdomain.com/swagger/index.html

### Monitoring
- Prometheus: http://localhost:9091
- Grafana: http://localhost:3001

### Documentation
- Deployment Guide: `docs/deployment/PRODUCTION_DEPLOYMENT.md`
- API Documentation: `backend/docs/swagger.yaml`
- User Guides: `docs/user-guides/`

## Support

### Check Documentation
```bash
# List all documentation
ls -R docs/

# View specific guide
cat docs/deployment/PRODUCTION_DEPLOYMENT.md
```

### Get Help
```bash
# View logs for errors
docker-compose -f docker-compose.prod.yml logs --tail=100

# Check service status
docker-compose -f docker-compose.prod.yml ps

# Run diagnostics
./scripts/verify-production-setup.sh
```

## Emergency Procedures

### Service Down
```bash
# 1. Check status
docker-compose -f docker-compose.prod.yml ps

# 2. Check logs
docker-compose -f docker-compose.prod.yml logs [service]

# 3. Restart service
docker-compose -f docker-compose.prod.yml restart [service]

# 4. If still down, rebuild
docker-compose -f docker-compose.prod.yml up -d --build [service]
```

### Database Corruption
```bash
# 1. Stop services
docker-compose -f docker-compose.prod.yml down

# 2. Restore from backup
docker-compose -f docker-compose.prod.yml up -d db
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# 3. Start all services
docker-compose -f docker-compose.prod.yml up -d
```

### High Load
```bash
# 1. Check resource usage
docker stats

# 2. Scale services
docker-compose -f docker-compose.prod.yml up -d --scale backend=3

# 3. Clear cache if needed
docker-compose -f docker-compose.prod.yml exec redis redis-cli FLUSHALL

# 4. Restart services
docker-compose -f docker-compose.prod.yml restart
```

---

**For detailed information, see**: `TASK_49_DEPLOYMENT_COMPLETE.md`
