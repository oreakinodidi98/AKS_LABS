# set-env.ps1
# Required environment variables: ARM_CLIENT_SECRET and TF_VAR_admin_password.
$env:ARM_SUBSCRIPTION_ID = "cb5b077c-3ef5-4b2e-83e5-490cc5ca0e19"
$env:ARM_TENANT_ID = "16b3c013-d300-468d-ac64-7eda0820b6d3"
$env:ARM_CLIENT_ID = "804735be-6477-484d-9d8e-e9bf654b2b38"
if ([string]::IsNullOrWhiteSpace($env:ARM_CLIENT_SECRET)) {
    throw "Set ARM_CLIENT_SECRET in your environment before running this script; do not save credentials in source control."
}


# VM Admin Password (must have: lowercase, uppercase, digit, special char)
if ([string]::IsNullOrWhiteSpace($env:TF_VAR_admin_password)) {
    throw "Set TF_VAR_admin_password in your environment before running this script; use a strong VM admin password."
}


# Remove ARM_ACCESS_KEY if set (conflicts with Azure AD auth)
Remove-Item Env:ARM_ACCESS_KEY -ErrorAction SilentlyContinue
Write-Output "Environment variables for Terraform have been set."

az role assignment create `
  --assignee "804735be-6477-484d-9d8e-e9bf654b2b38" `
  --role "Storage Blob Data Contributor" `
  --scope "/subscriptions/cb5b077c-3ef5-4b2e-83e5-490cc5ca0e19/resourceGroups/tfstaterg01/providers/Microsoft.Storage/storageAccounts/tfstate01919804057"
Write-Output "Role assignment for Storage Blob Data Contributor has been created."

az storage account update -n tfstate01919804057 -g tfstaterg01 --public-network-access Enabled
Write-Output "Storage account network access has been updated to Enabled."