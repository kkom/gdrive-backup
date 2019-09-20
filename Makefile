backend_bucket := $(shell jq -r '.backend_bucket' terraform.tfvars.json)
backend_prefix := $(shell jq -r '.backend_prefix' terraform.tfvars.json)

init:
	terraform init \
	    -backend-config="bucket=$(backend_bucket)" \
	    -backend-config="prefix=$(backend_prefix)"

apply:
	terraform apply
