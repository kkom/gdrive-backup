#! /bin/bash
set -euo pipefail

# Install rclone
sudo apt-get update
sudo apt-get upgrade --assume-yes
sudo apt-get install --assume-yes --no-install-recommends \
    ca-certificates \
    curl \
    man-db \
    unzip
curl https://rclone.org/install.sh | sudo bash

# # Retrieve, decrypt and copy the settings and service account files
# gsutil cp gs://settings.cloud-storage-backup.komorowski.me/rclone.conf .
# gsutil cp gs://settings.cloud-storage-backup.komorowski.me/cloud-storage-backup-service-account-file.json.encrypted .

# gcloud kms decrypt --location global --keyring service-account-files --key cloud-storage-backup \
#   --ciphertext-file cloud-storage-backup-service-account-file.json.encrypted \
#   --plaintext-file cloud-storage-backup-service-account-file.json

# sudo mkdir -p /var/rclone
# sudo mv cloud-storage-backup-service-account-file.json /var/rclone/
# sudo mv rclone.conf /var/rclone/

# # Perform the backup
# rclone copy --config /var/rclone/rclone.conf --drive-impersonate konrad@komorowski.me gdrive: gcs:drive.komorowski.me/backup_$(date +%Y%m%d)_$(date +%H%M)
