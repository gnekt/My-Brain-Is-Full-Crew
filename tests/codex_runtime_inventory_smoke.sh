#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if rg -n '8 specialized agents|8 core agents|The Eight Agents|all 8 agents|8 lightweight crew agents|The 13 specialized skills|13 specialized skills for complex flows' \
  README.md \
  skills/onboarding/SKILL.md \
  docs/getting-started.md \
  references/agents.md \
  references/agents-registry.md
then
  echo "Found stale runtime inventory wording that treats gated units as active." >&2
  exit 1
fi

if ! rg -n '7 active agents \+ 1 migration-gated role|7 active agents, plus 1 migration-gated Postman role|7 active agents \+ 1 gated' \
  README.md \
  skills/onboarding/SKILL.md \
  docs/getting-started.md >/dev/null
then
  echo "Active agent inventory wording is missing from the current runtime docs." >&2
  exit 1
fi

if ! rg -n '9 active skills \+ 4 migration-gated Postman skills|9 active skills \+ 4 gated|9 active skills plus 4 migration-gated Postman skills' \
  README.md \
  docs/getting-started.md >/dev/null
then
  echo "Active skill inventory wording is missing from the current runtime docs." >&2
  exit 1
fi

echo "codex_runtime_inventory_smoke: PASS"
