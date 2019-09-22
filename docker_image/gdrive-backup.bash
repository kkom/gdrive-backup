#! /bin/bash
set -euo pipefail

# Retrieve, decrypt and copy the settings and service account files
gsutil cp $RCLONE_CONF_GS_URL /var/rclone/rclone.conf
gsutil cp $SERVICE_ACCOUNT_KEY_GS_URL /var/rclone/service_account_key.json

# Debug the transferred files
ls -alh /var/rclone/
