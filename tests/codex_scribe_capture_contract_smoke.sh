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

require agents/scribe.md 'Low-risk local structure inside an existing area or project may be created directly' 'Scribe is missing the explicit low-risk local-structure allowance.'
require agents/scribe.md 'Only fall back to `00-Inbox/` plus `### Suggested next agent` when the routing is unclear or the note exposes an architecture-level missing structure' 'Scribe is missing the conditional Inbox-plus-Architect fallback boundary.'
require agents/scribe.md 'Identify the thread'\''s main through-line and capture it as one structured thread note first' 'Thread Capture is missing the fast-capture-first thread contract.'
require agents/scribe.md 'Break out separate notes only when ideas are clearly separable and splitting would materially help later use' 'Thread Capture is missing the lightweight split rule.'
require agents/scribe.md 'Capture the source and the user'\''s useful takeaways without forcing a heavy chapter-by-chapter workflow' 'Reading Notes still defaults to a heavyweight chapter workflow.'
require agents/scribe.md 'Keep the source'\''s structure only when it is genuinely useful for later retrieval' 'Reading Notes is missing the lightweight structure rule.'
require agents/scribe.md 'Capture the main brainstorm as one primary artifact first' 'Brainstorm is missing the capture-first default.'
require agents/scribe.md 'Add clusters, hot takes, or next steps only when they naturally help the capture' 'Brainstorm still promises heavyweight derivative outputs by default.'
require references/agents.md 'Fast Text Capture & Refinement' 'Shared agent reference still describes Scribe with the wrong role label.'
require references/agents.md 'Writes direct, low-risk captures in existing structure when the destination is obvious, uses richer capture modes in lighter-weight default ways, and escalates only architecture-level structure to Architect.' 'Shared agent reference drifted away from the fast-capture contract.'
require references/agents.md 'Raw text, quick thoughts, voice dumps, quotes, reading notes, or brainstorms need to be captured fast without overbuilding the structure.' 'Shared agent reference is missing the new Scribe contact boundary.'
require references/agents-registry.md 'Fast Text Capture & Refinement' 'Agent registry still uses the stale Scribe role label.'
require references/agents-registry.md 'Capture raw text quickly, write direct low-risk notes in existing structure, escalate architecture-level structure to Architect, and handle voice-to-note, thread capture, reading notes, brainstorms, and quotes with lightweight defaults' 'Agent registry capabilities still miss the explicit Architect escalation and lightweight-default richer modes contract.'
require references/agents-registry.md 'Refined notes in the best-fit location with frontmatter, tags, and lightweight connections' 'Agent registry output still implies the old Inbox-only capture contract.'

forbid agents/scribe.md 'before saving, ask for confirmation' 'Scribe still requires a pre-save confirmation step.'
forbid agents/scribe.md 'confirm before saving' 'Scribe still requires a pre-save confirmation step.'
forbid agents/scribe.md 'pre-save confirmation' 'Scribe still requires a pre-save confirmation step.'
forbid agents/scribe.md 'always use `00-Inbox/`' 'Scribe still treats missing structure as unconditional Inbox fallback.'
forbid agents/scribe.md 'unconditional Inbox' 'Scribe still treats missing structure as unconditional Inbox fallback.'
forbid agents/scribe.md 'every missing structure' 'Scribe still treats missing structure as unconditional Inbox fallback.'
forbid agents/scribe.md 'Save immediately to the best-fit location, using `00-Inbox/` as the default capture landing zone and fallback.' 'Scribe top summary still treats Inbox as the default landing zone.'
forbid references/agents-registry.md 'Create notes in `00-Inbox/`,' 'Agent registry still claims Inbox-only Scribe capture.'
forbid references/agents-registry.md 'Structured notes in `00-Inbox/`' 'Agent registry still claims Inbox-only Scribe output.'

echo "codex_scribe_capture_contract_smoke: PASS"
