# Production Deployment Documentation

Welcome to the production deployment documentation for the Hotel Booking System. This directory contains comprehensive guides for deploying, monitoring, and maintaining the system in production.

## 📚 Documentation Index

### 1. [Production Deployment Guide](PRODUCTION_DEPLOYMENT.md)
**Complete deployment walkthrough**

- Prerequisites and system requirements
- Environment setup and configuration
- SSL/TLS certificate setup
- Database initialization
- Application deployment
- Monitoring and alerting setup
- Security hardening
- Troubleshooting guide

**Start here if**: You're deploying the system for the first time.

### 2. [Logging and Monitoring Guide](LOGGING_MONITORING.md)
**Comprehensive logging and monitoring setup**

- Logging architecture and formats
- Log locations and rotation
- Monitoring stack (Prometheus + Grafana)
- Metrics collection and analysis
- Alert configuration
- Performance monitoring
- Security monitoring

**Start here if**: You need to set up or troubleshoot logging and monitoring.

### 3. [Backup and Disaster Recovery Guide](BACKUP_DISASTER_RECOVERY.md)
**Backup strategy and recovery procedures**

- Backup strategy (3-2-1 rule)
- Automated backup configuration
- Manual backup procedures
- Backup verification and testing
- Disaster recovery scenarios
- RTO/RPO objectives
- Off-site backup (S3)

**Start here if**: You need to configure backups or perform disaster recovery.

### 4. [Production Quick Reference](PRODUCTION_QUICK_REFERENCE.md)
**Quick commands for daily operations**

- Service management commands
- Monitoring access points
- Backup and restore commands
- Log viewing and searching
- Troubleshooting procedures
- Emergency procedures
- Maintenance tasks

**Start here if**: You need quick commands for common operations.

## 🚀 Quick Start

### First-Time Deployment

```bash
# 1. Configure environment
cp .env.production.example .env.production
nano .env.production  # Edit with your values

# 2. Set up SSL certificates
sudo certbot certonly --standalone -d yourdomain.com

# 3. Build and start services
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify deployment
docker-compose -f docker-compose.prod.yml ps
curl https://yourdomain.com/health
```

See [Production Deployment Guide](PRODUCTION_DEPLOYMENT.md) for detailed instructions.

### Daily Operations

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Create backup
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh

# Monitor metrics
open http://your-server:9091  # Prometheus
open http://your-server:3001  # Grafana
```

See [Production Quick Reference](PRODUCTION_QUICK_REFERENCE.md) for more commands.

## 📋 Pre-Deployment Checklist

Before deploying to production, ensure you have:

### Environment Configuration
- [ ] Copied `.env.production.example` to `.env.production`
- [ ] Generated strong secrets (JWT, NextAuth, passwords)
- [ ] Configured database credentials
- [ ] Set up domain names
- [ ] Configured email/SMTP settings
- [ ] Set up S3 bucket for backups (optional)

### Security
- [ ] Obtained SSL/TLS certificates
- [ ] Configured firewall rules
- [ ] Set up fail2ban
- [ ] Reviewed security settings
- [ ] Changed all default passwords

### Infrastructure
- [ ] Server meets minimum requirements (4 CPU, 8GB RAM, 100GB SSD)
- [ ] Docker and Docker Compose installed
- [ ] DNS configured correctly
- [ ] Backup storage configured

### Monitoring
- [ ] Prometheus configured
- [ ] Grafana dashboards set up
- [ ] Alerts configured
- [ ] Log rotation enabled

### Testing
- [ ] Tested backup and restore
- [ ] Verified SSL/HTTPS
- [ ] Tested all services
- [ ] Performed load testing

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │  Nginx  │ (Reverse Proxy, SSL/TLS)
                    │  :443   │
                    └────┬────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
    │Frontend │    │ Backend │    │Metrics  │
    │  :3000  │    │  :8080  │    │  :9090  │
    └────┬────┘    └────┬────┘    └─────────┘
         │              │
         │         ┌────┼────┐
         │         │    │    │
         │    ┌────▼──┐ │ ┌──▼────┐
         │    │  DB   │ │ │ Redis │
         │    │ :5432 │ │ │ :6379 │
         │    └───────┘ │ └───────┘
         │              │
         └──────────────┘
```

## 📊 Monitoring Stack

### Prometheus (Port 9091)
- Metrics collection and storage
- Alert rule evaluation
- Time-series database

### Grafana (Port 3001)
- Visualization dashboards
- Alert management
- Data exploration

