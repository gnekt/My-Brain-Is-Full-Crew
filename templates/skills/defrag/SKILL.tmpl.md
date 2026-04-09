---
name: defrag
description: >
  Weekly vault defragmentation. Runs a 5-phase structural audit: inbox hygiene,
  area completeness, project archival, MOC refresh, tag consistency, structure
  evolution, and generates a report. Triggers:
  EN: "defragment the vault", "reorganize the vault", "structural maintenance", "vault defrag", "weekly defrag".
  IT: "deframmenta il vault", "riorganizza il vault", "manutenzione strutturale", "defrag settimanale".
  FR: "defragmenter le vault", "reorganiser le vault".
  ES: "desfragmentar el vault", "reorganizar el vault".
  DE: "Vault defragmentieren", "Vault reorganisieren".
  PT: "desfragmentar o vault", "reorganizar o vault".
---

# Weekly Vault Defragmentation

You are executing the Architect's weekly vault defragmentation workflow. This is a structural operation — not a quality audit (that is the Librarian's job). You scan the vault's organizational skeleton, fix structural gaps, evolve the layout, and produce a comprehensive report.

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

## The 5-Phase Defragmentation Workflow

When the user triggers a defrag, execute all 5 phases in order.

### Phase 1: Structural Audit

1. **Scan all files in `00-Inbox/`** — anything older than 48 hours that is still in Inbox is a failure. Signal the Sorter via `### Suggested next agent` to triage it, or file it yourself if the destination is obvious.

2. **Scan `02-Areas/`** — for each area:
   - Does it have an `_index.md`? If not, create it.
   - Does it have a corresponding MOC in `MOC/`? If not, create it.
   - Are the sub-folders still relevant? Are there new clusters of notes that warrant a new sub-folder?
   - Are there notes that clearly belong to a different area? Move them.

3. **Scan `01-Projects/`** — are there completed projects that should be archived to `04-Archive/`?

4. **Scan `03-Resources/`** — are there resources that now belong to a specific area? Move them.

5. **Scan `MOC/`** — is the Master Index up to date? Are all area MOCs linked? Are there MOCs with no corresponding area (orphan MOCs)?

6. **Scan `Templates/`** — are there templates that are never used? Are there note types that lack a template?

### Phase 2: Tag Hygiene

1. Scan all notes for tags not listed in `Meta/tag-taxonomy.md` — either add them to the taxonomy or fix them.
2. Look for tag synonyms (e.g., `#ml` and `#machine-learning`) — consolidate.
3. Ensure hierarchical tags are consistent (all area tags use `#area/` prefix).

### Phase 3: MOC Refresh

1. For each MOC, verify that it actually links to the notes it should.
2. Add links to new notes that were created since the last defrag.
3. Remove links to notes that were archived or deleted.
4. Verify that the Master Index (`MOC/Index.md`) links to every area MOC.

### Phase 4: Structure Evolution

1. Check `Meta/user-profile.md` — has the user's situation changed? New jobs, new interests, new goals mentioned in recent notes?
2. If you notice a cluster of 3+ notes on a topic that has no dedicated area or sub-folder, **create the structure proactively** using the Area Scaffolding Procedure (see below).
3. Update `Meta/vault-structure.md` with all changes.

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
- Files moved: {{count}}
- Structures created: {{list}}
- Tags fixed: {{count}}
- MOCs updated: {{list}}
- Inbox items triaged: {{count}}
- Projects archived: {{list}}

## Structural Changes
{{Detailed list of what was created, moved, renamed, or archived}}

## Recommendations
{{Suggestions for the user — new areas to consider, templates to create, etc.}}

## Next Defrag
{{Anything to watch for next week}}
```

Log the defrag in `Meta/agent-log.md`.

---

## Area Scaffolding Procedure (Summary)

When Phase 4 detects a new area or sub-area is needed, follow these 7 steps:

1. **Create the folder structure** — create the area folder under `02-Areas/` with appropriate sub-folders.
2. **Create the area index note** — every area folder gets an `_index.md` with purpose, active projects, sub-areas, key resources, and a link to its MOC.
3. **Create the area MOC** — create `MOC/{{Area Name}}.md` with overview, structure, key notes, active projects, and a link back to the Master Index.
4. **Update the Master MOC** — add a link to the new area MOC in `MOC/Index.md`.
5. **Create area-specific templates** — if the area needs specialized templates (e.g., Finance needs Budget Entry), create them in `Templates/`.
6. **Update `Meta/vault-structure.md`** — document the new area, its sub-folders, and its purpose.
7. **Update `Meta/tag-taxonomy.md`** — add area-specific tags (e.g., `#area/finance`, `#budget`).

For the full detailed procedure with templates and examples, see the Architect agent (`agents/architect.md`, Section 4).

---

## Inter-Agent Coordination

After completing the defrag, analyze your findings and suggest follow-up agents when appropriate. Include a `### Suggested next agent` section at the end of your output for each applicable case:

- **Sorter** — when Inbox has items older than 48 hours, or when notes in `03-Resources/` should be moved to a newly created area.
- **Connector** — when new MOCs were created that need linking, or when orphan notes (no links) were found.
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
