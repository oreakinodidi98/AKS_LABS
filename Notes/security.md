# Workload Identity

- Workloads deployed on an Azure Kubernetes Services (AKS) cluster require Microsoft Entra application credentials or managed identities to access Microsoft Entra protected resources, such as Azure Key Vault and Microsoft Graph. 
- Microsoft Entra Workload ID integrates with the capabilities native to Kubernetes to federate with external identity providers.

```
# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"
echo "Random resource identifier will be: ${RAND}"

# Set Location
$env:LOCATION = "eastus"
$env:LOCATION = "uksouth"
Write-Output $env:LOCATION

#Create a resource group name using the random number.
export RG_NAME=myresourcegroup$RAND
$env:RG_NAME= "myresourcegroup$RAND"
Write-Output $env:RG_NAME

# Create RG
az group create --name $env:RG_NAME --location $env:LOCATION

#Setup AKS Cluster
$env:AKS_NAME= "myakscluster$RAND"

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

# Connect to cluster 
az aks get-credentials `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME

# Setup Azure Key Vault
$env:AKV_NAME= "mykeyvault$RAND"

# create an key vault and export its resource identifier for later use
$env:AKV_ID = (az keyvault create `
--resource-group $env:RG_NAME `
--name $env:AKV_NAME `
--enable-rbac-authorization `
--query id `
--output tsv)

## Enable Workload Identity and OpenID Connect (OIDC) on an AKS cluster

# check your AKS cluster to see if Workload Identity is already enabled

az aks show `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--query "securityProfile.workloadIdentity.enabled" `
--output tsv

az aks show `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--query "oidcIssuerProfile.enabled" `
--output tsv

# If you need to enable Workload Identity and/or the OIDC issuer, run the following command

--name $env:AKS_NAME `
--enable-oidc-issuer `
--enable-workload-identity

# Get the OIDC Issuer URL

$env:AKS_OIDC_ISSUER="$(az aks show `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--query "oidcIssuerProfile.issuerUrl" `
--output tsv)"

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

$env:USER_ASSIGNED_PRINCIPAL_ID="$(az identity show `
--name $env:USER_ASSIGNED_IDENTITY_NAME `
--resource-group ${RG_NAME}$env:RG_NAME `
--query "principalId" `
--output tsv)"

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
$vaultUri = $(az keyvault show -n $env:AKV_NAME -g $env:RG_NAME --query "properties.vaultUri" -o tsv)

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
```