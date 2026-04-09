# My Brain Is Full - Crew — Agent Directory

This reference is shared across all agents. Every agent knows the others, their responsibilities, and when to suggest them to the dispatcher.

---

## Agent Registry

For the definitive list of agents with capabilities, inputs, outputs, and status, see `.codex/references/agents-registry.md`. That file is the single source of truth — it supports both core and custom agents.

---

## Language Rule

**All agents respond in the user's language.** Match the language the user writes in. If the user switches languages mid-conversation, switch with them.

---

## User Profile

All agents read `Meta/user-profile.md` for personalization. This file is created during onboarding by the Architect and contains the user's name, language, role, health data (if opted in), and preferences. **Never hardcode personal data in agent files.**

---

## Agent Catalog

### 1. Architect

**Role**: Vault Structure & Governance
**Agent file**: `architect.md`
**Responsibilities**: Designs and maintains the vault's folder structure, templates, naming conventions, and tag taxonomy. The constitutional authority — sets the rules that all other agents follow. Creates and manages `Meta/user-profile.md`.
**Skills**: Complex flows (onboarding, defrag, agent creation/management) are handled by dedicated skills: `/onboarding`, `/defrag`, `/create-agent`, `/manage-agent`.
**Contact when**: A new folder, area, or project needs to be created. The vault structure seems wrong or incomplete. Template definitions are needed. Tag taxonomy needs updating. Another agent doesn't know where a note should live. The user wants to update their profile.

---

### 2. Scribe

**Role**: Fast Text Capture & Refinement
**Agent file**: `scribe.md`
**Responsibilities**: Turns raw, unstructured text into clean Obsidian notes quickly. Writes direct, low-risk captures in existing structure when the destination is obvious, uses richer capture modes in lighter-weight default ways, and escalates only architecture-level structure to Architect. Acts as a writing proxy for agents that operate in read-only mode.
**Contact when**: Raw text, quick thoughts, voice dumps, quotes, reading notes, or brainstorms need to be captured fast without overbuilding the structure.

---

### 3. Sorter

**Role**: Inbox Triage & Filing
**Agent file**: `sorter.md`
**Responsibilities**: Processes `00-Inbox/`, classifies notes, and moves them to their correct vault locations. Updates MOC files after filing. Handles smart batching, priority triage, and project pulse reporting.
**Skills**: Standard inbox triage is handled by the `/inbox-triage` skill.
**Contact when**: Notes are piling up in the inbox. A note was filed somewhere wrong. MOC files seem out of date.

---

### 4. Seeker

**Role**: Search, Retrieval & Synthesis
**Agent file**: `seeker.md`
**Responsibilities**: Finds and retrieves information across the vault using full-text search, metadata queries, and relationship navigation. Synthesizes answers from multiple notes with citations. May make narrow incidental fixes only when explicitly asked and only for obvious typos, broken wikilinks, small frontmatter mistakes, small factual corrections, or light formatting cleanup. Handles timeline mode, diff mode, and missing knowledge detection without resolving conflicts in place.
**Contact when**: Information needs to be found or verified before acting. A note's location is unknown. A cross-reference is needed. The user asks a factual question. A tiny safe fix is needed.

---

### 5. Connector

**Role**: Knowledge Graph & Link Analysis
**Agent file**: `connector.md`
**Responsibilities**: Analyzes the vault's link structure, discovers missing connections between notes, suggests wikilinks, updates existing MOCs, and strengthens the knowledge graph inside existing structure. Handles serendipity mode, bridge-note opportunities, constellation view, and people network analysis without taking over structural governance. Bridge notes are explicit follow-through artifacts, not the default outcome of graph analysis.
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
**Status**: `migration-gated` in the current Codex runtime.
**Responsibilities**: This role is preserved for future parity, but active email/calendar integrations are intentionally disabled during the current Codex migration.
**Skills**: `/email-triage`, `/meeting-prep`, `/weekly-agenda`, and `/deadline-radar` remain documented for future migration work, but they are not part of the active Codex dispatch surface yet.
**Contact when**: Not through active dispatch yet. If a user asks for these workflows, the dispatcher should explain that external integrations are still migration-gated.

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
| `/email-triage` | Postman | Migration-gated placeholder for future email scanning and prioritization |
| `/meeting-prep` | Postman | Migration-gated placeholder for future meeting brief preparation |
| `/weekly-agenda` | Postman | Migration-gated placeholder for future week-at-a-glance aggregation |
| `/deadline-radar` | Postman | Migration-gated placeholder for future deadline aggregation |
| `/transcribe` | Transcriber | Audio/transcript processing |
| `/vault-audit` | Librarian | Full 7-phase vault audit |
| `/deep-clean` | Librarian | Extended vault cleanup |
| `/tag-garden` | Librarian | Tag analysis and gardening |
| `/inbox-triage` | Sorter | Inbox note processing and routing |

---

## Quick Reference: When to Suggest Another Agent

When an agent detects work for another agent, it includes a `### Suggested next agent` section in its output. The dispatcher reads this and decides whether to chain the next agent. See `.codex/references/agent-orchestration.md` for the full protocol.

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
| "Cross-reference this with email" | Postman (migration-gated) |
| "This came from a meeting recording" | Transcriber |

---

## Custom Agents

Custom agents are created by the Architect and live in `.codex/agents/` alongside the core agents. They follow the same conventions: YAML frontmatter, trigger phrases written in the user's language, inter-agent coordination sections, and dispatcher-driven orchestration.

For the definitive list of all agents (core + custom) with capabilities, inputs, outputs, and status, see `.codex/references/agents-registry.md`.

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
- "List all agents" -> shows the active crew, the migration-gated Postman role, and any custom agents
