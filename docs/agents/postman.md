# Postman

> Your bridge between email (Gmail or Hey.com), Google Calendar, and your vault.

## What it does

The Postman connects your email and calendar to your Obsidian vault. It scans your inbox (Gmail via GWS CLI, Hey.com via Hey CLI, or Gmail via MCP as read-only fallback), identifies what actually matters (action requests, deadlines, important information), and saves it as structured notes. It imports Google Calendar events as meeting prep notes. It can even create new calendar events from your vault content.

The Postman is a smart filter, not a bulk importer. It knows the difference between a critical email from a client requesting a proposal and a marketing newsletter. It recognizes deadlines, extracts action items, and creates notes with the right priority level. Everything it skips, it tells you about, so you stay informed without your vault getting flooded with noise. When using Hey, the Postman leverages Hey's pre-sorted mailboxes (Imbox, Feed, Paper Trail, Reply Later, Set Aside, Bubble Up) for smarter triage.

It works in four modes: email triage (scan and save important emails), calendar import (bring upcoming events into your vault), event creation (schedule something from a note or request), and targeted search (find specific emails or events on a topic).

## Capabilities

Several of the Postman's more complex, multi-step flows have been promoted to dedicated skills that run as guided conversations:

| Capability | Now handled by |
|---|---|
| Email triage (scan and process unread emails) | `/email-triage` skill |
| Meeting prep (comprehensive meeting brief) | `/meeting-prep` skill |
| Weekly agenda (day-by-day week overview) | `/weekly-agenda` skill |
| Deadline radar (unified deadline timeline) | `/deadline-radar` skill |

What the Postman agent still does directly:

- **Calendar import**: pulls upcoming Google Calendar events into the vault as meeting prep notes with participant lists and agenda
- **Event creation**: creates Google Calendar events from your requests or from deadlines found in vault notes
- **Targeted search**: searches email (Gmail or Hey) or Calendar for specific topics, people, or date ranges
- **VIP filter**: prioritizes emails from important contacts (colleagues, clients, key people)
- **Email drafting**: drafts reply emails based on vault context
- **Travel mode**: when it detects travel-related events (flights, hotels, conferences), creates a consolidated travel itinerary note
- **Thread intelligence**: reads entire email threads and synthesizes key points and latest developments
- **Attachment awareness**: flags emails with attachments (cannot process them, but notes their existence)

## How to use it

Trigger the Postman for calendar and targeted email tasks. Some phrases invoke a dedicated skill instead of the agent:

- "Check my email" / "Triage my inbox" --> invokes the `/email-triage` skill
- "Prepare me for tomorrow's meetings" --> invokes the `/meeting-prep` skill
- "Weekly agenda" / "Plan my week" --> invokes the `/weekly-agenda` skill
- "What deadlines are coming up?" --> invokes the `/deadline-radar` skill
- "What's on my calendar this week?" --> Postman agent
- "Create an event for Friday at 3pm" --> Postman agent
- "Import this week's meetings" --> Postman agent
- "Find emails about [topic]" --> Postman agent
- "Draft a reply to [person]" --> Postman agent

In Italian: "Controlla la mail", "Cosa ho in inbox", "Crea evento", "Cosa ho in calendario"
In French: "Verifie mes emails", "Qu'est-ce que j'ai au calendrier"
In Spanish: "Revisa mi correo", "Que hay en mi calendario"
In German: "Prufe meine Emails", "Was steht im Kalender"

## Example conversations

### Email triage

**You:** Check my email

**Postman:** Scanning your inbox... Found 28 unread messages.

Saved to vault (3):
- **"Proposal Request From Luca"**: action required, high priority. Luca needs a project proposal by next Wednesday. Saved with action items and deadline.
- **"Contract Renewal Deadline April 15"**: deadline alert. Saved with the date flagged.
- **"Sprint Demo Feedback from Client"**: contains key decisions about the product direction. Saved as informational note.

Ignored (25):
- 12 newsletters and mailing lists
- 5 automated notifications (GitHub, Jira)
- 4 purchase receipts
- 3 system notifications (2FA, password resets)
- 1 CC-only thread with no action required

Needs your input (1):
- Email from an unknown sender about "partnership opportunity." Cannot determine relevance. Want me to save it?

---

### Calendar import with meeting prep

**You:** What's on my calendar this week?

**Postman:** Your week ahead (March 22-28):

**Monday March 22:**
- 10:00-11:00, Sprint Planning with Marco, Sarah, Luca (Google Meet)
- 14:00-14:30, 1:1 with Manager

**Wednesday March 24:**
- 09:00-10:30, Client Demo (Zoom, external participants)
- 16:00-17:00, Team Retrospective

**Friday March 26:**
- 11:00-12:00, Budget Review (in person, Room 3B)

I can create meeting prep notes for any of these. For the Client Demo, I found 2 related notes in your vault that might be useful for preparation. Want me to import all events as vault notes?

---

### Event creation

**You:** Create an event for the proposal review, next Thursday at 2pm, invite Marco and Luca, one hour, on Zoom

**Postman:** Here is what I will create:

- **Title:** Proposal Review
- **Date:** Thursday, March 27, 2026
- **Time:** 14:00 - 15:00
- **Location:** Zoom (I will add the link if you have a default Zoom room)
- **Attendees:** Marco, Luca

Shall I proceed?

**You:** Yes, go ahead

**Postman:** Event created on Google Calendar. I also created a meeting prep note in `00-Inbox/` linked to the related proposal notes in your vault.

## Works with

- **Sorter**: all notes created by the Postman land in `00-Inbox/` for the Sorter to file
- **Architect**: when emails or events reveal a new project, the Postman flags the Architect to create the folder structure
- **Transcriber**: when a calendar event has a recording link (Zoom, Meet), the Postman flags it for the Transcriber
- **Connector**: email threads that reference vault notes are flagged for cross-linking
- **Seeker**: if a contact is not found in the vault, the Postman suggests searching with the Seeker

## Tips

- **Run email triage daily.** A quick scan takes under a minute and catches deadlines before they sneak up on you.
- **Use "deadline radar" on Mondays.** Start your week knowing every deadline that is coming from your emails.
- **Create meeting prep notes before important meetings.** The Postman pulls participant info from your People folder and links relevant vault notes.
- **Let it create calendar events from notes.** If a note contains a deadline or meeting plan, tell the Postman to schedule it. Saves you switching to Google Calendar.
- **Trust the noise filter.** The Postman is aggressive about filtering newsletters, notifications, and receipts. If it ever filters something important, tell it. It learns from your corrections.
- **Check "needs your input" items.** The Postman flags ambiguous emails rather than guessing. These are usually worth a quick look.
- **Make sure at least one email backend is connected.** The Postman needs either GWS (`gws`), Hey CLI (`hey`), or MCP connectors to access your email. Check `Meta/user-profile.md` to verify integrations are enabled (including the `email_backend` setting if you have multiple backends), or ask the Architect during onboarding.

## What it remembers

The Postman keeps a post-it in `Meta/states/postman.md` with notes from its last run: when it last scanned the inbox, emails it saved to the vault, pending follow-ups, and upcoming deadlines it detected. This prevents re-processing the same emails and keeps deadline tracking continuous.
