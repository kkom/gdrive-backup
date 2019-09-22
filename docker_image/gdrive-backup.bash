#! /bin/bash
set -euo pipefail

# Retrieve the settings and service account files
gsutil cp $RCLONE_CONF_GS_URL /var/rclone/rclone.conf
gsutil cp $GDRIVE_SERVICE_ACCOUNT_KEY_GS_URL /var/rclone/gdrive_service_account_key.json

# Perform the backup
rclone copy \
    --config /var/rclone/rclone.conf \
    --drive-impersonate $GSUITE_ACCOUNT_EMAIL \
    gdrive: \
    gcs:$STORAGE_BUCKET_NAME/backup_$(date +%Y%m%d)_$(date +%H%M)
