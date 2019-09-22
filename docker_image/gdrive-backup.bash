#! /bin/bash
set -euo pipefail

# Retrieve, decrypt and copy the settings and service account files
gsutil cp $RCLONE_CONF_GS_URL /var/rclone/rclone.conf
cat /var/rclone/rclone.conf
