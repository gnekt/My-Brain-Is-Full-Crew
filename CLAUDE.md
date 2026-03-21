# My Brain Is Full - Crew

A crew of 10 AI subagents that manage an Obsidian vault through natural conversation.

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
│   ├── agents/          ← 10 crew agents (auto-loaded by Claude Code)
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
├── agents/                   The 10 subagents
│   ├── architect.md            Vault setup & onboarding
│   ├── scribe.md               Text capture & note creation
│   ├── sorter.md               Inbox triage & filing
│   ├── seeker.md               Search & knowledge retrieval
│   ├── connector.md            Knowledge graph & link analysis
│   ├── librarian.md            Vault health & maintenance
│   ├── transcriber.md          Audio & meeting transcription
│   ├── postman.md              Email & calendar integration
│   ├── food-coach.md           Nutrition coaching (opt-in)
│   └── wellness-guide.md       Mental health support (opt-in)
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

Each agent is a **Claude Code subagent** — an isolated agent with its own system prompt, tool restrictions, and model assignment. Key design decisions:

- **Wellness Guide** is read-only (`disallowedTools: Write, Edit`) — it delegates note creation to the Scribe
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
