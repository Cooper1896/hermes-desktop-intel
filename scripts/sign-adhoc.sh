#!/usr/bin/env bash
# Ad-hoc codesign Hermes.app for local testing without an Apple Developer ID.

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_cmd codesign

APP="${1:-${DIST_DIR}/Hermes.app}"

if [[ ! -d "${APP}" ]]; then
  # Try upstream release paths
  if APP_PATH="$(find_hermes_app 2>/dev/null)"; then
    APP="${APP_PATH}"
  else
    die "Hermes.app not found at ${APP}. Build first: ./scripts/build-desktop-mac-x64.sh"
  fi
fi

log "ad-hoc signing ${APP}"
codesign --force --deep --sign - "${APP}"
codesign --verify --verbose=2 "${APP}" || warn "codesign verify reported issues (often OK for ad-hoc)"

log "signed. If Gatekeeper blocks launch:"
log "  xattr -cr \"${APP}\""
log "  open \"${APP}\""
