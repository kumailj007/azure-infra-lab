#!/usr/bin/env bash
# deploy.sh — provision the AZ-104 lab into your Azure subscription.
# Run from the repo root:  ./scripts/deploy.sh
set -euo pipefail

# ---- Config (edit if you like) ----------------------------------------------
RG="rg-az104-lab"
LOCATION="northeurope"
ADMIN_USER="azureadmin"
SSH_KEY_PATH="$HOME/.ssh/az104_lab.pub"
# Storage account names must be globally unique — $RANDOM keeps it short + unique.
STORAGE_NAME="staz104lab${RANDOM}"
# -----------------------------------------------------------------------------

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "No SSH key found at $SSH_KEY_PATH"
  echo "Generate one first:  ssh-keygen -t ed25519 -f \$HOME/.ssh/az104_lab -C az104-lab"
  exit 1
fi

# Lock SSH down to your current public IP only.
MY_IP="$(curl -s https://api.ipify.org)/32"
echo "Scoping SSH access to your IP: $MY_IP"

echo "Creating resource group $RG in $LOCATION..."
az group create --name "$RG" --location "$LOCATION" --output none

echo "Deploying infrastructure (this takes ~3-5 min)..."
az deployment group create \
  --resource-group "$RG" \
  --template-file ./infra/main.bicep \
  --parameters \
      adminSourceAddressPrefix="$MY_IP" \
      adminUsername="$ADMIN_USER" \
      adminSshPublicKey="$(cat "$SSH_KEY_PATH")" \
      storageAccountName="$STORAGE_NAME" \
  --query "properties.outputs" \
  --output jsonc

echo ""
echo "Done. Open the webServerUrl above in a browser to see nginx serving the lab page."
echo "SSH in with:  ssh -i \$HOME/.ssh/az104_lab ${ADMIN_USER}@<public-ip>"
