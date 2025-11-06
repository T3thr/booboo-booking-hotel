# Production Deployment Guide

This guide covers the complete production deployment process for the Hotel Booking System.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [SSL/TLS Configuration](#ssltls-configuration)
4. [Database Setup](#database-setup)
5. [Application Deployment](#application-deployment)
6. [Monitoring Setup](#monitoring-setup)
7. [Backup Configuration](#backup-configuration)
8. [Security Hardening](#security-hardening)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Ubuntu 20.04 LTS or later (recommended)
- **CPU**: 4+ cores
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 100GB+ SSD
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### Domain Requirements

- Registered domain name
- DNS configured to point to your server
- SSL/TLS certificate (Let's Encrypt recommended)

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/hotel-booking-system.git
cd hotel-booking-system
```

### 2. Create Production Environment File

```bash
cp .env.production.example .env.production
```

### 3. Generate Secrets

Generate strong secrets for production:

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

### 4. Configure Environment Variables

Edit `.env.production` and set all required values:

```bash
nano .env.production
```

**Critical variables to set:**

- `POSTGRES_PASSWORD` - Strong database password
- `JWT_SECRET` - Generated JWT secret
- `NEXTAUTH_SECRET` - Generated NextAuth secret
- `REDIS_PASSWORD` - Redis password
- `NEXT_PUBLIC_API_URL` - Your API domain (e.g., https://api.yourdomain.com/api)
- `NEXTAUTH_URL` - Your frontend domain (e.g., https://yourdomain.com)
- `DOMAIN` - Your domain name
- `SMTP_*` - Email configuration for notifications

## SSL/TLS Configuration

### Option 1: Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot

# Obtain certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/key.pem
sudo chmod 644 nginx/ssl/cert.pem
sudo chmod 600 nginx/ssl/key.pem
```

### Option 2: Self-Signed Certificate (Development/Testing Only)

```bash
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=yourdomain.com"
```

### Certificate Renewal

Set up automatic renewal for Let's Encrypt:

```bash
# Add to crontab
sudo crontab -e

# Add this line (runs twice daily)
0 0,12 * * * certbot renew --quiet --post-hook "docker-compose -f /path/to/docker-compose.prod.yml restart nginx"
```

## Database Setup

### 1. Initialize Database

The database will be automatically initialized on first run with migrations.

### 2. Verify Database

```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking

# Check tables
\dt

# Exit
\q
```

### 3. Create Initial Admin User

```bash
# Run SQL to create admin user
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "
INSERT INTO guests (first_name, last_name, email, phone) 
VALUES ('Admin', 'User', 'admin@yourdomain.com', '1234567890');

INSERT INTO guest_accounts (guest_id, hashed_password) 
VALUES (
  (SELECT guest_id FROM guests WHERE email = 'admin@yourdomain.com'),
  '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIR.yvjK6e'
);
-- Default password: admin123 (CHANGE THIS IMMEDIATELY)
"
```

## Application Deployment

### 1. Build and Start Services

```bash
# Build images
docker-compose -f docker-compose.prod.yml build

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
```

### 2. Verify Services

```bash
# Check backend health
curl http://localhost:8080/health

# Check frontend
curl http://localhost:3000

# Check logs
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
```

### 3. Configure Nginx

Update `nginx/nginx.prod.conf` with your domain:

```bash
sed -i 's/yourdomain.com/your-actual-domain.com/g' nginx/nginx.prod.conf
```

Restart Nginx:

```bash
docker-compose -f docker-compose.prod.yml restart nginx
```

## Monitoring Setup

### 1. Access Prometheus

Navigate to: `http://your-server-ip:9091`

### 2. Access Grafana

Navigate to: `http://your-server-ip:3001`

Default credentials:
- Username: `admin`
- Password: Set in `GRAFANA_ADMIN_PASSWORD` environment variable

### 3. Configure Dashboards

1. Log in to Grafana
2. Go to Dashboards → Import
3. Import pre-configured dashboards from `monitoring/grafana/dashboards/`

### 4. Set Up Alerts

Configure alerts in Prometheus for:
- High CPU usage
- High memory usage
- Database connection failures
- API response time > 1s
- Error rate > 5%

## Backup Configuration

### 1. Automated Database Backups

Backups run automatically daily at 2 AM. Verify:

```bash
# Check backup logs
docker-compose -f docker-compose.prod.yml logs db-backup

# List backups
ls -lh backups/database/
```

### 2. Manual Backup

```bash
# Create manual backup
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh
```

### 3. Restore from Backup

```bash
# List available backups
docker-compose -f docker-compose.prod.yml exec db-backup ls -lh /backups/

# Restore latest backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# Restore specific backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh /backups/hotel_booking_20240101_020000.sql.gz
```

### 4. Off-site Backup (Recommended)

Configure S3 backup in `.env.production`:

```bash
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET=hotel-booking-backups
AWS_REGION=us-east-1
```

## Security Hardening

### 1. Firewall Configuration

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### 2. Fail2Ban Setup

```bash
# Install fail2ban
sudo apt-get install fail2ban

# Configure for nginx
sudo nano /etc/fail2ban/jail.local
```

Add:

```ini
[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /path/to/logs/nginx/error.log
maxretry = 5
findtime = 600
bantime = 3600
```

### 3. Regular Security Updates

```bash
# Set up automatic security updates
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 4. Docker Security

```bash
# Run Docker in rootless mode (optional)
# Follow: https://docs.docker.com/engine/security/rootless/

# Scan images for vulnerabilities
docker scan hotel-booking-backend-prod
docker scan hotel-booking-frontend-prod
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs [service-name]

# Check container status
docker-compose -f docker-compose.prod.yml ps

# Restart service
docker-compose -f docker-compose.prod.yml restart [service-name]
```

### Database Connection Issues

```bash
# Check database is running
docker-compose -f docker-compose.prod.yml exec db pg_isready

# Check connection from backend
docker-compose -f docker-compose.prod.yml exec backend ping db

# Verify credentials
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "SELECT 1;"
```

### High Memory Usage

```bash
# Check resource usage
docker stats

# Restart services to free memory
docker-compose -f docker-compose.prod.yml restart
```

### SSL Certificate Issues

```bash
# Verify certificate
openssl x509 -in nginx/ssl/cert.pem -text -noout

# Check certificate expiry
openssl x509 -in nginx/ssl/cert.pem -noout -dates

# Test SSL configuration
curl -vI https://yourdomain.com
```

## Maintenance

### Regular Tasks

**Daily:**
- Monitor application logs
- Check backup completion
- Review error rates

**Weekly:**
- Review security logs
- Check disk space
- Update dependencies (if needed)

**Monthly:**
- Review and rotate logs
- Test backup restoration
- Security audit
- Performance optimization

### Log Rotation

Logs are automatically rotated by Docker. To manually clean:

```bash
# Clean old logs
find logs/ -name "*.log" -mtime +30 -delete

# Truncate Docker logs
docker-compose -f docker-compose.prod.yml down
rm -rf /var/lib/docker/containers/*/*-json.log
docker-compose -f docker-compose.prod.yml up -d
```

## Scaling

### Horizontal Scaling

To scale backend or frontend:

```bash
# Scale backend to 3 instances
docker-compose -f docker-compose.prod.yml up -d --scale backend=3

# Scale frontend to 2 instances
docker-compose -f docker-compose.prod.yml up -d --scale frontend=2
```

Update nginx configuration to load balance across instances.

### Database Scaling

For high traffic, consider:
- Read replicas
- Connection pooling (PgBouncer)
- Database partitioning

## Support

For issues or questions:
- Check logs: `docker-compose -f docker-compose.prod.yml logs`
- Review documentation: `docs/`
- Contact: support@yourdomain.com
