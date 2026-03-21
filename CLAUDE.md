# My Brain Is Full - Crew

A Claude Code plugin providing 10 AI subagents that manage an Obsidian vault through natural conversation.

## Installation

### Option 1: Claude Code Desktop (recommended — no terminal needed)

1. Open **Claude Code Desktop**
2. Go to **Personalizza** (Customize) → **Plugin personali** (Personal plugins)
3. Click the **+** button → **Carica plugin locale** (Load local plugin)
4. Upload the plugin folder (download and unzip from [GitHub](https://github.com/gnekt/My-Brain-Is-Full-Crew))
5. Done — the 10 agents are ready to use

### Option 2: Copy agents manually (CLI)

```bash
git clone https://github.com/gnekt/My-Brain-Is-Full-Crew.git
mkdir -p ~/.claude/agents
cp My-Brain-Is-Full-Crew/agents/*.md ~/.claude/agents/
```

The agents are now permanently available in every Claude Code session.

> **Note**: This method installs only the agents, not the MCP connectors for Gmail/Calendar. To use the Postman agent, also copy `.mcp.json` or configure Gmail and Google Calendar MCP manually.

### Option 3: Load as plugin from CLI

```bash
git clone https://github.com/gnekt/My-Brain-Is-Full-Crew.git
claude --plugin-dir /path/to/My-Brain-Is-Full-Crew
```

This loads the full plugin (agents + MCP) for the current session.

## After Installation

1. Open Claude Code **inside your Obsidian vault folder**
2. Say: **"Initialize my vault"**
3. The **Architect** agent runs a conversational onboarding and automatically:
   - Creates your vault folder structure
   - Copies the selected agents into `.claude/agents/` inside your vault
   - Creates `.mcp.json` at the vault root (if Gmail/Calendar selected)
4. After onboarding, the agents are **scoped to this vault only** — they won't appear in other projects

> **Why this matters:** installing as a Personal plugin makes agents available in every project. The Architect's onboarding installs a local copy inside the vault, which takes priority and keeps other Claude Code sessions clean.

## Requirements

- **Claude Code** with a Claude Pro, Max, or Team subscription
- **Obsidian** (free) — [obsidian.md](https://obsidian.md)
- **Gmail MCP connector** (optional) — only needed for the Postman agent. Included in `.mcp.json`
- **Google Calendar MCP connector** (optional) — only needed for the Postman agent. Included in `.mcp.json`

## Plugin Structure

```
.claude-plugin/plugin.json    Plugin manifest
.mcp.json                     MCP servers (Gmail, Google Calendar)
agents/                        The 10 subagents
  architect.md                 Vault setup & onboarding
  scribe.md                    Text capture & note creation
  sorter.md                    Inbox triage & filing
  seeker.md                    Search & knowledge retrieval
  connector.md                 Knowledge graph & link analysis
  librarian.md                 Vault health & maintenance
  transcriber.md               Audio & meeting transcription
  postman.md                   Email & calendar integration
  food-coach.md                Nutrition coaching (opt-in)
  wellness-guide.md            Mental health support (opt-in)
references/                    Shared agent documentation
docs/                          User-facing documentation
```

## Language

All agent files are written in English. Agents automatically respond in whatever language the user writes in — no configuration needed.

## Architecture

Each agent is a **Claude Code subagent** — an isolated agent with its own system prompt, tool restrictions, and model assignment. Key design decisions:

- **Wellness Guide** is read-only (`disallowedTools: Write, Edit`) — it delegates note creation to the Scribe
- **Seeker** is search-only (`tools: Read, Glob, Grep`) — it finds information but doesn't modify notes
- **Architect** and **Librarian** have full access including Bash for structural operations
- **Postman** uses Gmail and Google Calendar via MCP servers defined in `.mcp.json`
- All agents auto-activate based on their `description` field — just talk naturally

## Development

To test changes locally without installing:

```bash
claude --plugin-dir ./
```

This loads the plugin for the current session only. Use `/reload-plugins` to pick up changes without restarting.
