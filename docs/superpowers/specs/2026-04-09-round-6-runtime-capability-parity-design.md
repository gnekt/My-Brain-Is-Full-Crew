# Round 6 Runtime Capability Parity Design

## Goal

Push the active Codex runtime from documentation-level parity into capability-level parity by aligning actual agent permissions with the behaviors the runtime already promises, while keeping the dispatcher model and migration gates intact.

This round is not about ungating Postman or adding new product surface. It is about making the current active crew internally coherent:

- if an agent claims it can edit notes, it must have the right tools
- if a workflow claims it can create a bridge note or update a MOC, it must have the right tools
- if two runtime files describe the same boundary, they must describe the same boundary

## Current Problems

### 1. Capability claims exceed actual tools

- `agents/seeker.md` claims it can update notes, compare versions, and handle "find and edit", but its tool set is read-only.
- `agents/connector.md` offers bridge-note creation and direct graph-improvement actions, but lacks write capability.

### 2. Structural authority is inconsistent

- `agents/sorter.md` and `skills/inbox-triage/SKILL.md` both say that missing structural destinations must escalate to the Architect.
- The same files also contain fallback language suggesting the Sorter can create folders in some cases.
- This creates ambiguity about where low-risk local filing stops and architecture begins.

### 3. Custom-agent management still reflects stale inventory assumptions

- `skills/create-agent/SKILL.md` and `skills/manage-agent/SKILL.md` still describe "8 core agents", which no longer matches the active Codex runtime inventory model.

## Scope

### In scope

- `agents/seeker.md`
- `agents/connector.md`
- `agents/sorter.md`
- `skills/inbox-triage/SKILL.md`
- `skills/create-agent/SKILL.md`
- `skills/manage-agent/SKILL.md`
- `func.md`
- `Status_2026-04-09_codex-migration.md`
- a new round-6 smoke test under `tests/`

### Out of scope

- ungating Postman
- changing dispatcher routing rules in `AGENTS.md`
- introducing new agent roles
- refactoring the runtime installer/updater again
- changing core product shape (`dispatcher + agents + skills + .codex/`)

## Design Decisions

### Decision 1: Seeker becomes safely editable

`Seeker` will move from read-only to edit-capable so it can legitimately support:

- "edit the note on X"
- "update the note"
- "find and edit"
- lightweight note corrections discovered during search

Implementation direction:

- add `Edit` to the tool list
- keep `Write` out unless the file already implies net-new note creation
- explicitly state that Seeker may edit existing vault notes and frontmatter, but must not create or modify runtime system files (`AGENTS.md`, `.codex/`, hooks, runtime references)

Why:

- this is the minimum capability increase that matches the current documented promise
- it preserves Seeker as a retrieval-and-revision role, not a structural role

### Decision 2: Connector becomes graph-write capable

`Connector` will gain `Write` and `Edit` so it can legitimately:

- add wikilinks into existing notes
- update relevant MOCs when graph work is approved
- create bridge notes when its own workflow explicitly proposes doing so

Constraints:

- Connector may write only vault knowledge artifacts such as notes, bridge notes, and MOCs
- Connector may not create new architectural scaffolding, templates, taxonomies, or area structures
- when graph findings imply a missing area or missing structural container, the Architect remains mandatory

Why:

- its current workflows already promise active graph repair, not just passive analysis
- without write capability, several documented modes are performative only

### Decision 3: Sorter boundary becomes explicit and shared

The Sorter boundary will be unified across `agents/sorter.md` and `skills/inbox-triage/SKILL.md` using a two-tier rule:

#### Tier A: allowed local creation

Sorter may create a low-risk local destination only when all of the following are true:

- the parent area or project already exists in `Meta/vault-structure.md`
- the destination is an obvious subfolder under an existing structure
- no new MOC, template family, taxonomy change, or area-level design is required

Examples:

- creating a missing month folder under `06-Meetings/YYYY/MM/`
- creating an obvious subfolder under an existing project
- creating a small filing container inside an already-defined area

#### Tier B: mandatory Architect escalation

Sorter must leave the note in Inbox and escalate to Architect when any of the following are true:

