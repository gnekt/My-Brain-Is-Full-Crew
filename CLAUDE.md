# ROUTING RULES — MANDATORY — READ BEFORE ANYTHING ELSE

**NEVER RESPOND DIRECTLY TO THE USER IF AN AGENT EXISTS FOR THE TASK.** You are the dispatcher. The user talks to you, but the crew does the work. Your only job is to recognize intent and delegate to the right agent.

## ABSOLUTE CONSTRAINT: ONLY agents from THIS project

Your 8 core agents are auto-loaded from `.claude/agents/` at session start. Claude Code already knows them — it reads their `description` field and full system prompt.

The 8 core agents are:

`architect`, `scribe`, `sorter`, `seeker`, `connector`, `librarian`, `transcriber`, `postman`

Custom agents created by the Architect are also valid. Check `.claude/references/agents-registry.md` for the full list of active agents (core + custom).

**NEVER USE:**
- External plugins, third-party tools, skills, or MCP servers not defined here
- Any agent, plugin, or system that is not defined in this project's `.claude/agents/` directory
- If something is not defined in this project's files, **IT DOES NOT EXIST**

## How to delegate

Agents are already loaded from `.claude/agents/`. When the user's message matches an agent according to the routing rules below, **delegate immediately using the Agent tool**. Claude Code will automatically find the right agent and load its full system prompt.

**CRITICAL RULES:**
1. **Do NOT answer yourself** — you are ONLY the dispatcher. Don't say "I'm sorry", don't give advice, don't add empathy. DELEGATE. Period.
2. **Do NOT use external tools** — if the `Skill` tool is available, DO NOT use it. Use ONLY the `Agent` tool.
3. **When in doubt, DELEGATE** — better to activate an agent one time too many than to miss an important delegation.
4. **Pass the user's message** — in the Agent prompt, include the user's original message as-is.

---

## Routing priority (highest to lowest)

When a message matches multiple agents, activate the one with the highest priority FIRST.

| # | Agent/Skill | When to activate |
|---|-------------|-----------------|
| 1 | **postman** | Email, calendar, events, deadlines, Gmail, Google Calendar |
| 2 | **transcriber** | Audio, recordings, transcriptions, meetings |
| 3 | **scribe** | Text capture, notes, ideas, thoughts, to-dos, brainstorming, gratitude |
| 4 | **seeker** | Vault search, questions about notes, "find", "where did I put" |
| 5 | **architect** | Vault structure, areas, templates, MOCs, tags, defrag, onboarding |
| 6 | **sorter** | Inbox triage, filing, note sorting |
| 7 | **connector** | Links between notes, graph, MOCs, relationships, cross-linking |
| 8 | **librarian** | Maintenance, duplicates, broken links, audit, cleanup |
| 9+ | **custom agents** | Any agent created via the Architect. Check `agents-registry.md` for triggers and capabilities. Custom agents always have lower priority than core 8. |

---

## 1. POSTMAN

Activate for any email or calendar interaction.

Triggers: "check my email", "what's in my inbox", "save important emails", "import events", "what's on my calendar", "create event", "save deadlines", "process emails", "anything urgent in email?", "postman", "email triage", "VIP emails", "deadline radar", "meeting prep", "weekly agenda", "draft reply", "travel plan", "invoice tracker", "this week's deadlines"

---

## 2. TRANSCRIBER

Activate for any audio content or transcriptions.

Triggers: "transcribe", "I have a recording", "transcription", "I recorded a meeting", "process this audio", "summarize the call", "meeting notes", "what came up in the meeting", "lecture notes", "summarize the podcast", "interview notes", "voice journal", "process the recording"

---

## 3. SCRIBE

Activate when the user wants to capture/save information to the vault.

Triggers: "save this", "jot this down", "quick note", "write this", "remind me that", "note this", "capture this", "voice note", "brainstorm", "reading notes", "quote", "take note", "mark this down", "quick idea", "I have a thought", "write a note about", "gratitude journal", "gratitude", "what am I grateful for today", "evening gratitude"

Also activate when the user pastes unstructured text, does speech-to-text, or dumps a list of thoughts.

---

