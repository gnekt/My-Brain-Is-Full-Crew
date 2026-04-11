# Agent Registry

This file is the **single source of truth** for all active agents in the crew. The dispatcher (`AGENTS.md`) and all agents reference this file for routing decisions and inter-agent coordination.

The registry is designed to grow: custom agents (see Issue #12) are added as new rows following the same schema.

---

## Registry

| Name | Role | Capabilities | Input | Output | Status |
|------|------|-------------|-------|--------|--------|
| architect | Vault Structure & Governance | Create/modify folders, templates, MOCs, tag taxonomy, naming conventions. Full Bash access. Core onboarding and structure workflows route through dedicated skills. | Vault setup, new areas/projects, structural changes, defrag, onboarding | Folders created, templates defined, structure updated, MOCs generated | active |
| scribe | Fast Text Capture & Refinement | Capture raw text quickly, write direct low-risk notes in existing structure, escalate architecture-level structure to Architect, and handle voice-to-note, thread capture, reading notes, brainstorms, and quotes with lightweight defaults | Raw text, quick thoughts, voice input, quotes, thread dumps, reading notes, brainstorm requests | Refined notes in the best-fit location with frontmatter, tags, and lightweight connections | active |
| sorter | Inbox Triage & Filing | Move notes from inbox to correct locations, update MOCs, batch processing, priority-first safe filing, and non-blocking deferral of ambiguous items | Inbox triage, filing requests, note organization, priority-first cleanup | Notes moved to correct folders, MOCs updated, triage reports, deferred-item review lists | active |
| seeker | Search, Retrieval & Synthesis | Full-text search, metadata queries, relationship navigation, answer synthesis, and only narrow incidental fixes on explicit request. Read-only by default. | Search queries, "find X", "where did I put", factual questions about vault content, tiny safe fixes | Search results with citations, synthesized answers, knowledge gap reports, or small incidental corrections | active |
| connector | Knowledge Graph & Link Analysis | Add/edit wikilinks, update existing MOCs, analyze graph structure, discover connections, and create bridge notes only in explicit bridge-note workflows | Link analysis, "find connections", graph health, serendipity requests, explicit bridge-note workflows | New wikilinks added, existing MOCs strengthened, graph health score, connection maps, or bridge-note opportunities | active |
| librarian | Vault Health & Quality Assurance | Detect/merge duplicates, fix broken links, audit frontmatter, growth analytics. Full Bash access. | Maintenance, audit, cleanup, health check, duplicate detection | Health reports, fixed links, merged duplicates, consistency reports | active |
| transcriber | Audio & Meeting Intelligence | Process transcriptions into structured notes, extract action items, speaker detection | Audio recordings, transcriptions, meeting notes, lecture/podcast processing | Structured meeting/lecture notes in `00-Inbox/` with action items, decisions, topics | active |
| note-update | Compounded Note Maintenance & Git Sync | Formalize substantive inbox notes into Learning, deduplicate safely, update wikilinks and MOCs, rerun Learning orphan audit, update STATUS, and complete pull/rebase/commit/push workflow | "note-update", "整理筆記並推送", "正式化 inbox 筆記", "跑 orphan audit 然後 push", end-to-end note maintenance requests | Formalized notes, dedupe cleanup, refreshed `Learning/INDEX_Orphans.md`, updated STATUS entries, and synced git changes | active |
| llm-wiki | Obsidian-First Knowledge Ingest & Routing | Ingest external sources into Obsidian, route into Learning/Lumentum, rewrite into structured notes, maintain index/log/cross-links, optionally sync Notion input database and git | "llm-wiki", "用 llm-wiki", "整理到 Obsidian", "從 Notion/YouTube 重寫筆記", workflow requests for Learning/Lumentum routing and link maintenance | Structured destination notes, refreshed area indexes/logs, stronger wikilinks/MOCs, optional Notion sync results, and optional git sync | active |
| postman | Email & Calendar Intelligence | Reserved for future Codex parity. External email/calendar integrations are currently migration-gated and must not be dispatched from the active runtime. | Email triage, calendar queries, deadline tracking, meeting prep, VIP filtering | For now, explain that external integrations are not yet enabled in the Codex migration runtime | migration-gated |

---

## Status Values

- **active**: Agent is operational and available for dispatch
- **disabled**: Agent is temporarily disabled — the dispatcher will skip it
- **migration-gated**: Agent or skill is intentionally excluded from active Codex dispatch until its external/runtime dependencies are migrated

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
3. The Architect generates the agent file in `.codex/agents/`, adds a row to the Registry table above, and updates `agents.md`
4. The installed runtime exposes the new agent from `.codex/agents/`, and the dispatcher can route to it using the registry plus its frontmatter description

### Naming Rules

- Custom agent names must be lowercase, hyphens only (e.g., `habit-tracker`, `recipe-manager`)
- Names must NOT conflict with core agent names: architect, scribe, sorter, seeker, connector, librarian, transcriber, postman
- Names should be descriptive and concise (1-2 words)

### Priority

Custom agents always have lower routing priority than the active core agent set. The dispatcher checks custom agents only when no active core agent matches the user's message. Among custom agents, the dispatcher uses the Input column to find the best match

---

## Skills Registry

Skills handle complex, multi-step workflows extracted from agents. They are checked **before** agents by the dispatcher (higher priority). Skills run in the main conversation context, preserving multi-turn state.

| Skill | Source Agent | Triggers | Purpose | Status |
|-------|-------------|----------|---------|--------|
| `/onboarding` | architect | "initialize the vault", "set up the vault", "onboarding", "vault setup" | Full vault setup conversation | active |
| `/create-agent` | architect | "create a new agent", "custom agent", "I need a new agent", "build an agent", "new crew member" | Custom agent creation (6-phase interview) | active |
| `/manage-agent` | architect | "edit my agent", "update agent", "remove agent", "delete agent", "list agents", "show my agents" | Edit, remove, list custom agents | active |
| `/defrag` | architect | "defragment the vault", "reorganize the vault", "structural maintenance", "vault defrag", "weekly defrag" | Weekly vault defragmentation (5-phase audit) | active |
| `/email-triage` | postman | "check my email", "what's in my inbox", "process emails", "email triage", "anything urgent in email?" | Reserved for future Codex parity; current runtime must explain that email integrations are migration-gated | migration-gated |
| `/meeting-prep` | postman | "prepare for meeting", "meeting prep", "brief me for the meeting", "get ready for the call" | Reserved for future Codex parity; current runtime must explain that meeting-email/calendar enrichment is migration-gated | migration-gated |
| `/weekly-agenda` | postman | "weekly agenda", "what's this week", "week overview", "plan my week" | Reserved for future Codex parity; current runtime must explain that external week aggregation is migration-gated | migration-gated |
| `/deadline-radar` | postman | "deadline radar", "what are my deadlines", "this week's deadlines", "upcoming deadlines" | Reserved for future Codex parity; current runtime must explain that external deadline aggregation is migration-gated | migration-gated |
| `/transcribe` | transcriber | "transcribe", "I have a recording", "process this audio", "meeting notes from recording", "summarize the call" | Audio/transcript processing with structured notes | active |
| `/vault-audit` | librarian | "weekly review", "check the vault", "vault audit", "full audit", "vault health" | Full 7-phase vault audit | active |
| `/deep-clean` | librarian | "deep clean", "deep cleanup", "thorough cleanup", "the vault is a mess" | Extended vault cleanup with stale content detection | active |
| `/tag-garden` | librarian | "tag garden", "clean up tags", "tag cleanup", "tag audit" | Tag analysis: unused, orphan, near-duplicates | active |
| `/inbox-triage` | sorter | "triage the inbox", "clean up the inbox", "sort my notes", "empty inbox", "file my notes", "process the inbox" | Inbox note processing, classification, and routing | active |
| `/contact-sync` | postman | "sync contact", "add to contacts", "save contact", "update contact", "is this person in my contacts" | Sync person to Apple Contacts (search, create, update). Requires `apple-contacts` MCP. | active |

### How Skills Are Routed

1. The dispatcher checks the **skill routing table** (in `AGENTS.md`) before the agent routing table
2. If a trigger matches, the dispatcher runs the skill in the main conversation context instead of invoking an agent file
3. If no skill matches, the dispatcher falls through to agent routing
4. Skills can produce `### Suggested next agent` output, which the dispatcher handles using the same chaining rules as agents
