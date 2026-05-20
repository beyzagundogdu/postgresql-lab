#!/bin/bash

set -e

BACKUP_DIR="/backups/base_1"

echo "Creating base backup..."

docker exec -it pg14-pitr bash -c "
  rm -rf ${BACKUP_DIR} &&
  PGUSER=beyza PGPASSWORD=password \
  pg_basebackup -h localhost -D ${BACKUP_DIR} -F plain -X fetch -P
"

echo "Base backup completed successfully."
echo "Backup location inside container: ${BACKUP_DIR}"
echo "Backup location on host: ./backups/base_1"

# Çalıştırma: ./scripts/create-base-backup.sh   
