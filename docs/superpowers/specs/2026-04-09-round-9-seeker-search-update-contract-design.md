# Round 9 Seeker Search-Update Contract Design

## Goal

Reshape `seeker` into a Codex-first search-and-answer agent whose default behavior is retrieval and synthesis first, with only a narrow class of safe incidental edits allowed during search-driven work.

This round is not a full redesign of Seeker's search modes. It focuses on the runtime contract:

- search, answer, and citation come before editing
- small incidental fixes are allowed only inside a tightly bounded set
- multi-source conflicts must be analyzed and surfaced, not silently rewritten
- shared references must stop implying that Seeker is a broad update agent

## Current Problems

### 1. Seeker currently reads as both a retrieval agent and a broad update agent

The top-level description in `agents/seeker.md` still says Seeker is used when the user needs to find, update, or analyze vault content.

That wording is too broad for the runtime boundary pigo selected:

- Seeker should be search-first
- editing should be incidental and narrow
- larger content correction still belongs to more deliberate workflows

### 2. The current write boundary is still too open-textured

The current boundary says Seeker may edit existing notes and frontmatter when the user explicitly asks to update, fix, or revise content.

That allows too much interpretation and risks overlap with:

- `Librarian` for maintenance cleanup
- `Connector` for graph-level edits
- `Architect` for structural changes

pigo chose a narrower operating model:

- Seeker may fix obvious small issues discovered during search-driven work
- but it must not become a general-purpose update agent

### 3. Multi-source conflict handling is under-specified

Seeker already has answer, timeline, and diff modes that synthesize across multiple notes. But the contract does not clearly say what happens when those notes disagree.

Without an explicit rule, the agent could drift toward:

- silently normalizing conflicting notes
- picking one source and rewriting another
- or acting as though synthesis implies permission to resolve contradictions in-place

pigo chose the opposite behavior:

- analyze the conflict
- cite the disagreement
- propose a fix when useful
- do not directly edit notes just because a conflict exists

### 4. Shared references may still overstate Seeker's editing role

`references/agents.md` and `references/agents-registry.md` should reflect the new contract once the agent file changes. Otherwise routing and documentation drift will return.

## Scope

### In scope

- `agents/seeker.md`
- `references/agents.md`
- `references/agents-registry.md`
- `func.md`
- `Status_2026-04-09_codex-migration.md`
- a new round-9 smoke test under `tests/`

### Out of scope

- redesigning Seeker's search algorithms
- changing `Connector`, `Sorter`, or `Librarian` behavior in this round
- adding new Seeker tools
- redesigning dispatcher routing rules in `AGENTS.md`
- implementing a new conflict-resolution workflow or issue queue

## Design Decisions

### Decision 1: Seeker is search-first, answer-first, citation-first

The default Seeker order of operations should be:

1. search
2. retrieve
3. synthesize
4. cite
5. edit only if the issue is very small and clearly safe

This makes editing subordinate to retrieval rather than a parallel purpose.

Why:

- pigo explicitly chose a search-first operating mode
- Seeker should not drift into a maintenance or governance role
- this keeps the search contract clear for users and for future guard rails

### Decision 2: Incidental edits are allowed only in a narrow set

Seeker may directly fix only these kinds of small issues:

- obvious typos
- broken wikilinks
- small frontmatter mistakes
- small factual corrections that do not change the note's underlying claim
- light formatting cleanup

These edits must remain local, low-risk, and non-interpretive.

Why:

- pigo explicitly allowed narrow search-adjacent repairs
- these fixes improve answer quality without changing Seeker's role

### Decision 3: Seeker must not change note claims or resolve substantive disagreement in-place

Seeker must not directly:

- rewrite a note's thesis or position
- merge competing interpretations into one canonical claim
- resolve multi-source disagreements by editing one or more notes
- perform broad cleanup or maintenance sweeps
- create new notes as part of search-driven correction

Why:

- this is the clearest boundary between Seeker and the rest of the crew
- conflict analysis is not the same thing as permission to rewrite history