### Metrics Collected
- **System**: CPU, memory, disk, network
- **Application**: Requests, errors, latency
- **Database**: Connections, queries, performance
- **Business**: Bookings, revenue, occupancy

## 💾 Backup Strategy

### Automated Backups
- **Frequency**: Daily at 2:00 AM
- **Retention**: 30 days local, 90 days S3
- **Format**: Compressed SQL dumps
- **Location**: `./backups/database/`

### Backup Types
1. **Database**: Full PostgreSQL dump
2. **Configuration**: Version controlled
3. **Logs**: Weekly archives
4. **User uploads**: Daily sync to S3

### Recovery Objectives
- **RTO** (Recovery Time Objective): 4 hours
- **RPO** (Recovery Point Objective): 24 hours

## 🔒 Security Features

### Network Security
- HTTPS/TLS encryption
- Internal Docker network
- No exposed database ports
- Nginx reverse proxy
- Rate limiting

### Application Security
- JWT authentication
- Password hashing (bcrypt)
- SQL injection prevention
- XSS protection
- CSRF protection
- Security headers

### Infrastructure Security
- Firewall configuration
- Fail2ban for brute force protection
- Automatic security updates
- Docker security best practices
- Regular security audits

## 📈 Performance Optimization

### Caching
- Redis for application cache
- Nginx static file caching
- Database query caching

### Database
- Connection pooling
- Indexed queries
- Regular VACUUM and ANALYZE

### Application
- Gzip compression
- Static asset optimization
- Lazy loading
- Code splitting

## 🆘 Support and Troubleshooting

### Common Issues

**Service won't start**
```bash
docker-compose -f docker-compose.prod.yml logs [service]
docker-compose -f docker-compose.prod.yml restart [service]
```

**Database connection issues**
```bash
docker-compose -f docker-compose.prod.yml exec db pg_isready
docker-compose -f docker-compose.prod.yml logs backend | grep database
```

**High memory usage**
```bash
docker stats
docker-compose -f docker-compose.prod.yml restart
```

See [Production Quick Reference](PRODUCTION_QUICK_REFERENCE.md) for more troubleshooting commands.

### Getting Help

- **Documentation**: Check the guides in this directory
- **Logs**: Review application and system logs
- **Monitoring**: Check Grafana dashboards
- **Support**: Contact system administrator

## 📝 Maintenance Schedule

### Daily
- Monitor service status
- Check logs for errors
- Verify backup completion

### Weekly
- Review metrics and trends
- Check disk space
- Review security logs
- Archive old logs

### Monthly
- Test backup restoration
- Update dependencies
- Security audit
- Performance optimization
- Review and update documentation

### Quarterly
- Full disaster recovery drill
- Review RTO/RPO objectives
- Capacity planning
- Security penetration testing

## 🔄 Update Procedures

### Application Updates

```bash
# 1. Pull latest code
git pull origin main

# 2. Backup database
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh

# 3. Build new images
docker-compose -f docker-compose.prod.yml build

# 4. Update services (zero-downtime)
docker-compose -f docker-compose.prod.yml up -d

# 5. Verify
docker-compose -f docker-compose.prod.yml ps
curl https://yourdomain.com/health
```

### Database Migrations

```bash
# 1. Backup database
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh

# 2. Run migrations
docker-compose -f docker-compose.prod.yml exec backend ./migrate

# 3. Verify
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "\dt"
```

## 📞 Contact Information

- **System Administrator**: admin@yourdomain.com
- **On-Call Support**: +1-XXX-XXX-XXXX
- **Documentation**: https://docs.yourdomain.com
- **Status Page**: https://status.yourdomain.com

## 📚 Additional Resources

### Internal Documentation
- [Architecture Documentation](../architecture/DESIGN.md)
- [API Documentation](../../backend/docs/swagger.yaml)
- [User Guides](../user-guides/)

### External Resources
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## 🎯 Next Steps

After completing the initial deployment:

1. **Configure Monitoring**
   - Set up custom dashboards
   - Configure alert thresholds
   - Test alert delivery

2. **Optimize Performance**
   - Run load tests
   - Tune database queries
   - Optimize cache settings

3. **Security Hardening**
   - Run security audit
   - Configure fail2ban
   - Set up intrusion detection

4. **Documentation**
   - Document any customizations
   - Create runbooks
   - Train team members

5. **Testing**
   - Test disaster recovery
   - Verify backup restoration
   - Perform security testing

---

**Last Updated**: 2024-01-15
**Version**: 1.0.0
**Maintained By**: DevOps Team
