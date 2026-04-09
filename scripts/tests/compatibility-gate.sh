#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d)"
VAULT_DIR="$TMP_ROOT/vault"
WORK_DIR="$VAULT_DIR/My-Brain-Is-Full-Crew"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$VAULT_DIR"
cp -R "$REPO_DIR" "$WORK_DIR"

pushd "$WORK_DIR" >/dev/null

# Claude installer smoke test
printf 'y\nn\n' | bash scripts/launchme.sh >/tmp/crew-claude-install.log
[[ -d "$VAULT_DIR/.claude/agents" ]]
[[ -d "$VAULT_DIR/.claude/skills" ]]
[[ -f "$VAULT_DIR/CLAUDE.md" ]]
[[ "$(find "$VAULT_DIR/.claude/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')" == "8" ]]
[[ "$(find "$VAULT_DIR/.claude/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')" == "13" ]]

# Codex installer smoke test
printf 'y\nn\n' | bash scripts/launchme-codex.sh >/tmp/crew-codex-install.log
[[ -d "$VAULT_DIR/.codex/agents" ]]
[[ -d "$VAULT_DIR/.codex/skills" ]]
[[ -d "$VAULT_DIR/.codex/references" ]]
[[ -f "$VAULT_DIR/AGENTS.md" ]]
[[ "$(find "$VAULT_DIR/.codex/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')" == "8" ]]
[[ "$(find "$VAULT_DIR/.codex/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')" == "13" ]]

# Token rewrite guard for Codex runtime
if grep -RInE "\\.claude/|\\bCLAUDE\\.md\\b|AskUserQuestion|Skill tool|Agent tool" "$VAULT_DIR/.codex"; then
  echo "Found unresolved Claude-specific tokens in .codex runtime" >&2
  exit 1
fi

# Cross-contamination guard: Codex installer must not touch Claude runtime
CLAUDE_MD_BEFORE="$(cat "$VAULT_DIR/CLAUDE.md")"

# Updater smoke tests
printf 'c\n' | bash scripts/updateme.sh >/tmp/crew-claude-update.log
printf 'c\n' | bash scripts/updateme-codex.sh >/tmp/crew-codex-update.log

[[ -d "$VAULT_DIR/.claude/agents" ]]
[[ -d "$VAULT_DIR/.codex/agents" ]]

# Verify Claude files were not modified by Codex operations
CLAUDE_MD_AFTER="$(cat "$VAULT_DIR/CLAUDE.md")"
[[ "$CLAUDE_MD_BEFORE" == "$CLAUDE_MD_AFTER" ]] || { echo "Codex updater modified CLAUDE.md" >&2; exit 1; }

echo "compatibility-gate.sh passed"
popd >/dev/null

