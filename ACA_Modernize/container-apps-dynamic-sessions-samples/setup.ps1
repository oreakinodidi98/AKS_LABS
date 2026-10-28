# User Information
$env:USER_PRINCIPAL_NAME = (az ad signed-in-user show --query userPrincipalName -o tsv).Trim()
$env:USER_OBJECT_ID = (az ad signed-in-user show --query id -o tsv).Trim()

# Azure Resources
$random = Get-Random -Minimum 10000 -Maximum 99999
# Print the random resource identifier
Write-Output "Random resource identifier will be: $random"

$env:RG = "aca-langchain-rg-$env:USERNAME-$random"
Write-Output "Resource group name set to: $env:RG"

# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Set Pool Name
$env:POOL = "aca-langchain-py-$env:USERNAME-$random"
Write-Output "Pool name set to: $env:POOL"

$env:OPENAI_NAME = "openai-aca-$env:USERNAME-$random"
Write-Output "OpenAI name set to: $env:OPENAI_NAME"

$env:OPENAI_DOMAIN = "openai-aca-$env:USERNAME-$random"
Write-Output "OpenAI domain set to: $env:OPENAI_DOMAIN"

$env:DEPLOYMENT_NAME = "gpt-5.4"
Write-Output "Deployment name set to: $env:DEPLOYMENT_NAME"

# Create Resource Group
az group create --name $env:RG --location $env:LOCATION
Write-Output "Resource group '$env:RG' created in location '$env:LOCATION'."

# Create a Dynamic Session Pool with Python runtime for secure code execution
az containerapp sessionpool create `
    --name $env:POOL `
    --resource-group $env:RG `
    --location $env:LOCATION `
    --container-type PythonLTS`
    --max-sessions 50`
    --lifecycle-type Timed `
    --cooldown-period 300 `
    --network-status EgressEnabled
Write-Output "Dynamic Session Pool '$env:POOL' created in resource group '$env:RG' with Python runtime."

# Get the pool management endpoint and resource ID needed for configuration and role assignments.
$poolInfo = az containerapp sessionpool show --name $env:POOL --resource-group $env:RG --query "{endpoint: managementEndpoint, resourceId: id}" -o json | ConvertFrom-Json
$env:POOL_ENDPOINT = $poolInfo.endpoint
$env:POOL_RESOURCE_ID = $poolInfo.resourceId
Write-Output "Dynamic Session Pool management endpoint: $env:POOL_ENDPOINT"
Write-Output "Dynamic Session Pool resource ID: $env:POOL_RESOURCE_ID"

# Get  Azure AD user information for role assignments
$env:USER_PRINCIPAL_NAME = (az ad signed-in-user show --query userPrincipalName -o tsv).Trim()
Write-Output "Detected signed-in user principal name: $env:USER_PRINCIPAL_NAME"
$env:USER_OBJECT_ID = (az ad signed-in-user show --query id -o tsv).Trim()
Write-Output "Detected signed-in user object ID: $env:USER_OBJECT_ID"

# Grant permissions to execute code in the session pool.
az role assignment create `
    --assignee-object-id $env:USER_OBJECT_ID `
    --role "Azure Container Apps Session Executor" `
    --scope $env:POOL_RESOURCE_ID
Write-Output "Granted 'Azure Container Apps Session Executor' role to user '$env:USER_PRINCIPAL_NAME' for session pool '$env:POOL'."
az role assignment create `
    --assignee-object-id $env:USER_OBJECT_ID `
    --role "Contributor" `
    --scope $env:POOL_RESOURCE_ID
Write-Output "Granted 'Contributor' role to user '$env:USER_PRINCIPAL_NAME' for session pool '$env:POOL'."

# Create Azure OpenAI Resource
az cognitiveservices account create `
    --name $env:OPENAI_NAME `
    --resource-group $env:RG `
    --kind OpenAI `
    --sku S0 `
    --location $env:LOCATION `
    --custom-domain $env:OPENAI_DOMAIN 
Write-Output "Azure OpenAI resource '$env:OPENAI_NAME' created in resource group '$env:RG' with custom domain '$env:OPENAI_DOMAIN'."
# Deploy GPT-3.5 Turbo Model
az cognitiveservices account deployment create `
    --name $env:OPENAI_NAME `
    --resource-group $env:RG `
    --deployment-name $env:DEPLOYMENT_NAME `
    --model-name gpt-5.4 `
    --model-version "1106" `
    --model-format OpenAI `
    --sku-capacity "30" `
    --sku-name "Standard"
Write-Output "Deployed GPT-5.4 model '$env:DEPLOYMENT_NAME' to Azure OpenAI resource '$env:OPENAI_NAME'."
# Retrieve Azure OpenAI Configuration
$env:OPENAI_ENDPOINT = az cognitiveservices account show --name $env:OPENAI_NAME --resource-group $env:RG --query "properties.endpoint" -o tsv
Write-Output "Azure OpenAI endpoint: $env:OPENAI_ENDPOINT"
$env:OPENAI_ID = az cognitiveservices account show --name $env:OPENAI_NAME --resource-group $env:RG --query "id" -o tsv
Write-Output "Azure OpenAI resource ID: $env:OPENAI_ID"

# Assign Azure OpenAI Permissions
az role assignment create `
    --assignee-object-id $env:USER_OBJECT_ID `
    --role "Cognitive Services OpenAI User" `
    --scope $env:OPENAI_ID
Write-Output "Granted 'Cognitive Services OpenAI User' role to user '$env:USER_PRINCIPAL_NAME' for Azure OpenAI resource '$env:OPENAI_NAME'. This role allows your identity to make API calls to Azure OpenAI without requiring API keys (uses Azure AD authentication instead)."