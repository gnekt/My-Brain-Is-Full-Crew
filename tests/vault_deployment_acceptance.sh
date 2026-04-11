#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_DIR="${1:-}"

if [[ -z "$VAULT_DIR" ]]; then
  echo "Usage: bash tests/vault_deployment_acceptance.sh /path/to/vault" >&2
  exit 1
fi

VAULT_DIR="${VAULT_DIR/#\~/$HOME}"
RUNTIME_DIR="$VAULT_DIR/.codex"

require_path() {
  local path="$1"
  local message="$2"
  [[ -e "$path" ]] || { echo "$message" >&2; exit 1; }
}

require_count() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  [[ "$expected" == "$actual" ]] || { echo "$message (expected $expected, got $actual)" >&2; exit 1; }
}

require_path "$VAULT_DIR" "Vault directory not found: $VAULT_DIR"
require_path "$RUNTIME_DIR/agents" "Missing deployed agents directory."
require_path "$RUNTIME_DIR/skills" "Missing deployed skills directory."
require_path "$RUNTIME_DIR/references" "Missing deployed references directory."
require_path "$RUNTIME_DIR/hooks" "Missing deployed hooks directory."
require_path "$RUNTIME_DIR/settings.json" "Missing deployed settings.json."
require_path "$VAULT_DIR/AGENTS.md" "Missing deployed workspace AGENTS.md."
require_path "$VAULT_DIR/Meta/states" "Missing Meta/states directory."
require_path "$VAULT_DIR/AGENTS.pre-codex-migration-2026-04-09.bak.md" "Missing backup of pre-deployment AGENTS.md."

agent_count="$(find "$RUNTIME_DIR/agents" -maxdepth 1 -name '*.md' ! -name '*-DEPRECATED.md' | wc -l | tr -d ' ')"
skill_count="$(find "$RUNTIME_DIR/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' | wc -l | tr -d ' ')"
hook_count="$(find "$RUNTIME_DIR/hooks" -maxdepth 1 -name '*.sh' | wc -l | tr -d ' ')"

require_count "8" "$agent_count" "Unexpected deployed agent count."
require_count "13" "$skill_count" "Unexpected deployed skill count."
require_count "3" "$hook_count" "Unexpected deployed hook count."

diff -q "$ROOT_DIR/AGENTS.md" "$VAULT_DIR/AGENTS.md" >/dev/null || { echo "Workspace AGENTS.md drift detected." >&2; exit 1; }
diff -q "$ROOT_DIR/settings.json" "$RUNTIME_DIR/settings.json" >/dev/null || { echo "settings.json drift detected." >&2; exit 1; }

for src in "$ROOT_DIR"/agents/*.md; do
  name="$(basename "$src")"
  diff -q "$src" "$RUNTIME_DIR/agents/$name" >/dev/null || { echo "Agent drift detected for $name." >&2; exit 1; }
done

for src in "$ROOT_DIR"/references/*.md; do
  name="$(basename "$src")"
  diff -q "$src" "$RUNTIME_DIR/references/$name" >/dev/null || { echo "Reference drift detected for $name." >&2; exit 1; }
done

for src in "$ROOT_DIR"/hooks/*.sh; do
  name="$(basename "$src")"
  diff -q "$src" "$RUNTIME_DIR/hooks/$name" >/dev/null || { echo "Hook drift detected for $name." >&2; exit 1; }
done

for src in "$ROOT_DIR"/skills/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$src")")"
  diff -q "$src" "$RUNTIME_DIR/skills/$skill_name/SKILL.md" >/dev/null || { echo "Skill drift detected for $skill_name." >&2; exit 1; }
done

if [[ -e "$VAULT_DIR/.mcp.json" ]]; then
  echo ".mcp.json exists even though MCP setup was skipped." >&2
  exit 1
fi

echo "vault_deployment_acceptance: PASS"
