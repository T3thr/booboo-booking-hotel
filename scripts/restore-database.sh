#!/bin/sh
# Database Restore Script for Production
# This script restores a PostgreSQL backup

set -e

# Configuration
BACKUP_DIR="/backups"
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${POSTGRES_DB:-hotel_booking}
DB_USER=${POSTGRES_USER:-postgres}

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lh ${BACKUP_DIR}/hotel_booking_*.sql.gz 2>/dev/null || echo "No backups found"
    echo ""
    echo "To restore the latest backup:"
    echo "  $0 latest"
    exit 1
fi

# Determine backup file
if [ "$1" = "latest" ]; then
    BACKUP_FILE="${BACKUP_DIR}/latest.sql.gz"
else
    BACKUP_FILE="$1"
fi

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "❌ Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "=========================================="
echo "Starting database restore: $(date)"
echo "=========================================="
echo "Backup file: ${BACKUP_FILE}"
echo "Database: ${DB_NAME}"
echo ""

# Warning
read -p "⚠️  This will OVERWRITE the current database. Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Drop existing connections
echo "Terminating existing connections..."
PGPASSWORD=${POSTGRES_PASSWORD} psql \
    -h ${DB_HOST} \
    -p ${DB_PORT} \
    -U ${DB_USER} \
    -d postgres \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();"

# Drop and recreate database
echo "Dropping and recreating database..."
PGPASSWORD=${POSTGRES_PASSWORD} psql \
    -h ${DB_HOST} \
    -p ${DB_PORT} \
    -U ${DB_USER} \
    -d postgres \
    -c "DROP DATABASE IF EXISTS ${DB_NAME};"

PGPASSWORD=${POSTGRES_PASSWORD} psql \
    -h ${DB_HOST} \
    -p ${DB_PORT} \
    -U ${DB_USER} \
    -d postgres \
    -c "CREATE DATABASE ${DB_NAME};"

# Restore backup
echo "Restoring backup..."
gunzip -c ${BACKUP_FILE} | PGPASSWORD=${POSTGRES_PASSWORD} psql \
    -h ${DB_HOST} \
    -p ${DB_PORT} \
    -U ${DB_USER} \
    -d ${DB_NAME} \
    --quiet

# Check if restore was successful
if [ $? -eq 0 ]; then
    echo "✅ Database restored successfully!"
    
    # Verify restore
    echo "Verifying restore..."
    TABLE_COUNT=$(PGPASSWORD=${POSTGRES_PASSWORD} psql \
        -h ${DB_HOST} \
        -p ${DB_PORT} \
        -U ${DB_USER} \
        -d ${DB_NAME} \
        -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    
    echo "Tables restored: ${TABLE_COUNT}"
else
    echo "❌ Restore failed!"
    exit 1
fi

echo "=========================================="
echo "Restore completed: $(date)"
echo "=========================================="
