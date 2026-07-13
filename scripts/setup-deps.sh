#!/usr/bin/env bash
# Check local toolchain for building Hermes Desktop (macOS x64).

set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

FAIL=0

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    log "found ${name}: $(command -v "$name")"
  else
    warn "missing: ${name}"
    FAIL=1
  fi
}

log "HDFI dependency check (host arch: $(uname -m))"
log "repo: ${HDFI_ROOT}"

check_cmd git
check_cmd file
check_cmd lipo
check_cmd codesign
check_cmd shasum
check_cmd npm

if command -v node >/dev/null 2>&1; then
  NODE_VER="$(node -v | sed 's/^v//')"
  log "found node: v${NODE_VER}"
  # Accept ^20.19 || >=22.12 (same family as apps/desktop engines)
  if version_ge "$NODE_VER" "22.12.0"; then
    :
  elif version_ge "$NODE_VER" "20.19.0" && ! version_ge "$NODE_VER" "21.0.0"; then
    :
  else
    warn "Node ${NODE_VER} may be outside engines (^20.19 || >=22.12). Prefer Node 22 LTS."
    FAIL=1
  fi
else
  warn "missing: node (install Node 22 LTS: brew install node@22 / nvm install 22)"
  FAIL=1
fi

if command -v python3 >/dev/null 2>&1; then
  PY_VER="$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])')"
  log "found python3: ${PY_VER}"
  if ! version_ge "$PY_VER" "3.11.0"; then
    warn "Python ${PY_VER} < 3.11 (Hermes agent expects 3.11+)"
    FAIL=1
  fi
else
  warn "missing: python3 (>=3.11 recommended for agent runtime)"
  FAIL=1
fi

if xcode-select -p >/dev/null 2>&1; then
  log "Xcode CLT: $(xcode-select -p)"
else
  warn "Xcode Command Line Tools not found. Run: xcode-select --install"
  FAIL=1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "not running on macOS; mac packaging will fail on this host"
  FAIL=1
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
  warn "host is $(uname -m), not x86_64 — you can still cross-build Electron --x64, but smoke-test on Intel"
fi

if [[ -n "${ELECTRON_MIRROR:-}" ]]; then
  log "ELECTRON_MIRROR=${ELECTRON_MIRROR}"
else
  log "ELECTRON_MIRROR unset (default Electron CDN). Set if downloads hang, e.g.:"
  log "  export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/"
fi

if [[ -f "${UPSTREAM_DIR}/package.json" ]]; then
  log "upstream present: ${UPSTREAM_DIR}"
else
  warn "upstream not initialized — run ./scripts/pin-upstream.sh"
fi

if [[ "$FAIL" -ne 0 ]]; then
  die "dependency check failed — fix the warnings above and re-run"
fi

log "dependency check passed"
