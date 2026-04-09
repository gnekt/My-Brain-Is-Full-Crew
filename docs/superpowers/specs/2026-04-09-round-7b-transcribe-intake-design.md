# Round 7B Transcribe Intake Design

## Goal

Reshape the active transcription intake flow into a Codex-first, two-layer interaction contract so `/transcribe` becomes faster to enter, more honest about runtime limits, and easier to keep aligned with `transcriber`.

This round is not a full rewrite of the transcription output system. It focuses on the intake experience only:

- raw audio requests must be handled honestly at the first turn
- transcript-based requests must start with a minimal first-layer intake
- second-layer follow-ups must expand only when the chosen source type and output target actually require them
- `skills/transcribe/SKILL.md` and `agents/transcriber.md` must describe the same intake contract

## Current Problems

### 1. The current intake is front-loaded

`skills/transcribe/SKILL.md` currently asks for a broad structured interview up front:

- date and time
- processing mode
- participants
- project or area
- language
- priority flags
- transcript format

This creates too much interaction cost before the system knows whether the request is even executable in the current Codex runtime.

### 2. Raw audio requests are not gated early enough

The skill does contain a limitation statement for raw audio, but the overall intake framing still reads as though "audio recordings" are part of the same standard input path.

pigo chose a stricter runtime behavior:

- if the user only has raw audio
- and no transcript is available
- the system should reveal that limitation immediately

The user should not be led through a normal transcription intake before discovering that Codex cannot natively transcribe the file.

### 3. The intake contract is heavier than the chosen operating model

For transcript-based work, pigo selected a layered intake:

- first layer should collect only the minimum information needed to route the work well
- second layer should expand only as needed

The current skill behaves more like a single dense interview than a staged conversation.

### 4. `transcriber` and `/transcribe` risk drifting apart

`agents/transcriber.md` says the `/transcribe` skill handles the intake interview and main processing, while the agent handles edge cases. That is the right high-level shape, but if the skill's intake contract changes and the agent wording does not, future runtime behavior will drift again.

## Scope

### In scope

- `skills/transcribe/SKILL.md`
- `agents/transcriber.md`
- `func.md`
- `Status_2026-04-09_codex-migration.md`
- a new round-7B smoke test under `tests/`

### Out of scope

- redesigning all transcription output templates
- changing the six major output modes beyond what is needed for intake routing
- adding native raw-audio transcription capability to Codex
- changing dispatcher routing rules in `AGENTS.md`
- merging `scribe` and `transcriber` into one role

## Design Decisions

### Decision 1: `/transcribe` starts with source-type gating, not a full interview

The intake now begins by determining whether the user has:

1. `raw audio only`
2. `a transcript or transcript-like text`

This is the first routing decision because it determines whether the current runtime can proceed.

Why:

- it prevents false expectation for raw-audio support
- it reduces wasted questions
- it keeps the user-facing contract aligned with actual Codex capability

### Decision 2: Raw audio path reveals the limit immediately

If the user provides only raw audio and no transcript, `/transcribe` should respond with a first-turn limit disclosure rather than beginning normal intake.

That response should do three things:

1. state clearly that the current Codex runtime cannot natively transcribe raw audio by itself
2. offer the supported next step: bring back a transcript produced by a trusted external transcription workflow
3. explain that once transcript text exists, `/transcribe` can continue with structuring, summarization, note generation, action extraction, and filing guidance

Why:

- pigo explicitly selected immediate disclosure
- this is the most honest runtime behavior
- it keeps the intake lightweight and credible

### Decision 3: Transcript path uses a fixed four-field first layer

If the user already has transcript text, the first layer intake should collect only these four things:

1. `Purpose`
2. `Output target`
3. `Destination`
4. `Speaker context`

These are the only mandatory first-layer fields.

#### First-layer field meanings

- `Purpose`: why the user wants this processed, such as meeting recap, interview extraction, lecture study notes, podcast summary, or voice-note capture
- `Output target`: what artifact the user wants, such as meeting note, concise summary, knowledge note, action digest, or cleaned transcript
- `Destination`: where the result should land conceptually, such as project, area, folder family, or inbox fallback
- `Speaker context`: named speakers, roles, or the fact that speaker identity is unknown

Why:

- pigo selected these four items as the minimal intake
- they are sufficient to decide the second-layer path
- they keep the first exchange fast and predictable

### Decision 4: Second-layer intake expands through a mixed model

The second layer should not be one large follow-up questionnaire. It should expand in two steps:

1. first by source type
2. then by output target

#### Source-type layer

Examples:

- meeting transcript
- interview transcript
- lecture or webinar transcript
- podcast transcript
- voice-note transcript
- general transcript

#### Output-target layer

Examples:

- meeting note
- knowledge note
- concise summary
- action digest
- cleaned transcript

The result is a mixed branching model:

- source type decides the conversation family
- output target decides the minimum extra details needed inside that family

