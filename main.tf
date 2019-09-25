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

resource "google_project_services" "project" {
  project = google_project.gdrive_backup.project_id
  services = [
    "containerregistry.googleapis.com",
    "drive.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "storage-api.googleapis.com",
  ]
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
  project  = google_project.gdrive_backup.project_id
  name     = "gdrive-backup-${random_id.storage_bucket_suffix.hex}"
  location = "${var.cloud_storage_location}"
}

output "storage_bucket_name" {
  value = google_storage_bucket.gdrive_backup.name
}

resource "google_storage_bucket_object" "rclone_conf" {
  bucket = google_storage_bucket.gdrive_backup.name
  name   = "settings/rclone.conf"
  content = templatefile("docker_image/rclone.conf.tpl", {
    cloud_storage_location = var.cloud_storage_location
  })
}

output "rclone_conf_gs_url" {
  value = "gs://${google_storage_bucket_object.rclone_conf.bucket}/${google_storage_bucket_object.rclone_conf.output_name}"
}

resource "google_storage_bucket_object" "gdrive_service_account_key" {
  bucket  = google_storage_bucket.gdrive_backup.name
  name    = "settings/gdrive_service_account_key.json"
  content = base64decode(google_service_account_key.gdrive.private_key)
}

output "gdrive_service_account_key_gs_url" {
  value = "gs://${google_storage_bucket_object.gdrive_service_account_key.bucket}/${google_storage_bucket_object.gdrive_service_account_key.output_name}"
}

data "google_container_registry_image" "gdrive_backup" {
  project = google_project.gdrive_backup.project_id
  region  = var.container_registry_region
  name    = "gdrive-backup"
}

output "gdrive_backup_gcr_location" {
  value = "${data.google_container_registry_image.gdrive_backup.image_url}"
}

resource "null_resource" "gdrive_backup_gcr_push" {
  provisioner "local-exec" {
    command = "docker build -t ${data.google_container_registry_image.gdrive_backup.image_url} -f docker_image/Dockerfile docker_image && docker push ${data.google_container_registry_image.gdrive_backup.image_url}"
  }
}
