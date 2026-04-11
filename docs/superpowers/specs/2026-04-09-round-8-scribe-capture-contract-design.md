# Round 8 Scribe Capture Contract Design

## Goal

Reshape `scribe` into a Codex-first fast-capture agent so the default interaction favors low-friction note creation, the structure boundary matches the round-6 contract, and the richer capture modes no longer overpromise heavy follow-up workflows by default.

This round is not a full redesign of Scribe templates. It focuses on the runtime contract:

- default capture should write directly instead of waiting for confirmation by default
- `scribe` should share the same low-risk versus architecture-level boundary already established elsewhere in the runtime
- `Thread Capture`, `Reading Notes`, and `Brainstorm` should follow the same fast-capture-first contract instead of implying heavyweight multi-artifact flows on every run

## Current Problems

### 1. Default capture is still too approval-heavy

`agents/scribe.md` currently ends with a requirement to present the final note to the user and ask whether it captures everything correctly before saving.

That conflicts with pigo's selected operating mode:

- default capture should reduce friction
- low-risk capture should land directly
- follow-up questions should be the exception, not the default

### 2. Scribe is still more conservative than the shared structure boundary

The current Scribe contract still says that if the target area or folder does not exist, it must:

1. place the note in `00-Inbox/`
2. suggest `Architect`
3. avoid silently continuing

That was a reasonable earlier migration stance, but pigo has now chosen the round-6 boundary for Scribe as well:

- low-risk local structure inside an existing area or project may be created directly
- architecture-level structure changes still belong to `Architect`

Without this alignment, Scribe remains out of step with `Sorter` and `/inbox-triage`.

### 3. Several Scribe modes still imply heavyweight default behavior

The current mode descriptions promise more structural work than a fast-capture agent should do by default:

- `Thread Capture` promises one note per atomic idea plus a thread index note
- `Reading Notes` implies a relatively heavy, full-structure reading workflow
- `Brainstorm` implies clusters, hot takes, and next steps even when the user may only want capture

These promises create two problems:

- they increase interaction and output weight even when the user wants speed
- they push Scribe toward orchestration-heavy behavior rather than capture-first behavior

### 4. Shared references still describe Scribe in the older, broader terms

`references/agents.md` and `references/agents-registry.md` still describe Scribe as a broad text-capture role without reflecting the newer fast-capture boundary or the lighter-weight handling of its richer modes.

If Scribe changes but the shared references do not, future routing and documentation drift will return.

## Scope

### In scope

- `agents/scribe.md`
- `references/agents.md`
- `references/agents-registry.md`
- `func.md`
- `Status_2026-04-09_codex-migration.md`
- a new round-8 smoke test under `tests/`

### Out of scope

- rewriting all Scribe output templates from scratch
- redesigning the broader dispatcher routing rules
- changing `Sorter` or `/inbox-triage` again unless a contradiction is discovered
- changing `Architect` authority itself
- redesigning quote capture in full unless needed to keep the fast-capture contract coherent

## Design Decisions

### Decision 1: Default Scribe capture writes directly by default

For standard low-risk text capture, Scribe should:

1. clean the input
2. structure it into a usable note
3. write it directly to `00-Inbox/`

It should no longer treat "show the draft and ask before saving" as the default behavior.

When follow-up is still allowed:

- the input is too ambiguous to title or classify safely
- the note appears to contain multiple unrelated capture intents and the split matters
- the user explicitly asks for a review-first workflow
- saving directly would create a material risk of wrong interpretation

Why:

- pigo explicitly selected direct landing as the default capture model
- capture agents should optimize for momentum
- low-risk inbox capture is reversible and consistent with the rest of the runtime

### Decision 2: Scribe adopts the round-6 structure boundary

Scribe should share the same structural boundary already used by `Sorter` and `/inbox-triage`:

#### Low-risk local structure: may execute directly

Examples:

- creating a clearly named child folder inside an already-existing area or project
- placing a note into an already-established local structure
- using an obvious existing folder family inside a known area

#### Architecture-level structure: must escalate to Architect

Examples:

- creating a new area
- creating a new project structure where none exists
- creating a new MOC system
- creating a new template family
- changing `Meta/vault-structure.md`

Why:

- Scribe should not lag behind the current runtime contract
- direct low-risk structure creation reduces unnecessary Inbox fallback
- architecture evolution still needs one constitutional owner

### Decision 3: Inbox fallback remains valid, but no longer universal

Scribe may still place notes in `00-Inbox/` when:

- the right location is genuinely unclear
- the needed structure is architecture-level and not yet present
- the user is clearly just capturing now and organizing later

But Scribe should not behave as though every missing folder implies immediate Inbox fallback plus Architect escalation.

Why:

- Inbox is a safe fallback, not the only safe behavior
- the runtime already allows low-risk local structure creation elsewhere

### Decision 4: Rich capture modes become fast-capture-first

`Thread Capture`, `Reading Notes`, and `Brainstorm` should follow the same default contract:

