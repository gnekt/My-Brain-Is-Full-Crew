#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
TMP_REPO="$TMP_ROOT/My-Brain-Is-Full-Crew"
TMP_VAULT="$TMP_ROOT/TestVault"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

cp -R "$REPO_DIR" "$TMP_REPO"
mkdir -p "$TMP_VAULT"

pushd "$TMP_REPO" >/dev/null
printf 'n\n%s\nn\n' "$TMP_VAULT" | bash scripts/launchme.sh >/dev/null
popd >/dev/null

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || {
    echo "Missing expected path: $path" >&2
    exit 1
  }
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || {
    echo "Unexpected path present: $path" >&2
    exit 1
  }
}

assert_exists "$TMP_VAULT/.codex/agents"
assert_exists "$TMP_VAULT/.codex/skills"
assert_exists "$TMP_VAULT/.codex/references"
assert_exists "$TMP_VAULT/.codex/hooks"
assert_exists "$TMP_VAULT/.codex/settings.json"
assert_exists "$TMP_VAULT/AGENTS.md"
assert_not_exists "$TMP_VAULT/CLAUDE.md"

echo "install_runtime_smoke: PASS"
