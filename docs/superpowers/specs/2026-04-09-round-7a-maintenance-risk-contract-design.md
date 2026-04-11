# Round 7A Maintenance Risk Contract Design

## Goal

Unify the active maintenance chain around one Codex-first execution contract so `librarian`, `/vault-audit`, `/deep-clean`, `/tag-garden`, and `/defrag` all behave consistently under the same approval model.

This round is not about adding new maintenance automation depth. It is about removing drift between maintenance surfaces and enforcing the runtime boundary pigo chose:

- low-risk maintenance fixes may execute directly
- medium-risk and high-risk maintenance actions must first appear in a pending approval plan
- architecture evolution must not happen implicitly inside the maintenance chain

## Current Problems

### 1. Maintenance interactions still use mixed approval styles

- `agents/librarian.md` still uses scattered interactive prompts such as "Want me to run a deep clean?" and "Want me to auto-fix..."
- `skills/tag-garden/SKILL.md` already batches approval reasonably well, but its approval contract is local to that skill rather than shared across the maintenance stack
- `skills/vault-audit/SKILL.md` and `skills/deep-clean/SKILL.md` contain partial approval logic, but they do not define a shared risk-driven runtime model

### 2. Defrag remains too aggressive for the selected operating mode

- `skills/defrag/SKILL.md` still assumes proactive area creation, MOC creation, template creation, and vault-structure evolution
- pigo selected a balanced maintenance mode, not autonomous architecture evolution
- this creates a direct mismatch between the requested runtime behavior and the current defrag contract

### 3. Maintenance outputs are not structurally standardized

- some maintenance flows produce reports
- some ask ad hoc yes/no questions
- some imply automatic fixes without clearly separating what was already changed from what still requires approval

This makes the dispatcher-facing runtime inconsistent and makes future drift harder to catch.

## Scope

### In scope

- `agents/librarian.md`
- `skills/vault-audit/SKILL.md`
- `skills/deep-clean/SKILL.md`
- `skills/tag-garden/SKILL.md`
- `skills/defrag/SKILL.md`
- `func.md`
- `Status_2026-04-09_codex-migration.md`
- a new round-7A smoke test under `tests/`

### Out of scope

- implementing the later `7B` input-chain work for `Scribe / Transcribe`
- changing dispatcher routing rules in `AGENTS.md`
- introducing a new runtime helper script or maintenance framework
- ungating Postman or changing migration-gated inventory
- broadening Architect authority or redesigning the overall product shape

## Design Decisions

### Decision 1: The maintenance chain adopts one shared risk-driven contract

All active maintenance surfaces in this round will align to one execution model:

1. `Scan Summary`
2. `Auto-Applied Low-Risk Fixes`
3. `Pending Approval Plan`
4. `Suggested Next Agent`

This does not mean every run must populate every section with content. It means every maintenance surface must align to the same structure and the same semantics:

- what was scanned
- what was already changed safely
- what still needs pigo's approval
- what should be escalated next

Why:

- it replaces scattered one-off question prompts with one Codex-first approval contract
- it gives the dispatcher and the user one consistent maintenance interaction model
- it creates a stable surface for round-7A smoke testing

### Decision 2: Risk levels are explicit and shared across the maintenance stack

The maintenance chain will use these categories:

#### Low risk: may execute directly

Examples:

- normalize date format to `YYYY-MM-DD`
- normalize tag casing and hyphenation without changing semantic meaning
- add an obvious `status` value inferred from location
- fix an obvious typo-style broken wikilink where the target is unambiguous
- rename `Meta/agent-messages.md` to `Meta/agent-messages-DEPRECATED.md`
- write the maintenance report, post-it, and audit summary artifacts for the current run

#### Medium risk: must enter `Pending Approval Plan`

Examples:

- merge duplicate notes
- batch-merge tags or update taxonomy entries
- move stale notes to `Archive`
- batch-rewrite MOC links
- move groups of notes between folders
- reassign notes between existing areas, projects, or resources

#### High risk: must never auto-apply in the maintenance chain

Examples:

- create a new area
- create a new MOC system
- create a new template family
- evolve `Meta/vault-structure.md`
- make proactive information-architecture changes beyond local structural repair

Why:

- pigo explicitly selected balanced mode
- the maintenance chain needs a clear boundary between cleanup and governance
- this keeps maintenance useful without letting it silently redesign the vault

### Decision 3: Defrag becomes structural repair, not structural evolution

`/defrag` will remain a structural maintenance mode, but its authority will be narrowed:

- it may still audit Inbox hygiene, existing area completeness, stale project archival candidates, MOC drift, and tag hygiene
- it may still directly perform low-risk structural repair inside already-defined structures
- it may not proactively create new areas, new MOC systems, or new template families
- whenever defrag discovers architecture-level work, it must record that work in `Pending Approval Plan` and/or escalate to `Architect`

Why:

- defrag currently conflicts most directly with the balanced-mode requirement
- this preserves the usefulness of defrag while preventing silent architecture growth

### Decision 4: Librarian becomes the clean approval-model exemplar

`Librarian` is the maintenance entry surface most users will hit first, so it should model the shared contract most clearly.

This means:

