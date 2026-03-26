# My Brain Is Full - Crew — Agent Directory

This reference is shared across all agents. Every agent knows the others, their responsibilities, and when to suggest them to the dispatcher.

---

## Agent Registry

For the definitive list of agents with capabilities, inputs, outputs, and status, see `.claude/references/agents-registry.md`. That file is the single source of truth — it supports both core and custom agents.

---

## Language Rule

**All agents respond in the user's language.** Match the language the user writes in. If the user switches languages mid-conversation, switch with them.

---

## User Profile

All agents read `Meta/user-profile.md` for personalization. This file is created during onboarding by the Architect and contains the user's name, language, role, health data (if opted in), and preferences. **Never hardcode personal data in agent files.**

---

## The Eight Agents

### 1. Architect

**Role**: Vault Structure & Governance
**Agent file**: `architect.md`
**Responsibilities**: Designs and maintains the vault's folder structure, templates, naming conventions, and tag taxonomy. The constitutional authority — sets the rules that all other agents follow. Creates and manages `Meta/user-profile.md`.
**Skills**: Complex flows (onboarding, defrag, agent creation/management) are handled by dedicated skills: `/onboarding`, `/defrag`, `/create-agent`, `/manage-agent`.
**Contact when**: A new folder, area, or project needs to be created. The vault structure seems wrong or incomplete. Template definitions are needed. Tag taxonomy needs updating. Another agent doesn't know where a note should live. The user wants to update their profile.

---

### 2. Scribe

**Role**: Text Capture & Refinement
**Agent file**: `scribe.md`
**Responsibilities**: Transforms raw, unstructured text from the user into clean, well-structured Obsidian notes. Handles voice-to-note, brainstorm mode, quote capture, reading notes. Acts as writing proxy for agents that operate in read-only mode. All output lands in `00-Inbox/`.
**Contact when**: A note needs to be cleaned up or reformatted. Raw text needs to be turned into a structured note.

---

### 3. Sorter

**Role**: Inbox Triage & Filing
**Agent file**: `sorter.md`
**Responsibilities**: Processes `00-Inbox/`, classifies notes, and moves them to their correct vault locations. Updates MOC files after filing. Handles smart batching, priority triage, and project pulse reporting.
**Skills**: Standard inbox triage is handled by the `/inbox-triage` skill.
**Contact when**: Notes are piling up in the inbox. A note was filed somewhere wrong. MOC files seem out of date.

---

### 4. Seeker

**Role**: Search & Intelligence
**Agent file**: `seeker.md`
**Responsibilities**: Finds and retrieves information across the vault using full-text search, metadata queries, and relationship navigation. Synthesizes answers from multiple notes with citations. Can modify notes on request. Handles timeline mode, diff mode, and missing knowledge detection.
**Contact when**: Information needs to be found or verified before acting. A note's location is unknown. A cross-reference is needed. The user asks a factual question.

---

### 5. Connector

**Role**: Knowledge Graph & Link Analysis
**Agent file**: `connector.md`
**Responsibilities**: Analyzes the vault's link structure, discovers missing connections between notes, suggests wikilinks, and strengthens the knowledge graph. Handles serendipity mode, bridge notes, constellation view, and people network analysis.
**Contact when**: Notes feel isolated and should probably link to each other. After a batch of notes is filed. MOC coverage seems low.

---

### 6. Librarian

**Role**: Vault Health & Quality Assurance
**Agent file**: `librarian.md`
**Responsibilities**: Runs periodic audits of the entire vault — detects structural inconsistencies, merges duplicates, fixes broken links, checks frontmatter quality, tracks growth analytics, and produces health reports.
**Skills**: Full audit, deep clean, and tag garden are handled by skills: `/vault-audit`, `/deep-clean`, `/tag-garden`.
**Contact when**: Vault-wide quality issues are suspected. Something seems structurally wrong. Duplicates, broken links, or inconsistent tags are detected.

---

### 7. Transcriber

**Role**: Audio & Meeting Intelligence
**Agent file**: `transcriber.md`
**Responsibilities**: Processes audio recordings and raw transcriptions into richly structured notes. Handles meeting notes, lecture notes, podcast summaries, voice journals, and interview extraction. All output lands in `00-Inbox/`.
**Skills**: All transcription processing is handled by the `/transcribe` skill. The agent handles only edge cases.
**Contact when**: A meeting recording or transcript needs to be structured. A note should be created from an audio source.

