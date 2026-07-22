#!/bin/bash
# MongoDB backup script for Ariadne database
# Usage: ./backup-mongodb.sh [output_dir]
# Default output: /home/rjodouin/backups/ariadne

set -euo pipefail

DB_NAME="ariadne"
MONGO_URI="mongodb://localhost:27017"
OUTPUT_DIR="${1:-/home/rjodouin/backups/ariadne}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${OUTPUT_DIR}/${TIMESTAMP}"

echo "=== MongoDB Backup for ${DB_NAME} ==="
echo "Timestamp: ${TIMESTAMP}"
echo "Output: ${BACKUP_DIR}"

# Create output directory
mkdir -p "${BACKUP_DIR}"

# Run mongodump
echo "Running mongodump..."
mongodump \
    --uri="${MONGO_URI}" \
    --db="${DB_NAME}" \
    --out="${BACKUP_DIR}" \
    --gzip

# Verify backup
if [ $? -eq 0 ]; then
    echo "Backup successful: ${BACKUP_DIR}"
    
    # Show backup size
    BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
    echo "Backup size: ${BACKUP_SIZE}"
    
    # List collections backed up
    echo "Collections backed up:"
    ls -1 "${BACKUP_DIR}/${DB_NAME}/" 2>/dev/null || echo "  (no collections found)"
    
    # Write metadata file
    cat > "${BACKUP_DIR}/backup-info.txt" << EOF
Backup Date: $(date)
Database: ${DB_NAME}
MongoDB URI: ${MONGO_URI}
Size: ${BACKUP_SIZE}
Collections:
$(ls -1 "${BACKUP_DIR}/${DB_NAME}/" 2>/dev/null | sed 's/^/  - /')
EOF
    echo "Metadata written to ${BACKUP_DIR}/backup-info.txt"
else
    echo "ERROR: Backup failed!"
    exit 1
fi

# Retention: keep last 7 backups (7 days if run daily)
MAX_BACKUPS=7
CURRENT_BACKUPS=$(ls -1d "${OUTPUT_DIR}"/*/ 2>/dev/null | wc -l)
if [ "${CURRENT_BACKUPS}" -gt "${MAX_BACKUPS}" ]; then
    echo "Pruning old backups (keeping last ${MAX_BACKUPS})..."
    ls -1dt "${OUTPUT_DIR}"/*/ | tail -n +$((MAX_BACKUPS + 1)) | while read -r old_dir; do
        echo "  Removing: ${old_dir}"
        rm -rf "${old_dir}"
    done
fi

echo "=== Backup Complete ==="
