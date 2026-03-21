# Postman

> Your bridge between Gmail, Google Calendar, and your vault.

## What it does

The Postman connects your email and calendar to your Obsidian vault. It scans your Gmail inbox, identifies what actually matters (action requests, deadlines, important information), and saves it as structured notes. It imports Google Calendar events as meeting prep notes. It can even create new calendar events from your vault content.

The Postman is a smart filter, not a bulk importer. It knows the difference between a critical email from a client requesting a proposal and a marketing newsletter. It recognizes deadlines, extracts action items, and creates notes with the right priority level. Everything it skips, it tells you about -- so you stay informed without your vault getting flooded with noise.

It works in four modes: email triage (scan and save important emails), calendar import (bring upcoming events into your vault), event creation (schedule something from a note or request), and targeted search (find specific emails or events on a topic).

## Capabilities

- **Email triage** -- scans unread Gmail messages, filters out noise (newsletters, notifications, receipts), and saves relevant emails as structured notes with action items and deadlines
- **VIP filter** -- prioritizes emails from important contacts (colleagues, clients, key people)
- **Calendar import** -- pulls upcoming Google Calendar events into the vault as meeting prep notes with participant lists and agenda
- **Event creation** -- creates Google Calendar events from your requests or from deadlines found in vault notes
- **Targeted search** -- searches Gmail or Calendar for specific topics, people, or date ranges
- **Deadline radar** -- extracts all upcoming deadlines from recent emails and presents them in one view
- **Meeting prep** -- creates pre-meeting notes from calendar events with participant context from your People folder
- **Weekly agenda** -- generates a week-at-a-glance view combining calendar events and email-sourced deadlines
- **Travel mode** -- when it detects travel-related events (flights, hotels, conferences), creates a consolidated travel itinerary note
- **Thread intelligence** -- reads entire email threads and synthesizes key points and latest developments
- **Attachment awareness** -- flags emails with attachments (cannot process them, but notes their existence)

## How to use it

Trigger the Postman for email and calendar tasks:

- "Check my email" / "Triage my inbox"
- "What's on my calendar this week?"
- "Create an event for Friday at 3pm"
- "Are there any urgent emails?"
- "Import this week's meetings"
- "Find emails about [topic]"
- "What deadlines are coming up?"
- "Prepare me for tomorrow's meetings"
- "Weekly agenda"

In Italian: "Controlla la mail", "Cosa ho in inbox", "Crea evento", "Cosa ho in calendario"
In French: "Verifie mes emails", "Qu'est-ce que j'ai au calendrier"
In Spanish: "Revisa mi correo", "Que hay en mi calendario"
In German: "Prufe meine Emails", "Was steht im Kalender"

## Example conversations

### Email triage

**You:** Check my email

**Postman:** Scanning your Gmail inbox... Found 28 unread messages.

Saved to vault (3):
- **"Proposal Request From Luca"** -- action required, high priority. Luca needs a project proposal by next Wednesday. Saved with action items and deadline.
- **"Contract Renewal Deadline April 15"** -- deadline alert. Saved with the date flagged.
- **"Sprint Demo Feedback from Client"** -- contains key decisions about the product direction. Saved as informational note.

Ignored (25):
- 12 newsletters and mailing lists
- 5 automated notifications (GitHub, Jira)
- 4 purchase receipts
- 3 system notifications (2FA, password resets)
- 1 CC-only thread with no action required

Needs your input (1):
- Email from an unknown sender about "partnership opportunity" -- cannot determine relevance. Want me to save it?

---

### Calendar import with meeting prep

**You:** What's on my calendar this week?

**Postman:** Your week ahead (March 22-28):

**Monday March 22:**
- 10:00-11:00 -- Sprint Planning with Marco, Sarah, Luca (Google Meet)
- 14:00-14:30 -- 1:1 with Manager

**Wednesday March 24:**
- 09:00-10:30 -- Client Demo (Zoom, external participants)
- 16:00-17:00 -- Team Retrospective

**Friday March 26:**
- 11:00-12:00 -- Budget Review (in person, Room 3B)

I can create meeting prep notes for any of these. For the Client Demo, I found 2 related notes in your vault that might be useful for preparation. Want me to import all events as vault notes?

---

### Event creation

**You:** Create an event for the proposal review -- next Thursday at 2pm, invite Marco and Luca, one hour, on Zoom

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

- **Sorter** -- all notes created by the Postman land in `00-Inbox/` for the Sorter to file
- **Architect** -- when emails or events reveal a new project, the Postman flags the Architect to create the folder structure
- **Transcriber** -- when a calendar event has a recording link (Zoom, Meet), the Postman flags it for the Transcriber
- **Connector** -- email threads that reference vault notes are flagged for cross-linking
- **Seeker** -- if a contact is not found in the vault, the Postman suggests searching with the Seeker
- **Food Coach** -- medical appointments, lab results, or dietary service emails are flagged
- **Wellness Guide** -- therapy session calendar events are cross-referenced with session notes

## Tips

- **Run email triage daily.** A quick scan takes under a minute and catches deadlines before they sneak up on you.
- **Use "deadline radar" on Mondays.** Start your week knowing every deadline that is coming from your emails.
- **Create meeting prep notes before important meetings.** The Postman pulls participant info from your People folder and links relevant vault notes.
- **Let it create calendar events from notes.** If a note contains a deadline or meeting plan, tell the Postman to schedule it -- saves you switching to Google Calendar.
- **Trust the noise filter.** The Postman is aggressive about filtering newsletters, notifications, and receipts. If it ever filters something important, tell it -- it learns from your corrections.
- **Check "needs your input" items.** The Postman flags ambiguous emails rather than guessing. These are usually worth a quick look.
- **Make sure Gmail and Google Calendar are connected.** The Postman needs API access to your accounts. Check `Meta/user-profile.md` to verify integrations are enabled, or ask the Architect during onboarding.
