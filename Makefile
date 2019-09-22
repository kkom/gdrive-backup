backend_bucket := $(shell jq -r '.backend_bucket' terraform.tfvars.json)
backend_prefix := $(shell jq -r '.backend_prefix' terraform.tfvars.json)
gsuite_account_email := $(shell jq -r '.gsuite_account_email' terraform.tfvars.json)

terraform-init:
	terraform init \
	    -backend-config="bucket=$(backend_bucket)" \
	    -backend-config="prefix=$(backend_prefix)"

terraform-apply:
	terraform apply

docker-test:
	docker-compose -f docker_image/docker-compose.dev.yml build
	docker-compose -f docker_image/docker-compose.dev.yml run \
		-e GSUITE_ACCOUNT_EMAIL=$(gsuite_account_email) \
		-e RCLONE_CONF_GS_URL=$(shell terraform output rclone_conf_gs_url) \
		-e GDRIVE_SERVICE_ACCOUNT_KEY_GS_URL=$(shell terraform output gdrive_service_account_key_gs_url) \
		-e STORAGE_BUCKET_NAME=$(shell terraform output storage_bucket_name) \
		gdrive-backup \
		bash
