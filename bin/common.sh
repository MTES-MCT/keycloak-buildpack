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
  start "Fetching jq $JQ_VERSION"
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
  start "Install AdoptOpenJDK $JRE_MAJOR_VERSION JRE"
  local jre_query_url="https://api.adoptopenjdk.net/v3/assets/feature_releases/${JRE_MAJOR_VERSION}/ga\?architecture\=x64\&heap_size\=normal\&image_type\=jre\&jvm_impl\=hotspot\&os\=linux\&page\=0\&page_size\=1\&project\=jdk\&sort_order\=DESC\&vendor\=adoptopenjdk"
  local http_code=$(curl -s -o "$TMP_PATH/jre.json" -w '%{http_code}' "${jre_query_url}")
  if [[ $http_code == 200 ]]; then
    local jre_dist=$(cat "$TMP_PATH/jre.json" | jq '.[] | .binaries | .[] | .package.name')
    local checksum="$(cat "$TMP_PATH/jre.json" | jq '.[] | .binaries | .[] | .package.checksum') $jre_dist"
    local jre_release_name=$(cat "$TMP_PATH/jre.json" | jq '.[] | .release_name')
    local jre_url=$(cat "$TMP_PATH/jre.json" | jq '.[] | .binaries | .[] | .package.link')
  else
    warn "AdoptOpenJDK API v3 unavailable"
    warn "HTTP STATUS CODE: $http_code"
    local jre_release_name="jdk-11.0.8+10"
    info "Using by default $jre_release_name"
    local jre_dist="OpenJDK11U-jre_x64_linux_hotspot_11.0.8_10.tar.gz"
    local jre_url="https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/${jre_dist}"
    local checksum="98615b1b369509965a612232622d39b5cefe117d6189179cbad4dcef2ee2f4e1 OpenJDK11U-jre_x64_linux_hotspot_11.0.8_10.tar.gz"
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
    echo "${checksum}" >"${dist_filename}.sha256"
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
  echo "export PATH=$PATH:/app/java/bin" >"${BUILD_DIR}/.profile.d/java.sh"
  info "$(java -version)"
  finished
}

function fetch_keycloak_dist() {
  local version="$1"
  local location="$2"

  local dist="keycloak-${version}.tar.gz"
  local dist_url="https://downloads.jboss.org/keycloak/${version}/${dist}"
  local sha1_url="${dist_url}.sha1"
  if [ -f "${CACHE_DIR}/dist/${dist}" ]; then
    info "File is already downloaded"
  else
    ${CURL} -o "${CACHE_DIR}/dist/${dist}" "${dist_url}"
  fi
  ${CURL} -o "${CACHE_DIR}/dist/${dist}.sha1" "${sha1_url}"
  local file_checksum="$(shasum "${CACHE_DIR}/dist/${dist}" | cut -d \  -f 1)"
  local checksum=$(cat "${CACHE_DIR}/dist/${dist}.sha1")
  if [ "$checksum" != "$file_checksum" ]; then
    err "Keycloak checksum file downloaded not valid"
    exit 1
  else
    info "Keycloak checksum valid"
  fi
  tar xzf "$CACHE_DIR/dist/${dist}" -C "$location"
}

function fetch_france_connect_dist() {
  local version="$1"
  local location="$2"

  local dist="keycloak-franceconnect-${version}.jar"
  local dist_url="https://github.com/InseeFr/Keycloak-FranceConnect/releases/download/${version}/${dist}"
  if [ -f "${CACHE_DIR}/dist/${dist}" ]; then
    info "File is already downloaded"
  else
    ${CURL} -o "${CACHE_DIR}/dist/${dist}" "${dist_url}"
  fi
  cp "${CACHE_DIR}/dist/${dist}" "${location}"
  mv "${location}/keycloak-franceconnect-${FRANCE_CONNECT_VERSION}.jar" "${KEYCLOAK_PATH}/standalone/deployments/keycloak-franceconnect.jar"
}

function fetch_keycloak_tools() {
  local version="$1"
  local location="$2"
  local tmp="$3"

  local tools_repo_url="https://github.com/keycloak/keycloak-containers"
  git clone --depth 1 --branch "${version}" "${tools_repo_url}" "${tmp}/keycloak-containers" >/dev/null 2>&1
  mv -rf "${tmp}/keycloak-containers/server/tools" "${location}"
  rm -rf "${tmp}/keycloak-containers"
}

function configure_postgres_module() {
  local version="$1"
  local keycloak_path="$2"
  local tools_path="$3"

  mkdir -p "${keycloak_path}/modules/system/layers/base/org/postgresql/jdbc/main"
  cd "${keycloak_path}/modules/system/layers/base/org/postgresql/jdbc/main" || return
  local jdbc_postgresql_url="https://jdbc.postgresql.org/download/postgresql-${version}.jar"
  curl -L -s "${jdbc_postgresql_url}" >postgres-jdbc.jar
  cp "${tools_path}/databases/postgres/module.xml" .
}

function configure_keycloak() {
  local keycloak_path="$1"
  local tools_path="$2"
  find "${tools_path}" -type f -name '*.sh' -exec chmod +x {} \;
  find "${keycloak_path}" -type f -name '*.sh' -exec chmod +x {} \;
  find "${tools_path}" -type f -name '*.cli' -exec sed -i "s|\/opt\/jboss|${BUILD_DIR}|g" {} \;
  find "${keycloak_path}" -type f -name '*.cli' -exec sed -i "s|\/opt\/jboss|${BUILD_DIR}|g" {} \;
  find "${tools_path}" -type f -name '*.sh' -exec sed -i "s|\/opt\/jboss|${BUILD_DIR}|g" {} \;
  find "${keycloak_path}" -type f -name '*.sh' -exec sed -i "s|\/opt\/jboss|${BUILD_DIR}|g" {} \;
  find "${tools_path}" -type f -name '*.cli' -exec sed -i "s|\/app|${BUILD_DIR}|g" {} \;
  find "${keycloak_path}" -type f -name '*.cli' -exec sed -i "s|\/app|${BUILD_DIR}|g" {} \;
  find "${tools_path}" -type f -name '*.sh' -exec sed -i "s|\/app|${BUILD_DIR}|g" {} \;
  find "${keycloak_path}" -type f -name '*.sh' -exec sed -i "s|\/app|${BUILD_DIR}|g" {} \;
  "${keycloak_path}/bin/jboss-cli.sh" --file="${tools_path}/cli/standalone-configuration.cli"
  rm -rf "${keycloak_path}/standalone/configuration/standalone_xml_history"
  "${keycloak_path}/bin/jboss-cli.sh" --file="${tools_path}/cli/standalone-ha-configuration.cli"
  rm -rf "${keycloak_path}/standalone/configuration/standalone_xml_history"
  find "${tools_path}" -type f -name '*.cli' -exec sed -i "s|${BUILD_DIR}|\/app|g" {} \;
  find "${keycloak_path}" -type f -name '*.cli' -exec sed -i "s|${BUILD_DIR}|\/app|g" {} \;
  find "${tools_path}" -type f -name '*.sh' -exec sed -i "s|${BUILD_DIR}|\/app|g" {} \;
  find "${keycloak_path}" -type f -name '*.sh' -exec sed -i "s|${BUILD_DIR}|\/app|g" {} \;
}
