#!/bin/bash
set -Eeuo pipefail

LOCATION="<region>"
RESOURCEGROUP=aro-rg
CLUSTER=clusterxx
MANAGED_RESOURCE_GROUP="${RESOURCEGROUP}-${CLUSTER}-managed-rg"
WORKER_VM_SIZE=Standard_D4as_v4
CLIENT_ID="<client-id>"
END_DATE=$(date -d "+1 days" '+%Y-%m-%d')
CREDENTIAL_DISPLAY_NAME="aro-${CLUSTER}-$(date '+%Y%m%d%H%M%S')"
NEW_SECRET=
TAG_WATCHER_PID=

cleanup() {
  if [[ -n ${TAG_WATCHER_PID:-} ]] && \
    kill -0 "$TAG_WATCHER_PID" 2>/dev/null; then
    kill "$TAG_WATCHER_PID" 2>/dev/null || true
    wait "$TAG_WATCHER_PID" 2>/dev/null || true
  fi

  unset NEW_SECRET
}

trap cleanup EXIT

NEW_SECRET=$(az ad app credential reset \
  --id "$CLIENT_ID" \
  --append \
  --display-name "$CREDENTIAL_DISPLAY_NAME" \
  --end-date "$END_DATE" \
  --query password \
  --output tsv)

if [[ -z $NEW_SECRET ]]; then
  echo "Failed to reset the service principal credential." >&2
  exit 1
fi

az group create \
  --name "$RESOURCEGROUP" \
  --location "$LOCATION"

az network vnet create \
  --resource-group "$RESOURCEGROUP" \
  --name aro-vnet \
  --address-prefixes 10.0.0.0/16

az network vnet subnet create \
  --resource-group "$RESOURCEGROUP" \
  --vnet-name aro-vnet \
  --name master-subnet \
  --address-prefixes 10.0.0.0/24 \
  --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet create \
  --resource-group "$RESOURCEGROUP" \
  --vnet-name aro-vnet \
  --name worker-subnet \
  --address-prefixes 10.0.2.0/24 \
  --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet update \
  --name master-subnet \
  --resource-group "$RESOURCEGROUP" \
  --vnet-name aro-vnet \
  --disable-private-link-service-network-policies true

watch_and_tag_managed_resource_group() {
  echo "Waiting for managed resource group: $MANAGED_RESOURCE_GROUP"

  for attempt in {1..1800}; do
    if [[ $(az group exists \
      --name "$MANAGED_RESOURCE_GROUP" \
      --output tsv 2>/dev/null || echo false) == true ]]; then
      if az group update \
        --name "$MANAGED_RESOURCE_GROUP" \
        --set tags.SecurityControl=Ignore \
        --output none 2>/dev/null; then
        echo "SecurityControl=Ignore applied to: $MANAGED_RESOURCE_GROUP"
        return 0
      fi

      echo "Managed resource group found; retrying tag update." >&2
    fi

    sleep 1
  done

  echo "Timed out waiting for the managed resource group." >&2
  return 1
}

# Start the watcher before az aro create so the tag precedes Storage creation.
watch_and_tag_managed_resource_group &
TAG_WATCHER_PID=$!

az aro create \
  --resource-group "$RESOURCEGROUP" \
  --name "$CLUSTER" \
  --vnet aro-vnet \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet \
  --worker-vm-size "$WORKER_VM_SIZE" \
  --pull-secret @pull-secret.json \
  --client-id "$CLIENT_ID" \
  --client-secret "$NEW_SECRET" \
  --cluster-resource-group "$MANAGED_RESOURCE_GROUP"

unset NEW_SECRET
wait "$TAG_WATCHER_PID"
TAG_WATCHER_PID=

az aro show \
  --name "$CLUSTER" \
  --resource-group "$RESOURCEGROUP" \
  --query "{state:provisioningState,console:consoleProfile.url,api:apiserverProfile.url}" \
  --output json