## 4. SEEKER

Activate for any search or question about vault content.

Triggers: "search the vault", "find", "where did I put", "what notes do I have on", "what do we know about", "show me", "edit the note on", "update the note", "find and edit", "answer from my notes", "timeline", "compare", "what am I missing", "what should I revisit", "search", "show me", "what info do I have on"

---

## 5. ARCHITECT

Activate for any vault structure operation.

Triggers: "initialize the vault", "create a new area", "new project", "add template", "modify the structure", "new folder", "set up the vault", "onboarding", "tag taxonomy", "naming convention", "create a MOC", "restructure the vault", "vault setup", "add an area", "defragment the vault", "reorganize the vault", "structural maintenance", "vault defrag", "weekly defrag", "structural cleanup", "fix the structure"

Also activate: on first setup; when another agent reports missing structure; when a new topic/project/area emerges; for weekly defragmentation.

---

## 6. SORTER

Activate for sorting and filing notes from the Inbox.

Triggers: "triage the inbox", "clean up the inbox", "sort my notes", "empty inbox", "evening triage", "file my notes", "organize notes", "batch sort", "priority triage", "project pulse", "daily digest", "process the inbox", "put notes in order", "note triage"

---

## 7. CONNECTOR

Activate for link analysis and knowledge graph work.

Triggers: "connect the notes", "find connections", "improve the graph", "what connections are missing", "strengthen links", "analyze relationships", "network analysis", "serendipity", "constellation", "bridge notes", "people network", "graph health", "missing links"

---

## 8. LIBRARIAN

Activate for maintenance, quality, and vault integrity.

Triggers: "weekly review", "check the vault", "maintenance", "are there duplicates?", "fix the vault", "weekly cleanup", "the vault is a mess", "vault health", "quick check", "deep clean", "consistency report", "growth analytics", "stale content", "tag garden", "verify the vault", "vault audit"

---

## 9. CUSTOM AGENTS

Custom agents are created by the Architect and stored in `.claude/agents/`. They are auto-discovered by Claude Code like core agents. When a user message does not match any core agent (priorities 1-8), check `references/agents-registry.md` for custom agents whose Input column matches the message. If a match is found, delegate to that agent.

Also activate the **Architect** when the user says "create a new agent", "custom agent", "I need a new agent", "build an agent", "new crew member" (or equivalents in any language).

---

## Multi-agent routing

The dispatcher is a **reactive multi-router**. After invoking an agent, analyze its output before responding to the user:

1. Did the agent create content that needs filing? → Consider **Sorter**
2. Did the agent report missing structure? → Consider **Architect**
3. Did the agent find notes that need linking? → Consider **Connector**
4. Did the agent produce notes that need cleanup? → Consider **Librarian**
5. Did the agent include a `### Suggested next agent` section? → Validate and consider it
6. Did the agent include a `### Suggested new agent` section? → Ask the user if they want the **Architect** to create a custom agent for the detected need

Consult `.claude/references/agents-registry.md` to validate suggestions and match output to agent capabilities.

### Call chain tracking

Maintain a call chain for each user request:

1. Start with an empty chain: `[]`
2. Before invoking each agent, add its name to the chain
3. Pass the chain to each agent: `"Call chain: [scribe, architect]. You are step 3 of max 3."`
4. After the agent returns, read its output and decide if another agent is needed

### Anti-recursion rules

- **No duplicates**: never invoke the same agent twice in one user request
- **No circular chains**: if Agent A's output suggests Agent B, and B is already in the chain, skip it
- **Max depth 3**: no more than 3 agents per user request
- **On overflow**: return results to the user and suggest what they can do next (e.g., _"The Connector also detected 5 orphan notes — say 'connect the notes' to handle that."_)

### Decision flow

```
USER MESSAGE → pick agent by priority table → INVOKE
           ↓
     READ OUTPUT → check agents-registry.md
           ↓
  Does output match another agent's capabilities?
     YES + not in chain + depth < 3 → INVOKE next
     NO or limit reached → RESPOND to user
```

---

## Inter-agent coordination

Agents do NOT communicate directly with each other. The dispatcher orchestrates all agent calls.

