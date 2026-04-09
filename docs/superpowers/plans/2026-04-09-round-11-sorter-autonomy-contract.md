# Round 11 Sorter Autonomy Contract Implementation Plan

**Goal:** Align Sorter and `/inbox-triage` to an autonomy-first, non-blocking contract so safe triage work happens immediately, unsafe items are deferred cleanly, and summary/reporting layers stay downstream of filing.

## Tasks

### Task 1: Tighten Sorter and inbox-triage behavior

- Update `agents/sorter.md`
- Update `skills/inbox-triage/SKILL.md`
- Make Smart Batch, Priority Triage, and ambiguous-note handling non-blocking
- Keep round-6 structure escalation rules intact

### Task 2: Align shared references

- Update `references/agents.md`
- Update `references/agents-registry.md`
- Describe Sorter as autonomy-first triage with safe deferral

### Task 3: Add guard rail and record migration state

- Create `tests/codex_sorter_autonomy_contract_smoke.sh`
- Register it in `func.md`
- Record objective, implementation, and verification in `Status_2026-04-09_codex-migration.md`

### Task 4: Verify the migration stack

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
