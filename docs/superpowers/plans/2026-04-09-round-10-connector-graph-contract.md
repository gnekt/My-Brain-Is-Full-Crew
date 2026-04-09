# Round 10 Connector Graph Contract Implementation Plan

**Goal:** Align Connector to a graph-first, existing-structure-first runtime contract so bridge-note creation stays explicit, structural escalation stays narrow, and shared references match the agent file.

## Tasks

### Task 1: Tighten Connector's runtime contract

- Update `agents/connector.md`
- Keep graph-strengthening inside existing structure
- Make bridge-note creation explicit-only
- Narrow Architect escalation to structural blockers
- Keep major analysis modes advisory by default

### Task 2: Align shared references

- Update `references/agents.md`
- Update `references/agents-registry.md`
- Describe Connector as graph-first with explicit bridge-note creation and narrow structural escalation

### Task 3: Add guard rail and record migration state

- Create `tests/codex_connector_graph_contract_smoke.sh`
- Register it in `func.md`
- Record objective, implementation, and verification in `Status_2026-04-09_codex-migration.md`

### Task 4: Verify the migration stack

Run:

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
