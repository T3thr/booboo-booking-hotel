# Backup and Disaster Recovery Guide

This document outlines the backup strategy and disaster recovery procedures for the Hotel Booking System.

## Table of Contents

1. [Backup Strategy](#backup-strategy)
2. [Automated Backups](#automated-backups)
3. [Manual Backups](#manual-backups)
4. [Backup Verification](#backup-verification)
5. [Disaster Recovery](#disaster-recovery)
6. [Recovery Time Objectives](#recovery-time-objectives)

## Backup Strategy

### Backup Types

#### 1. Database Backups

**Frequency**: Daily at 2:00 AM
**Retention**: 30 days
**Format**: Compressed SQL dump (.sql.gz)
**Location**: 
- Local: `./backups/database/`
- Remote: S3 bucket (optional)

#### 2. Application Configuration

**Frequency**: On change
**Retention**: Indefinite (version controlled)
**Format**: Git repository
**Location**: GitHub/GitLab

#### 3. User Uploads (if applicable)

**Frequency**: Daily
**Retention**: 90 days
**Format**: Tar archive
**Location**: S3 bucket

#### 4. Log Archives

**Frequency**: Weekly
**Retention**: 90 days
**Format**: Compressed logs
**Location**: `./backups/logs/`

### 3-2-1 Backup Rule

We follow the 3-2-1 backup strategy:
- **3** copies of data
- **2** different storage media
- **1** off-site backup

## Automated Backups

### Database Backup Service

The `db-backup` service runs automatically in production:

```yaml
db-backup:
  image: postgres:15-alpine
  command: -c "while true; do /backup-database.sh; sleep 86400; done"
  volumes:
    - ./backups/database:/backups
    - ./scripts/backup-database.sh:/backup-database.sh:ro
```

### Backup Script

Location: `scripts/backup-database.sh`

Features:
- Creates compressed SQL dumps
- Maintains retention policy (30 days)
- Creates "latest" symlink
- Logs all operations
- Optional S3 upload

### Verify Automated Backups

```bash
# Check backup service status
docker-compose -f docker-compose.prod.yml ps db-backup

# View backup logs
docker-compose -f docker-compose.prod.yml logs db-backup

# List backups
ls -lh backups/database/

# Check latest backup
ls -lh backups/database/latest.sql.gz
```

## Manual Backups

### Create Manual Database Backup

```bash
# Using the backup script
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh

# Or directly with pg_dump
docker-compose -f docker-compose.prod.yml exec db pg_dump \
  -U hotel_admin \
  -d hotel_booking \
  --format=plain \
  --no-owner \
  --no-acl | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Backup Specific Tables

```bash
# Backup only bookings table
docker-compose -f docker-compose.prod.yml exec db pg_dump \
  -U hotel_admin \
  -d hotel_booking \
  -t bookings \
  --format=plain | gzip > bookings_backup.sql.gz

# Backup multiple tables
docker-compose -f docker-compose.prod.yml exec db pg_dump \
  -U hotel_admin \
  -d hotel_booking \
  -t bookings \
  -t booking_details \
  -t room_assignments \
  --format=plain | gzip > bookings_full_backup.sql.gz
```

### Backup Configuration Files

```bash
# Create configuration backup
tar -czf config_backup_$(date +%Y%m%d).tar.gz \
  .env.production \
  nginx/nginx.prod.conf \
  monitoring/ \
  scripts/

# Backup to remote server
scp config_backup_*.tar.gz user@backup-server:/backups/
```

### Backup Docker Volumes

```bash
# Backup PostgreSQL data volume
docker run --rm \
  -v hotel-booking-system_pgdata:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/pgdata_$(date +%Y%m%d).tar.gz /data

# Backup Redis data volume
docker run --rm \
  -v hotel-booking-system_redisdata:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/redisdata_$(date +%Y%m%d).tar.gz /data
```

## Backup Verification

### Verify Backup Integrity

```bash
# Check if backup file is valid gzip
gunzip -t backups/database/latest.sql.gz

# Check backup size (should be > 0)
du -h backups/database/latest.sql.gz

# Verify SQL syntax (extract first 100 lines)
gunzip -c backups/database/latest.sql.gz | head -n 100
```

### Test Restore (Recommended Monthly)

```bash
# Create test database
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d postgres -c "CREATE DATABASE hotel_booking_test;"

# Restore to test database
gunzip -c backups/database/latest.sql.gz | \
  docker-compose -f docker-compose.prod.yml exec -T db psql -U hotel_admin -d hotel_booking_test

# Verify data
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking_test -c "SELECT COUNT(*) FROM bookings;"

# Drop test database
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d postgres -c "DROP DATABASE hotel_booking_test;"
```

## Disaster Recovery

### Scenario 1: Database Corruption

**Symptoms**: Database errors, data inconsistencies

**Recovery Steps**:

```bash
# 1. Stop application
docker-compose -f docker-compose.prod.yml stop backend frontend

# 2. Restore from latest backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# 3. Verify restoration
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "\dt"

# 4. Start application
docker-compose -f docker-compose.prod.yml start backend frontend

# 5. Verify application
curl http://localhost:8080/health
```

**Estimated Recovery Time**: 15-30 minutes

### Scenario 2: Complete Server Failure

**Symptoms**: Server unresponsive, hardware failure

**Recovery Steps**:

```bash
# 1. Provision new server
# - Same OS and specifications
# - Install Docker and Docker Compose

# 2. Clone repository
git clone https://github.com/yourusername/hotel-booking-system.git
cd hotel-booking-system

# 3. Restore configuration
# - Copy .env.production from backup
# - Copy SSL certificates
# - Copy nginx configuration

# 4. Download latest database backup
# From S3 or backup server
aws s3 cp s3://hotel-booking-backups/latest.sql.gz backups/database/

# 5. Start services
docker-compose -f docker-compose.prod.yml up -d

# 6. Wait for database to be ready
docker-compose -f docker-compose.prod.yml exec db pg_isready

# 7. Restore database
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh /backups/latest.sql.gz

# 8. Verify all services
docker-compose -f docker-compose.prod.yml ps
curl https://yourdomain.com/health

# 9. Update DNS if IP changed
# Point domain to new server IP
```

**Estimated Recovery Time**: 2-4 hours

### Scenario 3: Accidental Data Deletion

**Symptoms**: Missing bookings, deleted records

**Recovery Steps**:

```bash
# 1. Identify when data was deleted
# Check application logs
docker-compose -f docker-compose.prod.yml logs backend | grep "DELETE"

# 2. Find backup before deletion
ls -lt backups/database/

# 3. Extract specific data from backup
gunzip -c backups/database/hotel_booking_20240115_020000.sql.gz | \
  grep "INSERT INTO bookings" | \
  grep "booking_id = 123" > restore_booking_123.sql

# 4. Restore specific data
docker-compose -f docker-compose.prod.yml exec -T db psql -U hotel_admin -d hotel_booking < restore_booking_123.sql

# 5. Verify restoration
docker-compose -f docker-compose.prod.yml exec db psql -U hotel_admin -d hotel_booking -c "SELECT * FROM bookings WHERE booking_id = 123;"
```

**Estimated Recovery Time**: 30-60 minutes

### Scenario 4: Ransomware Attack

**Symptoms**: Encrypted files, ransom note

**Recovery Steps**:

```bash
# 1. IMMEDIATELY isolate server
# - Disconnect from network
# - Do not pay ransom

# 2. Assess damage
# - Check which files are encrypted
# - Verify backups are intact

# 3. Provision clean server
# - New server with fresh OS
# - Do not connect to compromised network

# 4. Restore from off-site backup
# - Use backup from before attack
# - Verify backup integrity

# 5. Implement security measures
# - Change all passwords
# - Update firewall rules
# - Enable 2FA
# - Scan for vulnerabilities

# 6. Restore services
# Follow "Complete Server Failure" procedure

# 7. Monitor for suspicious activity
# - Check logs regularly
# - Set up intrusion detection
```

**Estimated Recovery Time**: 4-8 hours

## Recovery Time Objectives

### RTO (Recovery Time Objective)

Maximum acceptable downtime:

| Scenario | RTO | Priority |
|----------|-----|----------|
| Database corruption | 30 min | Critical |
| Application crash | 5 min | Critical |
| Server failure | 4 hours | High |
| Data center outage | 8 hours | Medium |

### RPO (Recovery Point Objective)

Maximum acceptable data loss:

| Data Type | RPO | Backup Frequency |
|-----------|-----|------------------|
| Bookings | 24 hours | Daily |
| User data | 24 hours | Daily |
| Configuration | 0 (version controlled) | On change |
| Logs | 7 days | Weekly |

## Backup Checklist

### Daily

- [ ] Verify automated backup completed
- [ ] Check backup file size
- [ ] Review backup logs for errors

### Weekly

- [ ] Test backup integrity
- [ ] Archive old logs
- [ ] Review disk space usage

### Monthly

- [ ] Perform test restore
- [ ] Review retention policy
- [ ] Update disaster recovery documentation
- [ ] Test disaster recovery procedures

### Quarterly

- [ ] Full disaster recovery drill
- [ ] Review and update RTO/RPO
- [ ] Audit backup security
- [ ] Test off-site backup retrieval

## Off-Site Backup (S3)

### Configure S3 Backup

```bash
# Install AWS CLI in backup container
docker-compose -f docker-compose.prod.yml exec db-backup apk add aws-cli

# Configure AWS credentials
docker-compose -f docker-compose.prod.yml exec db-backup aws configure
```

### Upload Backup to S3

```bash
# Manual upload
aws s3 cp backups/database/latest.sql.gz s3://hotel-booking-backups/database/

# Automated upload (add to backup script)
if [ ! -z "${AWS_S3_BUCKET}" ]; then
  aws s3 cp ${BACKUP_FILE} s3://${AWS_S3_BUCKET}/database/
fi
```

### Download from S3

```bash
# List backups
aws s3 ls s3://hotel-booking-backups/database/

# Download specific backup
aws s3 cp s3://hotel-booking-backups/database/hotel_booking_20240115_020000.sql.gz ./backups/database/
```

## Backup Security

### Encrypt Backups

```bash
# Encrypt backup with GPG
gpg --symmetric --cipher-algo AES256 backup.sql.gz

# Decrypt backup
gpg --decrypt backup.sql.gz.gpg > backup.sql.gz
```

### Secure Backup Storage

- Use encrypted storage (S3 with encryption)
- Restrict access with IAM policies
- Enable versioning
- Use MFA for deletion
- Regular security audits

## Monitoring Backups

### Set Up Alerts

```bash
# Alert if backup fails
if [ $? -ne 0 ]; then
  # Send email alert
  echo "Backup failed!" | mail -s "Backup Alert" admin@yourdomain.com
fi

# Alert if backup is too old
LATEST_BACKUP=$(ls -t backups/database/*.sql.gz | head -1)
BACKUP_AGE=$(( ($(date +%s) - $(stat -c %Y $LATEST_BACKUP)) / 3600 ))

if [ $BACKUP_AGE -gt 36 ]; then
  echo "Backup is $BACKUP_AGE hours old!" | mail -s "Backup Alert" admin@yourdomain.com
fi
```

### Backup Metrics

Track in Prometheus:
- Backup success/failure rate
- Backup duration
- Backup file size
- Time since last backup

## Conclusion

A robust backup and disaster recovery strategy is essential for:
- Protecting against data loss
- Ensuring business continuity
- Meeting compliance requirements
- Maintaining customer trust

Regular testing and updates to this plan are critical for effective disaster recovery.