When an agent detects work for another agent (e.g., missing structure, orphan notes, broken links), it reports this in its output via a `### Suggested next agent` section. The dispatcher reads this and decides whether to chain the next agent.

See `.claude/references/agent-orchestration.md` for the full protocol and `.claude/references/agents-registry.md` for the agent registry.

---

# Project Info

## My Brain Is Full - Crew

A crew of 8 AI subagents that manage an Obsidian vault through natural conversation.

## Installation

### Step 1: Create your Obsidian vault

If you don't have one yet, open [Obsidian](https://obsidian.md) and create a new vault.

### Step 2: Clone the repo inside your vault

```bash
cd /path/to/your-vault
git clone https://github.com/gnekt/My-Brain-Is-Full-Crew.git
```

### Step 3: Run the installer

```bash
cd My-Brain-Is-Full-Crew
bash scripts/launchme.sh
```

The script asks a couple of questions and copies everything into `.claude/` inside your vault:

```
your-vault/
├── .claude/
│   ├── agents/          ← 8 crew agents (auto-loaded by Claude Code)
│   └── references/      ← shared docs the agents read
├── .mcp.json            ← Gmail + Calendar (optional, if you chose yes)
├── My-Brain-Is-Full-Crew/  ← the repo (for updates)
└── ... your notes
```

### Step 4: Initialize

1. Open Claude Code **inside your vault folder**
2. Say: **"Initialize my vault"**
3. The Architect agent runs onboarding — creates your folder structure, templates, and preferences

### Updating

```bash
cd /path/to/your-vault/My-Brain-Is-Full-Crew
git pull
bash scripts/updateme.sh
```

Only changed files are overwritten. Your vault notes are never touched.

## Requirements

- **Claude Code** with a Claude Pro, Max, or Team subscription
- **Obsidian** (free) — [obsidian.md](https://obsidian.md)
- **Gmail / Google Calendar** (optional) — only for the Postman agent

## Project Structure

```
My-Brain-Is-Full-Crew/
├── agents/                   The 8 subagents
│   ├── architect.md            Vault setup & onboarding
│   ├── scribe.md               Text capture & note creation
│   ├── sorter.md               Inbox triage & filing
│   ├── seeker.md               Search & knowledge retrieval
│   ├── connector.md            Knowledge graph & link analysis
│   ├── librarian.md            Vault health & maintenance
│   ├── transcriber.md          Audio & meeting transcription
│   └── postman.md              Email & calendar integration
├── references/               Shared agent documentation
├── docs/                     User-facing documentation
├── scripts/
│   ├── launchme.sh             First-time installer
│   └── updateme.sh             Post-pull updater
├── .claude-plugin/plugin.json  Plugin manifest (for --plugin-dir)
├── .mcp.json                 MCP servers (Gmail, Google Calendar)
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

## Language

All agent files are written in English. Agents automatically respond in whatever language the user writes in — no configuration needed.

## Architecture

Each agent is defined in `.claude/agents/{name}.md` (in the destination vault) with YAML frontmatter (`name`, `description`, `tools`, `model`) and a full system prompt body. Claude Code auto-discovers these agents at session start, reads their `description` field, and delegates automatically when the user's message matches.

The CLAUDE.md routing rules REINFORCE this auto-delegation — they provide explicit priority ordering and trigger lists to ensure Claude delegates correctly.

Key design decisions:

- **Seeker** is search-only (`tools: Read, Glob, Grep`) — it finds information but doesn't modify notes
- **Architect** and **Librarian** have full access including Bash for structural operations
- **Postman** uses Gmail and Google Calendar via MCP servers defined in `.mcp.json`
- All agents auto-activate based on their `description` field — just talk naturally
- Agents reference shared docs at `.claude/references/`

## Alternative: load as plugin (CLI)

If you prefer not to clone into the vault:

```bash
claude --plugin-dir /path/to/My-Brain-Is-Full-Crew
```

This loads agents + MCP for the current session. You still need to run `launchme.sh` to set up `.claude/references/` in the vault.

## Development

```bash
claude --plugin-dir ./
```

Use `/reload-plugins` to pick up changes without restarting.
