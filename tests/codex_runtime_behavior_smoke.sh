#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if rg -n 'AskUserQuestion' agents skills references AGENTS.md; then
  echo "Found AskUserQuestion references that are not valid in the Codex runtime." >&2
  exit 1
fi

if ! rg -n 'Migration-Gated Units' AGENTS.md >/dev/null; then
  echo "Dispatcher is missing the migration-gated unit contract." >&2
  exit 1
fi

if ! rg -n 'postman.*migration-gated|/email-triage.*migration-gated|/meeting-prep.*migration-gated|/weekly-agenda.*migration-gated|/deadline-radar.*migration-gated' references/agents-registry.md >/dev/null; then
  echo "Registry does not mark Postman runtime units as migration-gated." >&2
  exit 1
fi

if ! rg -n 'Codex Migration Gate' \
  agents/postman.md \
  skills/email-triage/SKILL.md \
  skills/meeting-prep/SKILL.md \
  skills/weekly-agenda/SKILL.md \
  skills/deadline-radar/SKILL.md >/dev/null
then
  echo "Postman runtime files are missing explicit migration-gate sections." >&2
  exit 1
fi

echo "codex_runtime_behavior_smoke: PASS"
