terraform {
  required_version = ">= 0.12"

  backend "gcs" {
  }
}

provider "random" {}

resource "random_id" "project_id_suffix" {
  byte_length = 8
}

resource "google_project" "gdrive_backup" {
  name            = "Google Drive backup"
  project_id      = "gdrive-backup-${random_id.project_id_suffix.hex}"
  org_id          = var.org_id
  billing_account = var.billing_account_id
}

output "project_id" {
  value = google_project.gdrive_backup.project_id
}

resource "google_project_service" "containerregistry" {
  project = google_project.gdrive_backup.project_id
  service = "containerregistry.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  project = google_project.gdrive_backup.project_id
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloudscheduler" {
  project = google_project.gdrive_backup.project_id
  service = "cloudscheduler.googleapis.com"
}

resource "google_project_service" "drive" {
  project = google_project.gdrive_backup.project_id
  service = "drive.googleapis.com"
}

resource "google_project_service" "storage-api" {
  project = google_project.gdrive_backup.project_id
  service = "storage-api.googleapis.com"
}

resource "google_service_account" "gdrive" {
  project      = google_project.gdrive_backup.project_id
  account_id   = "gdrive"
  display_name = "Service account with domain-wide access to Google Drive"
}

resource "google_service_account_key" "gdrive" {
  service_account_id = google_service_account.gdrive.name
}

output "gdrive_service_account_unique_id" {
  value = google_service_account.gdrive.unique_id
}

resource "random_id" "storage_bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "gdrive_backup" {
  project            = google_project.gdrive_backup.project_id
  name               = "gdrive-backup-${random_id.storage_bucket_suffix.hex}"
  location           = var.cloud_storage_location
  bucket_policy_only = true
}

output "storage_bucket_name" {
  value = google_storage_bucket.gdrive_backup.name
}

resource "google_storage_bucket_object" "rclone_conf" {
  bucket = google_storage_bucket.gdrive_backup.name
  name   = "settings/rclone.conf"
  content = templatefile("rclone.conf.tpl", {
    cloud_storage_location = var.cloud_storage_location
  })
}

locals {
  rclone_conf_gs_url = "gs://${google_storage_bucket_object.rclone_conf.bucket}/${google_storage_bucket_object.rclone_conf.output_name}"
}

output "rclone_conf_gs_url" {
  value = local.rclone_conf_gs_url
}

resource "google_storage_bucket_object" "gdrive_service_account_key" {
  bucket  = google_storage_bucket.gdrive_backup.name
  name    = "settings/gdrive_service_account_key.json"
  content = base64decode(google_service_account_key.gdrive.private_key)
}

locals {
  gdrive_service_account_key_gs_url = "gs://${google_storage_bucket_object.gdrive_service_account_key.bucket}/${google_storage_bucket_object.gdrive_service_account_key.output_name}"
}

output "gdrive_service_account_key_gs_url" {
  value = local.gdrive_service_account_key_gs_url
}

# this is a rather hacky way to tag the Docker image, it may be possible
# to do it much more elegantly
data "archive_file" "backup_performer_dir" {
  type        = "zip"
  source_dir  = "backup_performer/"
  output_path = ".tmp/backup_performer_dir.zip"
}

data "google_container_registry_image" "backup_performer" {
  project = google_project.gdrive_backup.project_id
  region  = var.container_registry_region
  name    = "backup-performer"
  tag     = substr(data.archive_file.backup_performer_dir.output_sha, 0, 7)
}

output "backup_performer_gcr_location" {
  value = data.google_container_registry_image.backup_performer.image_url
}

resource "null_resource" "backup_performer_gcr_push" {
  triggers = {
    backup_performer_url = data.google_container_registry_image.backup_performer.image_url
  }

  provisioner "local-exec" {
    command = "docker build -t ${data.google_container_registry_image.backup_performer.image_url} -f backup_performer/Dockerfile backup_performer && docker push ${data.google_container_registry_image.backup_performer.image_url}"
  }
}

resource "google_service_account" "cloud_function_invoker" {
  project      = google_project.gdrive_backup.project_id
  account_id   = "cloud-function-invoker"
  display_name = "Service account allowed to invoke the cloud function endpoint"
}

data "archive_file" "backup_invoker_dir" {
  type        = "zip"
  source_dir  = "backup_invoker/"
  output_path = ".tmp/backup_invoker_dir.zip"
}

resource "google_storage_bucket_object" "backup_invoker_dir" {
  name   = "cloud_functions/backup_invoker-${substr(data.archive_file.backup_invoker_dir.output_sha, 0, 7)}.zip"
  bucket = google_storage_bucket.gdrive_backup.name
  source = data.archive_file.backup_invoker_dir.output_path
}

resource "google_cloudfunctions_function" "backup_invoker" {
  project = google_project.gdrive_backup.project_id
  region  = var.cloud_function_region

  name        = "backup-invoker"
  description = "Function used to invoke a Google Drive backup procedure"
  runtime     = "python37"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket_object.backup_invoker_dir.bucket
  source_archive_object = google_storage_bucket_object.backup_invoker_dir.output_name
  trigger_http          = true
  entry_point           = "run"
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.backup_invoker.project
  region         = google_cloudfunctions_function.backup_invoker.region
  cloud_function = google_cloudfunctions_function.backup_invoker.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.cloud_function_invoker.email}"
}

resource "google_app_engine_application" "default" {
  project = google_project.gdrive_backup.project_id
  # App Engine uses custom names for two GCP regions...
  location_id = replace(
    replace(
      var.cloud_scheduler_region,
      "us-central1",
      "us-central",
    ),
    "europe-west1",
    "europe-west",
  )
}

resource "google_cloud_scheduler_job" "default" {
  depends_on = [
    google_app_engine_application.default,
  ]

  project = google_project.gdrive_backup.project_id
  region  = var.cloud_scheduler_region

  name        = "gdrive-backup"
  description = "Triggers a Cloud Run-based Google Drive backup"
  schedule    = "30 0 * * 0"
  time_zone   = "Europe/London"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.backup_invoker.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.cloud_function_invoker.email
    }
  }
}
