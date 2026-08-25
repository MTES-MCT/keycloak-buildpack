#!/bin/bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bin/common.sh"

BUILD_DIR="$(mktemp -d)"
TMP_PATH="${BUILD_DIR}/tmp"
CACHE_DIR="${BUILD_DIR}/cache"
KEYCLOAK_PATH="${BUILD_DIR}/keycloak"

mkdir -p "${TMP_PATH}" "${CACHE_DIR}/dist" "${KEYCLOAK_PATH}/providers"

echo "=== TESTING URL PROVIDERS (KEYCLOAK_URL_PROVIDERS) ==="
echo "KEYCLOAK_URL_PROVIDERS=${KEYCLOAK_URL_PROVIDERS}"
echo "--------------------------------------------------------"

if [[ -z "${KEYCLOAK_URL_PROVIDERS}" ]]; then
  echo "Error: Please set KEYCLOAK_URL_PROVIDERS environment variable."
  echo "Example:"
  echo "  KEYCLOAK_URL_PROVIDERS=\"https://s3.amazonaws.com/my-bucket/my-provider.jar?AWSAccessKeyId=...&Signature=...\" ./test_url_provider.sh"
  exit 1
fi

IFS=','
read -ra URL_PROVIDERS <<< "${KEYCLOAK_URL_PROVIDERS}"
for PROVIDER_URL in "${URL_PROVIDERS[@]}"; do   
  PROVIDER_URL=$(echo "${PROVIDER_URL}" | xargs)
  if [[ -n "${PROVIDER_URL}" ]]; then
    FILENAME=$(get_filename_from_url "${PROVIDER_URL}")
    echo "[INFO] Extracted Filename: '${FILENAME}'"
    echo "[INFO] Downloading from URL: ${PROVIDER_URL%%?*}..."
    fetch_url_provider_dist "${PROVIDER_URL}" "${TMP_PATH}" "${KEYCLOAK_PATH}"
    echo "✅ Success! Installed provider to ${KEYCLOAK_PATH}/providers/${FILENAME}"
  fi
done
IFS=' '

echo "--------------------------------------------------------"
echo "Contents of ${KEYCLOAK_PATH}/providers:"
ls -la "${KEYCLOAK_PATH}/providers"

rm -rf "${BUILD_DIR}"
