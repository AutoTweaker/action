#!/usr/bin/env bash
set -euo pipefail

log() {
    local msg="${*//'%'/'%25'}"
    msg="${msg//$'\r'/'%0D'}"
    msg="${msg//$'\n'/'%0A'}"
    printf '::notice::%s\n' "${msg}"
}

INDEX_URL="https://autotweaker.github.io/index/"
ROOT="${RUNNER_TEMP}/autotweaker"
CORE_HOME="${ROOT}/home"
CORE_DIR="${ROOT}/dist"
PLUGIN_DIR="${CORE_HOME}/.config/autotweaker/plugins"

index=$(curl -fsSL "${INDEX_URL}")
core_tar_url=$(jq -r '.core.latest.tar_url' <<<"${index}")

adapter_index=$(curl -fsSL "$(jq -r '.adapter.actions' <<<"${index}")")
adapter_jar_url=$(jq -r '.latest.jar_url' <<<"${adapter_index}")

log "core:    $(jq -r '.core.latest.version' <<<"${index}")"
log "adapter: $(jq -r '.latest.version' <<<"${adapter_index}")"

mkdir -p "${CORE_DIR}" "${PLUGIN_DIR}"
curl -fsSL "${core_tar_url}" | tar -x -C "${CORE_DIR}" --strip-components=1
curl -fsSL -o "${PLUGIN_DIR}/actions-adapter.jar" "${adapter_jar_url}"

while IFS= read -r url; do
    url="${url#"${url%%[![:space:]]*}"}"
    url="${url%"${url##*[![:space:]]}"}"
    [ -n "${url}" ] || continue

    name=$(basename "${url%%\?*}")
    if [ -z "${name}" ]; then
        log "skip plugin url without a file name: ${url}"
        continue
    fi

    log "plugin:  ${name} <- ${url}"
    curl -fsSL -o "${PLUGIN_DIR}/${name}" "${url}"
done <<<"${INPUT_PLUGIN_URLS:-}"

export AUTOTWEAKER_OPTS="-Dlog.level=OFF -Duser.home=${CORE_HOME}"

exec "${CORE_DIR}/bin/autotweaker"
