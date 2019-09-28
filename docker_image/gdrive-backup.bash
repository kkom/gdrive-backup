#! /bin/bash
set -euo pipefail

# Retrieve the settings and service account files
gsutil cp $RCLONE_CONF_GS_URL /var/rclone/rclone.conf
gsutil cp $GDRIVE_SERVICE_ACCOUNT_KEY_GS_URL /var/rclone/gdrive_service_account_key.json

# Prepare the backup command (note that we *don't* want to evaluate the date command yet)
GDRIVE_BACKUP_CMD="rclone copy \
    --stats=60s \
    --stats-one-line \
    --stats-log-level=NOTICE \
    --checkers=40 \
    --transfers=40 \
    --tpslimit=5 \
    --fast-list \
    --config /var/rclone/rclone.conf \
    --drive-impersonate $GSUITE_ACCOUNT_EMAIL \
    --gcs-bucket-policy-only \
    gdrive: \
    gcs:$STORAGE_BUCKET_NAME/backup_\$(date --utc +%Y%m%d_%H%M)"

# Perform the backup on HTTP trigger
shell2http -port $PORT / "$GDRIVE_BACKUP_CMD"
