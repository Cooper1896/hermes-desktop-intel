#!/usr/bin/env bash
# Verify macOS x64 Hermes Desktop artifacts and write dist/SHA256SUMS.

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_cmd file
require_cmd lipo
require_cmd shasum
ensure_dist

FAIL=0

APP="${DIST_DIR}/Hermes.app"
if [[ ! -d "${APP}" ]]; then
  if APP_PATH="$(find_hermes_app 2>/dev/null)"; then
    log "using upstream app at ${APP_PATH}"
    APP="${APP_PATH}"
  else
    die "Hermes.app not found. Run ./scripts/build-desktop-mac-x64.sh first"
  fi
fi

BIN="${APP}/Contents/MacOS/Hermes"
if [[ ! -f "${BIN}" ]]; then
  # Some builds use product executable name variants
  BIN="$(find "${APP}/Contents/MacOS" -type f -perm +111 2>/dev/null | head -n1 || true)"
fi
[[ -n "${BIN}" && -f "${BIN}" ]] || die "main executable not found under ${APP}/Contents/MacOS"

log "inspecting ${BIN}"
FILE_OUT="$(file "${BIN}")"
log "file: ${FILE_OUT}"

LIPO_OUT="$(lipo -info "${BIN}" 2>/dev/null || true)"
log "lipo: ${LIPO_OUT}"

if echo "${FILE_OUT}" | grep -q 'arm64' && ! echo "${FILE_OUT}" | grep -q 'x86_64'; then
  warn "binary appears arm64-only"
  FAIL=1
fi

if ! echo "${FILE_OUT}${LIPO_OUT}" | grep -q 'x86_64'; then
  warn "x86_64 not found in file/lipo output"
  FAIL=1
fi

# Prefer pure x86_64; allow universal if x86_64 slice present
if echo "${LIPO_OUT}" | grep -qi 'Non-fat' && echo "${FILE_OUT}" | grep -q 'x86_64'; then
  log "thin x86_64 binary OK"
elif echo "${LIPO_OUT}" | grep -q 'x86_64'; then
  log "fat/universal binary contains x86_64 OK"
else
  warn "could not confirm x86_64 slice"
  FAIL=1
fi

# node-pty staging paths inside asarUnpack / Resources
log "searching for node-pty darwin-x64 payload"
PTY_HITS="$(find "${APP}/Contents" \( -path '*darwin-x64*' -o -path '*prebuilds/darwin-x64*' \) 2>/dev/null | head -n 20 || true)"
if [[ -z "${PTY_HITS}" ]]; then
  # Also look for pty.node that is x86_64
  PTY_NODE="$(find "${APP}/Contents" -name 'pty.node' 2>/dev/null | head -n 5 || true)"
  if [[ -n "${PTY_NODE}" ]]; then
    while IFS= read -r n; do
      [[ -z "$n" ]] && continue
      nf="$(file "$n" 2>/dev/null || true)"
      log "pty.node: ${n} → ${nf}"
      if echo "$nf" | grep -q 'x86_64'; then
        PTY_HITS="${n}"
      fi
    done <<< "${PTY_NODE}"
  fi
fi

if [[ -z "${PTY_HITS}" ]]; then
  warn "no darwin-x64 / x86_64 node-pty payload found (terminal features may break)"
  # Soft fail: upstream layout may change; don't hard-fail if main bin is x64
  warn "continuing without hard-fail on node-pty (review if terminals fail at runtime)"
else
  log "node-pty related paths:"
  echo "${PTY_HITS}" | while read -r line; do log "  ${line}"; done
fi

# Checksums for everything in dist that looks like a shippable artifact
log "writing ${DIST_DIR}/SHA256SUMS"
(
  cd "${DIST_DIR}"
  : > SHA256SUMS
  shopt -s nullglob
  for f in Hermes-*.dmg Hermes-*.zip build-info.txt; do
    if [[ -f "$f" ]]; then
      shasum -a 256 "$f" >> SHA256SUMS
    fi
  done
  if [[ -d Hermes.app ]]; then
    # Hash a deterministic tar stream of the app for integrity
    tar -cf - Hermes.app | shasum -a 256 | awk '{print $1 "  Hermes.app (tar stream)"}' >> SHA256SUMS
  fi
  shopt -u nullglob
)

if [[ ! -s "${DIST_DIR}/SHA256SUMS" ]]; then
  # App only in upstream release — still emit sum for binary
  shasum -a 256 "${BIN}" | sed "s|${BIN}|Hermes.app/Contents/MacOS/Hermes|" > "${DIST_DIR}/SHA256SUMS"
fi

log "SHA256SUMS:"
cat "${DIST_DIR}/SHA256SUMS"

if [[ "$FAIL" -ne 0 ]]; then
  die "verification FAILED — do not ship these artifacts"
fi

log "verification PASSED"
