[gcs]
type = google cloud storage
location = ${cloud_storage_location}
storage_class = NEARLINE
service_account_file = /var/rclone/gdrive-backup-service-account-file.json

[gdrive]
type = drive
scope = drive.readonly
service_account_file = /var/rclone/gdrive-backup-service-account-file.json
