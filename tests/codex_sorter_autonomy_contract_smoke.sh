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

require agents/sorter.md 'Classify each cluster by filing risk (low-risk clear destination vs ambiguous/unsafe destination)' 'Sorter Smart Batch is missing cluster risk classification.'
require agents/sorter.md 'File low-risk clusters immediately, ensuring related notes are cross-linked' 'Sorter Smart Batch no longer files low-risk clusters immediately.'
require agents/sorter.md 'Leave ambiguous or unsafe clusters in `00-Inbox/` with explicit reasons, then continue the rest of the batch' 'Sorter Smart Batch is still blocking on ambiguous clusters.'
require agents/sorter.md 'Leave ambiguous and medium-risk items in `00-Inbox/` with reasons, mark them for review, and continue without asking to pause' 'Sorter Priority Triage is still pause-driven.'
require agents/sorter.md 'Build a working summary and proceed with triage immediately (do not block on pre-approval):' 'Sorter still blocks on pre-approval before triage.'
require agents/sorter.md '| Unclear | Keep in Inbox, mark `Needs Review` | Ambiguous or unsafe — record reason and continue |' 'Sorter still routes unclear notes through user interruption.'
require agents/sorter.md '**Ambiguous destination**: do not ask the user by default.' 'Sorter conflict resolution still asks the user by default.'
require skills/inbox-triage/SKILL.md '### Mode Extensions (Autonomy-First, Non-Blocking)' 'Inbox triage is missing the autonomy-first mode section.'
require skills/inbox-triage/SKILL.md 'Generate a project activity report as a reporting layer, never as a filing gate' 'Inbox triage still conflates Project Pulse with filing.'

require references/agents.md 'Processes `00-Inbox/`, classifies notes, files clear low-risk items immediately, and leaves unsafe items in `Needs Review` without blocking the rest of triage.' 'Shared agent directory is missing the autonomy-first Sorter summary.'
require references/agents-registry.md 'Move notes from inbox to correct locations, update MOCs, batch processing, priority-first safe filing, and non-blocking deferral of ambiguous items' 'Agent registry is missing the autonomy-first Sorter capability summary.'

forbid agents/sorter.md 'Present grouped clusters to the user before filing' 'Sorter still requires pre-filing cluster approval.'
forbid agents/sorter.md 'Ask if the user wants to continue with lower-priority items or defer' 'Sorter still pauses after Priority Triage.'
forbid skills/inbox-triage/SKILL.md 'ask the user one concise clarification question in the main conversation' 'Inbox triage still defaults to asking the user during ambiguity handling.'

echo "codex_sorter_autonomy_contract_smoke: PASS"
