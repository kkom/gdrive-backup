variable "backend_bucket" {
  description = "Google Cloud Storage bucket of the backend. This is used for documentation only, the data is accessed from terraform.tfvars.json using jq in the Makefile."
}

variable "backend_prefix" {
  description = "Google Cloud Storage prefix of the backend. This is used for documentation only, the data is accessed from terraform.tfvars.json using jq in the Makefile."
}

variable "gsuite_account_email" {
  description = "E-mail address of the G Suite account whose Google Drive folder is backed up."
}

variable "billing_account_id" {
  description = "Google Cloud Platform billing account ID."
}

variable "cloud_function_region" {
  description = "Region for the Google Cloud Function invoking the backup"
}

variable "cloud_scheduler_region" {
  description = "Region for the Google Cloud Scheduler service"
}

variable "cloud_storage_location" {
  description = "Location for the Google Cloud Storage bucket"
}

variable "container_registry_region" {
  description = "Google Container Registry region, which specifies the region of the registry's storage"
}

variable "org_id" {
  description = "Google Cloud Platform organisation ID."
}
