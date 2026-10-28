# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND
# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "uksouth"
Write-Output "Location set to: $env:LOCATION"

# Create Service Principal for Terraform
$spOutput = az ad sp create-for-rbac --name "terraform-sp-$RAND" --role="Contributor" --scopes="/subscriptions/cb5b077c-3ef5-4b2e-83e5-490cc5ca0e19" | ConvertFrom-Json
write-host "Service Principal created. Please copy the output above and save it securely."

# Set Terraform environment variables from the service principal output
$env:ARM_CLIENT_ID = $spOutput.appId
$env:ARM_CLIENT_SECRET = $spOutput.password
$env:ARM_TENANT_ID = $spOutput.tenant
$env:ARM_SUBSCRIPTION_ID = "cb5b077c-3ef5-4b2e-83e5-490cc5ca0e19"

# Set Ray variables:
$env:RAY_NAMESPACE="ray-system"
$env:RAY_CLUSTER_NAME="raycluster-ml"
$env:RAY_SERVICE_NAME="ray-service"
$env:RAY_JOB_NAME="ray-job"

# Create a resource group name using the random number
$env:RG_NAME = "myresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Create Resource Group for Terraform state
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Create Storage Account
$env:TFSA_name = "tfstorage$RAND"
az storage account create --name $env:TFSA_name --resource-group $env:RG_NAME --sku Standard_LRS --encryption-services blob

# Create Storage Container
$env:TFSC_name = "tfcontainer$RAND"
az storage container create --name $env:TFSC_name --account-name $env:TFSA_name

# Remove ARM_ACCESS_KEY if set (conflicts with Azure AD auth)
Remove-Item Env:ARM_ACCESS_KEY -ErrorAction SilentlyContinue
Write-Output "Environment variables for Terraform have been set."

az role assignment create `
  --assignee $env:ARM_CLIENT_ID `
  --role "Storage Blob Data Contributor" `
  --scope "/subscriptions/$env:ARM_SUBSCRIPTION_ID/resourceGroups/$env:RG_NAME/providers/Microsoft.Storage/storageAccounts/$env:TFSA_name"
Write-Output "Role assignment for Storage Blob Data Contributor has been created."

az storage account update -n $env:TFSA_name -g $env:RG_NAME --public-network-access Enabled
Write-Output "Storage account network access has been updated to Enabled."