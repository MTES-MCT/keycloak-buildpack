#!/bin/bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bin/common.sh"

BUILD_DIR="$(mktemp -d)"
TMP_PATH="${BUILD_DIR}/tmp"
CACHE_DIR="${BUILD_DIR}/cache"
KEYCLOAK_PATH="${BUILD_DIR}/keycloak"

mkdir -p "${TMP_PATH}" "${CACHE_DIR}/dist" "${KEYCLOAK_PATH}/providers"

echo "=== TESTING PRIVATE PROVIDERS ==="
echo "KEYCLOAK_PRIVATE_PROVIDER=${KEYCLOAK_PRIVATE_PROVIDER}"
echo "---------------------------------"

if [[ -z "${KEYCLOAK_PRIVATE_PROVIDER}" ]]; then
  echo "Error: Please set KEYCLOAK_PRIVATE_PROVIDER environment variable"
  echo "Example: KEYCLOAK_PRIVATE_PROVIDER=\"MTES-MCT/Dossier-Facile-Keycloak:1.0.0||TOKEN\" ./test_private_provider.sh"
  exit 1
fi

IFS=','
read -ra PRIVATE_PROVIDERS <<< "${KEYCLOAK_PRIVATE_PROVIDER}"
for PRIVATE_PROVIDER_REPO in "${PRIVATE_PROVIDERS[@]}"; do   
  PRIVATE_PROVIDER_NAME=$(get_private_provider_name "${PRIVATE_PROVIDER_REPO}")
  PRIVATE_REPO_NAME=$(get_private_repo_name "${PRIVATE_PROVIDER_REPO}")
  PRIVATE_GITHUB_TOKEN=$(get_private_github_token "${PRIVATE_PROVIDER_REPO}")
  SPECIFIED_VERSION=$(get_private_repo_version "${PRIVATE_PROVIDER_REPO}")

  echo "[DEBUG] PRIVATE_PROVIDER_NAME: '${PRIVATE_PROVIDER_NAME}'"
  echo "[DEBUG] PRIVATE_REPO_NAME:     '${PRIVATE_REPO_NAME}'"
  echo "[DEBUG] SPECIFIED_VERSION:     '${SPECIFIED_VERSION}'"

  if [[ -n "${SPECIFIED_VERSION}" ]]; then
    echo "[INFO] Fetching release for tag '${SPECIFIED_VERSION}'..."
    PRIVATE_RELEASE_PATH=$(fetch_private_github_release_by_tag "${TMP_PATH}" "${PRIVATE_REPO_NAME}" "${SPECIFIED_VERSION}" "${PRIVATE_GITHUB_TOKEN}")
  else
    echo "[INFO] Fetching latest release..."
    PRIVATE_RELEASE_PATH=$(fetch_private_github_latest_release "${TMP_PATH}" "${PRIVATE_REPO_NAME}" "${PRIVATE_GITHUB_TOKEN}")
  fi

  PRIVATE_PROVIDER_VERSION=$(read_version_github_json "${PRIVATE_RELEASE_PATH}")
  echo "[INFO] Resolved version: '${PRIVATE_PROVIDER_VERSION}'"

  if [[ -n "${PRIVATE_PROVIDER_VERSION}" && "${PRIVATE_PROVIDER_VERSION}" != "null" ]]; then
    echo "[INFO] Fetching provider distribution..."
    fetch_private_provider_dist "${PRIVATE_PROVIDER_REPO}" "${PRIVATE_PROVIDER_VERSION}" "${TMP_PATH}" "${KEYCLOAK_PATH}" "${PRIVATE_GITHUB_TOKEN}" "${PRIVATE_RELEASE_PATH}" "${PRIVATE_PROVIDER_NAME}"
    echo "✅ Success! Provider installed in ${KEYCLOAK_PATH}/providers"
    ls -la "${KEYCLOAK_PATH}/providers"
  else
    echo "❌ Error: Unable to fetch release JSON or tag version is invalid"
    cat "${PRIVATE_RELEASE_PATH}"
    exit 1
  fi
done
IFS=' '

rm -rf "${BUILD_DIR}"
