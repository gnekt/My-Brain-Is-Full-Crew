# Librarian

> The quality inspector that keeps your vault healthy, consistent, and trustworthy.

## What it does

The Librarian is your vault's maintenance crew. While other agents create and organize notes, the Librarian checks that everything stays clean, consistent, and structurally sound over time. Think of it as a weekly health checkup for your entire knowledge base.

Run it once a week (or whenever things feel off), and it performs a thorough 6-phase audit: scanning folder structure, hunting duplicates, verifying every wikilink, auditing frontmatter consistency, reviewing Maps of Content, and generating a detailed health report. It finds the problems you would never notice on your own -- that broken link from two months ago, the two nearly identical notes in different folders, the 15 notes still tagged `status: inbox` even though they were filed weeks ago.

The Librarian is conservative by design. It never deletes anything -- only archives. It never auto-merges duplicates -- it shows you both versions and asks. Every change is logged and transparent.

## Capabilities

- **6-phase full audit** -- structural scan, duplicate detection, link integrity, frontmatter audit, MOC review, and health report generation
- **Quick health check** -- a lighter version focusing on the most common issues (broken links, inbox stragglers, recent duplicates)
- **Deep clean** -- aggressive audit that catches everything, including near-duplicate content with 70%+ overlap
- **Duplicate detection** -- finds exact filename matches, "(copy)" variants, sync conflicts, and content-similar notes
- **Broken link repair** -- identifies wikilinks pointing to non-existent notes and fixes or flags them
- **Orphan note rescue** -- finds notes with zero incoming links and suggests where they should be connected
- **Frontmatter consistency** -- checks that every note has required fields (type, date, tags, status) and fixes format issues automatically
- **Tag audit** -- validates all tags against the official taxonomy and flags unknown or duplicate-meaning tags
- **Consistency report** -- shows exactly what is wrong and what was fixed, with counts and percentages
- **Growth analytics** -- tracks your vault's growth over time (notes per week, links per note, health score trends)
- **Stale content detector** -- identifies notes not touched in 30, 60, or 90 days across active areas
- **Tag garden** -- cleans up tag sprawl by finding redundant, misspelled, or orphaned tags
- **Message archive cleanup** -- archives resolved agent messages older than 7 days

## How to use it

Run the Librarian periodically to maintain vault quality:

- "Weekly review" / "Run the weekly audit"
- "Check vault health" / "Quick health check"
- "Are there any duplicates?"
- "Deep clean the vault"
- "Fix broken links"
- "Show me orphan notes"
- "Consistency report"
- "How has my vault grown?"
- "Clean up the tags"

In Italian: "Review settimanale", "Controlla il vault", "Ci sono duplicati?", "Pulizia"
In French: "Revision hebdomadaire", "Verifier le vault"
In Spanish: "Revision semanal", "Verificar el vault"
In German: "Wochentliche Uberprufung", "Vault-Gesundheit"

## Example conversations

### Weekly review

**You:** Weekly review

**Librarian:** Running full 6-phase audit...

**Phase 1 -- Structure:** Folders OK (12/12 match the canonical structure). 1 empty folder found: `04-Archive/2024/` -- consider removing?

**Phase 2 -- Duplicates:** Found 2 potential duplicates:
- "Project Plan.md" (01-Projects/) vs "Project Plan (updated).md" (01-Projects/) -- the updated version contains everything from the original plus 17 new lines. Recommendation: keep the updated version, archive the original.

**Phase 3 -- Links:** 3 broken wikilinks found and fixed:
- `[[Sprint Planning]]` updated to `[[Sprint Planning Q2]]` (file was renamed)
- `[[Marco]]` updated to `[[05-People/Marco Rossi]]` (path corrected)
- `[[Old RFC]]` -- target does not exist. Should I create a stub note or remove the link?

**Phase 4 -- Frontmatter:** 8 notes had format issues:
- 5 notes had dates in non-standard format -- auto-fixed to YYYY-MM-DD
- 3 notes were missing `status` field -- added based on file location

**Phase 5 -- MOCs:** 2 MOCs are stale (not updated in 30+ days with new notes available). Updated both with 4 new entries total.

**Phase 6 -- Health Report:** Saved to `Meta/health-reports/2026-03-21 -- Vault Health.md`

Health Score: 87% (up from 82% last week)
Notes: 147 total, 12 new this week
Orphan notes: 18 (down from 23 after Connector work)

---

### Quick duplicate check

**You:** Are there any duplicates?

**Librarian:** Scanned 147 notes for duplicates. Found 3 issues:

1. **Exact duplicate:** "Meeting Notes March 10.md" exists in both `00-Inbox/` and `06-Meetings/2026/03/`. The Inbox version is older. Recommendation: delete the Inbox copy.

2. **Near-duplicate (85% overlap):** "API Design Notes.md" and "API Architecture Draft.md" cover the same topic with different titles. The Architecture Draft is more complete. Recommendation: merge and archive the older one.

3. **Sync conflict:** "Daily 2026-03-15 (conflict).md" -- a sync conflict from Obsidian Sync. The conflict version has 2 extra lines. Recommendation: merge the extra lines into the main version.

Want me to handle any of these?

---

### Growth analytics

**You:** How has my vault grown this month?

**Librarian:** Vault Growth -- March 2026

- Notes created: 42 (up 15% from February)
- Average per week: 10.5
- Most active areas: Projects (18 notes), Meetings (12 notes), Resources (7 notes)
- Links created: 89 new links this month
- Link density trend: 2.1 links/note (up from 1.8 in February)
- Health score trend: 82% -> 85% -> 87% (improving steadily)

Top contributors (by agent):
- Scribe: 22 notes
- Transcriber: 12 notes
- Postman: 8 notes

Your vault is growing healthily. The link density improvement is a good sign -- the Connector has been doing solid work.

## Works with

- **Architect** -- when the Librarian finds structural inconsistencies that need a design decision (overlapping areas, drifting taxonomy), it flags the Architect
- **Sorter** -- misplaced notes found during audits are reported to the Sorter for re-filing
- **Connector** -- orphan notes that need linking are flagged for the Connector
- **Seeker** -- when the Librarian finds conflicting information in duplicate notes, it asks the Seeker for content-level verification
- **Scribe** -- malformed notes in the Health area are sent back to the Scribe for reformatting
- **All agents** -- the Librarian cleans up the shared message board by archiving resolved messages older than 7 days

## Tips

- **Run it weekly.** A weekly audit catches small issues before they compound. Monthly audits find too much to fix at once.
- **Start with quick health checks.** If you are new to the vault, a quick check is less overwhelming than a full 6-phase audit.
- **Let it auto-fix the safe stuff.** Date format normalization, tag casing, and missing status fields are safe to fix automatically. The Librarian always asks before doing anything destructive.
- **Pay attention to the health score.** It is a single number that tells you how well-maintained your vault is. Aim for 85%+.
- **Use growth analytics for motivation.** Seeing your vault grow in notes, links, and quality is surprisingly satisfying and helps you stay consistent.
- **Act on archive suggestions.** Stale content in active areas adds noise. Archiving old notes keeps your working areas focused.
