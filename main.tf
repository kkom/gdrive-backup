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

resource "google_project_services" "project" {
  project  = google_project.gdrive_backup.project_id
  services = ["compute.googleapis.com", "oslogin.googleapis.com"]
}

resource "random_id" "storage_bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "gdrive_backup" {
  project  = google_project.gdrive_backup.project_id
  name     = "gdrive-backup-${random_id.storage_bucket_suffix.hex}"
  location = "${var.cloud_storage_location}"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_compute_instance" "gdrive_backup" {
  project = google_project.gdrive_backup.project_id

  name         = "gdrive-backup"
  machine_type = "n1-standard-1"
  zone         = var.compute_instance_zone

  boot_disk {
    initialize_params {
      image = "gce-uefi-images/ubuntu-1804-lts"
    }
  }

  shielded_instance_config {}

  metadata_startup_script = "${file("compute_instance_startup_script.bash")}"

  network_interface {
    network = "default"
    access_config {
    }
  }
}