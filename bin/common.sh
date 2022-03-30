#!/bin/bash

steptxt="----->"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'                              # No Color
CURL="curl -L --retry 15 --retry-delay 2" # retry for up to 30 seconds

info() {
  echo -e "${GREEN}       $*${NC}"
}

warn() {
  echo -e "${YELLOW} !!    $*${NC}"
}

err() {
  echo -e "${RED} !!    $*${NC}" >&2
}

step() {
  echo "$steptxt $*"
}

start() {
  echo -n "$steptxt $*... "
}

finished() {
  echo "done"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
  Darwin) sed -l "$c" ;; # mac/bsd sed: -l buffers on line boundaries
  *) sed -u "$c" ;;      # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

function install_jq() {
  if [[ -f "${ENV_DIR}/JQ_VERSION" ]]; then
    JQ_VERSION=$(cat "${ENV_DIR}/JQ_VERSION")
  else
    JQ_VERSION=1.6
  fi
  step "Fetching jq $JQ_VERSION"
  if [ -f "${CACHE_DIR}/dist/jq-$JQ_VERSION" ]; then
    info "File already downloaded"
  else
    ${CURL} -o "${CACHE_DIR}/dist/jq-$JQ_VERSION" "https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/jq-linux64"
  fi
  cp "${CACHE_DIR}/dist/jq-$JQ_VERSION" "${BUILD_DIR}/bin/jq"
  chmod +x "${BUILD_DIR}/bin/jq"
  finished
}

function install_jre() {
  install_jq
  if [[ -f "${ENV_DIR}/JRE_MAJOR_VERSION" ]]; then
    JRE_MAJOR_VERSION=$(cat "${ENV_DIR}/JRE_MAJOR_VERSION")
  else
    JRE_MAJOR_VERSION=11
  fi
  step "Install AdoptOpenJDK $JRE_MAJOR_VERSION JRE"
  local jre_query_url="https://api.adoptopenjdk.net/v3/assets/feature_releases/${JRE_MAJOR_VERSION}/ga"
  local http_code
  http_code=$($CURL -G -o "$TMP_PATH/jre.json" -w '%{http_code}' -H "accept: application/json" "${jre_query_url}" \
   --data-urlencode "architecture=x64" \
   --data-urlencode "heap_size=normal" \
   --data-urlencode "image_type=jre" \
   --data-urlencode "jvm_impl=hotspot" \
   --data-urlencode "os=linux" \
   --data-urlencode "page=0" \
   --data-urlencode "page_size=1" \
   --data-urlencode "project=jdk" \
   --data-urlencode "sort_method=DEFAULT" \
   --data-urlencode "sort_order=DESC" \
   --data-urlencode "vendor=adoptopenjdk")
  
  if [[ $http_code == 200 ]]; then
    local jre_dist
    jre_dist=$(cat "$TMP_PATH/jre.json" | jq '.[] | .binaries | .[] | .package.name' )
    jre_dist="${jre_dist%\"}"
    jre_dist="${jre_dist#\"}"
    local checksum_url
    checksum_url=$(cat "$TMP_PATH/jre.json" | jq '.[] | .binaries | .[] | .package.checksum_link' | xargs)
    local jre_release_name
    jre_release_name=$(cat "$TMP_PATH/jre.json" | jq '.[] | .release_name')
    jre_release_name="${jre_release_name%\"}"
    jre_release_name="${jre_release_name#\"}"
    local jre_url
    jre_url=$(cat "$TMP_PATH/jre.json" | jq '.[] | .binaries | .[] | .package.link' | xargs)
  else
    warn "AdoptOpenJDK API v3 HTTP STATUS CODE: $http_code"
    local jre_release_name="jdk-11.0.11+9"
    info "Using by default $jre_release_name"
    local jre_dist="OpenJDK11U-jre_x64_linux_hotspot_11.0.11_9.tar.gz"
    local jre_url="https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/${jre_dist}"
    local checksum_url="${jre_url}.sha256.txt"
  fi
  info "Fetching $jre_dist"
  local dist_filename="${CACHE_DIR}/dist/$jre_dist"
  if [ -f "${dist_filename}" ]; then
    info "File already downloaded"
  else
    ${CURL} -o "${dist_filename}" "${jre_url}"
  fi
  if [ -f "${dist_filename}.sha256" ]; then
    info "JRE sha256 sum already checked"
  else
    ${CURL} -o "${dist_filename}.sha256" "${checksum_url}"
    cd "${CACHE_DIR}/dist" || return
    sha256sum -c --strict --status "${dist_filename}.sha256"
    info "JRE sha256 checksum valid"
  fi
  if [ -d "${BUILD_DIR}/java" ]; then
    warn "JRE already installed"
  else
    tar xzf "${dist_filename}" -C "${CACHE_DIR}/dist"
    mv "${CACHE_DIR}/dist/$jre_release_name-jre" "$BUILD_DIR/java"
    info "JRE archive unzipped to $BUILD_DIR/java"
  fi
  export PATH=$PATH:"${BUILD_DIR}/java/bin"
  if [ ! -d "${BUILD_DIR}/.profile.d" ]; then
    mkdir -p "${BUILD_DIR}/.profile.d"
  fi
  touch "${BUILD_DIR}/.profile.d/java.sh"
  echo "export PATH=$PATH:/app/java/bin" > "${BUILD_DIR}/.profile.d/java.sh"
  info "$(java -version)"
  finished
}

