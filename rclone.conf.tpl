[gcs]
type = google cloud storage
location = ${cloud_storage_location}
storage_class = NEARLINE
bucket-policy-only = true

[gdrive]
type = drive
scope = drive.readonly
service_account_file = /var/rclone/gdrive_service_account_key.json
