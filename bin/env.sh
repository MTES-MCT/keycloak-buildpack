#!/bin/bash
# usage: bin/env.sh <env-file> <env-dir>

set -eo pipefail

ENV_FILE=${1:-}
ENV_DIR=${2:-}

if [ -n "$BUILDPACK_DEBUG" ]; then
    set -x
fi

function read_env_file() {
    local env_file="$1"
    local env_dir="$2"
    while IFS= read -r line; do
        if [[ "$line" == "#"* ]]; then

            if [ -n "$BUILDPACK_DEBUG" ]; then
                echo "Comment skipped: $line"
            fi
        else
            if [[ -n "$line" ]]; then

                if [ -n "$BUILDPACK_DEBUG" ]; then
                    echo "Split line: $line"
                fi
                IFS='=' read -ra key_val <<<"$line"

                if [ -n "$BUILDPACK_DEBUG" ]; then
                    echo "Key=Value found: ${key_val[0]}=${key_val[1]}"
                fi
                touch "$env_dir/${key_val[0]}"
                echo "${key_val[1]}" >"$env_dir/${key_val[0]}"
            else

                if [ -n "$BUILDPACK_DEBUG" ]; then
                    echo "Line empty: $line"
                fi
            fi
        fi
    done <"$env_file"
}

read_env_file "$ENV_FILE" "$ENV_DIR"
