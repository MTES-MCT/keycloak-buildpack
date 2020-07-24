#!/usr/bin/env bash

function indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
    *)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

function install_jre(){
  if [ -d /usr/share/man/man1 ]; then
    echo "Java is already installed"
    java -version
  else
    mkdir -p /usr/share/man/man1
    apt-get -qq update && apt-get -qq -y install default-jre
  fi
}

function fetch_keycloak_dist() {
  local version="$1"
  local location="$2"

  local dist="keycloak-${version}.tar.gz"
  local dist_url="https://downloads.jboss.org/keycloak/${version}/${dist}"
  local sha1_url="${dist_url}.sha1"
  local checksum=""
  checksum=$(curl --fail --retry 3 --retry-delay 2 --connect-timeout 3 --max-time 30 "${sha1_url}" 2> /dev/null)
  echo "checksum downloaded: $checksum"
  local cache_checksum=""

  if [ -f "$CACHE_DIR/dist/${dist}.sha1" ]; then
    cache_checksum=$(cat "$CACHE_DIR/dist/${dist}.sha1")
  fi

  if [ "$cache_checksum" != "$checksum" ]; then
    curl --fail --retry 3 --retry-delay 2 --connect-timeout 3 --max-time 30 "${dist_url}" -L -s > "$CACHE_DIR/dist/${dist}"
    echo "Keycloak dist downloaded"
    # echo -n " ${dist}.sha1" >> "${dist}.sha1"
    # echo "cat sha1: $(cat "${dist}.sha1")"
    # sha1sum -c "${dist}.sha1"
    echo "$checksum" > "$CACHE_DIR/dist/${dist}.sha1"
  else
    echo "Checksums match. Fetching from cache."
  fi

  echo "Keycloak dist to be unzipped" 
  tar xzf "$CACHE_DIR/dist/${dist}" -C "$location"
  echo "Keycloak dist is unzipped"    
}

function fetch_keycloak_tools() {
  local version="$1"
  local location="$2"
  local tmp="$3"

  local tools_repo_url="https://github.com/keycloak/keycloak-containers"
  git clone --depth 1 --branch "${version}" "${tools_repo_url}" "${tmp}/keycloak-containers" >/dev/null 2>&1
  if [ -d "${location}" ]; then
    echo "${location} not empty"
  else
    echo "copy tools to ${location}"
    mv "${tmp}/keycloak-containers/server/tools" "${location}"
  fi
  rm -rf "${tmp}/keycloak-containers"
}

function configure_postgres_module(){
    local version="$1"
    local keycloak_path="$2"
    local tools_path="$3"

    mkdir -p "${keycloak_path}/modules/system/layers/base/org/postgres/jdbc/main"
    cd "${keycloak_path}/modules/system/layers/base/org/postgres/jdbc/main" || return
    local jdbc_postgresql_url="https://repo1.maven.org/maven2/org/postgres/postgres/${version}/postgresql-${version}.jar"
    curl -L -s "${jdbc_postgresql_url}" > postgres-jdbc.jar
    cp "${tools_path}/databases/postgres/module.xml" .
}

function configure_keycloak(){
    local keycloak_path="$1"
    local tools_path="$2"
    local std_cfg_cli_path="${tools_path}/cli/standalone-configuration.cli"
    local std_cfg_ha_cli_path="${tools_path}/cli/standalone-ha-configuration.cli"
    
    awk -v tools_path="$tools_path" -v std_cfg_cli_path="$std_cfg_cli_path" '{gsub("/opt/jboss/tools", tools_path); print > std_cfg_cli_path}' "${std_cfg_cli_path}"

    "${keycloak_path}/bin/jboss-cli.sh" --file="${tools_path}/cli/standalone-configuration.cli"
    rm -rf "${keycloak_path}/standalone/configuration/standalone_xml_history"
    
    awk -v tools_path="$tools_path" -v std_cfg_ha_cli_path="$std_cfg_ha_cli_path" '{gsub("/opt/jboss/tools", tools_path); print > std_cfg_ha_cli_path}' "${std_cfg_ha_cli_path}"

    "${keycloak_path}/bin/jboss-cli.sh" --file="${tools_path}/cli/standalone-ha-configuration.cli"
    rm -rf "${keycloak_path}/standalone/configuration/standalone_xml_history"
}