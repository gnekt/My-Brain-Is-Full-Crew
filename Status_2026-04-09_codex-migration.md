# Status 2026-04-09 Codex Migration

## Goal

Track the in-progress rewrite from Claude-first runtime assumptions to Codex-first runtime assumptions.

## Completed

- Established Codex migration design baseline in `docs/design-rules/2026-04-09-codex-first-migration-design-rule.md`
- Added `func.md` as the reusable function and entrypoint registry
- Added workspace dispatcher entrypoint `AGENTS.md`
- Migrated installer runtime target from `.claude/` to `.codex/`
- Migrated updater runtime target from `.claude/` to `.codex/`
- Migrated runtime hook/settings paths to `.codex/hooks/...`
- Added installer smoke test: `tests/install_runtime_smoke.sh`
- Added source-reference smoke test: `tests/codex_source_reference_smoke.sh`
- Rewrote README architecture and runtime wording to Codex-first language
- Rewrote contribution, onboarding, and orchestration docs away from Claude-specific runtime terms
- Removed fake Codex MCP endpoint examples from onboarding and replaced them with provider-supplied placeholders
- Updated the legacy plugin manifest copy so it no longer describes the old Claude-era product shape
- Replaced `AskUserQuestion`-specific runtime assumptions with Codex-compatible one-question-at-a-time conversation rules
- Added explicit migration gating for Postman and Postman-derived skills so dispatcher behavior no longer promises unsupported external integrations
- Added round-3 runtime behavior smoke test: `tests/codex_runtime_behavior_smoke.sh`
- Cleaned active runtime onboarding/transcription docs to stop depending on stale installer and Postman assumptions
- Added round-4 active-runtime consistency smoke test: `tests/codex_active_runtime_consistency_smoke.sh`
- Rewrote active runtime inventory wording so docs consistently distinguish 7 active agents + 1 migration-gated role and 9 active skills + 4 migration-gated skills
- Removed stale active-product examples that still implied live Postman calendar/email behavior in day-to-day usage guidance
- Added round-5 runtime inventory smoke test: `tests/codex_runtime_inventory_smoke.sh`
- Upgraded Seeker and Connector runtime permissions so their documented edit and graph-write behaviors now match their actual tools
- Unified Sorter and `/inbox-triage` around one shared structural-boundary rule: low-risk local subfolders are allowed, architecture-level structure still escalates to Architect
- Updated custom-agent creation/management docs to use active-core-crew plus migration-gated Postman inventory language
- Added round-6 runtime capability parity smoke test: `tests/codex_runtime_capability_parity_smoke.sh`
- Added round-7A maintenance risk contract guard rail across Librarian, Vault Audit, Deep Clean, Defrag, and Tag Garden: `tests/codex_maintenance_risk_contract_smoke.sh`
- Registered the round-7A smoke-test entrypoint in `func.md`
- Updated the maintenance-chain wording so Librarian, Vault Audit, Deep Clean, Defrag, and Tag Garden keep the low-risk vs approval-required boundary explicit
- Aligned Librarian, Vault Audit, Deep Clean, Tag Garden, and Defrag to one shared maintenance risk contract with `Pending Approval Plan` as the medium-risk approval boundary
- Narrowed Defrag from autonomous structure evolution into structural repair plus approval/escalation flow so vault-shape changes no longer happen implicitly

## In Progress

- Round 8: continue deeper parity work inside the remaining active agents and skills now that the round-7A maintenance-risk contract guard rail is verified

## Next

- Audit the remaining docs outside the round-2 smoke-test scope (for example disclaimers and setup side-docs) for stale Claude-era wording
- Start deeper parity work inside the remaining active agent and skill bodies now that the Codex runtime contract, interaction model, and gating rules are aligned
- Decide whether the legacy plugin manifest should remain indefinitely or be removed in a later cleanup phase
- Plan the future ungating path for Postman once Codex-native external integration support is defined
- Reduce remaining future-facing references in top-level docs that still discuss Postman design in detail

## Verification

- `bash tests/install_runtime_smoke.sh` passed after foundation changes
- `bash tests/codex_source_reference_smoke.sh` passed
- `bash tests/install_runtime_smoke.sh` passed
- `bash -n tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh scripts/launchme.sh scripts/updateme.sh hooks/protect-system-files.sh hooks/validate-frontmatter.sh hooks/notify.sh` passed
- `bash tests/codex_runtime_behavior_smoke.sh` passed
- `bash -n tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh` passed
- `bash tests/codex_active_runtime_consistency_smoke.sh` passed
- `bash tests/codex_runtime_inventory_smoke.sh` passed
- `bash -n tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh` passed
- `bash tests/codex_runtime_capability_parity_smoke.sh` passed
- `bash -n tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh` passed
- `bash tests/codex_maintenance_risk_contract_smoke.sh` passed
- `bash tests/codex_runtime_capability_parity_smoke.sh` passed
- `bash tests/codex_runtime_inventory_smoke.sh` passed
- `bash tests/codex_active_runtime_consistency_smoke.sh` passed
- `bash tests/codex_runtime_behavior_smoke.sh` passed
- `bash tests/codex_source_reference_smoke.sh` passed
- `bash tests/install_runtime_smoke.sh` passed
- `bash -n tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh` passed
