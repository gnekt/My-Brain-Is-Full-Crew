#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if ! rg -n 'Low-risk work you may auto-apply' agents/librarian.md >/dev/null; then
  echo "Librarian is missing the low-risk maintenance contract." >&2
  exit 1
fi

if ! rg -n 'Work that requires approval first' agents/librarian.md >/dev/null; then
  echo "Librarian is missing the approval-required maintenance contract." >&2
  exit 1
fi

if ! rg -n '\*\*Low-risk\*\*:' skills/vault-audit/SKILL.md >/dev/null; then
  echo "Vault Audit is missing the explicit low-risk maintenance contract." >&2
  exit 1
fi

if ! rg -n 'Pending Approval Plan' skills/vault-audit/SKILL.md >/dev/null; then
  echo "Vault Audit is missing the Pending Approval Plan boundary." >&2
  exit 1
fi

if ! rg -n '\*\*Low-risk\*\*:' skills/deep-clean/SKILL.md >/dev/null; then
  echo "Deep Clean is missing the explicit low-risk maintenance contract." >&2
  exit 1
fi

if ! rg -n 'Pending Approval Plan' skills/deep-clean/SKILL.md >/dev/null; then
  echo "Deep Clean is missing the Pending Approval Plan boundary." >&2
  exit 1
fi

if ! rg -n '\*\*Low-risk\*\*:' skills/defrag/SKILL.md >/dev/null; then
  echo "Defrag is missing the explicit low-risk vs approval-required maintenance contract." >&2
  exit 1
fi

if ! rg -n 'Pending Approval Plan' skills/defrag/SKILL.md >/dev/null; then
  echo "Defrag is missing the approval-required maintenance contract." >&2
  exit 1
fi

if ! rg -n '\*\*Low-risk\*\*:' skills/tag-garden/SKILL.md >/dev/null; then
  echo "Tag Garden is missing the explicit low-risk vs approval-required maintenance contract." >&2
  exit 1
fi

if ! rg -n 'Pending Approval Plan' skills/tag-garden/SKILL.md >/dev/null; then
  echo "Tag Garden is missing the approval-required maintenance contract." >&2
  exit 1
fi

if ! rg -n '### Phase 4: Structural Escalation' skills/defrag/SKILL.md >/dev/null; then
  echo "Defrag is missing the structural-escalation phase that replaces autonomous structure evolution." >&2
  exit 1
fi

if ! rg -n 'do \*\*not\*\* create the structure proactively|Do not update `Meta/vault-structure\.md` as an autonomous action' skills/defrag/SKILL.md >/dev/null; then
  echo "Defrag is missing the explicit prohibition on autonomous structural expansion." >&2
  exit 1
fi

if rg -n 'Want me to|Would you like me to|If you want, I can|let me know if you want' agents/librarian.md >/dev/null; then
  echo "Librarian still uses legacy loose prompts instead of direct maintenance language." >&2
  exit 1
fi

if rg -n 'independent approval model|independent approval' skills/tag-garden/SKILL.md >/dev/null; then
  echo "Tag Garden still describes an independent approval model." >&2
  exit 1
fi

if ! rg -n 'semantic changes belong in `Pending Approval Plan`' skills/tag-garden/SKILL.md >/dev/null; then
  echo "Tag Garden is missing the shared Pending Approval Plan boundary for semantic changes." >&2
  exit 1
fi

if ! rg -n 'semantic tag merges, taxonomy edits, adding or removing taxonomy entries|semantic merges, taxonomy edits, and additions or removals from `Meta/tag-taxonomy.md`' skills/tag-garden/SKILL.md >/dev/null; then
  echo "Tag Garden is missing the semantic change examples for the Pending Approval Plan boundary." >&2
  exit 1
fi

echo "codex_maintenance_risk_contract_smoke: PASS"
