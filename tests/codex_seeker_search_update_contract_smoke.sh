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

require agents/seeker.md 'You may directly edit an existing note only when the change is an obvious, local incidental fix that is clearly safe and the user has asked for it.' 'Seeker is missing the narrow incidental-edit boundary.'
require agents/seeker.md 'Allowed incidental edits are limited to:' 'Seeker is missing the explicit incidental-edit allowlist.'
require agents/seeker.md 'small factual corrections that do not change the note'\''s underlying claim' 'Seeker is missing the non-claim-changing factual fix rule.'
require agents/seeker.md 'If a user asks for something broader than the boundary above, analyze the issue, cite the relevant notes, and suggest the appropriate next agent instead of editing.' 'Seeker is missing the analyze-and-escalate fallback.'
require agents/seeker.md 'If it exists and is likely helpful for the current search, read `Meta/states/seeker.md`.' 'Seeker state-read timing is not conditional on usefulness.'
require agents/seeker.md 'These reads are background-only and non-blocking; they do not expand the vault search scope.' 'Seeker still treats profile/state reads as active search scope.'
require agents/seeker.md 'Priority rule: if a note can be moved into an obvious existing home, suggest `Sorter`; if the home is missing or the structure itself is the problem, suggest `Architect`.' 'Seeker is missing the Sorter-vs-Architect priority rule.'
require agents/seeker.md 'You may keep a short post-it at `Meta/states/seeker.md`. This is optional agent-local runtime state, not a user-facing vault note.' 'Seeker state file is not clearly carved out as agent-local runtime state.'
require agents/seeker.md 'Only refresh the post-it when it adds useful carryover context. Do not rewrite it on every run.' 'Seeker state updates are still too mandatory.'

require references/agents.md 'Search, Retrieval & Synthesis' 'Shared agent directory still uses the stale Seeker role label.'
require references/agents.md 'Finds and retrieves information across the vault using full-text search, metadata queries, and relationship navigation.' 'Shared agent directory is missing the retrieval-first Seeker summary.'
require references/agents.md 'May make narrow incidental fixes only when explicitly asked and only for obvious typos, broken wikilinks, small frontmatter mistakes, small factual corrections, or light formatting cleanup.' 'Shared agent directory is missing the narrow incidental-edit policy.'
require references/agents.md 'Handles timeline mode, diff mode, and missing knowledge detection without resolving conflicts in place.' 'Shared agent directory still implies in-place conflict resolution.'
require references/agents-registry.md 'Search, Retrieval & Synthesis' 'Agent registry still uses the stale Seeker role label.'
require references/agents-registry.md 'answer synthesis, and only narrow incidental fixes on explicit request. Read-only by default.' 'Agent registry is missing the retrieval-first / narrow-edit contract.'
require references/agents-registry.md 'Search results with citations, synthesized answers, knowledge gap reports, or small incidental corrections' 'Agent registry output still misses the bounded correction surface.'

forbid agents/seeker.md 'create brand-new notes unless another workflow explicitly hands that off to you' 'Seeker should not be granted broad note-creation authority.'
forbid agents/seeker.md 'write every run' 'Seeker still implies routine state-file writes.'
forbid agents/seeker.md 'ANY structural gap' 'Seeker still overreaches into general structure auditing.'
forbid references/agents.md 'Can modify notes on request.' 'Shared agent directory still grants broad note-update authority.'
forbid references/agents-registry.md 'Can modify notes on request' 'Agent registry still grants broad note-update authority.'

echo "codex_seeker_search_update_contract_smoke: PASS"
