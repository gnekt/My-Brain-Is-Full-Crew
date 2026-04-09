# Round 10 Connector Graph Contract Design

## Goal

Tighten `connector` into a Codex-first graph agent whose default behavior is analysis and connection strengthening inside existing structure, with bridge-note creation treated as an explicit workflow rather than a default side effect.

## Current Problems

### 1. Connector still reads too close to structural governance

`agents/connector.md` currently risks drifting into Architect territory by over-emphasizing missing-MOC escalation and under-defining when existing graph surfaces are enough.

### 2. Bridge-note creation is too easy to over-assume

Connector has write access, but bridge-note creation should remain explicit. The contract should make it clear that the default is to surface an opportunity and outline, not silently create new artifacts.

### 3. Analysis modes can imply automatic graph rewrites

Full Graph Audit, Serendipity, Constellation, and Temporal Connections should remain analysis-first. They can recommend links, MOC updates, or bridge notes, but should not imply structural redesign by default.

### 4. Shared references still need to reflect the narrowed contract

The agent directory and registry should describe Connector as graph-first, existing-structure-first, and explicit about when Architect owns the next step.

## Scope

### In scope

- `agents/connector.md`
- `references/agents.md`
- `references/agents-registry.md`
- `tests/codex_connector_graph_contract_smoke.sh`
- `func.md`
- `Status_2026-04-09_codex-migration.md`

### Out of scope

- changing Connector tools
- redesigning Architect or Librarian behavior
- changing dispatcher routing in `AGENTS.md`
- inventing new graph workflows or data structures

## Design Decisions

### Decision 1: Connector is graph-first and existing-structure-first

Connector's primary job is to analyze relationships and strengthen links inside the structure that already exists.

### Decision 2: Bridge notes are explicit, not default

Connector may create a bridge note only when:

- the user explicitly asks for a bridge-note workflow, or
- the current mode is Bridge Notes and the user explicitly wants creation as the follow-through

Otherwise Connector should surface the opportunity and provide an outline.

### Decision 3: Architect escalation is for structural blockers, not every MOC gap

Connector should suggest Architect only when the missing piece is structural scaffolding that does not already exist and blocks correct interpretation or routing.

If an existing MOC can absorb the connection, or a bridge note can solve the gap inside the current graph, Connector should stay within its own lane.

### Decision 4: Analysis modes stay advisory by default

Full Graph Audit, Serendipity, Constellation, and Temporal Connections should explicitly read as analysis and suggestion modes. They should not imply automatic graph rewrites or structural changes.

## Verification Plan

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
