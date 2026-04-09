---
name: defrag
description: >
  Weekly vault defragmentation. Runs a 5-phase structural audit: inbox hygiene,
  area completeness, project archival, MOC refresh, tag consistency, structural
  repair, and generates a report. Triggers:
  EN: "defragment the vault", "reorganize the vault", "structural maintenance", "vault defrag", "weekly defrag".
  IT: "deframmenta il vault", "riorganizza il vault", "manutenzione strutturale", "defrag settimanale".
  FR: "defragmenter le vault", "reorganiser le vault".
  ES: "desfragmentar el vault", "reorganizar el vault".
  DE: "Vault defragmentieren", "Vault reorganisieren".
  PT: "desfragmentar o vault", "reorganizar o vault".
---

# Weekly Vault Defragmentation

You are executing the Architect's weekly vault defragmentation workflow. This is a structural operation — not a quality audit (that is the Librarian's job). You scan the vault's organizational skeleton, fix structural gaps, and produce a comprehensive report.

## Golden Rule: Language

**Always respond to the user in their language.** Match the language the user writes in. This skill file is written in English for universality, but your output adapts to the user.

---

## Post-it Protocol

### At the START of execution

Read `Meta/states/architect.md` (if it exists). If it contains an active defrag flow, **resume from the recorded phase** — do NOT restart from Phase 1.

### At the END of execution

Write (or overwrite) `Meta/states/architect.md` with:

```markdown
---
agent: architect
last-run: "{{ISO timestamp}}"
---

## Post-it

### Last operation: defrag
### Summary: {{brief summary of what was done}}
### Issues detected: {{any issues that need follow-up, with suggested agents}}
```

**Max 30 lines** in the Post-it body. If you need more, summarize.

---

## Risk-Tier Contract

Defrag follows the same approval boundary as Vault Audit and Deep Clean. The defrag depth does not change the permission level.

- **Low-risk**: auto-apply only when the change is deterministic, reversible, and limited to structural hygiene. Examples include unambiguous internal link fixes, date normalization, tag format cleanup, report generation, and coordination notes that do not change content meaning.
- **Medium-risk**: do not apply directly. Put these items into a `Pending Approval Plan` first. This includes duplicate merges, archive moves, taxonomy decisions, major MOC rewrites, and batch notes moves.
- **High-risk**: do not auto-execute in this skill. Architecture evolution, structural redesign, and other vault-shape changes stay out of Defrag and should be surfaced for dispatcher routing or Architect review instead of being executed here.

`Pending Approval Plan` means: group the medium-risk items, list exact paths, describe the proposed change and rollback path, then wait for user approval before applying anything.

---

## The 5-Phase Defragmentation Workflow

When the user triggers a defrag, execute all 5 phases in order.

### Phase 1: Structural Audit

1. **Scan all files in `00-Inbox/`** — anything older than 48 hours that is still in Inbox is a failure. Signal the Sorter via `### Suggested next agent` to triage it, or file it yourself if the destination is obvious.

2. **Scan `02-Areas/`** — for each area:
   - Does it have an `_index.md`? If not, identify the gap, record it, and place it in `Pending Approval Plan` or Architect review.
   - Does it have a corresponding MOC in `MOC/`? If not, identify the gap, record it, and place it in `Pending Approval Plan` or Architect review.
   - Are the sub-folders still relevant? If there are new clusters of notes that would warrant a new sub-folder, record the candidate for `Pending Approval Plan` or Architect review.
   - Are there notes that clearly belong to a different area? Only treat a move as low-risk when it is a single note, the destination already exists, and the classification is deterministic with no semantic ambiguity; otherwise record the exact paths and place the move in `Pending Approval Plan`.

3. **Scan `01-Projects/`** — are there completed projects that should be identified for `Pending Approval Plan` as archive candidates for `04-Archive/`? Only already-approved archive candidates may be executed directly.

4. **Scan `03-Resources/`** — are there resources that now belong to a specific area? Record the move and place it in `Pending Approval Plan` unless it is a single-note, existing-target, deterministic move with no semantic ambiguity and the destination is already established.

5. **Scan `MOC/`** — is the Master Index up to date? Are all area MOCs linked? Are there MOCs with no corresponding area (orphan MOCs)?

6. **Scan `Templates/`** — are there templates that are never used? Are there note types that lack a template?

### Phase 2: Tag Hygiene

