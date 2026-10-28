# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND
# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Create Service Principal for Terraform
$spOutput = az ad sp create-for-rbac --name "terraform-sp-1" --role="Contributor" --scopes="/subscriptions/f76acfa2-f79b-465f-a4ef-4cd279b35d4d" | ConvertFrom-Json
write-host "Service Principal created. Please copy the output above and save it securely."

# Set Terraform environment variables from the service principal output
$env:ARM_CLIENT_ID = $spOutput.appId
write-host "ARM_CLIENT_ID set to: $env:ARM_CLIENT_ID"
$env:ARM_CLIENT_SECRET = $spOutput.password
write-host "ARM_CLIENT_SECRET set to: $env:ARM_CLIENT_SECRET"
$env:ARM_TENANT_ID = $spOutput.tenant
write-host "ARM_TENANT_ID set to: $env:ARM_TENANT_ID"
$env:ARM_SUBSCRIPTION_ID = "f76acfa2-f79b-465f-a4ef-4cd279b35d4d"
write-host "ARM_SUBSCRIPTION_ID set to: $env:ARM_SUBSCRIPTION_ID"

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
write-Output "Storage account $env:TFSA_name created. Now creating container $env:TFSC_name."
az storage container create --name $env:TFSC_name --account-name $env:TFSA_name