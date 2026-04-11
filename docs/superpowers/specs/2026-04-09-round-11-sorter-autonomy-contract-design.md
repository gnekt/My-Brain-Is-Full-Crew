# Round 11 Sorter Autonomy Contract Design

## Goal

Tighten `sorter` and `/inbox-triage` into an autonomy-first, non-blocking triage workflow that files safe work immediately, leaves unsafe items in `00-Inbox/` with explicit reasons, and avoids turning inbox cleanup into a user-gated approval loop.

## Current Problems

### 1. Sorter still reads as too approval-heavy

Several triage modes still imply "present first, then file" or "ask if the user wants to continue", which raises friction for a workflow that should primarily reduce inbox backlog.

### 2. Ambiguous notes still risk blocking the whole run

Ambiguous destination handling should default to safe deferral, not conversation interruption.

### 3. Reporting and filing are still partially conflated

Project Pulse and summary reporting should be post-triage reporting layers, not gates that delay safe filing.

## Scope

### In scope

- `agents/sorter.md`
- `skills/inbox-triage/SKILL.md`
- `references/agents.md`
- `references/agents-registry.md`
- `tests/codex_sorter_autonomy_contract_smoke.sh`
- `func.md`
- `Status_2026-04-09_codex-migration.md`

### Out of scope

- changing Sorter tools
- changing Architect escalation rules chosen in round 6
- redesigning vault filing taxonomy

## Design Decisions

### Decision 1: Smart Batch files safe clusters immediately

Smart Batch should group notes, classify cluster risk, file low-risk clusters directly, and report deferred clusters afterward.

### Decision 2: Priority Triage is non-blocking

Priority Triage should complete `Critical`, `High`, and clear low-risk items in the same run, then leave ambiguous or medium-risk items in `00-Inbox/` with reasons.

### Decision 3: Ambiguous notes default to `Needs Review`

If a safe destination cannot be established from existing vault patterns, the note stays in `00-Inbox/` with a precise reason. Sorter continues the rest of the run.

### Decision 4: Project Pulse is reporting-only

Project Pulse should be generated after triage actions are complete. It must not act as a filing gate.

## Verification Plan

Run:

- `bash tests/codex_sorter_autonomy_contract_smoke.sh`
- `bash tests/codex_connector_graph_contract_smoke.sh`
- `bash tests/codex_seeker_search_update_contract_smoke.sh`
- `bash tests/codex_scribe_capture_contract_smoke.sh`
- `bash tests/codex_transcribe_intake_smoke.sh`
- `bash tests/codex_maintenance_risk_contract_smoke.sh`
- `bash tests/codex_runtime_capability_parity_smoke.sh`
- `bash tests/codex_runtime_inventory_smoke.sh`
- `bash tests/codex_active_runtime_consistency_smoke.sh`
- `bash tests/codex_runtime_behavior_smoke.sh`
- `bash tests/codex_source_reference_smoke.sh`
- `bash tests/install_runtime_smoke.sh`
