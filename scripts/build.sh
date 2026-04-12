#!/usr/bin/env bash
# =============================================================================
# scripts/build.sh — Run the platform adapter to populate dist/<platform>/
# =============================================================================
# Usage: bash scripts/build.sh --platform <name>
# Discovers available platforms by listing adapters/ subdirectories.
# =============================================================================
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

# ── Parse args ─────────────────────────────────────────────────────────────
PLATFORM="claude-code"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

# ── Validate platform ─────────────────────────────────────────────────────
if [[ ! -d "$REPO_ROOT/adapters/$PLATFORM" ]]; then
  AVAILABLE="$(ls "$REPO_ROOT/adapters/" 2>/dev/null | grep -v '^lib.sh$' | tr '\n' ' ')"
  die "Unknown platform: $PLATFORM. Available: $AVAILABLE"
fi

# ── Check dependencies ─────────────────────────────────────────────────────
case "$PLATFORM" in
  codex-cli) ;;
  *)
    command -v jq >/dev/null 2>&1 || die "jq is required for the build (install via brew, apt, etc.)"
    ;;
esac

# ── Source adapters ────────────────────────────────────────────────────────
# shellcheck source=adapters/lib.sh
source "$REPO_ROOT/adapters/lib.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/adapters/$PLATFORM/adapter.sh"

# ── Run the build ──────────────────────────────────────────────────────────
DIST_DIR="$REPO_ROOT/dist/$PLATFORM"
info "Building $PLATFORM → $DIST_DIR"
adapter_build "$REPO_ROOT" "$DIST_DIR"
success "Build complete"
