#!/usr/bin/env bash
# teardown.sh — delete everything so the lab stops costing money.
# Run from the repo root:  ./scripts/teardown.sh
set -euo pipefail

RG="rg-az104-lab"

echo "This will DELETE resource group '$RG' and every resource in it."
read -r -p "Type the resource group name to confirm: " CONFIRM

if [ "$CONFIRM" != "$RG" ]; then
  echo "Names did not match. Aborting."
  exit 1
fi

az group delete --name "$RG" --yes --no-wait
echo "Deletion started. Check the portal in a few minutes to confirm the group is gone."
