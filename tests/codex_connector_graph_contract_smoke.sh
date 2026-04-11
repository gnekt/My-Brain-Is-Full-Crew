#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

require() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if ! rg -n --fixed-strings "$pattern" "$file" >/dev/null; then
    echo "$message" >&2
    exit 1
  fi
}

forbid() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if rg -n --fixed-strings "$pattern" "$file" >/dev/null; then
    echo "$message" >&2
    exit 1
  fi
}

require agents/connector.md 'This agent is graph-first: it improves existing connections before it considers any new bridge artifact, and it does not take over structure design or governance.' 'Connector is missing the graph-first contract.'
require agents/connector.md 'You may write only graph-level knowledge artifacts inside existing structure:' 'Connector is missing the existing-structure write boundary.'
require agents/connector.md 'create bridge notes only when the user explicitly requests a bridge-note workflow or the current mode is Bridge Notes' 'Connector still over-allows bridge-note creation.'
require agents/connector.md 'If an existing MOC can plausibly absorb the connection, stay in Connector. If a bridge note can solve the gap inside the current graph, stay in Connector.' 'Connector is missing the narrowed Architect escalation rule.'
require agents/connector.md 'Default behavior: suggest the opportunity and outline first. Treat creation as an explicit follow-through, not the default outcome.' 'Connector bridge-note mode still defaults to creation.'
require agents/connector.md 'This mode is primarily analytical: report the graph shape, call out opportunities, and suggest targeted follow-up links or MOCs when they fit the existing structure. Do not frame it as automatic restructuring.' 'Connector full graph audit still implies automatic restructuring.'

require references/agents.md 'Analyzes the vault'\''s link structure, discovers missing connections between notes, suggests wikilinks, updates existing MOCs, and strengthens the knowledge graph inside existing structure.' 'Shared agent directory is missing the narrowed Connector summary.'
require references/agents.md 'Bridge notes are explicit follow-through artifacts, not the default outcome of graph analysis.' 'Shared agent directory is missing the explicit bridge-note rule.'
require references/agents-registry.md 'Add/edit wikilinks, update existing MOCs, analyze graph structure, discover connections, and create bridge notes only in explicit bridge-note workflows' 'Agent registry is missing the narrowed Connector capability summary.'
require references/agents-registry.md 'New wikilinks added, existing MOCs strengthened, graph health score, connection maps, or bridge-note opportunities' 'Agent registry output still implies broad bridge-note creation.'

forbid agents/connector.md 'a cluster of 3+ interconnected notes with no MOC' 'Connector still contains the stale mandatory 3+ cluster escalation rule.'
forbid references/agents.md 'Handles serendipity mode, bridge notes, constellation view, and people network analysis.' 'Shared agent directory still uses the older broad Connector wording.'

echo "codex_connector_graph_contract_smoke: PASS"
