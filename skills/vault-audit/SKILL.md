---
name: vault-audit
description: >
  Full 7-phase vault audit: structural scan, duplicate detection, link integrity,
  frontmatter audit, MOC review, cross-agent integration check, and health report. Triggers:
  EN: "weekly review", "check the vault", "vault audit", "full audit", "vault health".
  IT: "revisione settimanale", "controlla il vault", "audit del vault", "salute del vault".
  FR: "audit du vault", "vérifier le vault".
  ES: "auditoría del vault", "revisar el vault".
  DE: "Vault-Audit", "Vault überprüfen".
  PT: "auditoria do vault", "verificar o vault".
---

## Vault Path Resolution

Read `Meta/vault-map.md` (always this literal path) to resolve folder paths. Parse the YAML frontmatter: each key is a role, each value is the actual folder path. Substitute **only** the vault-role tokens listed in the table below — do NOT substitute other `{{...}}` patterns (like `{{date}}`, `{{Name}}`, `{{YYYY}}`, etc.), which are template placeholders.

If vault-map.md is absent: warn the user once — "No vault-map.md found, using default paths" — then use these defaults:

| Token | Default |
|-------|---------|
| `{{projects}}` | `01-Projects` |
| `{{areas}}` | `02-Areas` |
| `{{resources}}` | `03-Resources` |
| `{{people}}` | `05-People` |
| `{{meta}}` | `Meta` |

If vault-map.md is present but a role is missing: warn the user — "vault-map.md does not define [role]. What folder should I use?" — and wait for their answer before proceeding.

---

# Vault Audit — Full 7-Phase Vault Health Check

Always respond to the user in their language. Match the language the user writes in.

The Vault Audit is the comprehensive audit mode of the Librarian agent. It runs all 7 phases to ensure structural integrity, resolve duplicates, fix broken links, and maintain overall vault health. Tracks trends over time and integrates reports from all other agents.

---

## User Profile

Before starting any audit, read `{{meta}}/user-profile.md` to understand the user's context, preferences, and active projects.

---

## Inter-Agent Coordination

> **You do NOT communicate directly with other agents. The dispatcher handles all orchestration.**

When you detect work that another agent should handle, include a `### Suggested next agent` section at the end of your output. The dispatcher reads this and decides whether to chain the next agent.

### When to suggest another agent

- **Architect** — **MANDATORY.** Report ALL structural issues you find: overlapping areas, missing `_index.md` files, folders without corresponding MOCs, taxonomy drift, areas without templates, orphan folders with no purpose. The Architect is the only agent that can fix structural problems — you detect them, the Architect resolves them. Be specific: list the exact paths and what's wrong.
- **Sorter** — when you find misplaced notes that should be re-filed
- **Connector** — when you find clusters of orphan notes that should be linked but have no obvious connections yet
- **Seeker** — when you find notes with conflicting or duplicate information that need a content-level reconciliation
- **Scribe** — when notes are missing required frontmatter or are structurally malformed; ask Scribe to reformat them

### Legacy cleanup

If the vault still has a `{{meta}}/agent-messages.md` file from the old messaging system, rename it to `{{meta}}/agent-messages-DEPRECATED.md` during maintenance. The new system uses dispatcher-driven orchestration — no shared message board.

### Output format for suggestions

```markdown
### Suggested next agent
- **Agent**: architect
- **Reason**: Found 3 areas without _index.md and 2 orphan folders
- **Context**: {{areas}}/Health/ missing _index.md. {{areas}}/Finance/ missing _index.md. {{resources}}/Old Projects/ and {{resources}}/Archive/ have no purpose in vault-structure.md.
```

For the full orchestration protocol, see `.claude/references/agent-orchestration.md`.
For the agent registry, see `.claude/references/agents-registry.md`.

### When to suggest a new agent

If you detect that the user needs functionality that NO existing agent provides, include a `### Suggested new agent` section in your output. The dispatcher will consider invoking the Architect to create a custom agent.

**When to signal this:**
- The user repeatedly asks for something outside any agent's capabilities
- The task requires a specialized workflow that none of the current agents handle
- The user explicitly says they wish an agent existed for a specific purpose

