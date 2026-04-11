# Round 9 Seeker Search-Update Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Seeker into a retrieval-first and synthesis-first agent so search and citation remain primary, incidental edits stay narrowly bounded, and multi-source conflicts are analyzed rather than rewritten in-place.

**Architecture:** Keep Seeker as the active vault search agent and preserve its major synthesis modes, but tighten its runtime contract in `agents/seeker.md` and the shared references around one search-first model. Add a dedicated smoke test to guard the narrow write boundary, conflict-handling rules, and shared reference wording.

**Tech Stack:** Markdown runtime instructions, shell smoke tests, Codex runtime docs

---

### Task 1: Rewrite Seeker's top-level contract and write boundary

**Files:**
- Modify: `agents/seeker.md`

- [ ] Tighten the top-level description so Seeker is primarily about search, retrieval, synthesis, and answering from existing notes.
- [ ] Rewrite `Runtime Write Boundary` so allowed incidental edits are explicitly limited to obvious typos, broken wikilinks, small frontmatter mistakes, small non-claim-changing factual corrections, and light formatting cleanup.
- [ ] Explicitly forbid claim-changing edits, direct conflict-resolution edits, broad maintenance sweeps, structural governance, and creating new notes.
- [ ] Re-read the inter-agent section to confirm Seeker still escalates maintenance, graph, and structure work to the correct downstream agents.

### Task 2: Align Seeker's synthesis modes to analysis-first conflict handling

**Files:**
- Modify: `agents/seeker.md`

- [ ] Update `Answer Mode` so conflicting sources are surfaced, cited, and explained, with optional suggested fixes but no direct note edits.
- [ ] Update `Timeline Mode` so chronological conflict or date disagreement is reported as analysis rather than silently normalized.
- [ ] Update `Diff Mode` so comparison remains analytical and does not imply that Seeker resolves contradictions in-place.
- [ ] Update `Missing Knowledge` if needed so contradiction discovery stays in `analyze + cite + suggest` territory rather than direct correction.

### Task 3: Align shared references to the narrower Seeker contract

**Files:**
- Modify: `references/agents.md`
- Modify: `references/agents-registry.md`

- [ ] Update the Seeker summary in `references/agents.md` so it describes retrieval-first behavior with only narrow incidental fixes.
- [ ] Update the Seeker row in `references/agents-registry.md` so capabilities and outputs reflect search-first behavior, bounded safe edits, and non-authoritative conflict handling.
- [ ] Re-read both reference files and confirm they no longer imply broad note-updating authority.

### Task 4: Add the round-9 guard rail and record the migration state

**Files:**
- Create: `tests/codex_seeker_search_update_contract_smoke.sh`
- Modify: `func.md`
- Modify: `Status_2026-04-09_codex-migration.md`

- [ ] Add a smoke test that fails if `agents/seeker.md` still frames Seeker as a broad update agent.
- [ ] Make the smoke test fail if the write boundary no longer constrains Seeker to the approved narrow incidental-edit set.
- [ ] Make the smoke test fail if Seeker still permits claim-changing edits, direct conflict resolution, broad maintenance edits, or note creation.
- [ ] Make the smoke test fail if the synthesis modes drift away from `analyze + cite + suggest` conflict handling or if shared references drift away from the rewritten contract.
- [ ] Register the new smoke-test entrypoint in `func.md`.
- [ ] Record the round-9 Seeker objective, implemented contract changes, and verification commands in `Status_2026-04-09_codex-migration.md`.

### Task 5: Verify the full migration stack after round 9

**Files:**
- Verify only: `tests/codex_seeker_search_update_contract_smoke.sh`
- Verify only: `tests/codex_scribe_capture_contract_smoke.sh`
- Verify only: `tests/codex_transcribe_intake_smoke.sh`
- Verify only: `tests/codex_maintenance_risk_contract_smoke.sh`
- Verify only: `tests/codex_runtime_capability_parity_smoke.sh`
- Verify only: `tests/codex_runtime_inventory_smoke.sh`
- Verify only: `tests/codex_active_runtime_consistency_smoke.sh`
- Verify only: `tests/codex_runtime_behavior_smoke.sh`
- Verify only: `tests/codex_source_reference_smoke.sh`
- Verify only: `tests/install_runtime_smoke.sh`

- [ ] Run `bash tests/codex_seeker_search_update_contract_smoke.sh`
- [ ] Run `bash tests/codex_scribe_capture_contract_smoke.sh`
- [ ] Run `bash tests/codex_transcribe_intake_smoke.sh`
- [ ] Run `bash tests/codex_maintenance_risk_contract_smoke.sh`
- [ ] Run `bash tests/codex_runtime_capability_parity_smoke.sh`
- [ ] Run `bash tests/codex_runtime_inventory_smoke.sh`
- [ ] Run `bash tests/codex_active_runtime_consistency_smoke.sh`
- [ ] Run `bash tests/codex_runtime_behavior_smoke.sh`
- [ ] Run `bash tests/codex_source_reference_smoke.sh`
- [ ] Run `bash tests/install_runtime_smoke.sh`
- [ ] Run `bash -n tests/codex_seeker_search_update_contract_smoke.sh tests/codex_scribe_capture_contract_smoke.sh tests/codex_transcribe_intake_smoke.sh tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`
