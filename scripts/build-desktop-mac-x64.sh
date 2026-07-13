#!/usr/bin/env bash
# Build official Hermes Desktop for macOS x86_64 and copy artifacts to dist/.

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_cmd npm
require_cmd node
require_upstream
ensure_dist

export CSC_IDENTITY_AUTO_DISCOVERY="${CSC_IDENTITY_AUTO_DISCOVERY:-false}"
export npm_config_arch=x64
# electron-builder target arch
export npm_config_target_arch=x64

log "building Hermes Desktop for macOS x64"
log "upstream: ${UPSTREAM_DIR}"
log "CSC_IDENTITY_AUTO_DISCOVERY=${CSC_IDENTITY_AUTO_DISCOVERY}"
if [[ -n "${ELECTRON_MIRROR:-}" ]]; then
  log "ELECTRON_MIRROR=${ELECTRON_MIRROR}"
fi

cd "${UPSTREAM_DIR}"

log "npm install --workspace apps/desktop"
npm install --workspace apps/desktop

log "npm run build --workspace apps/desktop"
npm run build --workspace apps/desktop

# electron-builder CLI: targets are positional after --mac, not after --x64.
# package.json already lists mac.target: [dmg, zip] — prefer flags only.
# Equivalent upstream scripts: dist:mac / dist:mac:dmg / dist:mac:zip
log "electron-builder --mac --x64 (targets from package.json: dmg + zip)"
set +e
npm_config_arch=x64 npm run builder --workspace apps/desktop -- --mac --x64 --publish=never
BUILD_STATUS=$?
set -e

if [[ "$BUILD_STATUS" -ne 0 ]]; then
  warn "default mac targets failed (exit ${BUILD_STATUS}); retrying --mac dmg --x64"
  set +e
  npm_config_arch=x64 npm run builder --workspace apps/desktop -- --mac dmg --x64 --publish=never
  BUILD_STATUS=$?
  set -e
fi

if [[ "$BUILD_STATUS" -ne 0 ]]; then
  warn "dmg failed (exit ${BUILD_STATUS}); retrying --mac zip --x64"
  npm_config_arch=x64 npm run builder --workspace apps/desktop -- --mac zip --x64 --publish=never
fi

log "collecting artifacts into ${DIST_DIR}"
# Remove previous desktop artifacts but keep other dist files (e.g. bootstrap)
# Use nullglob so empty globs do not error under bash; zsh users should run via bash.
shopt -s nullglob
rm -f "${DIST_DIR}"/Hermes-*-mac-x64.* || true
rm -rf "${DIST_DIR}/Hermes.app" || true

COPIED=0
for f in "${DESKTOP_DIR}"/release/Hermes-*-mac-x64.*; do
  # skip blockmaps in primary copy? keep them out of dist for cleaner ship set
  case "$f" in
    *.blockmap) continue ;;
  esac
  cp -f "$f" "${DIST_DIR}/"
  log "copied $(basename "$f")"
  COPIED=1
done
# Also pick any arch-named variants electron-builder might emit
for f in "${DESKTOP_DIR}"/release/Hermes-*x64*.dmg "${DESKTOP_DIR}"/release/Hermes-*x64*.zip; do
  case "$f" in
    *.blockmap) continue ;;
  esac
  base="$(basename "$f")"
  if [[ ! -f "${DIST_DIR}/${base}" ]]; then
    cp -f "$f" "${DIST_DIR}/"
    log "copied ${base}"
    COPIED=1
  fi
done
shopt -u nullglob

if APP_PATH="$(find_hermes_app)"; then
  log "copying app bundle from ${APP_PATH}"
  rm -rf "${DIST_DIR}/Hermes.app"
  cp -R "${APP_PATH}" "${DIST_DIR}/Hermes.app"
  COPIED=1
else
  warn "Hermes.app not found under apps/desktop/release — check builder output"
fi

if [[ "$COPIED" -eq 0 ]]; then
  die "no artifacts collected; listing release dir:"$'\n'"$(ls -la "${DESKTOP_DIR}/release" 2>/dev/null || true)"
fi

# Record upstream pin for provenance
{
  echo "upstream_commit=$(cd "${UPSTREAM_DIR}" && git rev-parse HEAD)"
  echo "upstream_describe=$(cd "${UPSTREAM_DIR}" && git describe --tags --always 2>/dev/null || true)"
  echo "desktop_version=$(node -p "require('${DESKTOP_DIR}/package.json').version")"
  echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "host_arch=$(uname -m)"
  echo "node=$(node -v)"
} > "${DIST_DIR}/build-info.txt"

log "build complete — outputs in dist/"
ls -la "${DIST_DIR}"
