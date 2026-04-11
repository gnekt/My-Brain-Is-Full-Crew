# Round 8 Scribe Capture Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Scribe into a Codex-first fast-capture agent so default capture writes directly, low-risk local structure follows the shared runtime boundary, and rich capture modes stop implying heavyweight default workflows.

**Architecture:** Keep Scribe as the active text-capture agent and preserve its mode catalog, but tighten the runtime contract in `agents/scribe.md` and the shared references around one fast-capture-first model. Add one dedicated smoke test to guard the new direct-write default, the shared structure boundary, and the lighter-weight handling of thread, reading, and brainstorm capture.

**Tech Stack:** Markdown runtime instructions, shell smoke tests, Codex runtime docs

---

### Task 1: Rewrite Scribe default capture and structure boundary

**Files:**
- Modify: `agents/scribe.md`

- [ ] Remove the default requirement that Scribe must present the final note and ask for confirmation before saving.
- [ ] Rewrite the normal capture contract so low-risk capture cleans the input, structures it, and writes directly to `00-Inbox/`.
- [ ] Replace the current universal "Inbox + Architect" missing-structure rule with the round-6 boundary: low-risk local structure inside an existing area or project may be created directly, while new area / new project structure / new MOC system / new template family still escalates to `Architect`.
- [ ] Keep Inbox fallback wording, but make it situational for unclear routing or architecture-level missing structure rather than the default for every missing folder.

### Task 2: Lighten the richer Scribe modes without deleting them

**Files:**
- Modify: `agents/scribe.md`

- [ ] Rewrite `Thread Capture` so it defaults to one structured thread capture note first, with optional splitting only when the content is clearly separable and the split materially helps later use.
- [ ] Rewrite `Reading Notes` so it preserves source, reflections, and useful structure without implying a mandatory heavyweight chapterized workflow on every run.
- [ ] Rewrite `Brainstorm` so it preserves raw idea energy in one primary capture artifact and treats clusters, hot takes, and next steps as optional additions rather than required outputs.
- [ ] Re-read `Voice-to-Note`, the mode index, and any closing guidance to confirm they do not contradict the new fast-capture-first contract.

### Task 3: Align the shared agent references to the new Scribe contract

**Files:**
- Modify: `references/agents.md`
- Modify: `references/agents-registry.md`

- [ ] Update the Scribe summary in `references/agents.md` so it describes direct low-risk capture, lighter-weight rich modes, and architecture-level escalation to `Architect`.
- [ ] Update the Scribe row in `references/agents-registry.md` so capabilities, input, and output reflect the fast-capture contract rather than heavier implied multi-artifact workflows.
- [ ] Re-read both reference files and confirm they no longer imply default pre-save confirmation or mandatory derivative outputs for thread, reading, or brainstorm captures.

### Task 4: Add the round-8 guard rail and record the migration state

**Files:**
- Create: `tests/codex_scribe_capture_contract_smoke.sh`
- Modify: `func.md`
- Modify: `Status_2026-04-09_codex-migration.md`

- [ ] Add a smoke test that fails if `agents/scribe.md` still requires default pre-save confirmation.
- [ ] Make the smoke test fail if Scribe still treats every missing structure as unconditional `00-Inbox/` plus `Architect` fallback.
- [ ] Make the smoke test fail if Scribe is missing the explicit low-risk local-structure allowance or if the richer modes still promise heavyweight default derivative outputs.
- [ ] Make the smoke test fail if `references/agents.md` or `references/agents-registry.md` drift away from the rewritten Scribe contract.
- [ ] Register the new smoke-test entrypoint in `func.md`.
- [ ] Record the round-8 Scribe objective, implemented contract changes, and verification commands in `Status_2026-04-09_codex-migration.md`.

### Task 5: Verify the full migration stack after round 8

**Files:**
- Verify only: `tests/codex_scribe_capture_contract_smoke.sh`
- Verify only: `tests/codex_transcribe_intake_smoke.sh`
- Verify only: `tests/codex_maintenance_risk_contract_smoke.sh`
- Verify only: `tests/codex_runtime_capability_parity_smoke.sh`
- Verify only: `tests/codex_runtime_inventory_smoke.sh`
- Verify only: `tests/codex_active_runtime_consistency_smoke.sh`
- Verify only: `tests/codex_runtime_behavior_smoke.sh`
- Verify only: `tests/codex_source_reference_smoke.sh`
- Verify only: `tests/install_runtime_smoke.sh`

- [ ] Run `bash tests/codex_scribe_capture_contract_smoke.sh`
- [ ] Run `bash tests/codex_transcribe_intake_smoke.sh`
- [ ] Run `bash tests/codex_maintenance_risk_contract_smoke.sh`
- [ ] Run `bash tests/codex_runtime_capability_parity_smoke.sh`
- [ ] Run `bash tests/codex_runtime_inventory_smoke.sh`
- [ ] Run `bash tests/codex_active_runtime_consistency_smoke.sh`
- [ ] Run `bash tests/codex_runtime_behavior_smoke.sh`
- [ ] Run `bash tests/codex_source_reference_smoke.sh`
- [ ] Run `bash tests/install_runtime_smoke.sh`
- [ ] Run `bash -n tests/codex_scribe_capture_contract_smoke.sh tests/codex_transcribe_intake_smoke.sh tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`