function fetch_github_latest_release() {
  local location="$1"
  local repo="$2"
  local repo_checksum
  repo_checksum=$(printf "%s" "${repo}" | sha256sum | grep -o '^\S\+')
  local http_code
  if [[ -f "$ENV_DIR/GITHUB_ID" ]]; then
    GITHUB_ID=$(cat "$ENV_DIR/GITHUB_ID")
  fi
  if [[ -f "$ENV_DIR/GITHUB_SECRET" ]]; then
    GITHUB_SECRET=$(cat "$ENV_DIR/GITHUB_SECRET")
  fi
  local latest_release_url
  latest_release_url="https://api.github.com/repos/${repo}/releases/latest"
  http_code=$(curl -L --retry 15 --retry-delay 2 -G -o "${TMP_PATH}/latest_release_${repo_checksum}.json" -w '%{http_code}' -u "${GITHUB_ID}:${GITHUB_SECRET}" -H "Accept: application/vnd.github.v3+json" "${latest_release_url}")
  local latest_release_version
  latest_release_version=""
  if [[ $http_code == 200 ]]; then
    latest_release_version=$(< "${TMP_PATH}/latest_release_${repo_checksum}.json" jq '.tag_name' | xargs)
    latest_release_version="${latest_release_version%\"}"
    latest_release_version="${latest_release_version#\"}"
  fi
  echo "$latest_release_version"
}

function fetch_keycloak_dist() {
  local version="$1"
  local location="$2"
  local dist="keycloak-${version}.tar.gz"
  local dist_url
  local download_url
  local major_version
  major_version="${version%.*}"
  major_version="${major_version%.*}"
  if [[ "${major_version}" -gt 11 ]]; then
    download_url="https://github.com/keycloak/keycloak/releases/download/${version}"
  else
    download_url="https://downloads.jboss.org/keycloak/${version}"
  fi
  dist_url=$(echo "${download_url}/${dist}" | xargs)
  dist_url="${dist_url%\"}"
  dist_url="${dist_url#\"}"
  local sha1_dist
  sha1_dist=$(echo "${dist}.sha1" | xargs)
  local sha1_url
  sha1_url=$(echo "${download_url}/${sha1_dist}" | xargs)
  sha1_url="${sha1_url%\"}"
  sha1_url="${sha1_url#\"}"
  step "Fetch keycloak ${version} dist"
  if [ -f "${CACHE_DIR}/dist/${dist}" ]; then
    info "File is already downloaded"
  else
    ${CURL} -g -o "${CACHE_DIR}/dist/${dist}" "${dist_url}"
  fi
  ${CURL} -g -o "${CACHE_DIR}/dist/${dist}.sha1" "${sha1_url}"
  local file_checksum
  file_checksum="$(shasum "${CACHE_DIR}/dist/${dist}" | cut -d \  -f 1)"
  local checksum
  checksum=$(cat "${CACHE_DIR}/dist/${dist}.sha1")
  if [ "$checksum" != "$file_checksum" ]; then
    err "Keycloak checksum file downloaded not valid"
    exit 1
  else
    info "Keycloak checksum valid"
  fi
  tar xzf "$CACHE_DIR/dist/${dist}" -C "$location"
  finished
}

function get_provider_name() {
  local provider_repo="$1"
  local provider_name
  IFS='/'
  read -ra repo <<< "${provider_repo}"
  provider_name="${repo[1]}"
  provider_name="${provider_name%\"}"
  provider_name="${provider_name#\"}"
  echo "${provider_name}"
}

function fetch_provider_dist() {
  local provider_repo="$1"
  local version="$2"
  local location="$3"
  local dest="$4"
  local provider_name
  provider_name=$(get_provider_name "${provider_repo}")
  local dist="${provider_name}-${version}.jar"
  local dist_url="https://github.com/${provider_repo}/releases/download/${version}/${dist}"
  if [ -f "${CACHE_DIR}/dist/${dist}" ]; then
    info "File is already downloaded"
  else
    curl -L --retry 15 --retry-delay 2 -o "${CACHE_DIR}/dist/${dist}" "${dist_url}"
  fi
  cp "${CACHE_DIR}/dist/${dist}" "${location}"
  mv "${location}/${provider_name}-${version}.jar" "${dest}/providers/${provider_name}.jar"
}

function add_template() {
  local keycloak_template_dir="$1"
  if [ -d "${keycloak_template_dir}" ]; then
    echo "KEYCLOAK_TEMPLATE_DIR: $(ls -al ${keycloak_template_dir})"
  else
    echo "!!!___ KEYCLOAK_TEMPLATE_DIR does not exist ___!!!"
  fi
}
