# Real-World Usage Examples

Practical scenarios showing how the Crew works in daily life. Each example shows what you say and what happens behind the scenes.

---

## Scenario 1: The Brain Dump

**Situation**: You just got out of a meeting and your head is full of scattered thoughts.

**You say:**
> "Quick dump: Marco wants the API docs by Thursday, Lisa mentioned the budget is getting cut by 15%, I had an idea about using webhooks instead of polling for the notification system, and I need to book a dentist appointment"

**What happens:**
1. **Scribe** detects 4 distinct items
2. Creates 4 separate notes:
   - `Task: API Docs for Marco.md` (with deadline: Thursday, linked to `[[Marco]]`)
   - `Note: Budget Cut 15 Percent.md` (tagged with #budget, linked to `[[Lisa]]`)
   - `Idea: Webhooks for Notifications.md` (tagged with #architecture, #notifications)
   - `Task: Book Dentist Appointment.md` (tagged with #personal, #health)
3. All notes land in `00-Inbox/` with proper frontmatter
4. Scribe reports: *"Captured 4 notes: 2 tasks, 1 idea, 1 informational note. Shall I save them?"*

---

## Scenario 2: Evening Inbox Triage

**Situation**: End of the day. Your inbox has accumulated 12 notes.

**You say:**
> "Triage my inbox"

**What happens:**
1. The `/inbox-triage` skill scans all 12 notes in `00-Inbox/`
2. Reads each note's content and frontmatter
3. Files them:
   - 3 meeting notes go to `06-Meetings/2026/03/`
   - 2 project tasks go to `01-Projects/Rebrand/`
   - 1 person note goes to `05-People/`
   - 2 ideas go to `03-Resources/Ideas/`
   - 2 ambiguous notes are kept in inbox with questions for you
4. Updates 3 MOCs that gained new entries
5. Leaves a message for **Connector** to check new links
6. Reports the full summary with a clear breakdown

---

## Scenario 3: Meeting Transcription

**Situation**: You recorded a 45-minute sprint planning meeting and pasted the raw transcript.

**You say:**
> "Transcribe this meeting, it was the Q2 sprint planning with Marco, Lisa, and Ahmed. We met today at 10am."

*[pastes raw transcript]*

**What happens:**
1. The `/transcribe` skill processes the raw text
2. Identifies speakers from context
3. Generates:
   - Executive summary (4 sentences)
   - 8 key discussion points
   - 3 decisions made (with who decided and conditions)
   - Action items table (6 tasks, assigned to specific people, with deadlines)
   - Detailed notes organized by topic
   - 2 open questions for follow-up
4. Creates wikilinks to all participants: `[[Marco]]`, `[[Lisa]]`, `[[Ahmed]]`
5. Saves to `00-Inbox/` as `2026-03-21, Meeting, Q2 Sprint Planning.md`
6. Leaves message for **Postman**: "Check if there were pre-meeting emails about Q2 planning"

---

## Scenario 4: Email Triage

**Situation**: Monday morning. You want to know what's important in your email.

**You say:**
> "Check my email for anything urgent"

**What happens:**
1. The `/email-triage` skill scans your Gmail inbox (last 48 hours)
2. Reads 34 emails
3. Filters:
   - 22 newsletters/promos/notifications are ignored
   - 3 action requests are saved as notes with tasks
   - 2 deadline reminders are saved with deadline tags
   - 4 informational emails from key contacts are saved as reference notes
   - 1 meeting invitation is saved and flagged for calendar sync
   - 2 ambiguous emails are summarized for your decision
4. All notes land in `00-Inbox/`
5. Creates wikilinks to people in `05-People/`
6. Reports: *"34 emails scanned. 10 saved to vault (3 urgent, 2 deadlines, 4 info, 1 meeting). 22 filtered out. 2 need your input."*

---

## Scenario 7: Knowledge Discovery

**Situation**: You're writing a proposal and need context from your notes.

**You say:**
> "What do I know about microservices architecture? I need to write a proposal."

**What happens:**
1. **Seeker** searches your entire vault
2. Finds 7 relevant notes across different areas:
   - 2 meeting notes where architecture was discussed
   - 1 resource note on microservices patterns
   - 3 project notes that reference architectural decisions
   - 1 archived note from a past project
3. Synthesizes: *"Based on your notes, here's what you've documented about microservices..."*
4. Provides a structured summary with source citations (`[[Meeting: Architecture Review]]`, etc.)
5. Identifies a gap: *"Note: your vault has no notes on service mesh or container orchestration. You might want to add these to your proposal research."*

---

## Scenario 8: Weekly Review

**Situation**: Sunday morning. Time for your weekly vault check-up.

**You say:**
> "Run the weekly review"

**What happens:**
1. The `/vault-audit` skill runs a multi-phase audit:
   - Structure scan: all folders intact
   - Duplicate detection: found 1 near-duplicate
   - Link integrity: 3 broken links fixed automatically, 2 orphan notes flagged
   - Frontmatter audit: 5 notes missing tags (auto-fixed)
   - MOC review: 2 MOCs updated with new entries
   - Growth analytics: 23 notes added this week, vault health score: 94%
2. Generates a health report saved to `Meta/health-reports/`
3. Reports: *"Your vault is in great shape! 1 duplicate needs your decision, 2 orphan notes might need homes. Everything else is handled."*

---

## Scenario 10: Graph Intelligence

**Situation**: You want to understand how your knowledge connects.

**You say:**
> "Analyze my vault graph and find missing connections"

**What happens:**
1. **Connector** runs a full graph audit
2. Reports:
   - 247 notes, 412 links, average 1.7 links per note
   - 18 orphan notes (7%, under the 10% target)
   - 3 isolated clusters
   - Top connected note: your MOC/Engineering with 23 links
3. Discovers 12 suggested connections:
   - 4 strong (should definitely be linked)
   - 5 medium (probably useful)
   - 3 serendipitous (unexpected but interesting)
4. Presents each with explanation: *"Your note on 'Team Communication Patterns' should link to 'Sprint Retrospective Q1', because both discuss the same communication breakdown from different angles."*

---

## Codex CLI session examples

These examples show how to start and use the Crew with Codex CLI specifically.

### Install and launch

```bash
# Install Codex CLI
npm i -g @openai/codex@latest

# Install the Crew for Codex CLI
bash scripts/launchme.sh --platform codex-cli

# Launch Codex in your vault
codex -C /path/to/your-vault
```

### Verify the layout before your first session

```bash
# Non-interactive discovery smoke — confirms agents, skills, and dispatcher are visible
codex exec -C /path/to/your-vault "List the project custom agents under .codex/agents, the repo skills under .agents/skills, and the dispatcher file used in this workspace."

# Check MCP server visibility
codex -C /path/to/your-vault mcp list
```

### Using agents and skills inside Codex

Once inside the interactive `codex` session, the Crew works the same way as on other platforms — just talk naturally:

```
"Initialize my vault"          → /onboarding skill starts
"Save this note: quick idea"   → Scribe agent captures it
"Triage my inbox"              → /inbox-triage skill runs
"Check my email"               → /email-triage skill scans Gmail
"Weekly review"                → /vault-audit skill audits vault
```

### Update after a git pull

```bash
cd /path/to/your-vault/My-Brain-Is-Full-Crew
git pull
bash scripts/updateme.sh --platform codex-cli
```

For the full runtime smoke matrix covering all 8 agents, all 14 skills, bounded child-agent chaining, and MCP visibility, see [docs/codex-cli.md](codex-cli.md).

---

## Daily Workflow Cheat Sheet

| Time | What to say | Skill/Agent |
|------|------------|-------------|
| Morning | "What's on my calendar today?" | Postman agent |
| Morning | "Check my email" | `/email-triage` skill |
| Any time | "Save this: [thought]" | Scribe agent |
| After meeting | "Transcribe this meeting: [paste]" | `/transcribe` skill |
| Evening | "Triage my inbox" | `/inbox-triage` skill |
| Weekly | "Weekly review" | `/vault-audit` skill |
| When lost | "Find [topic]" | Seeker agent |
| When stuck | "Find connections for [note]" | Connector agent |

---

*These are just examples. The beauty of the Crew is that you don't need to memorize commands. Just talk naturally, and the right agent will pick it up.*
