#!/usr/bin/env bash
# shfmt -i 2 -ci -w
set -e

# Requirements:
# - Azure CLI (>= 2.67.0)
# - ARO preview extension
# - jq

__usage="
Available Commands:
    [-x  action]        action to be executed.

    Possible verbs are:
        install         creates ARO cluster with managed identities
        destroy         deletes ARO cluster and associated resources
        show            shows cluster information and credentials
        check-deps      checks if required dependencies are installed
        download-ext    downloads and installs ARO preview extension
"

# Default configuration
LOCATION=${LOCATION:-uksouth}
RESOURCEGROUP=${RESOURCEGROUP:-aro-rg}
CLUSTER=${CLUSTER:-cluster}
CLUSTER_VERSION=${CLUSTER_VERSION:-4.15.35}
PULL_SECRET_FILE=${PULL_SECRET_FILE:-pull-secret.txt}

usage() {
  echo "usage: ${0##*/} [options]"
  echo "${__usage/[[:space:]]/}"
  echo ""
  echo "Environment variables (with defaults):"
  echo "  LOCATION=${LOCATION}"
  echo "  RESOURCEGROUP=${RESOURCEGROUP}"
  echo "  CLUSTER=${CLUSTER}"
  echo "  CLUSTER_VERSION=${CLUSTER_VERSION}"
  echo "  PULL_SECRET_FILE=${PULL_SECRET_FILE}"
  exit 1
}

timestamp() {
  date +"%r"
}

log() {
  echo "[$(timestamp)] $*"
}

checkDependencies() {
  log "Checking dependencies ..."
  _NEEDED="az jq"
  _DEP_FLAG=false

  for i in ${_NEEDED}; do
    if hash "$i" 2>/dev/null; then
      log "  $i: OK"
    else
      log "  $i: NOT FOUND"
      _DEP_FLAG=true
    fi
  done

  # Check Azure CLI version
  AZ_VERSION=$(az version --query '"azure-cli"' -o tsv 2>/dev/null)
  if [[ $(echo "$AZ_VERSION 2.67.0" | tr " " "\n" | sort -V | head -n1) != "2.67.0" ]]; then
    log "  Azure CLI version $AZ_VERSION is too old. Minimum required: 2.67.0"
    _DEP_FLAG=true
  else
    log "  Azure CLI version: $AZ_VERSION (OK)"
  fi

  if [[ "${_DEP_FLAG}" == "true" ]]; then
    log "Dependencies missing. Please fix that before proceeding"
    exit 1
  fi

  log "All dependencies satisfied"
}