Why:

- pigo selected a mixed second-layer strategy
- source type changes what contextual questions matter
- output target changes what form the final note must take

### Decision 5: Second-layer questions must stay sparse and purpose-driven

The second layer may ask follow-up questions, but only when the answer materially affects the output.

Examples of allowed second-layer questions:

- for meetings: date, ownership clarity, deadline sensitivity, known project context
- for interviews: interviewer/interviewee roles, extraction focus, quote sensitivity
- for lectures: course context, study depth, exam relevance
- for podcasts: show or episode identity if missing, emphasis on insights vs quotes
- for voice notes: whether the user wants capture, cleanup, or conversion into a more structured note

Examples of questions that should no longer be default first-turn requirements:

- language, unless transcript language is ambiguous or output language matters
- transcript tool format, unless parsing depends on it
- priority flags, unless the user asks for urgent action extraction
- exact timestamp handling, unless timestamps are present and relevant

Why:

- the new intake should feel adaptive rather than bureaucratic
- the system should ask only what changes the result

### Decision 6: `transcriber` mirrors the new intake contract instead of inventing its own

`agents/transcriber.md` should be updated so it clearly matches the new skill contract:

- `/transcribe` owns the main intake path
- raw audio is immediately gated as unsupported for native transcription
- transcript-based work uses a two-layer intake
- the agent remains an edge-case surface rather than a parallel alternate intake model

Why:

- this reduces wording drift
- it makes future smoke testing straightforward
- it keeps agent and skill responsibilities legible

## File-Level Change Plan

### `skills/transcribe/SKILL.md`

- replace the current broad intake interview with a two-stage intake section
- add an explicit first-turn source-type gate
- make raw-audio handling an immediate disclosure path
- define the fixed four-field first layer for transcript-based requests
- define second-layer expansion by source type and output target
- keep downstream processing guidance, but only revise parts that directly depend on intake flow

### `agents/transcriber.md`

- update the core-processing contract so it describes the new `/transcribe` intake model accurately
- align raw-audio wording with the skill
- align transcript-path wording with the two-layer intake model
- preserve the agent's edge-case role and post-it behavior

### `tests/codex_transcribe_intake_smoke.sh`

New smoke test responsibilities:

- fail if `/transcribe` no longer clearly separates raw-audio path from transcript path
- fail if raw-audio handling no longer reveals the limitation immediately
- fail if the transcript first-layer intake grows beyond the four selected field categories
- fail if `agents/transcriber.md` drifts away from the skill's declared intake contract

### `func.md`

- record the new round-7B smoke-test entrypoint

### `Status_2026-04-09_codex-migration.md`

- record the round-7B intake objective
- record the implemented intake-contract changes
- record the new verification command and results

## Risks

### Risk 1: The new first layer becomes too vague

If the first layer is reduced too aggressively, the second layer may have to compensate with too many ad hoc questions.

Mitigation:

- keep the four first-layer fields explicit
- make second-layer branching examples concrete in the skill

### Risk 2: The mixed second layer becomes too complex to maintain

If every source type and every output target is written as a full matrix, the skill may become harder to read than before.

Mitigation:

- describe the branching rules clearly
- keep only the minimum additional questions for each path
- avoid writing a giant exhaustive decision table unless the existing file genuinely needs it

### Risk 3: Public-facing wording still overpromises raw-audio support

Even if the intake section is fixed, stale wording elsewhere could still imply native audio transcription.

Mitigation:

- align the high-level description text in the skill and agent with the new gate
- cover the gate wording in the smoke test

## Verification Plan

After implementation, run:

- `bash tests/codex_transcribe_intake_smoke.sh`
- `bash tests/codex_maintenance_risk_contract_smoke.sh`
- `bash tests/codex_runtime_capability_parity_smoke.sh`
- `bash tests/codex_runtime_inventory_smoke.sh`
- `bash tests/codex_active_runtime_consistency_smoke.sh`
- `bash tests/codex_runtime_behavior_smoke.sh`
- `bash tests/codex_source_reference_smoke.sh`
- `bash tests/install_runtime_smoke.sh`
- `bash -n tests/codex_transcribe_intake_smoke.sh tests/codex_maintenance_risk_contract_smoke.sh tests/codex_runtime_capability_parity_smoke.sh tests/codex_runtime_inventory_smoke.sh tests/codex_active_runtime_consistency_smoke.sh tests/codex_runtime_behavior_smoke.sh tests/codex_source_reference_smoke.sh tests/install_runtime_smoke.sh`

## Expected Outcome

After round 7B:

- users who bring raw audio will get an immediate and honest boundary
- users who bring transcript text will enter a lighter first-layer intake
- second-layer questions will feel targeted instead of front-loaded
- `transcriber` and `/transcribe` will describe the same runtime contract
- the input chain will be easier to extend later without reintroducing interaction drift
