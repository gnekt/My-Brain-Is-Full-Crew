#!/usr/bin/env bash

set -euo pipefail

VAULT_DIR="${1:-}"

if [[ -z "$VAULT_DIR" ]]; then
  echo "Usage: bash tests/vault_runtime_journey_acceptance.sh /path/to/vault" >&2
  exit 1
fi

VAULT_DIR="${VAULT_DIR/#\~/$HOME}"
RUNTIME_DIR="$VAULT_DIR/.codex"

require() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! rg -n --fixed-strings -- "$pattern" "$file" >/dev/null; then
    echo "$message" >&2
    exit 1
  fi
}

require "$VAULT_DIR/AGENTS.md" '## Active Core Skills' 'Deployed dispatcher is missing the active skill surface.'
require "$VAULT_DIR/AGENTS.md" '- `onboarding`' 'Onboarding journey is not exposed in deployed AGENTS.md.'
require "$VAULT_DIR/AGENTS.md" 'The production runtime is Codex-only.' 'Deployed dispatcher is not Codex-only.'
require "$VAULT_DIR/AGENTS.md" '.codex/agents/' 'Deployed dispatcher is missing the installed agent path contract.'

require "$RUNTIME_DIR/skills/transcribe/SKILL.md" 'the current Codex runtime cannot natively transcribe raw audio' 'Transcribe journey is missing the raw-audio gate in deployed runtime.'
require "$RUNTIME_DIR/skills/transcribe/SKILL.md" 'Purpose' 'Transcribe journey is missing the first-layer intake fields.'
require "$RUNTIME_DIR/agents/transcriber.md" 'All transcription processing is handled by the `/transcribe` skill.' 'Transcriber agent is not aligned to the deployed transcribe journey.'

require "$RUNTIME_DIR/agents/seeker.md" 'Find, retrieve, analyze, and synthesize information across the entire Obsidian vault.' 'Seeker journey is missing retrieval-first behavior.'
require "$RUNTIME_DIR/agents/seeker.md" 'Allowed incidental edits are limited to:' 'Seeker journey is missing its narrow edit boundary.'

require "$RUNTIME_DIR/agents/connector.md" 'This agent is graph-first: it improves existing connections before it considers any new bridge artifact' 'Connector journey is missing the graph-first contract.'
require "$RUNTIME_DIR/agents/connector.md" 'create bridge notes only when the user explicitly requests a bridge-note workflow or the current mode is Bridge Notes' 'Connector journey is missing explicit bridge-note gating.'

require "$RUNTIME_DIR/agents/sorter.md" 'Leave ambiguous or unsafe clusters in `00-Inbox/` with explicit reasons, then continue the rest of the batch' 'Sorter Smart Batch journey is still blocking.'
require "$RUNTIME_DIR/skills/inbox-triage/SKILL.md" '### Mode Extensions (Autonomy-First, Non-Blocking)' 'Inbox triage journey is missing autonomy-first mode extensions.'
require "$RUNTIME_DIR/skills/inbox-triage/SKILL.md" 'Needs Review' 'Inbox triage journey is missing non-blocking deferred review behavior.'

echo "vault_runtime_journey_acceptance: PASS"