- create the primary useful capture artifact first
- do not automatically create extra derivative notes or index artifacts unless clearly necessary
- keep analysis or clustering optional, not mandatory

#### Thread Capture

Default behavior should shift from:

- one note per atomic idea
- plus a thread index note

to:

- one structured thread capture note by default
- optional splitting only when the content is clearly separable and the split materially helps later use

#### Reading Notes

Default behavior should shift from a heavy structured reading workflow toward:

- capture the reading note cleanly
- preserve source and reflections
- avoid implying full chapterized treatment unless the source material or user intent clearly supports it

#### Brainstorm

Default behavior should shift toward:

- preserving raw idea energy
- producing one fast-capture artifact
- treating clusters, hot takes, and next steps as optional additions rather than required sections every time

Why:

- these modes should still exist
- but they should operate under the same fast-capture contract as the rest of Scribe

### Decision 5: Shared references must describe the new Scribe contract

`references/agents.md` and `references/agents-registry.md` should be updated so they describe Scribe as:

- a fast text-capture and refinement agent
- directly writing low-risk captures
- using richer modes in a lightweight default way
- escalating only architecture-level structure to `Architect`

Why:

- Scribe's runtime contract should be legible outside the agent file
- dispatcher-adjacent reference drift is a recurring migration risk

## File-Level Change Plan

### `agents/scribe.md`

- remove the default requirement to ask for confirmation before saving
- rewrite the `Architect` escalation section to match the round-6 low-risk versus architecture-level structure boundary
- keep Inbox fallback, but describe it as situational rather than universal
- rewrite `Thread Capture`, `Reading Notes`, and `Brainstorm` so they create one primary capture artifact first and treat heavier outputs as conditional
- align any closing behavior or guidance text with the new direct-write default

### `references/agents.md`

- update the Scribe responsibilities summary to reflect direct low-risk capture
- note the lighter-weight handling of voice, brainstorm, thread, and reading capture
- align the "contact when" wording with the new role

### `references/agents-registry.md`

- update the Scribe capabilities, input, and output wording to reflect the new fast-capture contract
- avoid implying mandatory multi-note splitting or heavyweight post-processing

### `tests/codex_scribe_capture_contract_smoke.sh`

New smoke test responsibilities:

- fail if `agents/scribe.md` still requires default pre-save confirmation
- fail if Scribe still treats every missing structure as unconditional Inbox + Architect fallback
- fail if Scribe is missing the explicit low-risk local-structure allowance
- fail if `Thread Capture`, `Reading Notes`, or `Brainstorm` still promise heavyweight default derivative outputs that violate the fast-capture-first contract
- fail if the shared references drift away from the rewritten Scribe contract

### `func.md`

- record the new round-8 smoke-test entrypoint

### `Status_2026-04-09_codex-migration.md`

- record the round-8 Scribe objective
- record the implemented contract changes
- record the new verification command and results

## Risks

### Risk 1: Scribe becomes too lightweight for users who wanted richer outputs

If the rewrite strips too much structure out of the richer modes, Scribe may feel less capable.

Mitigation:

- preserve the modes themselves
- change the default contract, not the existence of richer outputs
- keep upgrade paths explicit when the user clearly wants more than fast capture

### Risk 2: Scribe starts competing with Sorter

If low-risk local structure creation is written too broadly, Scribe may start acting like a filing agent rather than a capture agent.

Mitigation:

- keep Scribe's authority limited to obvious local structure
- preserve Inbox fallback when routing or placement is unclear
- keep deeper filing and routing work with Sorter

### Risk 3: Rich mode wording remains uneven

If only default capture is updated, `Thread Capture`, `Reading Notes`, and `Brainstorm` may still signal the older heavy contract and confuse users.

Mitigation:

- update all three modes in the same round
- cover them in the round-8 smoke test

## Verification Plan

After implementation, run:

- `bash tests/codex_scribe_capture_contract_smoke.sh`
- `bash tests/codex_transcribe_intake_smoke.sh`
- `bash tests/codex_maintenance_risk_contract_smoke.sh`
- `bash tests/codex_runtime_capability_parity_smoke.sh`
- `bash tests/codex_runtime_inventory_smoke.sh`
- `bash tests/codex_active_runtime_consistency_smoke.sh`
- `bash tests/codex_runtime_behavior_smoke.sh`
- `bash tests/codex_source_reference_smoke.sh`
- `bash tests/install_runtime_smoke.sh`
- `bash -n tests/codex_scribe_capture_contract_smoke.sh tests/codex_transcribe_intake_smoke.sh tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`

## Expected Outcome

After round 8:

- Scribe will feel faster and less approval-heavy during normal capture
- Scribe will share the same structure boundary as the rest of the active runtime
- `Thread Capture`, `Reading Notes`, and `Brainstorm` will remain available but stop implying heavyweight default workflows
- the shared agent references will reflect the new Scribe contract
- the input side of the Codex runtime will be materially closer to stable parity
