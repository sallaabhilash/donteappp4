#!/bin/bash
# Azure CLI sample for Azure Site Recovery vault provisioning and resource setup.
# Customize the values before running.

set -euo pipefail

SUBSCRIPTION_ID="<your-subscription-id>"
PRIMARY_RG="dr-primary-rg"
RECOVERY_RG="dr-secondary-rg"
VAULT_NAME="dr-asr-vault"
VAULT_LOCATION="centralindia"
RECOVERY_LOCATION="southindia"

az login
az account set --subscription "$SUBSCRIPTION_ID"

az group create --name "$PRIMARY_RG" --location "$VAULT_LOCATION"
az group create --name "$RECOVERY_RG" --location "$RECOVERY_LOCATION"

az provider register --namespace Microsoft.RecoveryServices

az recoveryservices vault create \
  --resource-group "$PRIMARY_RG" \
  --name "$VAULT_NAME" \
  --location "$VAULT_LOCATION"

az recoveryservices vault backup-properties set \
  --resource-group "$PRIMARY_RG" \
  --vault-name "$VAULT_NAME" \
  --storage-model GeoRedundant

echo "ASR vault provisioning complete. Continue with Azure Site Recovery configuration in the Portal or using ASR-specific tooling."
