backend_bucket := $(shell jq -r '.backend_bucket' terraform.tfvars.json)
backend_prefix := $(shell jq -r '.backend_prefix' terraform.tfvars.json)
gsuite_account_name := $(shell jq -r '.gsuite_account_name' terraform.tfvars.json)

init:
	terraform init \
	    -backend-config="bucket=$(backend_bucket)" \
	    -backend-config="prefix=$(backend_prefix)"

apply:
	terraform apply

docker-build:
	docker-compose -f docker_image/docker-compose.dev.yml build

docker-test:
	docker-compose -f docker_image/docker-compose.dev.yml run \
		-e GSUITE_ACCOUNT_NAME=$(gsuite_account_name) \
		-e RCLONE_CONF_GS_URL=$(shell terraform output rclone_conf_gs_url) \
		gdrive-backup \
		bash
