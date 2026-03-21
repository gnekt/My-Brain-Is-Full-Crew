# Sorter

> Inbox zero for your vault -- every note in the right place, every time.

## What it does

The Sorter is your vault's filing system. Notes pile up in your Inbox throughout the day -- quick captures from the Scribe, email imports from the Postman, meeting notes from the Transcriber. The Sorter processes them all, figures out where each note belongs, moves it to the right folder, updates the Maps of Content, creates wikilinks, and gives you a clean summary of what went where.

It does not just look at metadata. The Sorter reads the full content of every note, detects mentioned people and projects, understands temporal context, and makes intelligent filing decisions. When something is ambiguous, it asks. When a destination folder does not exist yet, it either creates a minor subfolder or flags the Architect for a bigger structural decision.

Run the Sorter daily (or whenever your Inbox feels cluttered) and your vault stays organized without you having to think about where things go.

## Capabilities

- **Standard triage** -- processes inbox notes one by one, classifying and filing each to its proper location
- **Smart batch mode** -- groups related notes by project, topic, or date before filing, so related notes end up cross-linked
- **Priority triage** -- scans the inbox and ranks notes by urgency (critical, high, normal, low), filing the most important ones first
- **Project pulse** -- generates an activity report showing which projects received the most new notes and which have gone quiet
- **MOC updates** -- automatically adds filed notes to the relevant Map of Content
- **Duplicate detection** -- checks for existing notes with similar content before filing
- **Action item extraction** -- pulls tasks out of notes and ensures they are captured in daily or project notes
- **Archive suggestions** -- flags notes not touched in 30+ days as candidates for archiving
- **Wikilink creation** -- links people to `05-People/`, projects to `01-Projects/`, and related notes to each other
- **Health-aware filing** -- routes nutrition, diet, and therapy-related notes to the appropriate Health subfolders

## How to use it

Trigger the Sorter when your Inbox has accumulated notes:

- "Triage my inbox" / "Process inbox" / "File my notes"
- "Batch sort" / "Smart batch" (for 10+ notes)
- "Priority triage" / "Urgent first" / "What needs attention?"
- "Project pulse" / "Which projects are active?"
- "What's piling up?"
- "Evening triage" / "Daily digest"

In Italian: "Smista la inbox", "Pulisci la inbox", "Svuota inbox"
In French: "Trie la boite de reception", "Range mes notes"
In Spanish: "Ordena la bandeja", "Triaje"
In German: "Sortiere den Eingang", "Posteingang aufraumen"

## Example conversations

### Standard triage

**You:** Triage my inbox

**Sorter:** Inbox: 6 notes to process

1. [Meeting] 2026-03-18 -- Sprint Planning Q2
2. [Idea] 2026-03-19 -- New Onboarding Approach
3. [Task] 2026-03-20 -- Call Supplier by Wednesday
4. [Note] 2026-03-20 -- Client Feedback on Pricing
5. [Quote] 2026-03-21 -- Seneca on Time Management
6. [Email] 2026-03-21 -- Proposal Request From Luca

Here is my filing plan:

- Sprint Planning Q2 --> `06-Meetings/2026/03/` (linked to [[01-Projects/Product]])
- New Onboarding Approach --> `01-Projects/Rebrand/` (matches active project)
- Call Supplier --> extracted as task in today's daily note
- Client Feedback on Pricing --> `02-Areas/Sales/` (linked to [[05-People/Marco]])
- Seneca on Time Management --> `03-Resources/Quotes/`
- Proposal Request From Luca --> `01-Projects/Consulting/` (action required, high priority)

Shall I proceed?

---

### Priority triage

**You:** What needs attention?

**Sorter:** Priority scan of 8 inbox notes:

**Critical (act today):**
- "Call Supplier by Wednesday" -- deadline is tomorrow
- "Proposal Request From Luca" -- client waiting for response

**High (this week):**
- "Sprint Planning Q2" -- meeting notes with 3 unresolved action items
- "Client Feedback on Pricing" -- relates to active project decision

**Normal:**
- "New Onboarding Approach" -- idea, no deadline
- "Reading Notes -- Atomic Habits Ch3"

**Low:**
- "Seneca on Time Management" -- quote, archivable
- "Random Bookmarks List"

Want me to file the critical items first?

---

### Project pulse

**You:** Project pulse

**Sorter:** Project Pulse -- 2026-03-21

Most Active:
1. **Rebrand** -- 7 new notes this week (3 meetings, 2 ideas, 2 tasks)
2. **Consulting** -- 4 new notes (2 emails, 1 meeting, 1 task)

Quiet (no new notes in 7+ days):
- **Beta Launch** -- last note: 2026-03-10
- **Internal Tools** -- last note: 2026-03-05

Emerging Topics (not yet a project/area):
- "AI automation" mentioned in 4 recent notes -- consider creating a dedicated area?

## Works with

- **Scribe** -- most notes in the Inbox come from the Scribe
- **Postman** -- email and calendar imports land in the Inbox for the Sorter to process
- **Transcriber** -- meeting transcriptions arrive in the Inbox
- **Architect** -- when notes do not fit any existing folder, the Sorter flags the Architect to create new structure
- **Connector** -- after filing a batch, the Sorter can flag notes for the Connector to cross-link
- **Librarian** -- the Sorter reports duplicates and broken links it finds during triage

## Tips

- **Run it daily.** A small inbox is fast to process. A huge inbox takes longer and produces worse results because context fades.
- **Use smart batch when you have 10+ notes.** The Sorter will group related notes together, which produces better cross-links than one-by-one processing.
- **Trust the filing plan.** The Sorter always shows you where it intends to file before moving anything. Review the plan, approve, and move on.
- **Check the archive suggestions.** At the end of every triage, the Sorter flags stale notes. Archiving keeps your active areas lean.
- **Use project pulse weekly.** It is a quick way to see where your energy is actually going versus where you think it is going.
- **Never delete notes.** The Sorter follows a strict no-deletion policy. Notes are moved, archived, or merged -- never destroyed.