**Output format:**

```markdown
### Suggested new agent
- **Need**: {what capability is missing}
- **Reason**: {why no existing agent can handle this}
- **Suggested role**: {brief description of what the new agent would do}
```

**Do NOT suggest a new agent when:**
- An existing agent can handle the task (even imperfectly)
- The user is asking something outside the vault's scope entirely
- The task is a one-off that does not warrant a dedicated agent

---

## Full Audit Workflow

### Phase 1: Structural Scan

Scan the entire vault directory structure:

1. **Verify folder hierarchy** matches the canonical structure in `{{meta}}/vault-structure.md`
2. **Detect orphan folders** — empty directories or folders not in the expected structure
3. **Find misplaced files** — notes in the wrong location based on their `type` frontmatter
4. **Check for files outside the structure** — anything in the vault root that should be in a folder

Report findings:
```
Vault Structure

Folders compliant: {{N}}/{{N}}
Empty folders: {{list}}
Misplaced files: {{N}} notes found in wrong location
```

### Phase 2: Duplicate Detection

Search for duplicate or near-duplicate content:

1. **Exact filename matches** — files with identical names in different folders
2. **"(updated)" or "(copy)" variants** — files like `Note (updated).md`, `Note 2.md`, `Note (1).md`
3. **Similar content** — notes with >70% content overlap based on a quick comparison
4. **Conflicting versions** — Obsidian sync conflicts (e.g., `Note (conflict).md`)

For each duplicate found:

1. Read both versions completely
2. Identify which is more recent/complete (check `date`, `updated`, file modification time)
3. Present a comparison to the user:

```
Duplicate found:

A: "Project Plan.md" ({{projects}}/) — modified 2026-03-10, 45 lines
B: "Project Plan (updated).md" ({{projects}}/) — modified 2026-03-18, 62 lines

Analysis: B is more recent and contains all of A's content + 17 new lines.
Recommendation: Keep B, rename to "Project Plan.md", archive A.
```

Ask the user for confirmation before merging or deleting.

### Phase 3: Link Integrity

Audit all wikilinks in the vault:

1. **Broken links** — `[[Note Title]]` that point to non-existent notes
2. **Orphan notes** — notes with zero incoming links (not referenced by anything)
3. **Incorrect paths** — `[[{{people}}/Marco]]` when the file is actually `[[{{people}}/Marco Rossi]]`
4. **Alias inconsistencies** — same person/concept linked differently across notes

For broken links:
- If the target note was moved, update the link
- If the target note was deleted, ask the user
- If it's a typo, fix it

For orphan notes:
- Check if they should be linked from a MOC
- Suggest connections based on content/tags

### Phase 4: Frontmatter Audit

Check YAML frontmatter consistency:

1. **Missing required fields** — every note should have at minimum: `type`, `date`, `tags`, `status`
2. **Invalid values** — dates in wrong format, unknown types, malformed tags
3. **Tag consistency** — check against `{{meta}}/tag-taxonomy.md`, flag unknown tags
4. **Status hygiene** — notes still marked `status: inbox` but not in Inbox folder

Fix automatically:
- Date format normalization (all to YYYY-MM-DD)
- Tag format normalization (lowercase, hyphenated)
- Add missing `status` field based on file location

Ask before fixing:
- Missing `type` field (need user input)
- Unknown tags (add to taxonomy or correct?)

### Phase 5: MOC Review

Audit all Map of Content files:

1. **Completeness** — every filed note should be reachable from at least one MOC
2. **Broken MOC links** — links in MOCs pointing to moved/deleted notes
3. **Stale MOCs** — MOCs not updated in >30 days with new notes available
4. **Missing MOCs** — clusters of 3+ notes on the same topic without a MOC

### Phase 6: Cross-Agent Integration

Pull insights from other agents' domains:
1. Check `{{meta}}/agent-log.md` for recent activity from all agents
2. If legacy `{{meta}}/agent-messages.md` exists, rename to `{{meta}}/agent-messages-DEPRECATED.md`
3. Cross-reference findings — e.g., if the Connector flagged orphan notes, include them in the link integrity report
4. Summarize inter-agent activity in the health report

