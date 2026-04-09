# Function Registry

Last updated: 2026-04-09
Owner: Codex with pigo

## Purpose

This file is the repo-level registry for reusable functions, shell subroutines, and script entrypoints.

Rule:
- Before adding any new function, subroutine, or reusable script behavior, check this file first.
- Reuse an existing function when possible.
- If no existing function fits, add the new function and record it here in the same change.

## Current Reusable Shell Functions

| Name | File | Type | Purpose | Notes |
| --- | --- | --- | --- | --- |
| `info` | `scripts/launchme.sh` | shell function | Print informational installer messages | Local to installer script |
| `success` | `scripts/launchme.sh` | shell function | Print success installer messages | Local to installer script |
| `warn` | `scripts/launchme.sh` | shell function | Print warning installer messages | Local to installer script |
| `die` | `scripts/launchme.sh` | shell function | Print error and exit installer flow | Local to installer script |
| `info` | `scripts/updateme.sh` | shell function | Print informational updater messages | Local to updater script |
| `success` | `scripts/updateme.sh` | shell function | Print success updater messages | Local to updater script |
| `warn` | `scripts/updateme.sh` | shell function | Print warning updater messages | Local to updater script |
| `die` | `scripts/updateme.sh` | shell function | Print error and exit updater flow | Local to updater script |

## Current Script Entrypoints

| Entrypoint | File | Purpose | Notes |
| --- | --- | --- | --- |
| `dispatcher-runtime` | `AGENTS.md` | Codex workspace dispatcher entrypoint for installed runtimes | Replaces `CLAUDE.md` in the production runtime |
| `launchme` | `scripts/launchme.sh` | Install repo assets into the user workspace runtime directory | Deploys Codex runtime assets into `.codex/` |
| `updateme` | `scripts/updateme.sh` | Update installed runtime assets in the user workspace | Updates deployed Codex runtime assets in `.codex/` |
| `protect-system-files` | `hooks/protect-system-files.sh` | Block runtime edits to protected system files | Protects `AGENTS.md` and `.codex/` runtime files |
| `validate-frontmatter` | `hooks/validate-frontmatter.sh` | Warn on malformed frontmatter in written markdown files | Skips `.codex/` system runtime files |
| `notify` | `hooks/notify.sh` | Send desktop notifications when attention is needed | Default copy is now Codex-first |
| `install-runtime-smoke` | `tests/install_runtime_smoke.sh` | Smoke-test Codex runtime installation into a workspace | Verifies `.codex/` assets and workspace-root `AGENTS.md` |
| `codex-source-reference-smoke` | `tests/codex_source_reference_smoke.sh` | Smoke-test source/docs for unmigrated Claude runtime references | Guards round-2 content migration |
| `codex-runtime-behavior-smoke` | `tests/codex_runtime_behavior_smoke.sh` | Smoke-test Codex runtime behavior contract for valid interaction model and migration gating | Guards round-3 behavior migration |
| `codex-active-runtime-consistency-smoke` | `tests/codex_active_runtime_consistency_smoke.sh` | Smoke-test active-runtime docs and skills for stale installer, integration, and host assumptions | Guards round-4 parity cleanup |
| `codex-runtime-inventory-smoke` | `tests/codex_runtime_inventory_smoke.sh` | Smoke-test runtime inventory wording so active and migration-gated units stay clearly separated | Guards round-5 inventory parity cleanup |
| `codex-runtime-capability-parity-smoke` | `tests/codex_runtime_capability_parity_smoke.sh` | Smoke-test active runtime files for capability/tool parity, Sorter boundary consistency, and custom-agent inventory drift | Guards round-6 capability parity cleanup |
| `codex-maintenance-risk-contract-smoke` | `tests/codex_maintenance_risk_contract_smoke.sh` | Smoke-test maintenance-chain risk contracts and round-7A wording drift in Librarian, Vault Audit, Deep Clean, Defrag, and Tag Garden | Guards round-7A maintenance risk cleanup |

## Migration Notes

- The Codex runtime foundation now uses `AGENTS.md` plus `.codex/` as the deployed runtime contract.
- There is no Codex-first reusable runtime helper layer yet.
- During the Codex migration, new shared functions should prefer extraction into a dedicated helper script instead of duplicating `info/success/warn/die` patterns again.
- Any new dispatcher, installer, updater, or hook helper introduced for Codex must be recorded here before further dependent work is added.
