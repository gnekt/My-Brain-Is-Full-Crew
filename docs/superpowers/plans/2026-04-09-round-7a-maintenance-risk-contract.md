# Round 7A Maintenance Risk Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the active maintenance chain to one shared Codex-first risk contract so low-risk fixes can execute directly while medium-risk and high-risk changes always flow through a pending approval plan.

**Architecture:** Keep the current dispatcher, active crew, and maintenance entrypoints intact. Update only the maintenance-chain instruction surfaces so `librarian`, `/vault-audit`, `/deep-clean`, `/tag-garden`, and `/defrag` all share the same output structure, the same risk-tier boundary, and the same Architect escalation behavior.

**Tech Stack:** Markdown runtime instructions, shell smoke tests, Codex runtime docs

---

### Task 1: Establish the shared maintenance contract at the entry surface

**Files:**
- Modify: `agents/librarian.md`

- [ ] Rewrite the librarian maintenance modes so they consistently output `Scan Summary`, `Auto-Applied Low-Risk Fixes`, `Pending Approval Plan`, and `Suggested Next Agent`.
- [ ] Replace loose prompt endings such as "Want me to run a deep clean?" and "Want me to auto-fix..." with plan-based approval wording that matches pigo's balanced mode.
- [ ] Re-read quick health, consistency, and stale-content sections and confirm that low-risk fixes are the only actions that can happen without approval.

### Task 2: Align the full-audit surfaces to the same risk tiers

**Files:**
- Modify: `skills/vault-audit/SKILL.md`
- Modify: `skills/deep-clean/SKILL.md`

- [ ] Add explicit low-risk, medium-risk, and high-risk maintenance language to `/vault-audit`.
- [ ] Ensure `/vault-audit` keeps duplicate merges, archive moves, taxonomy edits, and major MOC rewrites inside `Pending Approval Plan`.
- [ ] Mirror the same contract in `/deep-clean` so deeper scanning does not imply broader autonomous authority.
- [ ] Re-read both files side by side and confirm they describe the same approval boundary for duplicates, archive moves, taxonomy changes, and MOC rewrites.

### Task 3: Normalize maintenance sub-modes and narrow defrag authority

**Files:**
- Modify: `skills/tag-garden/SKILL.md`
- Modify: `skills/defrag/SKILL.md`

- [ ] Update `/tag-garden` so format-only normalization remains low-risk while semantic merges and taxonomy edits move into `Pending Approval Plan`.
- [ ] Remove wording in `/defrag` that promises proactive area creation, new MOC systems, new template families, or vault-structure evolution.
- [ ] Rewrite `/defrag` so it still performs structural inspection and low-risk structural repair, but routes architecture-level work to approval or Architect escalation.
- [ ] Re-read both files and confirm they now use the same shared contract rather than their own local approval models.

### Task 4: Add round-7A guard rail and record the work

**Files:**
- Create: `tests/codex_maintenance_risk_contract_smoke.sh`
- Modify: `func.md`
- Modify: `Status_2026-04-09_codex-migration.md`

- [ ] Add a smoke test that fails when the maintenance chain does not distinguish low-risk auto-fixes from approval-required work.
- [ ] Make the smoke test fail if `skills/defrag/SKILL.md` still promises proactive structure evolution or if `agents/librarian.md` still uses legacy loose-prompt endings.
- [ ] Make the smoke test fail if `skills/tag-garden/SKILL.md` still treats semantic tag merges as a separate approval model.
- [ ] Register the new smoke-test entrypoint in `func.md`.
- [ ] Record round-7A goals, implemented changes, and verification commands in `Status_2026-04-09_codex-migration.md`.

### Task 5: Verify the full migration stack after round 7A

**Files:**
- Verify only: `tests/codex_maintenance_risk_contract_smoke.sh`
- Verify only: `tests/codex_runtime_capability_parity_smoke.sh`
- Verify only: `tests/codex_runtime_inventory_smoke.sh`
- Verify only: `tests/codex_active_runtime_consistency_smoke.sh`
- Verify only: `tests/codex_runtime_behavior_smoke.sh`
- Verify only: `tests/codex_source_reference_smoke.sh`
- Verify only: `tests/install_runtime_smoke.sh`

- [ ] Run `bash tests/codex_maintenance_risk_contract_smoke.sh`
- [ ] Run `bash tests/codex_runtime_capability_parity_smoke.sh`
- [ ] Run `bash tests/codex_runtime_inventory_smoke.sh`
- [ ] Run `bash tests/codex_active_runtime_consistency_smoke.sh`
- [ ] Run `bash tests/codex_runtime_behavior_smoke.sh`
- [ ] Run `bash tests/codex_source_reference_smoke.sh`
- [ ] Run `bash tests/install_runtime_smoke.sh`
- [ ] Run `bash -n tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`
