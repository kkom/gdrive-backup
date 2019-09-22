1. `make terraform-init`
2. `make terraform-apply`
3. Run `open "https://console.cloud.google.com/iam-admin/serviceaccounts/details/$(terraform output service_account_unique_id)?project=$(terraform output project_id)"` to go the service account settings and then enable G Suite Domain-wide Delegation.
4. Go to `https://admin.google.com/ManageOauthClients` and assign permission `https://www.googleapis.com/auth/drive.readonly` to the service account unique ID (`service_account_unique_id` output variable, also shown on the previous screen).