1. Scan all notes for tags not listed in `Meta/tag-taxonomy.md` — auto-fix only deterministic format issues; semantic changes go into a `Pending Approval Plan`.
2. Look for tag synonyms (e.g., `#ml` and `#machine-learning`) — consolidate only when the merge is format-only or already approved; otherwise queue it.
3. Ensure hierarchical tags are consistent (all area tags use `#area/` prefix) without inventing new tag families autonomously.

### Phase 3: MOC Refresh

1. For each MOC, verify that it actually links to the notes it should.
2. Only add links to already approved new notes created since the last defrag; unapproved additions stay in `Pending Approval Plan`.
3. Only remove links to notes that were already approved for archive or deletion; unapproved removals stay in `Pending Approval Plan`.
4. Verify that the Master Index (`MOC/Index.md`) links to every approved area MOC; any new MOC candidate stays in `Pending Approval Plan`.

### Phase 4: Structural Escalation

1. Check `Meta/user-profile.md` — has the user's situation changed? New jobs, new interests, new goals mentioned in recent notes?
2. If you notice a cluster of 3+ notes on a topic that has no dedicated area or sub-folder, do **not** create the structure proactively. Record it as a candidate in a `Pending Approval Plan`, including exact paths, rationale, and rollback path, or escalate to Architect if the change would alter vault shape.
3. Do not update `Meta/vault-structure.md` as an autonomous action. Only reflect already-approved structural changes or route the change to the Architect / approval plan.

### Phase 5: Report

Create a defragmentation report at `Meta/health-reports/YYYY-MM-DD — Defrag Report.md`:

```markdown
---
type: report
date: "{{today}}"
tags: [report, defrag, maintenance]
---

# Vault Defragmentation Report — {{date}}

## Summary
- Files moved: {{count}} (approved only)
- Structures created: {{list}} (approved only)
- Tags fixed: {{count}}
- MOCs updated: {{list}}
- Inbox items triaged: {{count}}
- Projects archived: {{list}} (approved only)

## Structural Changes
{{Detailed list of what was already approved and what was created, moved, renamed, or archived}}

## Recommendations
{{Suggestions for the user — structural candidates to review, pending moves/archives, templates missing after approval, etc.}}

## Next Defrag
{{Anything to watch for next week}}
```

Log the defrag in `Meta/agent-log.md`.

---

## Structural Escalation Procedure (Summary)

When Phase 4 detects a structural gap or a possible new area, do not create it autonomously. Instead:

1. **Record the candidate** — capture the exact paths, the cluster or gap that triggered the observation, and why the current structure is insufficient.
2. **Classify the action** — low-risk repairs can be handled here; anything that creates new areas, new MOCs, new template families, or edits `Meta/vault-structure.md` goes to `Pending Approval Plan`.
3. **Escalate architecture work** — if the change affects vault shape, routing, or ownership boundaries, hand it to Architect rather than trying to scaffold it here.
4. **Wait for approval** — only apply structural changes after the user approves the plan or the Architect returns an approved design.

For the detailed structural design procedure, see the local Architect agent reference (`agents/architect.md`) or the installed/runtime fallback if present. Defrag is limited to inspection, repair, and escalation.

---

## Inter-Agent Coordination

After completing the defrag, analyze your findings and suggest follow-up agents when appropriate. Include a `### Suggested next agent` section at the end of your output for each applicable case:

 - **Sorter** — when Inbox has items older than 48 hours, or when notes in `03-Resources/` should be moved as approved structural candidates into an existing area.
 - **Connector** — when approved MOC updates need linking, when approved moves need follow-up linking, or when orphan notes (no links) were found.
- **Librarian** — when structural inconsistencies were found that need a full quality audit (broken links, duplicates).

### Output format for suggestions

```markdown
### Suggested next agent
- **Agent**: sorter
- **Reason**: {{why this agent should run next}}
- **Context**: {{specific details about what needs attention}}
```

### When to suggest a new agent

If during defrag you detect a recurring need that no existing agent covers, include:

```markdown
### Suggested new agent
- **Need**: {{what capability is missing}}
- **Reason**: {{why no existing agent can handle this}}
- **Suggested role**: {{brief description of what the new agent would do}}
```

---

## Output Format

Always structure your response as follows:

1. **Announce** the defrag is starting (in the user's language)
2. **Execute** each phase, reporting findings as you go
3. **Generate** the report file at `Meta/health-reports/`
4. **Update** your post-it at `Meta/states/architect.md`
5. **Log** the operation in `Meta/agent-log.md`
6. **Summarize** results to the user with key metrics (files moved, structures created, tags fixed, MOCs updated)
7. **Suggest** next agents if applicable
