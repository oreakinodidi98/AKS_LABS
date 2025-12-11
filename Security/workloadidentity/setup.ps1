# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "uksouth"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "myresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Create the resource group
az group create --name $env:RG_NAME --location $env:LOCATION

# Setup AKS Cluster
$env:AKS_NAME = "myakscluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--network-plugin azure `
--network-plugin-mode overlay `
--network-dataplane cilium `
--network-policy cilium `
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--generate-ssh-keys

# Connect to the cluster
az aks get-credentials `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME

# Setup Azure Key Vault
$env:AKV_NAME = "mykeyvault$RAND"
Write-Output "Key Vault name: $env:AKV_NAME"

# Create a Key Vault and export its resource identifier for later use
$env:AKV_ID = (az keyvault create `
--resource-group $env:RG_NAME `
--name $env:AKV_NAME `
--enable-rbac-authorization `
--query id `
--output tsv)
Write-Output "Key Vault ID: $env:AKV_ID"

# Check your AKS cluster to see if Workload Identity is already enabled
az aks show `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--query "securityProfile.workloadIdentity.enabled" `
--output tsv

#  check if the OIDC issuer is enabled on your AKS cluster.
az aks show `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--query "oidcIssuerProfile.enabled" `
--output tsv

# Get the OIDC Issuer URL

$env:AKS_OIDC_ISSUER="$(az aks show `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--query "oidcIssuerProfile.issuerUrl" `
--output tsv)"
Write-Output "OIDC Issuer URL: $env:AKS_OIDC_ISSUER"

#Create a Managed Identity

$env:USER_ASSIGNED_IDENTITY_NAME="myIdentity"
Write-Output "User Assighned Identity: $env:USER_ASSIGNED_IDENTITY_NAME"

#create a Managed Identity.

az identity create `
--resource-group $env:RG_NAME `
--name $env:USER_ASSIGNED_IDENTITY_NAME `
--location $env:LOCATION `

# capture the details of the managed identity and save the values as environment variables
$env:USER_ASSIGNED_CLIENT_ID="$(az identity show `
--resource-group $env:RG_NAME `
--name $env:USER_ASSIGNED_IDENTITY_NAME `
--query "clientId" `
--output tsv)"
Write-Output "User Assighned Client Identity: $env:USER_ASSIGNED_CLIENT_ID"

$env:USER_ASSIGNED_PRINCIPAL_ID="$(az identity show `
--name $env:USER_ASSIGNED_IDENTITY_NAME `
--resource-group $env:RG_NAME `
--query "principalId" `
--output tsv)"
Write-Output "User Assighned Principal Identity: $env:USER_ASSIGNED_PRINCIPAL_ID"

#Create a Kubernetes Service Account
$env:SERVICE_ACCOUNT_NAME="workload-identity-sa"
$env:SERVICE_ACCOUNT_NAMESPACE="default"

$serviceAccountYaml = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $env:USER_ASSIGNED_CLIENT_ID
  name: $env:SERVICE_ACCOUNT_NAME
  namespace: $env:SERVICE_ACCOUNT_NAMESPACE
"@

# Apply the YAML
$serviceAccountYaml | kubectl apply -f -

# Create the Federated Identity Credential
$env:FEDERATED_IDENTITY_CREDENTIAL_NAME="myFedIdentity"

# Create the federated identity credential that links the Kubernetes service account to the managed identity
az identity federated-credential create `
--name $env:FEDERATED_IDENTITY_CREDENTIAL_NAME `
--identity-name $env:USER_ASSIGNED_IDENTITY_NAME `
--resource-group $env:RG_NAME `
--issuer $env:AKS_OIDC_ISSUER `
--subject "system:serviceaccount:$env:SERVICE_ACCOUNT_NAMESPACE:$env:SERVICE_ACCOUNT_NAME" `
--audience api://AzureADTokenExchange

#Assign the Key Vault Secrets User role to the user-assigned managed identity
az role assignment create `
--assignee-object-id $env:USER_ASSIGNED_PRINCIPAL_ID `
--role "Key Vault Secrets User" `
--scope $env:AKV_ID `
--assignee-principal-type ServicePrincipal

# run the sample application in security folder
$podYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: sample-workload-identity
  namespace: $env:SERVICE_ACCOUNT_NAMESPACE
  labels:
    azure.workload.identity/use: "true"  # Required. Only pods with this label can use workload identity.
spec:
  serviceAccountName: $env:SERVICE_ACCOUNT_NAME
  containers:
    - image: busybox
      name: busybox
      command: ["sh", "-c", "sleep 3600"]
"@

# Apply the YAML
$podYaml | kubectl apply -f -

# Access Secrets in Azure Key Vault with Workload Identity
az role assignment create `
--assignee-object-id $(az ad signed-in-user show --query id -o tsv) `
--role "Key Vault Administrator" `
--scope "$env:AKV_ID" `
--assignee-principal-type User

#create a secret in the key vault
az keyvault secret set `
--vault-name "$env:AKV_NAME" `
--name "my-secret" `
--value "Hello\!"


#deploy a pod that references the service account and key vault URL
$env:vaultUri = $(az keyvault show -n $env:AKV_NAME -g $env:RG_NAME --query "properties.vaultUri" -o tsv)

$podYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: sample-workload-identity-key-vault
  namespace: $env:SERVICE_ACCOUNT_NAMESPACE
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: $env:SERVICE_ACCOUNT_NAME
  containers:
    - image: ghcr.io/azure/azure-workload-identity/msal-go
      name: oidc
      env:
      - name: KEYVAULT_URL
        value: $vaultUri
      - name: SECRET_NAME
        value: my-secret
  nodeSelector:
    kubernetes.io/os: linux
"@

# Apply the YAML
$podYaml | kubectl apply -f -

#To check whether all properties are injected properly, use the kubectl describe command:
kubectl describe pod sample-workload-identity-key-vault -n $env:SERVICE_ACCOUNT_NAMESPACE | Select-String "SECRET_NAME:"

#To verify that pod is able to get a token and access the resource, use the kubectl logs command:
kubectl logs -n $env:SERVICE_ACCOUNT_NAMESPACE sample-workload-identity-key-vault
