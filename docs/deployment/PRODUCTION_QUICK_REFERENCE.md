# Production Quick Reference

Quick commands and procedures for common production operations.

## Table of Contents

- [Service Management](#service-management)
- [Monitoring](#monitoring)
- [Backups](#backups)
- [Logs](#logs)
- [Troubleshooting](#troubleshooting)
- [Emergency Procedures](#emergency-procedures)

## Service Management

### Start Services

```bash
# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Start specific service
docker-compose -f docker-compose.prod.yml up -d backend
```

### Stop Services

```bash
# Stop all services
docker-compose -f docker-compose.prod.yml down

# Stop specific service
docker-compose -f docker-compose.prod.yml stop backend
```

### Restart Services

```bash
# Restart all services
docker-compose -f docker-compose.prod.yml restart

# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend
```

### Check Status

```bash
# View all services
docker-compose -f docker-compose.prod.yml ps

# Check health
curl http://localhost:8080/health
curl http://localhost:3000
```

### Update Services

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

## Monitoring

### Access Monitoring Tools

```bash
# Prometheus
open http://your-server:9091

# Grafana
open http://your-server:3001
# Default: admin / (password from .env.production)
```

### Check Metrics

```bash
# Backend metrics
curl http://localhost:9090/metrics

# System metrics
docker stats
```

### View Resource Usage

```bash
# CPU and Memory
docker stats --no-stream

# Disk usage
df -h
du -sh backups/
du -sh logs/
```

## Backups

### Create Backup

```bash
# Automatic (runs daily at 2 AM)
# Manual backup
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh
```

### List Backups

```bash
# Local backups
ls -lh backups/database/

# S3 backups (if configured)
aws s3 ls s3://hotel-booking-backups/database/
```

### Restore Backup

```bash
# Restore latest
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# Restore specific backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh /backups/hotel_booking_YYYYMMDD_HHMMSS.sql.gz
```

### Verify Backup

```bash
# Check integrity
gunzip -t backups/database/latest.sql.gz

# Check size
du -h backups/database/latest.sql.gz
```

## Logs

### View Logs

```bash
# All services (real-time)
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend

# Last 100 lines
docker-compose -f docker-compose.prod.yml logs --tail=100 backend
```

### Search Logs

```bash
# Search for errors
docker-compose -f docker-compose.prod.yml logs backend | grep ERROR

# Search in log files
grep "ERROR" logs/backend/app.log

# Search with context
grep -C 5 "ERROR" logs/backend/app.log
```

### Log Files

```bash
# Backend logs
tail -f logs/backend/app.log

# Nginx access logs
tail -f logs/nginx/access.log

# Database logs
tail -f logs/postgres/postgresql.log
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs [service]

# Check configuration
docker-compose -f docker-compose.prod.yml config

# Restart service
docker-compose -f docker-compose.prod.yml restart [service]
```

### Database Issues

```bash
# Check database status
docker-compose -f docker-compose.prod.yml exec db pg_isready

# Connect to database
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking

# Check connections
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "SELECT count(*) FROM pg_stat_activity;"
```

### High CPU/Memory

```bash
# Check resource usage
docker stats

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Check for memory leaks
docker-compose -f docker-compose.prod.yml logs backend | grep "memory"
```

### Slow Performance

```bash
# Check database queries
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"

# Check cache
docker-compose -f docker-compose.prod.yml exec redis redis-cli INFO

# Check nginx
tail -f logs/nginx/access.log | awk '{print $NF}'
```

## Emergency Procedures

### Complete System Failure

```bash
# 1. Stop all services
docker-compose -f docker-compose.prod.yml down

# 2. Check system resources
df -h
free -h
top

# 3. Restart services
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify
docker-compose -f docker-compose.prod.yml ps
curl http://localhost:8080/health
```

### Database Corruption

```bash
# 1. Stop application
docker-compose -f docker-compose.prod.yml stop backend frontend

# 2. Restore from backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# 3. Start application
docker-compose -f docker-compose.prod.yml start backend frontend

# 4. Verify
curl http://localhost:8080/health
```

### Security Breach

```bash
# 1. Isolate system
docker-compose -f docker-compose.prod.yml down

# 2. Change all passwords
# Edit .env.production

# 3. Review logs
grep -i "unauthorized\|failed\|attack" logs/nginx/access.log
grep -i "error\|failed" logs/backend/app.log

# 4. Restore from clean backup
# Follow disaster recovery procedures

# 5. Update security
# Apply patches, update firewall rules
```

### Out of Disk Space

```bash
# 1. Check disk usage
df -h
du -sh logs/
du -sh backups/

# 2. Clean old logs
find logs/ -name "*.log" -mtime +7 -delete

# 3. Clean old backups
find backups/database/ -name "*.sql.gz" -mtime +30 -delete

# 4. Clean Docker
docker system prune -a --volumes

# 5. Restart services
docker-compose -f docker-compose.prod.yml restart
```

## Maintenance Tasks

### Daily

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# Check logs for errors
docker-compose -f docker-compose.prod.yml logs --tail=100 | grep ERROR

# Verify backup completed
ls -lh backups/database/latest.sql.gz
```

### Weekly

```bash
# Review metrics
# Open Grafana dashboards

# Check disk space
df -h

# Review security logs
grep -i "failed\|unauthorized" logs/nginx/access.log | tail -100
```

### Monthly

```bash
# Test backup restore
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# Update dependencies
git pull
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Review and rotate logs
find logs/ -name "*.log" -mtime +30 -delete

# Security audit
docker scan hotel-booking-backend-prod
```

## Useful Commands

### Database

```bash
# Backup
docker-compose -f docker-compose.prod.yml exec db pg_dump -U hotel_admin hotel_booking | gzip > backup.sql.gz

# Restore
gunzip -c backup.sql.gz | docker-compose -f docker-compose.prod.yml exec -T db psql -U hotel_admin hotel_booking

# Query
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "SELECT COUNT(*) FROM bookings;"
```

### Redis

```bash
# Connect
docker-compose -f docker-compose.prod.yml exec redis redis-cli

# Check keys
docker-compose -f docker-compose.prod.yml exec redis redis-cli KEYS "*"

# Flush cache
docker-compose -f docker-compose.prod.yml exec redis redis-cli FLUSHALL
```

### Nginx

```bash
# Test configuration
docker-compose -f docker-compose.prod.yml exec nginx nginx -t

# Reload configuration
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload

# View access log
tail -f logs/nginx/access.log
```

## Environment Variables

### View Current Configuration

```bash
# Show environment
docker-compose -f docker-compose.prod.yml config

# Check specific service
docker-compose -f docker-compose.prod.yml exec backend env
```

### Update Configuration

```bash
# 1. Edit .env.production
nano .env.production

# 2. Restart services
docker-compose -f docker-compose.prod.yml restart
```

## SSL/TLS

### Check Certificate

```bash
# View certificate details
openssl x509 -in nginx/ssl/cert.pem -text -noout

# Check expiry
openssl x509 -in nginx/ssl/cert.pem -noout -dates

# Test SSL
curl -vI https://yourdomain.com
```

### Renew Certificate (Let's Encrypt)

```bash
# Renew
sudo certbot renew

# Copy new certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/key.pem

# Restart nginx
docker-compose -f docker-compose.prod.yml restart nginx
```

## Performance Tuning

### Database

```bash
# Check slow queries
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"

# Analyze tables
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "ANALYZE;"

# Vacuum
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "VACUUM ANALYZE;"
```

### Cache

```bash
# Check cache hit rate
docker-compose -f docker-compose.prod.yml exec redis redis-cli INFO stats | grep hit_rate

# Clear cache
docker-compose -f docker-compose.prod.yml exec redis redis-cli FLUSHALL
```

## Contact Information

- **System Administrator**: admin@yourdomain.com
- **On-Call**: +1-XXX-XXX-XXXX
- **Documentation**: `/docs/deployment/`
- **Support**: support@yourdomain.com

## Additional Resources

- [Production Deployment Guide](PRODUCTION_DEPLOYMENT.md)
- [Logging & Monitoring Guide](LOGGING_MONITORING.md)
- [Backup & Disaster Recovery Guide](BACKUP_DISASTER_RECOVERY.md)
