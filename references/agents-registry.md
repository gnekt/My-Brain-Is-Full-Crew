# Agent Registry

This file is the **single source of truth** for all active agents in the crew. The dispatcher (`CLAUDE.md`) and all agents reference this file for routing decisions and inter-agent coordination.

The registry is designed to grow: custom agents (see Issue #12) are added as new rows following the same schema.

---

## Registry

| Name | Role | Capabilities | Input | Output | Status |
|------|------|-------------|-------|--------|--------|
| architect | Vault Structure & Governance | Create/modify folders, templates, MOCs, tag taxonomy, naming conventions. Full Bash access. Runs onboarding. | Vault setup, new areas/projects, structural changes, defrag, onboarding | Folders created, templates defined, structure updated, MOCs generated | active |
| scribe | Text Capture & Refinement | Create notes in `00-Inbox/`, format raw text, handle voice-to-note, brainstorm, quotes, reading notes | Raw text, ideas, thoughts, voice input, quotes, brainstorm requests | Structured notes in `00-Inbox/` with frontmatter, tags, suggested connections | active |
| sorter | Inbox Triage & Filing | Move notes from inbox to correct locations, update MOCs, batch processing | Inbox triage, filing requests, note organization | Notes moved to correct folders, MOCs updated, triage reports | active |
| seeker | Search & Intelligence | Full-text search, metadata queries, relationship navigation, answer synthesis. Read-only by default. | Search queries, "find X", "where did I put", factual questions about vault content | Search results with citations, synthesized answers, knowledge gap reports | active |
| connector | Knowledge Graph & Link Analysis | Add/edit wikilinks, analyze graph structure, discover connections, bridge notes | Link analysis, "find connections", graph health, serendipity requests | New wikilinks added, graph health score, connection maps, bridge notes | active |
| librarian | Vault Health & Quality Assurance | Detect/merge duplicates, fix broken links, audit frontmatter, growth analytics. Full Bash access. | Maintenance, audit, cleanup, health check, duplicate detection | Health reports, fixed links, merged duplicates, consistency reports | active |
| transcriber | Audio & Meeting Intelligence | Process transcriptions into structured notes, extract action items, speaker detection | Audio recordings, transcriptions, meeting notes, lecture/podcast processing | Structured meeting/lecture notes in `00-Inbox/` with action items, decisions, topics | active |
| postman | Email & Calendar Intelligence | Read Gmail, search emails, read/create calendar events, draft replies. Uses MCP connectors. | Email triage, calendar queries, deadline tracking, meeting prep, VIP filtering | Email summaries saved as notes in `00-Inbox/`, calendar events created, deadline reports | active |

---

## Status Values

- **active**: Agent is operational and available for dispatch
- **disabled**: Agent is temporarily disabled — the dispatcher will skip it

---

## How This File Is Used

1. **Dispatcher** reads the `Input` column to match user messages to agents
2. **Dispatcher** reads `Output` + `Capabilities` of other agents to decide if chaining is needed after an agent returns
3. **Agents** reference this file when suggesting next agents in their output
4. **Custom agents** are added as new rows by the Architect during the custom agent creation flow

---

## Custom Agents

Custom agents are created by the Architect through a conversational flow with the user. They follow the exact same schema as core agents and are added as new rows in the Registry table above.

### How Custom Agents Are Added

1. The user asks the Architect to create a new agent (or an existing agent suggests one via `### Suggested new agent`)
2. The Architect conducts a detailed conversation to understand requirements
3. The Architect generates the agent file in `.claude/agents/`, adds a row to the Registry table above, and updates `agents.md`
4. Claude Code auto-discovers the new agent from its frontmatter

### Naming Rules

- Custom agent names must be lowercase, hyphens only (e.g., `habit-tracker`, `recipe-manager`)
- Names must NOT conflict with core agent names: architect, scribe, sorter, seeker, connector, librarian, transcriber, postman
- Names should be descriptive and concise (1-2 words)

### Priority

Custom agents always have lower routing priority than the 8 core agents. The dispatcher checks custom agents only when no core agent matches the user's message. Among custom agents, the dispatcher uses the Input column to find the best match
