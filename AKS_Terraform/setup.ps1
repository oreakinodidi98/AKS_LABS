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
$spOutput = az ad sp create-for-rbac --name "terraform-sp-3" --role="Contributor" --scopes="/subscriptions/cb5b077c-3ef5-4b2e-83e5-490cc5ca0e19" | ConvertFrom-Json
write-host "Service Principal created. Please copy the output above and save it securely."

# Set Terraform environment variables from the service principal output
$env:ARM_CLIENT_ID = $spOutput.appId
$env:ARM_CLIENT_SECRET = $spOutput.password
$env:ARM_TENANT_ID = $spOutput.tenant
$env:ARM_SUBSCRIPTION_ID = "cb5b077c-3ef5-4b2e-83e5-490cc5ca0e19"

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