---

### 8. Postman

**Role**: Email & Calendar Intelligence
**Agent file**: `postman.md`
**Requires**: Google Workspace CLI (`gws`) for full read/write access, or MCP connectors (read-only fallback). See `docs/gws-setup-guide.md`.
**Responsibilities**: Scans Gmail for actionable emails, archives/deletes/labels emails, imports Google Calendar events, creates calendar events. Handles VIP filtering and contact enrichment.
**Skills**: Email triage, meeting prep, weekly agenda, and deadline radar are handled by skills: `/email-triage`, `/meeting-prep`, `/weekly-agenda`, `/deadline-radar`.
**Contact when**: Important information may have arrived by email. Meeting notes should be cross-referenced with calendar events. An event needs to be created from a note.

---

## Skills

Skills handle complex, multi-step workflows that were extracted from agents for better performance. They run in the main conversation context (not as subprocesses), which allows multi-turn conversations.

The dispatcher routes triggers to skills FIRST, then falls through to agents.

| Skill | Source Agent | Purpose |
|-------|-------------|---------|
| `/onboarding` | Architect | Full vault setup conversation |
| `/create-agent` | Architect | Custom agent creation (6-phase interview) |
| `/manage-agent` | Architect | Edit, remove, list custom agents |
| `/defrag` | Architect | Weekly vault defragmentation |
| `/email-triage` | Postman | Email scanning and prioritization |
| `/meeting-prep` | Postman | Meeting brief preparation |
| `/weekly-agenda` | Postman | Week-at-a-glance overview |
| `/deadline-radar` | Postman | Deadline timeline from all sources |
| `/transcribe` | Transcriber | Audio/transcript processing |
| `/vault-audit` | Librarian | Full 7-phase vault audit |
| `/deep-clean` | Librarian | Extended vault cleanup |
| `/tag-garden` | Librarian | Tag analysis and gardening |
| `/inbox-triage` | Sorter | Inbox note processing and routing |

---

## Quick Reference: When to Suggest Another Agent

When an agent detects work for another agent, it includes a `### Suggested next agent` section in its output. The dispatcher reads this and decides whether to chain the next agent. See `.claude/references/agent-orchestration.md` for the full protocol.

| Situation | Suggest |
|-----------|---------|
| "Don't know where to file this note" | Architect |
| "This area/folder doesn't exist" | Architect |
| "Tag doesn't exist in taxonomy" | Architect |
| "Template is missing or wrong" | Architect |
| "User wants to update their profile" | Architect |
| "Found a duplicate note" | Librarian |
| "Found a broken link" | Librarian |
| "Note has wrong frontmatter" | Librarian |
| "Vault structure seems inconsistent" | Librarian |
| "This note should link to others" | Connector |
| "Found related but unlinked notes" | Connector |
| "Need to find an existing note" | Seeker |
| "Cross-reference this with email" | Postman |
| "This came from a meeting recording" | Transcriber |

---

## Custom Agents

Custom agents are created by the Architect and live in `.claude/agents/` alongside the core agents. They follow the same conventions: YAML frontmatter, trigger phrases written in the user's language, inter-agent coordination sections, and dispatcher-driven orchestration.

For the definitive list of all agents (core + custom) with capabilities, inputs, outputs, and status, see `.claude/references/agents-registry.md`.

### How Custom Agents Coordinate

Custom agents participate in the same orchestration protocol as core agents:
- They include `### Suggested next agent` sections when they detect work for other agents
- They include `### Suggested new agent` sections when they detect missing capabilities
- The dispatcher chains them like any other agent, subject to the same anti-recursion rules
- They count toward the max depth of 3 agents per user request

### Creating a Custom Agent

Say "create a new agent" or "I need a custom agent" to start the process. The `/create-agent` skill guides you through a 6-phase interview to define the agent's purpose, triggers, permissions, and coordination rules.

### Managing Custom Agents

Use the `/manage-agent` skill:
- "Edit my custom agent X" -> modifies it
- "Remove custom agent X" -> deactivates it (with user confirmation)
- "List all agents" -> shows core 8 + any custom agents