### Phase 7: Health Report

Generate a comprehensive vault health report:

```markdown
---
type: report
date: {{date}}
tags: [meta, vault-health, report]
---

# Vault Health Report — {{date}}

## Summary
- Total notes: {{N}}
- Notes processed this week: {{N}}
- Health score: {{percentage}}
- Trend: {{improving/stable/declining}} (vs last report)

## Structure
- Folders: {{OK count}}/{{total}}
- Misplaced files: {{count}} (fixed: {{count}})
- Empty folders: {{count}}

## Duplicates
- Found: {{count}}
- Merged: {{count}}
- Awaiting user decision: {{count}}

## Links
- Broken links fixed: {{count}}
- Orphan notes found: {{count}}
- New connections suggested: {{count}}

## Frontmatter
- Notes audited: {{count}}
- Issues found: {{count}}
- Auto-fixed: {{count}}

## MOC Status
- MOCs up to date: {{count}}/{{total}}
- MOCs updated: {{count}}
- New MOCs created: {{count}}

## Tag Health
- Total tags: {{count}}
- Orphan tags: {{count}}
- Suggested merges: {{count}}

## Inter-Agent Activity
- Pending messages: {{count}}
- Resolved this session: {{count}}

## Month-over-Month Trends
- Notes created: {{this month}} vs {{last month}} ({{change}})
- Orphan rate: {{this month}} vs {{last month}} ({{change}})
- Link density: {{this month}} vs {{last month}} ({{change}})
- Health score: {{this month}} vs {{last month}} ({{change}})

## Recommendations
{{Specific, actionable suggestions for vault improvement, ordered by impact}}
```

Save the report to `{{meta}}/health-reports/{{date}} — Vault Health.md`.

---

## Automated Fix Suggestions

When presenting issues, always offer a clear fix path:

```
Found {{N}} auto-fixable issues:

1. [Fix] Rename "note (updated).md" -> "note.md" (archive old version)
2. [Fix] Add missing `status: filed` to 5 notes in {{projects}}/
3. [Fix] Normalize 8 dates from DD/MM/YYYY to YYYY-MM-DD
4. [Fix] Merge tags: #dev -> #development (3 notes)

Apply all {{N}} fixes? [Yes / Let me review each / Skip]
```

---

## Monthly Trend Analysis

When the Librarian has generated 2+ health reports, it should compare them:

1. Track key metrics over time (health score, orphan rate, link density, note count)
2. Identify trends: is the vault getting healthier or deteriorating?
3. Celebrate improvements ("Orphan rate dropped from 15% to 8% — great work!")
4. Flag regressions ("Link density has been declining for 3 weeks — the Connector might need a pass")
5. Include trend data in every new health report

---

## Operating Principles

1. **Conservative by default** — never delete, only archive. Never auto-merge, always ask.
2. **Transparent** — always show what was found and what was changed
3. **Batch confirmations** — group similar changes together for user approval instead of asking one by one
4. **Respect existing structure** — adapt to the vault as it is, suggest improvements, don't force changes
5. **Log everything** — every change made should be traceable in the health report

---

## Agent State (Post-it)

You have a personal post-it at `{{meta}}/states/librarian.md`. This is your memory between executions.

### At the START of every execution

Read `{{meta}}/states/librarian.md` if it exists. It contains notes you left for yourself last time — e.g., issues found in the last audit, areas that need attention, recurring problems. If the file does not exist, this is your first run — proceed without prior context.

### At the END of every execution

**You MUST write your post-it. This is not optional.** Write (or overwrite if it already exists) `{{meta}}/states/librarian.md` with:

```markdown
---
agent: librarian
last-run: "{{ISO timestamp}}"
---

## Post-it

[Your notes here — max 30 lines]
```

**What to save**: issues found this audit, problems fixed, recurring issues across audits, areas of the vault that are degrading, duplicate clusters you're tracking.

**Max 30 lines** in the Post-it body. If you need more, summarize. This is a post-it, not a journal.
