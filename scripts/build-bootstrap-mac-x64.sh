#!/usr/bin/env bash
# Optional: build Tauri bootstrap installer for x86_64-apple-darwin.
# DMG packaging may fail on some hosts; we always try to ship a .app zip.

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_cmd npm
require_cmd node
require_upstream
ensure_dist

if [[ ! -f "${BOOTSTRAP_DIR}/package.json" ]]; then
  die "bootstrap-installer not present at ${BOOTSTRAP_DIR}"
fi

TARGET="${BOOTSTRAP_TARGET:-x86_64-apple-darwin}"
log "building bootstrap installer for ${TARGET}"

if ! command -v rustc >/dev/null 2>&1; then
  die "rustc not found. Install Rust (https://rustup.rs/) for Tauri bootstrap builds"
fi

if command -v rustup >/dev/null 2>&1; then
  log "ensuring rust target ${TARGET}"
  rustup target add "${TARGET}" || warn "rustup target add failed — continuing"
fi

cd "${UPSTREAM_DIR}"

log "npm install --workspace apps/bootstrap-installer"
npm install --workspace apps/bootstrap-installer

log "npm run build --workspace apps/bootstrap-installer"
npm run build --workspace apps/bootstrap-installer || warn "bootstrap JS build script failed or missing — trying tauri anyway"

set +e
npm run tauri:build --workspace apps/bootstrap-installer -- --target "${TARGET}"
TAURI_STATUS=$?
set -e

BUNDLE_MAC="${BOOTSTRAP_DIR}/src-tauri/target/${TARGET}/release/bundle/macos"
APP_CANDIDATE=""
if [[ -d "${BUNDLE_MAC}" ]]; then
  APP_CANDIDATE="$(find "${BUNDLE_MAC}" -maxdepth 1 -name '*.app' | head -n1 || true)"
fi
# Alternate product names
if [[ -z "${APP_CANDIDATE}" ]]; then
  APP_CANDIDATE="$(find "${BOOTSTRAP_DIR}/src-tauri/target/${TARGET}/release" -maxdepth 3 -name '*.app' 2>/dev/null | head -n1 || true)"
fi

if [[ -n "${APP_CANDIDATE}" && -d "${APP_CANDIDATE}" ]]; then
  BASE="$(basename "${APP_CANDIDATE}" .app)"
  OUT_ZIP="${DIST_DIR}/${BASE}-mac-x64-bootstrap.app.zip"
  log "zipping ${APP_CANDIDATE} → ${OUT_ZIP}"
  rm -f "${OUT_ZIP}"
  (
    cd "$(dirname "${APP_CANDIDATE}")"
    zip -ry "${OUT_ZIP}" "$(basename "${APP_CANDIDATE}")"
  )
  # Copy any DMG if present
  shopt -s nullglob
  for dmg in "${BOOTSTRAP_DIR}/src-tauri/target/${TARGET}/release/bundle/dmg"/*.dmg \
             "${BOOTSTRAP_DIR}/src-tauri/target/${TARGET}/release/bundle/macos"/*.dmg; do
    cp -f "$dmg" "${DIST_DIR}/$(basename "${dmg}" .dmg)-bootstrap-mac-x64.dmg" 2>/dev/null || \
      cp -f "$dmg" "${DIST_DIR}/"
    log "copied DMG $(basename "$dmg")"
  done
  shopt -u nullglob
  log "bootstrap app artifact ready"
else
  warn "no .app bundle found after tauri build (exit ${TAURI_STATUS})"
  if [[ "${TAURI_STATUS}" -ne 0 ]]; then
    die "bootstrap build failed"
  fi
fi

log "bootstrap build step finished"
