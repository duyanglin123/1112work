#!/usr/bin/env bash
set -euo pipefail

API_URL="${1:?Usage: ./scripts/upload_frontend.sh https://api-url}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STORAGE_ACCOUNT="$(terraform -chdir="$ROOT_DIR/infra" output -raw storage_account_name)"

python3 "$ROOT_DIR/scripts/package_frontend.py" --api-url "$API_URL" --out "$DIST_DIR"
az storage blob upload-batch \
  --account-name "$STORAGE_ACCOUNT" \
  --destination '$web' \
  --source "$DIST_DIR" \
  --overwrite \
  --auth-mode login

echo "Frontend uploaded: $(terraform -chdir="$ROOT_DIR/infra" output -raw frontend_url)"