- a new area or project structure is needed
- a new MOC system or `_index.md` structure is needed
- a new template family is implied
- the proper destination is conceptually unclear, not just physically missing

Why:

- this preserves filing speed without turning Sorter into a second Architect
- it creates one reusable runtime rule instead of two drifting variants

### Decision 4: Custom-agent docs align to active/gated inventory

`create-agent` and `manage-agent` will stop describing the runtime as "8 core agents".

They will instead use language that matches the current runtime:

- active core crew
- migration-gated Postman role
- custom agents must not conflict with any reserved core names, including `postman`

Why:

- custom-agent workflows are runtime authoring tools; stale inventory language here causes downstream drift

## File-Level Change Plan

### `agents/seeker.md`

- update `tools:` from read-only to edit-capable
- clarify that Seeker edits existing vault notes only
- add explicit prohibition on runtime/system-file mutation
- keep structural escalation to Architect intact

### `agents/connector.md`

- update `tools:` to include write capability
- rewrite bridge-note and link-application language so it reflects direct execution capability
- clarify allowed write surface: notes, bridge notes, MOCs
- clarify forbidden write surface: area scaffolding, templates, taxonomy, runtime files

### `agents/sorter.md`

- replace mixed wording about folder creation with the shared two-tier boundary
- make the Architect escalation rule and the allowed low-risk local creation rule non-contradictory

### `skills/inbox-triage/SKILL.md`

- mirror the same two-tier boundary used in `agents/sorter.md`
- remove any wording that implies unsupported architectural autonomy

### `skills/create-agent/SKILL.md`

- replace "8 core agents" inventory references
- keep `postman` reserved as a core name even though it is migration-gated

### `skills/manage-agent/SKILL.md`

- replace "Core Agents (8)" wording
- describe the runtime as active crew plus migration-gated Postman role

### `tests/codex_runtime_capability_parity_smoke.sh`

New smoke test responsibilities:

- fail if `agents/seeker.md` claims edit/update behaviors without edit-capable tools
- fail if `agents/connector.md` offers bridge-note creation without write-capable tools
- fail if `agents/sorter.md` and `skills/inbox-triage/SKILL.md` disagree on local creation vs Architect escalation
- fail if custom-agent management files still say "8 core agents" or similar stale inventory wording

### `func.md`

- record the new smoke test entrypoint

### `Status_2026-04-09_codex-migration.md`

- record the round-6 objective, implemented changes, and verification commands

## Risks

### Risk 1: Permission creep

Adding `Edit` or `Write` expands the potential blast radius of Seeker and Connector.

Mitigation:

- restrict their documented authority to vault knowledge artifacts only
- explicitly forbid runtime/system file mutation in the agent instructions
- add smoke-test coverage for capability/tool parity rather than leaving this implicit

### Risk 2: Role overlap with Architect

If Connector or Sorter write too broadly, they start acting like structural governance agents.

Mitigation:

- define architectural scaffolding as Architect-only
- define local graph repair and low-risk local filing as non-Architect work
- use identical boundary wording in both Sorter surfaces

### Risk 3: Drift between docs and implementation

Round 6 improves capability parity, but later edits could reintroduce promise/tool mismatch.

Mitigation:

- add the dedicated round-6 smoke test
- register it in `func.md`
- rerun all previous smoke tests after implementation

## Verification Plan

Required:

- `bash tests/codex_runtime_capability_parity_smoke.sh`
- `bash tests/codex_runtime_inventory_smoke.sh`
- `bash tests/codex_active_runtime_consistency_smoke.sh`
- `bash tests/codex_runtime_behavior_smoke.sh`
- `bash tests/codex_source_reference_smoke.sh`
- `bash tests/install_runtime_smoke.sh`
- `bash -n tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`

## Success Criteria

Round 6 is complete when:

- Seeker and Connector tool permissions match their documented runtime promises
- Sorter and `/inbox-triage` share one consistent structural-boundary rule
- custom-agent management docs no longer use stale "8 core agents" language
- the new round-6 smoke test passes
- all previous round smoke tests still pass