- quick health check wording must stop ending in loose prompts like "Want me to run a deep clean?"
- consistency and stale-content modes must stop ending in scattered yes/no prompts
- instead, the output should clearly distinguish:
  - findings
  - low-risk fixes already applied
  - higher-risk changes waiting in a plan

Why:

- the entry surface sets expectations for the whole maintenance stack
- if librarian remains ad hoc, the rest of the stack will drift back toward ad hoc behavior too

### Decision 5: Tag Garden joins the same contract without losing its batch-review strengths

`/tag-garden` already has the right instinct: batch related changes rather than asking one question at a time for every tag.

Round 7A will keep that strength but align it to the shared contract:

- format-only tag normalization may be low-risk
- semantic tag merges and taxonomy edits become pending-approval work
- the skill should stop presenting merge approvals as a special one-off interaction model separate from the rest of the maintenance chain

Why:

- tag cleanup is one of the most likely places for semantic drift
- it should use the same contract as every other maintenance surface

## File-Level Change Plan

### `agents/librarian.md`

- replace loose prompt-style endings with the shared maintenance output model
- define the risk contract in librarian-facing terms
- make quick health, consistency, and stale-content modes reflect the balanced approval boundary
- preserve report-generation and escalation behavior

### `skills/vault-audit/SKILL.md`

- add explicit risk-tier language
- separate auto-fixable low-risk maintenance from pending-approval work
- keep duplicate merges, taxonomy decisions, archive moves, and major MOC rewrites in approval-required space
- align the health-report expectations to the shared maintenance contract

### `skills/deep-clean/SKILL.md`

- mirror the same risk-tier contract used in `/vault-audit`
- make the extended deep-clean passes obey the same approval boundary
- ensure "deep" means broader scanning depth, not broader autonomous authority

### `skills/tag-garden/SKILL.md`

- align tag-garden approvals to the shared maintenance contract
- keep format normalization low-risk
- move semantic tag merges and taxonomy updates into `Pending Approval Plan`
- keep the post-it/report behavior intact

### `skills/defrag/SKILL.md`

- remove language that implies proactive architecture evolution inside defrag
- narrow direct action to low-risk structural repair only
- convert architecture-level creation/evolution into approval-required or Architect-escalated work
- keep report generation and post-it/log expectations intact where they do not violate the new contract

### `tests/codex_maintenance_risk_contract_smoke.sh`

New smoke test responsibilities:

- fail if maintenance-chain files do not clearly distinguish low-risk direct fixes from approval-required work
- fail if `skills/defrag/SKILL.md` still promises proactive structure evolution such as new-area or new-template creation
- fail if `agents/librarian.md` still ends maintenance modes with legacy loose prompts instead of plan-based approval flow
- fail if `skills/tag-garden/SKILL.md` still treats semantic tag merges as a separate approval model outside the shared contract

### `func.md`

- record the new round-7A smoke test entrypoint

### `Status_2026-04-09_codex-migration.md`

- record the round-7A maintenance-contract objective
- record the implemented maintenance-chain changes
- record the verification commands and results

## Risks

### Risk 1: The contract becomes too abstract

If the shared maintenance model is written too generically, the files may technically "align" while still behaving differently in practice.

Mitigation:

- define the output sections explicitly
- define risk levels with concrete examples
- verify concrete wording in the smoke test rather than only checking for broad concepts

### Risk 2: Defrag loses too much usefulness

If defrag is narrowed too aggressively, it could become redundant with vault audit.

Mitigation:

- keep defrag focused on structural inspection and low-risk structural repair
- only remove architecture-evolution authority, not all structural work
- preserve its reporting and structural follow-up role

### Risk 3: Tag cleanup remains semantically dangerous

Even with a shared contract, tag merges can still silently change meaning if the boundary is written poorly.

Mitigation:

- treat semantic merges and taxonomy edits as approval-required by default
- only allow format normalization to auto-apply
- explicitly differentiate formatting fixes from meaning-changing merges

### Risk 4: Future edits reintroduce ad hoc prompts

Later edits could bring back informal "Want me to..." approval flows and undo the consistency gained here.

Mitigation:

- add the dedicated round-7A smoke test
- register it in `func.md`
- rerun all prior round smoke tests after implementation

## Verification Plan

Required:

- `bash tests/codex_maintenance_risk_contract_smoke.sh`
- `bash tests/codex_runtime_capability_parity_smoke.sh`
- `bash tests/codex_runtime_inventory_smoke.sh`
- `bash tests/codex_active_runtime_consistency_smoke.sh`
- `bash tests/codex_runtime_behavior_smoke.sh`
- `bash tests/codex_source_reference_smoke.sh`
- `bash tests/install_runtime_smoke.sh`
- `bash -n tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`

## Success Criteria

Round 7A is complete when:

- the maintenance chain shares one explicit risk-driven execution contract
- low-risk fixes are clearly separated from approval-required work
- `defrag` no longer promises autonomous architecture evolution
- librarian-mode outputs no longer rely on scattered legacy prompt endings
- tag-garden merges and taxonomy edits align to the same approval model as the rest of the maintenance stack
- the new round-7A smoke test passes
- all prior round smoke tests still pass
