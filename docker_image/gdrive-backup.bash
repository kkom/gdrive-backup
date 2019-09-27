#! /bin/bash
set -euo pipefail

# Retrieve the settings and service account files
gsutil cp $RCLONE_CONF_GS_URL /var/rclone/rclone.conf
gsutil cp $GDRIVE_SERVICE_ACCOUNT_KEY_GS_URL /var/rclone/gdrive_service_account_key.json

# Prepare the backup command (note that we *don't* want to evaluate the date command yet)
GDRIVE_BACKUP_CMD="rclone copy \
    --config /var/rclone/rclone.conf \
    --drive-impersonate $GSUITE_ACCOUNT_EMAIL \
    --checkers=40 \
    --transfers=40 \
    --tpslimit=10 \
    --fast-list \
    --gcs-bucket-policy-only \
    gdrive: \
    gcs:$STORAGE_BUCKET_NAME/backup_\$(date --utc +%Y%m%d_%H%M)"

# Perform the backup on HTTP trigger
shell2http -port 80 / "$GDRIVE_BACKUP_CMD"
