# Round 6 Runtime Capability Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align active Codex runtime permissions and role boundaries with the behaviors already promised by the agent and skill instructions.

**Architecture:** Keep the dispatcher, runtime contract, and Postman migration gate unchanged. Upgrade Seeker and Connector to the minimum write/edit capability required by their documented workflows, unify Sorter and `/inbox-triage` structural authority, and update custom-agent management docs plus smoke-test coverage.

**Tech Stack:** Markdown, shell smoke tests, Codex runtime instructions

---

### Task 1: Upgrade active capability declarations

**Files:**
- Modify: `agents/seeker.md`
- Modify: `agents/connector.md`

- [ ] Update `agents/seeker.md` tools and responsibility language so note editing is explicitly supported but runtime/system file mutation remains forbidden.
- [ ] Update `agents/connector.md` tools and workflow language so link application, MOC updates, and bridge-note creation are explicitly supported but structural governance remains Architect-only.
- [ ] Re-read both files and confirm the new tool lists match the strongest capability claim in each file.

### Task 2: Unify Sorter structural authority

**Files:**
- Modify: `agents/sorter.md`
- Modify: `skills/inbox-triage/SKILL.md`

- [ ] Replace contradictory folder-creation wording with a shared two-tier rule: low-risk local destination creation is allowed only under an existing structure; anything architectural escalates to Architect.
- [ ] Ensure both files describe the same fallback behavior when the correct destination is conceptually missing.
- [ ] Re-read both files side by side and confirm there is no contradictory language left.

### Task 3: Update custom-agent management inventory

**Files:**
- Modify: `skills/create-agent/SKILL.md`
- Modify: `skills/manage-agent/SKILL.md`

- [ ] Replace stale `8 core agents` wording with active-core-crew plus migration-gated Postman language.
- [ ] Preserve `postman` as a reserved core name in custom-agent naming rules.
- [ ] Ensure list/manage flows present the runtime inventory consistently with round-5 wording.

### Task 4: Add round-6 guard rail and registry updates

**Files:**
- Create: `tests/codex_runtime_capability_parity_smoke.sh`
- Modify: `func.md`
- Modify: `Status_2026-04-09_codex-migration.md`

- [ ] Add a smoke test that fails on capability/tool mismatches, stale `8 core agents` wording, and Sorter boundary drift.
- [ ] Register the new test entrypoint in `func.md`.
- [ ] Record round-6 goals, changes, and verification commands in the status file.

### Task 5: Verify full migration stack

**Files:**
- Verify only: `tests/codex_runtime_capability_parity_smoke.sh`
- Verify only: `tests/codex_runtime_inventory_smoke.sh`
- Verify only: `tests/codex_active_runtime_consistency_smoke.sh`
- Verify only: `tests/codex_runtime_behavior_smoke.sh`
- Verify only: `tests/codex_source_reference_smoke.sh`
- Verify only: `tests/install_runtime_smoke.sh`

- [ ] Run `bash tests/codex_runtime_capability_parity_smoke.sh`
- [ ] Run `bash tests/codex_runtime_inventory_smoke.sh`
- [ ] Run `bash tests/codex_active_runtime_consistency_smoke.sh`
- [ ] Run `bash tests/codex_runtime_behavior_smoke.sh`
- [ ] Run `bash tests/codex_source_reference_smoke.sh`
- [ ] Run `bash tests/install_runtime_smoke.sh`
- [ ] Run `bash -n tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`
