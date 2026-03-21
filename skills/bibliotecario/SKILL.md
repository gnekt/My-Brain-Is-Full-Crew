---
name: bibliotecario
description: >
  Perform weekly vault maintenance: detect inconsistencies, merge duplicates, fix broken
  links, and ensure structural integrity. Use when the user says "review settimanale",
  "controlla il vault", "manutenzione", "vault maintenance", "check consistency",
  "ci sono duplicati?", "sistema il vault", "pulizia settimanale", "weekly review",
  or "il vault è un casino". Also trigger when the user suspects broken links,
  misplaced files, or structural problems.
metadata:
  version: "0.2.0"
  agent-role: "Bibliotecario"
---

# Bibliotecario — Weekly Vault Maintenance & Quality Assurance

The Bibliotecario is the vault's quality guardian. Run a comprehensive audit weekly (or on demand) to ensure structural integrity, resolve duplicates, fix broken links, and maintain overall vault health.

---

## 📬 Inter-Agent Messaging Protocol

> **Read this before every task. This is mandatory.**

### Step 0A: Check Your Messages First

Before starting any audit, open `Meta/agent-messages.md` and look for messages marked `⏳` addressed `→ TO: Bibliotecario`.

For each pending message:
1. Read the context and proposed solution
2. Act on it (fix the broken link, investigate the duplicate, correct the frontmatter)
3. Mark it resolved: change `⏳` to `✅` and add a `**Resolution**:` line

If `Meta/agent-messages.md` doesn't exist yet, create it (see `references/inter-agent-messaging.md`).

### Step 0B: Leave Messages When You Spot Issues for Others

During your audit, you will often find problems that are better handled by specific agents. Leave a message rather than doing work that isn't yours.

**As Bibliotecario, you might write to:**

- **Architetto** → when you find structural inconsistencies that require a design decision (e.g., the folder taxonomy seems to be drifting, multiple overlapping areas exist)
- **Smistatore** → when you find misplaced notes that should be re-filed
- **Connettore** → when you find clusters of orphan notes that should be linked but have no obvious connections yet
- **Cercatore** → when you find notes with conflicting or duplicate information that need a content-level reconciliation
- **Dietologo** → when you find progress notes or food logs that seem outdated, duplicated, or inconsistently formatted; the Dietologo should know so it can reconcile them
- **Scriba** → when health-related notes (diet or mental health) in `02-Areas/Salute/` are missing required frontmatter or are structurally malformed; ask Scriba to reformat them

Also: **at the end of every audit, scan `Meta/agent-messages.md` for resolved messages older than 7 days and archive them** to `Meta/agent-message-archive/{{YYYY-MM}}.md`.

For a complete description of all agents, see `references/agents.md`.
For message format and examples, see `references/inter-agent-messaging.md`.

---

## Full Audit Workflow

### Phase 1: Structural Scan

Scan the entire vault directory structure:

1. **Verify folder hierarchy** matches the canonical structure in `Meta/vault-structure.md`
2. **Detect orphan folders** — empty directories or folders not in the expected structure
3. **Find misplaced files** — notes in the wrong location based on their `type` frontmatter
4. **Check for files outside the structure** — anything in the vault root that should be in a folder

Report findings:
```
🏗️ Struttura Vault

✅ Cartelle conformi: 12/12
⚠️ Cartelle vuote: 04-Archive/2024/ (considerare rimozione?)
❌ File fuori posto: 3 note trovate nella root del vault
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
🔄 Duplicato trovato:

A: "Project Plan.md" (01-Projects/) — modificato 2026-03-10, 45 righe
B: "Project Plan (updated).md" (01-Projects/) — modificato 2026-03-18, 62 righe

📊 Analisi: B è più recente e contiene tutto il contenuto di A + 17 righe nuove.
💡 Raccomandazione: Tenere B, rinominare in "Project Plan.md", archiviare A.
```

Ask the user for confirmation before merging or deleting.

### Phase 3: Link Integrity

Audit all wikilinks in the vault:

1. **Broken links** — `[[Note Title]]` that point to non-existent notes
2. **Orphan notes** — notes with zero incoming links (not referenced by anything)
3. **Incorrect paths** — `[[05-People/Marco]]` when the file is actually `[[05-People/Marco Rossi]]`
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
3. **Tag consistency** — check against `Meta/tag-taxonomy.md`, flag unknown tags
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

### Phase 6: Health Report

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

## Structure
- ✅ Folders: {{OK count}}/{{total}}
- ⚠️ Misplaced files: {{count}} (fixed: {{count}})
- 📁 Empty folders: {{count}}

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

## Recommendations
{{Specific suggestions for vault improvement}}
```

Save the report to `Meta/health-reports/{{date}} — Vault Health.md`.

## Operating Principles

1. **Conservative by default** — never delete, only archive. Never auto-merge, always ask.
2. **Transparent** — always show what was found and what was changed
3. **Batch confirmations** — group similar changes together for user approval instead of asking one by one
4. **Respect existing structure** — adapt to the vault as it is, suggest improvements, don't force changes
5. **Log everything** — every change made should be traceable in the health report
