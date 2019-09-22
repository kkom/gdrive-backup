1. Run `cp -n terraform.tfvars.json.example terraform.tfvars.json` to initialize a settings file and then populate it with your values.
2. Run `make terraform-init` and `make terraform-apply` to initialize the Google Cloud project.
3. Run `open "https://console.cloud.google.com/iam-admin/serviceaccounts/details/$(terraform output gdrive_service_account_unique_id)?project=$(terraform output project_id)"` to go the service account settings and then enable G Suite Domain-wide Delegation.
4. Go to `https://admin.google.com/ManageOauthClients` and assign permission `https://www.googleapis.com/auth/drive.readonly` to the service account unique ID (`service_account_unique_id` output variable, also shown on the previous screen).