downloadExtension() {
  log "Installing ARO preview extension..."

  # Remove existing ARO extension if present
  if az extension show --name aro >/dev/null 2>&1; then
    log "  Removing existing ARO extension"
    az extension remove --name aro
  fi

  # Download and install the preview extension
  log "  Downloading ARO preview extension..."

  # Get the actual URL by following redirects
  ACTUAL_URL=$(curl -s -L -I -o /dev/null -w '%{url_effective}' https://aka.ms/az-aroext-latest)
  log "  Resolved URL: $ACTUAL_URL"

  # Download with proper filename that Azure CLI expects
  curl -L "$ACTUAL_URL" -o aro-1.0.12-py2.py3-none-any.whl

  log "  Installing ARO preview extension"
  az extension add --source ./aro-1.0.12-py2.py3-none-any.whl --yes

  # Clean up downloaded file
  rm -f aro-1.0.12-py2.py3-none-any.whl

  log "ARO preview extension installed successfully"
}

registerProviders() {
  log "Registering resource providers..."

  _PROVIDERS="Microsoft.RedHatOpenShift Microsoft.Compute Microsoft.Storage Microsoft.Authorization"

  for provider in ${_PROVIDERS}; do
    log "  Registering $provider"
    az provider register -n "$provider" --wait
  done

  log "Resource providers registered"
}

validateQuota() {
  log "Validating quota requirements..."
  QUOTA_INFO=$(az vm list-usage -l "$LOCATION" --query "[?contains(name.value, 'standardDSv5Family')]" -o json)

  if [[ $(echo "$QUOTA_INFO" | jq '.[0].currentValue') -gt 0 ]]; then
    AVAILABLE_CORES=$(echo "$QUOTA_INFO" | jq '.[0].limit - .[0].currentValue')
    if [[ $AVAILABLE_CORES -lt 44 ]]; then
      log "Insufficient quota: Need 44 cores, available: $AVAILABLE_CORES"
      log "Request quota increase for Standard DSv5 Family vCPUs"
      exit 1
    fi
    log "Quota validation passed: $AVAILABLE_CORES cores available"
  else
    log "Cannot validate quota for Standard DSv5 Family in $LOCATION"
  fi
}

createResourceGroup() {
  log "Creating resource group $RESOURCEGROUP in $LOCATION"
  az group create --location "$LOCATION" --name "$RESOURCEGROUP"
}

createVirtualNetwork() {
  log "Creating virtual network and subnets..."

  # Create virtual network
  az network vnet create \
    --resource-group "$RESOURCEGROUP" \
    --name aro-vnet \
    --address-prefixes 10.0.0.0/22

  # Create master subnet
  az network vnet subnet create \
    --resource-group "$RESOURCEGROUP" \
    --vnet-name aro-vnet \
    --name master \
    --address-prefixes 10.0.0.0/23

  # Create worker subnet
  az network vnet subnet create \
    --resource-group "$RESOURCEGROUP" \
    --vnet-name aro-vnet \
    --name worker \
    --address-prefixes 10.0.2.0/23

  log "Virtual network created"
}

createManagedIdentities() {
  log "Creating managed identities..."

  _IDENTITIES="aro-cluster cloud-controller-manager ingress machine-api disk-csi-driver cloud-network-config image-registry file-csi-driver aro-operator"

  for identity in ${_IDENTITIES}; do
    log "  Creating identity: $identity"
    az identity create --resource-group "$RESOURCEGROUP" --name "$identity"
  done

  log "Managed identities created"
}

assignRoles() {
  log "Assigning role assignments..."

  SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)

  # Cluster identity permissions over other identities
  CLUSTER_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name aro-cluster --query principalId -o tsv)

  _OPERATOR_IDENTITIES="aro-operator cloud-controller-manager ingress machine-api disk-csi-driver cloud-network-config image-registry file-csi-driver"

  for identity in ${_OPERATOR_IDENTITIES}; do
    log "  Assigning cluster identity permissions to $identity"
    az role assignment create \
      --assignee-object-id "$CLUSTER_PRINCIPAL_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/ef318e2a-8334-4a05-9e4a-295a196c6a6e" \
      --scope "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCEGROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$identity"
  done

  # VNet-level and subnet-level role assignments
  log "  Assigning network permissions to operators..."

  # Cloud Controller Manager - master and worker subnets
  CCM_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name cloud-controller-manager --query principalId -o tsv)
  az role assignment create \
    --assignee-object-id "$CCM_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/a1f96423-95ce-4224-ab27-4e3dc72facd4" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/master"

  az role assignment create \
    --assignee-object-id "$CCM_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/a1f96423-95ce-4224-ab27-4e3dc72facd4" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/worker"

  # Ingress - master and worker subnets
  INGRESS_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name ingress --query principalId -o tsv)
  az role assignment create \
    --assignee-object-id "$INGRESS_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/0336e1d3-7a87-462b-b6db-342b63f7802c" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/master"

  az role assignment create \
    --assignee-object-id "$INGRESS_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/0336e1d3-7a87-462b-b6db-342b63f7802c" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/worker"

  # Machine API - master and worker subnets
  MACHINE_API_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name machine-api --query principalId -o tsv)
  az role assignment create \
    --assignee-object-id "$MACHINE_API_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/0358943c-7e01-48ba-8889-02cc51d78637" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/master"

  az role assignment create \
    --assignee-object-id "$MACHINE_API_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/0358943c-7e01-48ba-8889-02cc51d78637" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/worker"

  # Cloud Network Config - vnet level
  CLOUD_NET_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name cloud-network-config --query principalId -o tsv)
  az role assignment create \
    --assignee-object-id "$CLOUD_NET_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/be7a6435-15ae-4171-8f30-4a343eff9e8f" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet"

  # File CSI Driver - vnet level
  FILE_CSI_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name file-csi-driver --query principalId -o tsv)
  az role assignment create \
    --assignee-object-id "$FILE_CSI_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/0d7aedc0-15fd-4a67-a412-efad370c947e" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet"

  # Image Registry - vnet level
  IMAGE_REG_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name image-registry --query principalId -o tsv)
  az role assignment create \
    --assignee-object-id "$IMAGE_REG_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/8b32b316-c2f5-4ddf-b05b-83dacd2d08b5" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet"

  # ARO Operator - master and worker subnets
  ARO_OP_PRINCIPAL_ID=$(az identity show --resource-group "$RESOURCEGROUP" --name aro-operator --query principalId -o tsv)
  az role assignment create \
    --assignee-object-id "$ARO_OP_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/4436bae4-7702-4c84-919b-c4069ff25ee2" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/master"

  az role assignment create \
    --assignee-object-id "$ARO_OP_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/4436bae4-7702-4c84-919b-c4069ff25ee2" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet/subnets/worker"

  # First-party service principal role assignment
  ARO_RP_SP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query '[0].id' -o tsv)
  az role assignment create \
    --assignee-object-id "$ARO_RP_SP_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/aro-vnet"

  log "Role assignments completed"
}

