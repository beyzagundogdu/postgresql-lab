#!/bin/bash

set -e

VOLUME_NAME="pitr-lab_postgres-data"
BACKUP_DIR="/backups/base_1"

echo "Stopping PostgreSQL container..."
docker stop pg14-pitr

echo "Restoring PGDATA from base backup..."

docker run --rm -it \
  -v ${VOLUME_NAME}:/var/lib/postgresql/data \
  -v "$(pwd)/backups:/backups" \
  -v "$(pwd)/wal-archive:/wal-archive" \
  postgres:14 bash -c "
    rm -rf /var/lib/postgresql/data/* &&
    cp -a ${BACKUP_DIR}/* /var/lib/postgresql/data/ &&
    touch /var/lib/postgresql/data/recovery.signal &&
    chown -R postgres:postgres /var/lib/postgresql/data
  "

echo "Base backup restored."
echo "recovery.signal created."
echo ""
echo "Next step:"
echo "Update docker-compose.yml with:"
echo "  restore_command='cp /wal-archive/%f %p'"
echo "  recovery_target_time='YYYY-MM-DD HH:MM:SS+00'"
echo "  recovery_target_action=promote"
echo ""
echo "Then run:"
echo "  docker compose up -d"


# Senin Docker Compose proje adına göre volume ismi farklı olabilir. Kontrol etmek için: docker volume ls

# Calıstırma: ./scripts/restore.sh

