#!/usr/bin/env bash
# Initialize or pin the hermes-agent git submodule.
#
# Usage:
#   ./scripts/pin-upstream.sh              # init/update to recorded SHA
#   ./scripts/pin-upstream.sh <ref>        # checkout tag/branch/commit inside submodule
#   UPSTREAM_URL=... ./scripts/pin-upstream.sh

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_cmd git

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/NousResearch/hermes-agent.git}"
REF="${1:-}"

cd "${HDFI_ROOT}"

if [[ ! -f "${HDFI_ROOT}/.gitmodules" ]] && [[ ! -d "${UPSTREAM_DIR}/.git" && ! -f "${UPSTREAM_DIR}/.git" ]]; then
  log "adding submodule ${UPSTREAM_URL} → upstream/"
  # Shallow-ish first clone for speed; history available after full fetch if needed
  git submodule add --force "${UPSTREAM_URL}" upstream || {
    # If path exists empty or partial, clean and retry once
    if [[ -d upstream ]] && [[ ! -f upstream/package.json ]]; then
      rm -rf upstream
    fi
    git submodule add "${UPSTREAM_URL}" upstream
  }
fi

if [[ ! -f "${HDFI_ROOT}/.gitmodules" ]]; then
  # Submodule may already be registered from a prior clone
  if [[ ! -d "${UPSTREAM_DIR}/.git" && ! -f "${UPSTREAM_DIR}/.git" ]]; then
    die "upstream is not a submodule and .gitmodules missing"
  fi
fi

log "syncing submodule"
git submodule sync --recursive
git submodule update --init --recursive

cd "${UPSTREAM_DIR}"

if [[ -n "${REF}" ]]; then
  log "fetching and checking out ${REF}"
  git fetch --tags origin
  git checkout --detach "${REF}" || git checkout "${REF}"
  PINNED="$(git rev-parse HEAD)"
  log "upstream pinned to ${PINNED} (${REF})"
  cd "${HDFI_ROOT}"
  git add upstream .gitmodules 2>/dev/null || true
  log "submodule pointer updated in index (commit when ready)"
else
  PINNED="$(git rev-parse HEAD)"
  SHORT="$(git rev-parse --short HEAD)"
  DESC="$(git describe --tags --always 2>/dev/null || echo "$SHORT")"
  log "upstream at ${PINNED} (${DESC})"
fi

if [[ ! -f "${DESKTOP_DIR}/package.json" ]]; then
  die "apps/desktop/package.json missing after pin — wrong repo or path?"
fi

DESKTOP_VER="$(node -p "require('${DESKTOP_DIR}/package.json').version" 2>/dev/null || python3 -c "import json; print(json.load(open('${DESKTOP_DIR}/package.json'))['version'])")"
log "apps/desktop version: ${DESKTOP_VER}"
log "done"