createCluster() {
  log "Creating ARO cluster with managed identities..."

  # Prepare pull secret parameter
  PULL_SECRET_PARAM=""
  if [[ -f "$PULL_SECRET_FILE" ]]; then
    log "Using pull secret from $PULL_SECRET_FILE"
    PULL_SECRET_PARAM="--pull-secret @$PULL_SECRET_FILE"
  else
    log "Pull secret file not found: $PULL_SECRET_FILE (cluster will be created without pull secret)"
  fi

  # Create the cluster
  az aro create \
    --resource-group "$RESOURCEGROUP" \
    --name "$CLUSTER" \
    --vnet aro-vnet \
    --master-subnet master \
    --worker-subnet worker \
    --version "$CLUSTER_VERSION" \
    --enable-managed-identity \
    --assign-cluster-identity aro-cluster \
    --assign-platform-workload-identity file-csi-driver file-csi-driver \
    --assign-platform-workload-identity cloud-controller-manager cloud-controller-manager \
    --assign-platform-workload-identity ingress ingress \
    --assign-platform-workload-identity image-registry image-registry \
    --assign-platform-workload-identity machine-api machine-api \
    --assign-platform-workload-identity cloud-network-config cloud-network-config \
    --assign-platform-workload-identity aro-operator aro-operator \
    --assign-platform-workload-identity disk-csi-driver disk-csi-driver \
    $PULL_SECRET_PARAM

  log "ARO cluster created successfully"
}

show() {
  log "Getting cluster information..."

  if az aro show --name "$CLUSTER" --resource-group "$RESOURCEGROUP" >/dev/null 2>&1; then
    CLUSTER_INFO=$(az aro show --name "$CLUSTER" --resource-group "$RESOURCEGROUP" --output json)

    echo ""
    echo "Cluster Information:"
    echo "==================="
    echo "Name: $CLUSTER"
    echo "Resource Group: $RESOURCEGROUP"
    echo "Location: $LOCATION"
    echo "Version: $(echo "$CLUSTER_INFO" | jq -r '.properties.clusterProfile.version')"
    echo "Console URL: $(echo "$CLUSTER_INFO" | jq -r '.properties.consoleProfile.url')"
    echo "API Server URL: $(echo "$CLUSTER_INFO" | jq -r '.properties.apiserverProfile.url')"
    echo "Provisioning State: $(echo "$CLUSTER_INFO" | jq -r '.properties.provisioningState')"

    echo ""
    echo "Login Credentials:"
    echo "=================="
    CREDENTIALS=$(az aro list-credentials --name "$CLUSTER" --resource-group "$RESOURCEGROUP" --output json)
    echo "Username: $(echo "$CREDENTIALS" | jq -r '.kubeadminUsername')"
    echo "Password: $(echo "$CREDENTIALS" | jq -r '.kubeadminPassword')"
  else
    log "Cluster $CLUSTER not found in resource group $RESOURCEGROUP"
    exit 1
  fi
}

destroy() {
  log "Destroying ARO cluster and associated resources..."

  # Delete the cluster
  if az aro show --name "$CLUSTER" --resource-group "$RESOURCEGROUP" >/dev/null 2>&1; then
    log "Deleting ARO cluster $CLUSTER"
    az aro delete --name "$CLUSTER" --resource-group "$RESOURCEGROUP" --yes
  else
    log "Cluster $CLUSTER not found, skipping cluster deletion"
  fi

  # Delete managed identities
  log "Deleting managed identities..."
  _IDENTITIES="aro-cluster cloud-controller-manager ingress machine-api disk-csi-driver cloud-network-config image-registry file-csi-driver aro-operator"

  for identity in ${_IDENTITIES}; do
    if az identity show --resource-group "$RESOURCEGROUP" --name "$identity" >/dev/null 2>&1; then
      log "  Deleting identity: $identity"
      az identity delete --resource-group "$RESOURCEGROUP" --name "$identity"
    fi
  done

  # Delete the entire resource group
  log "Deleting resource group $RESOURCEGROUP"
  az group delete --name "$RESOURCEGROUP" --yes --no-wait

  log "Destruction completed"
}

install() {
  checkDependencies
  downloadExtension
  registerProviders
  validateQuota
  createResourceGroup
  createVirtualNetwork
  createManagedIdentities

  log "Waiting 30 seconds for managed identity propagation..."
  sleep 30

  assignRoles
  createCluster

  log ""
  log "ARO cluster installation completed!"
  log "Run '$0 -x show' to get cluster information and credentials"
}

exec_case() {
  local _opt=$1

  case ${_opt} in
    install) install ;;
    destroy) destroy ;;
    show) show ;;
    check-deps) checkDependencies ;;
    download-ext) downloadExtension ;;
    *) usage ;;
  esac
  unset _opt
}

while getopts "x:" opt; do
  case $opt in
    x)
      exec_flag=true
      EXEC_OPT="${OPTARG}"
      ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ $OPTIND = 1 ]; then
  usage
  exit 0
fi

if [[ "${exec_flag}" == "true" ]]; then
  exec_case "${EXEC_OPT}"
fi

exit 0