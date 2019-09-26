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

resource "google_project_service" "drive" {
  project = google_project.gdrive_backup.project_id
  service = "drive.googleapis.com"
}

resource "google_project_service" "run" {
  project = google_project.gdrive_backup.project_id
  service = "run.googleapis.com"
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
data "archive_file" "docker_image_dir" {
  type        = "zip"
  source_dir  = "docker_image/"
  output_path = ".tmp/docker_image_dir.zip"
}

data "google_container_registry_image" "gdrive_backup" {
  project = google_project.gdrive_backup.project_id
  region  = var.container_registry_region
  name    = "gdrive-backup"
  tag     = substr(data.archive_file.docker_image_dir.output_sha, 0, 7)
}

output "gdrive_backup_gcr_location" {
  value = "${data.google_container_registry_image.gdrive_backup.image_url}"
}

resource "null_resource" "gdrive_backup_gcr_push" {
  triggers = {
    docker_image_url = data.google_container_registry_image.gdrive_backup.image_url
  }

  provisioner "local-exec" {
    command = "docker build -t ${data.google_container_registry_image.gdrive_backup.image_url} -f docker_image/Dockerfile docker_image && docker push ${data.google_container_registry_image.gdrive_backup.image_url}"
  }
}

resource "google_cloud_run_service" "default" {
  depends_on = [
    google_project_service.run,
    null_resource.gdrive_backup_gcr_push,
  ]
  project  = google_project.gdrive_backup.project_id
  provider = "google-beta"

  name     = "gdrive-backup"
  location = var.cloud_run_location

  metadata {
    namespace = google_project.gdrive_backup.project_id
  }

  spec {
    container_concurrency = 1

    containers {
      image = data.google_container_registry_image.gdrive_backup.image_url

      resources {
        limits = {
          "memory" = "1Gi"
        }
      }

      env {
        name  = "GSUITE_ACCOUNT_EMAIL"
        value = var.gsuite_account_email
      }

      env {
        name  = "RCLONE_CONF_GS_URL"
        value = local.rclone_conf_gs_url
      }

      env {
        name  = "GDRIVE_SERVICE_ACCOUNT_KEY_GS_URL"
        value = local.gdrive_service_account_key_gs_url
      }

      env {
        name  = "STORAGE_BUCKET_NAME"
        value = google_storage_bucket.gdrive_backup.name
      }
    }
  }
}
