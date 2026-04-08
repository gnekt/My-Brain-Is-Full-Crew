#!/usr/bin/env bash
# =============================================================================
# scripts/build.sh — Run the framework adapter to populate dist/<framework>/
# =============================================================================
# Usage: bash scripts/build.sh --framework <name>
# Discovers available frameworks by listing adapters/ subdirectories.
# =============================================================================
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

# ── Parse args ─────────────────────────────────────────────────────────────
FRAMEWORK="claude-code"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --framework) FRAMEWORK="$2"; shift 2 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

# ── Validate framework ─────────────────────────────────────────────────────
if [[ ! -d "$REPO_ROOT/adapters/$FRAMEWORK" ]]; then
  AVAILABLE="$(ls "$REPO_ROOT/adapters/" 2>/dev/null | grep -v '^lib.sh$' | tr '\n' ' ')"
  die "Unknown framework: $FRAMEWORK. Available: $AVAILABLE"
fi

# ── Check dependencies ─────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || die "jq is required for the build (install via brew, apt, etc.)"

# ── Source adapters ────────────────────────────────────────────────────────
# shellcheck source=adapters/lib.sh
source "$REPO_ROOT/adapters/lib.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/adapters/$FRAMEWORK/adapter.sh"

# ── Run the build ──────────────────────────────────────────────────────────
DIST_DIR="$REPO_ROOT/dist/$FRAMEWORK"
info "Building $FRAMEWORK → $DIST_DIR"
adapter_build "$REPO_ROOT" "$DIST_DIR"
success "Build complete"
