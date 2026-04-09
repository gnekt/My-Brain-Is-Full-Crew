#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if ! rg -n '^tools: Read, Edit, Glob, Grep$' agents/seeker.md >/dev/null; then
  echo "Seeker tools do not match the documented edit-capable runtime contract." >&2
  exit 1
fi

if ! rg -n 'You may directly edit an existing note only when the change is an obvious, local incidental fix that is clearly safe and the user has asked for it\.' agents/seeker.md >/dev/null; then
  echo "Seeker no longer documents the narrow edit-capable runtime contract round 6 expects to support." >&2
  exit 1
fi

if ! rg -n 'Allowed incidental edits are limited to:' agents/seeker.md >/dev/null; then
  echo "Seeker is missing an explicit runtime write boundary." >&2
  exit 1
fi

if ! rg -n '^tools: Read, Write, Edit, Glob, Grep$' agents/connector.md >/dev/null; then
  echo "Connector tools do not match the documented graph-write runtime contract." >&2
  exit 1
fi

if ! rg -n 'create the bridge note if the user wants|create bridge notes when the workflow explicitly calls for one' agents/connector.md >/dev/null; then
  echo "Connector no longer documents bridge-note creation despite round 6 graph-write scope." >&2
  exit 1
fi

if ! rg -n 'You may write only graph-level knowledge artifacts' agents/connector.md >/dev/null; then
  echo "Connector is missing an explicit runtime write boundary." >&2
  exit 1
fi

if ! rg -n 'low-risk obvious subfolder is missing, you may create that local destination yourself' agents/sorter.md skills/inbox-triage/SKILL.md >/dev/null; then
  echo "Sorter runtime surfaces are missing the shared low-risk local creation rule." >&2
  exit 1
fi

if ! rg -n 'new area, new project structure, new MOC system, new `_index.md`, new template family, or any architecture-level design is needed' agents/sorter.md skills/inbox-triage/SKILL.md >/dev/null; then
  echo "Sorter runtime surfaces are missing the shared Architect-escalation boundary." >&2
  exit 1
fi

if rg -n '8 core agents|Core Agents \(8\)' skills/create-agent/SKILL.md skills/manage-agent/SKILL.md; then
  echo "Custom-agent management docs still contain stale 8-core-agent inventory wording." >&2
  exit 1
fi

if ! rg -n 'reserved core names|Active Core Crew \+ Migration-Gated Postman Role' skills/create-agent/SKILL.md skills/manage-agent/SKILL.md >/dev/null; then
  echo "Custom-agent management docs are missing the round-6 active/gated inventory wording." >&2
  exit 1
fi

echo "codex_runtime_capability_parity_smoke: PASS"
