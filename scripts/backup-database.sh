#!/bin/sh
# Database Backup Script for Production
# This script creates automated PostgreSQL backups

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/hotel_booking_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Database connection details
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${POSTGRES_DB:-hotel_booking}
DB_USER=${POSTGRES_USER:-postgres}

echo "=========================================="
echo "Starting database backup: $(date)"
echo "=========================================="

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Create backup
echo "Creating backup: ${BACKUP_FILE}"
PGPASSWORD=${POSTGRES_PASSWORD} pg_dump \
    -h ${DB_HOST} \
    -p ${DB_PORT} \
    -U ${DB_USER} \
    -d ${DB_NAME} \
    --format=plain \
    --no-owner \
    --no-acl \
    --verbose \
    2>&1 | gzip > ${BACKUP_FILE}

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "✅ Backup created successfully: ${BACKUP_FILE}"
    
    # Get backup size
    BACKUP_SIZE=$(du -h ${BACKUP_FILE} | cut -f1)
    echo "Backup size: ${BACKUP_SIZE}"
    
    # Create a "latest" symlink
    ln -sf $(basename ${BACKUP_FILE}) ${BACKUP_DIR}/latest.sql.gz
    echo "✅ Latest backup symlink updated"
else
    echo "❌ Backup failed!"
    exit 1
fi

# Clean up old backups
echo "Cleaning up backups older than ${RETENTION_DAYS} days..."
find ${BACKUP_DIR} -name "hotel_booking_*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
echo "✅ Old backups cleaned up"

# List current backups
echo "Current backups:"
ls -lh ${BACKUP_DIR}/hotel_booking_*.sql.gz 2>/dev/null || echo "No backups found"

# Optional: Upload to S3 (if AWS credentials are configured)
if [ ! -z "${AWS_ACCESS_KEY_ID}" ] && [ ! -z "${AWS_S3_BUCKET}" ]; then
    echo "Uploading backup to S3..."
    # Requires aws-cli to be installed
    # aws s3 cp ${BACKUP_FILE} s3://${AWS_S3_BUCKET}/backups/
    echo "Note: S3 upload requires aws-cli to be installed"
fi

echo "=========================================="
echo "Backup completed: $(date)"
echo "=========================================="