### Decision 4: Conflict handling becomes explicit across the main synthesis modes

When Seeker finds conflicting sources, it should:

1. state that the sources conflict
2. cite the conflicting notes clearly
3. explain the nature of the disagreement
4. optionally suggest a likely fix or follow-up path
5. stop short of editing the notes directly

This should be reflected not only in the write-boundary section but also in the major synthesis modes where conflict is most likely to appear:

- `Answer Mode`
- `Timeline Mode`
- `Diff Mode`
- `Missing Knowledge` when contradiction is part of the gap

Why:

- the mode descriptions must not undermine the top-level boundary
- synthesis behavior is where hidden editing drift is most likely to re-enter

### Decision 5: Shared references must describe Seeker as retrieval-first with limited safe updates

`references/agents.md` and `references/agents-registry.md` should describe Seeker as:

- a search and synthesis agent
- able to make limited, low-risk incidental fixes
- not responsible for substantive conflict resolution or maintenance-scale edits

Why:

- the shared documentation needs to match the actual contract
- this reduces future routing and wording drift

## File-Level Change Plan

### `agents/seeker.md`

- tighten the top-level description so Seeker is primarily about search, retrieval, analysis, and answer synthesis
- rewrite the `Runtime Write Boundary` so allowed edits are listed explicitly and narrowly
- explicitly forbid claim-changing edits, conflict-resolution edits, broad maintenance, and note creation
- update synthesis-heavy modes so conflict handling means analysis plus suggestion, not direct edit

### `references/agents.md`

- update the Seeker responsibilities summary to emphasize retrieval-first behavior
- mention limited incidental edits only in narrow safe cases
- avoid implying broad update authority

### `references/agents-registry.md`

- update the Seeker row so capabilities and outputs reflect search-first behavior with bounded small fixes
- avoid language that suggests general-purpose note updating

### `tests/codex_seeker_search_update_contract_smoke.sh`

New smoke test responsibilities:

- fail if `agents/seeker.md` still frames Seeker as a broad update agent
- fail if the write boundary no longer explicitly constrains Seeker to the approved narrow set of incidental edits
- fail if Seeker still permits claim-changing edits, direct conflict resolution, maintenance-scale edits, or note creation
- fail if the synthesis modes drift away from `analyze + cite + suggest` conflict handling
- fail if shared references drift away from the new Seeker contract

### `func.md`

- record the new round-9 smoke-test entrypoint

### `Status_2026-04-09_codex-migration.md`

- record the round-9 Seeker objective
- record the implemented contract changes
- record the new verification command and results

## Risks

### Risk 1: Seeker becomes too passive to be useful

If the boundary is written too tightly, Seeker may stop making harmless fixes that genuinely help users.

Mitigation:

- preserve the narrow set of incidental edits explicitly
- avoid collapsing Seeker into pure read-only behavior

### Risk 2: Allowed factual fixes are still interpreted too broadly

The phrase "small factual correction" could drift if not bounded carefully.

Mitigation:

- tie it explicitly to non-claim-changing fixes
- treat any interpretive change as out of scope

### Risk 3: Mode text could still quietly imply stronger edit authority

Even if the write boundary is precise, a broad statement inside `Answer Mode` or `Diff Mode` could reintroduce drift.

Mitigation:

- update the mode language in the same round
- guard the new wording in the smoke test

## Verification Plan

After implementation, run:

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
- `bash -n tests/codex_seeker_search_update_contract_smoke.sh tests/codex_scribe_capture_contract_smoke.sh tests/codex_transcribe_intake_smoke.sh tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`

## Expected Outcome

After round 9:

- Seeker will behave as a retrieval-first and synthesis-first agent
- small search-adjacent fixes will remain possible without broadening Seeker into a maintenance agent
- multi-source conflicts will be surfaced and explained instead of silently rewritten
- shared references will reflect the narrower Seeker contract
- the active Codex runtime will gain a cleaner boundary between search, maintenance, graph work, and structure governance
