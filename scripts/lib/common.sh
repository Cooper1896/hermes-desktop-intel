#!/usr/bin/env bash
# Shared helpers for HDFI scripts.

set -euo pipefail

HDFI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPSTREAM_DIR="${HDFI_ROOT}/upstream"
DIST_DIR="${HDFI_ROOT}/dist"
DESKTOP_DIR="${UPSTREAM_DIR}/apps/desktop"
BOOTSTRAP_DIR="${UPSTREAM_DIR}/apps/bootstrap-installer"

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_upstream() {
  if [[ ! -d "${UPSTREAM_DIR}/.git" && ! -f "${UPSTREAM_DIR}/.git" ]]; then
    if [[ ! -f "${UPSTREAM_DIR}/package.json" ]]; then
      die "upstream missing. Run: ./scripts/pin-upstream.sh"
    fi
  fi
  if [[ ! -f "${DESKTOP_DIR}/package.json" ]]; then
    die "upstream/apps/desktop not found. Run: ./scripts/pin-upstream.sh"
  fi
}

ensure_dist() {
  mkdir -p "${DIST_DIR}"
}

# Resolve Hermes.app after electron-builder (path varies by builder version/arch).
find_hermes_app() {
  local candidates=(
    "${DESKTOP_DIR}/release/mac-x64/Hermes.app"
    "${DESKTOP_DIR}/release/mac/Hermes.app"
    "${DESKTOP_DIR}/release/mac-universal/Hermes.app"
  )
  local c
  for c in "${candidates[@]}"; do
    if [[ -d "$c" ]]; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  # Fallback: first Hermes.app under release/
  local found
  found="$(find "${DESKTOP_DIR}/release" -maxdepth 3 -type d -name 'Hermes.app' 2>/dev/null | head -n1 || true)"
  if [[ -n "${found}" ]]; then
    printf '%s\n' "${found}"
    return 0
  fi
  return 1
}

version_ge() {
  # usage: version_ge "$have" "$need"  → 0 if have >= need
  local have="$1" need="$2"
  printf '%s\n%s\n' "$need" "$have" | sort -V | head -n1 | grep -qx "$need"
}
