# Vault Deployment Test Plan

Date: 2026-04-09
Owner: Codex with pigo
Target Vault: `/Users/pigo/Documents/Pigo_Obsidian`

## Goal

Validate that the Codex-first runtime was deployed into the real vault correctly, that the installed runtime matches the source repository, and that the migration-gated choices were preserved during installation.

## Scope

- installed runtime under `.codex/`
- workspace-root `AGENTS.md`
- `Meta/states/` creation
- expected skip of `.mcp.json`
- source-to-runtime fidelity for core agents, skills, hooks, and references

## Test Cases

### 1. Deployment surface exists

Verify:

- `.codex/agents/`
- `.codex/skills/`
- `.codex/references/`
- `.codex/hooks/`
- `.codex/settings.json`
- workspace-root `AGENTS.md`
- `Meta/states/`

### 2. Core inventory counts match source

Verify:

- 8 agent markdown files in `.codex/agents/`
- 13 deployed skill directories containing `SKILL.md`
- 3 deployed hook scripts

### 3. Source/runtime fidelity

Verify deployed runtime matches repo source for:

- `agents/*.md`
- `skills/*/SKILL.md`
- `hooks/*.sh`
- `references/*.md`
- root `AGENTS.md`
- `settings.json`

### 4. Migration choices preserved

Verify:

- `.mcp.json` was not installed because external integrations were intentionally skipped
- previous vault-root `AGENTS.md` was backed up before overwrite

### 5. Repo regression safety

Run the full smoke-test stack in the repo before or alongside deployment acceptance:

- `codex_sorter_autonomy_contract_smoke`
- `codex_connector_graph_contract_smoke`
- `codex_seeker_search_update_contract_smoke`
- `codex_scribe_capture_contract_smoke`
- `codex_transcribe_intake_smoke`
- `codex_maintenance_risk_contract_smoke`
- `codex_runtime_capability_parity_smoke`
- `codex_runtime_inventory_smoke`
- `codex_active_runtime_consistency_smoke`
- `codex_runtime_behavior_smoke`
- `codex_source_reference_smoke`
- `install_runtime_smoke`

## Execution

Primary executable check:

```bash
bash tests/vault_deployment_acceptance.sh /Users/pigo/Documents/Pigo_Obsidian
bash tests/vault_runtime_journey_acceptance.sh /Users/pigo/Documents/Pigo_Obsidian
```

## Pass Criteria

- acceptance script exits `0`
- every repo smoke test exits `0`
- no source/runtime drift is reported
- skipped external-integration choice is preserved

## Notes

- This plan validates filesystem/runtime deployment, not interactive Codex conversation quality inside the vault UI.
- Interactive product QA is covered separately by the final QA and CEO-style acceptance pass.
