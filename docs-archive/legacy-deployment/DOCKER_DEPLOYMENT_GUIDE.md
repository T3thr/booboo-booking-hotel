# 🐳 Docker Deployment Guide

## Quick Start

### Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production
```bash
# Windows
deploy-production.bat

# Linux/Mac
chmod +x deploy-production.sh
./deploy-production.sh
```

## Step by Step Deployment

### 1. เตรียม Environment
```bash
# Copy และแก้ไข environment files
cp .env.production.example .env.production
# แก้ไขค่าต่างๆ ใน .env.production
```

### 2. สร้าง SSL Certificates (Production)
```bash
# Windows
setup-ssl.bat

# Linux/Mac - ใช้ Let's Encrypt
sudo certbot --nginx -d yourdomain.com
```

### 3. Deploy Services
```bash
# Production deployment
docker-compose -f docker-compose.prod.yml up -d --build

# ตรวจสอบสถานะ
docker-compose -f docker-compose.prod.yml ps

# ดู logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Services Overview

| Service | Port | Description |
|---------|------|-------------|
| nginx | 80, 443 | Reverse Proxy & Load Balancer |
| frontend | 3000 | Next.js Application |
| backend | 8080 | Go API Server |
| db | 5432 | PostgreSQL Database |
| redis | 6379 | Redis Cache |
| prometheus | 9091 | Monitoring |
| grafana | 3001 | Dashboard |

## Useful Commands

### ดู Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f nginx
```

### Restart Services
```bash
# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend

# Restart all services
docker-compose -f docker-compose.prod.yml restart
```

### Update Services
```bash
# Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build

# Pull latest images
docker-compose -f docker-compose.prod.yml pull
```

### Database Operations
```bash
# Access database
docker-compose -f docker-compose.prod.yml exec db psql -U postgres -d hotel_booking

# Backup database
docker-compose -f docker-compose.prod.yml exec db pg_dump -U postgres hotel_booking > backup.sql

# Restore database
docker-compose -f docker-compose.prod.yml exec -T db psql -U postgres hotel_booking < backup.sql
```

### Monitoring
```bash
# Check container stats
docker stats

# Check container health
docker-compose -f docker-compose.prod.yml ps
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   netstat -tulpn | grep :80
   
   # Kill process
   sudo kill -9 <PID>
   ```

2. **Permission Denied**
   ```bash
   # Fix permissions
   sudo chown -R $USER:$USER logs/
   sudo chown -R $USER:$USER backups/
   ```

3. **Database Connection Failed**
   ```bash
   # Check database logs
   docker-compose -f docker-compose.prod.yml logs db
   
   # Restart database
   docker-compose -f docker-compose.prod.yml restart db
   ```

4. **Frontend Build Failed**
   ```bash
   # Check frontend logs
   docker-compose -f docker-compose.prod.yml logs frontend
   
   # Rebuild frontend
   docker-compose -f docker-compose.prod.yml up -d --build frontend
   ```

### Health Checks
```bash
# Check all services health
curl http://localhost/health

# Check backend health
curl http://localhost/api/health

# Check frontend
curl http://localhost
```

## Security Checklist

- [ ] Change all default passwords in `.env.production`
- [ ] Use strong JWT secrets
- [ ] Configure SSL/TLS certificates
- [ ] Set up firewall rules
- [ ] Enable rate limiting
- [ ] Configure CORS properly
- [ ] Set up monitoring and alerts
- [ ] Regular security updates

## Backup Strategy

### Automated Backups
- Database backup runs daily at 2 AM
- Backups stored in `./backups/database/`
- Retention: 30 days (configurable)

### Manual Backup
```bash
# Create backup
./scripts/backup-database.sh

# Restore backup
./scripts/restore-database.sh backup_file.sql
```

## Scaling

### Horizontal Scaling
```yaml
# Add more backend instances
backend:
  deploy:
    replicas: 3
```

### Load Balancing
- Nginx handles load balancing
- Backend instances are load balanced
- Database connection pooling

## Production Checklist

- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Database migrations run
- [ ] Monitoring configured
- [ ] Backups tested
- [ ] Health checks working
- [ ] Logs configured
- [ ] Security headers set
- [ ] Rate limiting enabled
- [ ] CORS configured