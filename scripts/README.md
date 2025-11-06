# Production Scripts

This directory contains scripts for production deployment, backup, and maintenance.

## 🔧 PostgreSQL Auto-Detection

**ปัญหา:** ไฟล์ `.bat` ไม่สามารถหา `psql` command ได้

**โซลูชัน:** ใช้ `setup-env.bat` หรือ `psql.bat` wrapper

```batch
# วิธีที่ 1: Setup Environment
call scripts\setup-env.bat
psql -U postgres -d hotel_db -f migration.sql

# วิธีที่ 2: Use Wrapper
scripts\psql.bat -U postgres -d hotel_db -f migration.sql
```

📖 **อ่านเพิ่มเติม:** [POSTGRESQL_SETUP.md](./POSTGRESQL_SETUP.md)

## Scripts

### backup-database.sh

Automated database backup script that runs daily.

**Features:**
- Creates compressed SQL dumps
- Maintains 30-day retention policy
- Creates "latest" symlink for easy access
- Optional S3 upload
- Detailed logging

**Usage:**

```bash
# Manual execution
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh

# Or directly on the host
./scripts/backup-database.sh
```

**Configuration:**

Set these environment variables in `.env.production`:
- `BACKUP_RETENTION_DAYS` - Number of days to keep backups (default: 30)
- `AWS_ACCESS_KEY_ID` - AWS access key for S3 upload (optional)
- `AWS_SECRET_ACCESS_KEY` - AWS secret key (optional)
- `AWS_S3_BUCKET` - S3 bucket name (optional)

### restore-database.sh

Database restoration script for disaster recovery.

**Features:**
- Restores from compressed backups
- Safety confirmation prompt
- Terminates existing connections
- Verifies restoration
- Detailed logging

**Usage:**

```bash
# Restore latest backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest

# Restore specific backup
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh /backups/hotel_booking_20240115_020000.sql.gz

# List available backups
docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh
```

**⚠️ Warning:** This will overwrite the current database. Always confirm you have a recent backup before restoring.

## Setup

### On Linux/Mac

```bash
# Make scripts executable
chmod +x scripts/backup-database.sh
chmod +x scripts/restore-database.sh
```

### On Windows

```bash
# Using Git Bash
./scripts/make-executable.bat

# Or manually
git update-index --chmod=+x scripts/backup-database.sh
git update-index --chmod=+x scripts/restore-database.sh
```

## Backup Schedule

The backup service runs automatically in production:

- **Frequency**: Daily at 2:00 AM
- **Retention**: 30 days
- **Location**: `./backups/database/`
- **Format**: Compressed SQL (.sql.gz)

## Monitoring Backups

### Check Backup Status

```bash
# View backup service logs
docker-compose -f docker-compose.prod.yml logs db-backup

# List backups
ls -lh backups/database/

# Check latest backup
ls -lh backups/database/latest.sql.gz
```

### Verify Backup Integrity

```bash
# Test gzip integrity
gunzip -t backups/database/latest.sql.gz

# Check backup size
du -h backups/database/latest.sql.gz

# View backup contents (first 100 lines)
gunzip -c backups/database/latest.sql.gz | head -n 100
```

## Disaster Recovery

### Quick Recovery Steps

1. **Stop application**
   ```bash
   docker-compose -f docker-compose.prod.yml stop backend frontend
   ```

2. **Restore database**
   ```bash
   docker-compose -f docker-compose.prod.yml exec db-backup /restore-database.sh latest
   ```

3. **Start application**
   ```bash
   docker-compose -f docker-compose.prod.yml start backend frontend
   ```

4. **Verify**
   ```bash
   curl http://localhost:8080/health
   ```

See `docs/deployment/BACKUP_DISASTER_RECOVERY.md` for detailed recovery procedures.

## Off-Site Backup (S3)

### Configure S3 Backup

1. Create S3 bucket:
   ```bash
   aws s3 mb s3://hotel-booking-backups
   ```

2. Set environment variables in `.env.production`:
   ```bash
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_S3_BUCKET=hotel-booking-backups
   AWS_REGION=us-east-1
   ```

3. Backups will automatically upload to S3

### Download from S3

```bash
# List backups
aws s3 ls s3://hotel-booking-backups/database/

# Download specific backup
aws s3 cp s3://hotel-booking-backups/database/hotel_booking_20240115_020000.sql.gz ./backups/database/
```

## Troubleshooting

### Backup Fails

```bash
# Check backup service status
docker-compose -f docker-compose.prod.yml ps db-backup

# View detailed logs
docker-compose -f docker-compose.prod.yml logs --tail=100 db-backup

# Check disk space
df -h

# Manually run backup
docker-compose -f docker-compose.prod.yml exec db-backup /backup-database.sh
```

### Restore Fails

```bash
# Check database is running
docker-compose -f docker-compose.prod.yml ps db

# Verify backup file exists
docker-compose -f docker-compose.prod.yml exec db-backup ls -lh /backups/

# Check backup integrity
docker-compose -f docker-compose.prod.yml exec db-backup gunzip -t /backups/latest.sql.gz

# Try restore with verbose output
docker-compose -f docker-compose.prod.yml exec db-backup sh -x /restore-database.sh latest
```

## Best Practices

1. **Test Restores Monthly**
   - Verify backups are working
   - Practice recovery procedures
   - Update documentation

2. **Monitor Backup Size**
   - Track backup growth
   - Plan for storage needs
   - Set up alerts for failures

3. **Keep Multiple Copies**
   - Local backups (30 days)
   - Off-site backups (S3)
   - Follow 3-2-1 backup rule

4. **Secure Backups**
   - Encrypt sensitive backups
   - Restrict access
   - Use secure transfer methods

5. **Document Procedures**
   - Keep runbooks updated
   - Document any customizations
   - Train team members

## Additional Resources

- [Production Deployment Guide](../docs/deployment/PRODUCTION_DEPLOYMENT.md)
- [Backup & Disaster Recovery Guide](../docs/deployment/BACKUP_DISASTER_RECOVERY.md)
- [Logging & Monitoring Guide](../docs/deployment/LOGGING_MONITORING.md)
