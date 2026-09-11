#!/usr/bin/env bash
set -euo pipefail

# stdout is reserved for the adapter, everything here goes to stderr.
log() { printf '%s\n' "$*" >&2; }

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

# -Duser.home keeps every piece of state (plugins, logs, secret keystore,
# database) under $RUNNER_TEMP instead of the runner's real home. gpg follows
# along, because GNUPGHOME is derived from CONFIG_PATH rather than $HOME.
# -Dlog.level=OFF silences the STDOUT appender only; the JSONL file appender and
# the shared log bus stay intact, which is what the uploaded logs come from.
export AUTOTWEAKER_OPTS="-Dlog.level=OFF -Duser.home=${CORE_HOME}"

exec "${CORE_DIR}/bin/autotweaker"
