# Obsidian Vault Crew

A Claude Code plugin providing 10 AI agents that manage an Obsidian vault through natural conversation.

## Installation

### Method 1: Plugin Install (Recommended)

```bash
/plugin install obsidian-vault-crew
```

Or use the interactive plugin manager:

```
/plugin
```

Then browse the **Discover** tab and select **obsidian-vault-crew**.

### Method 2: Manual Install from GitHub

```bash
# Clone the repo anywhere on your machine
git clone https://github.com/gnekt/obsidian-vault-crew.git

# Load it as a plugin in Claude Code
claude --plugin-dir /path/to/obsidian-vault-crew
```

Or add it directly to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "plugins": [
    "/absolute/path/to/obsidian-vault-crew"
  ]
}
```

### Method 3: Manual Skill Copy (Fallback)

If the plugin system doesn't work for you, copy the skills manually:

```bash
# Clone the repo
git clone https://github.com/gnekt/obsidian-vault-crew.git

# Copy all skills to your personal skills folder
cp -r obsidian-vault-crew/skills/* ~/.claude/skills/
```

## After Installation

1. Open Claude Code and start a conversation
2. Navigate to your Obsidian vault folder (or tell Claude where it is)
3. Say: **"Initialize my vault"**
4. The **Architect** agent will guide you through a friendly onboarding process

## Requirements

- **Claude Code** with a Claude Pro, Max, or Team subscription
- **Obsidian** (free) — [obsidian.md](https://obsidian.md)
- **Gmail MCP connector** (optional) — only needed for the Postman agent
- **Google Calendar MCP connector** (optional) — only needed for the Postman agent

## Plugin Structure

```
.claude-plugin/plugin.json    Plugin manifest
skills/                        All 10 agent skill files
  architect/SKILL.md           Vault setup & onboarding
  scribe/SKILL.md              Text capture & note creation
  sorter/SKILL.md              Inbox triage & filing
  seeker/SKILL.md              Search & knowledge retrieval
  connector/SKILL.md           Knowledge graph & link analysis
  librarian/SKILL.md           Vault health & maintenance
  transcriber/SKILL.md         Audio & meeting transcription
  postman/SKILL.md             Email & calendar integration
  food-coach/SKILL.md          Nutrition coaching (opt-in)
  wellness-guide/SKILL.md      Mental health support (opt-in)
references/                    Shared agent documentation
docs/                          User-facing documentation
```

## Language

All skill files are written in English. Agents automatically respond in whatever language the user writes in — no configuration needed.

## Development

To test changes locally without installing:

```bash
claude --plugin-dir ./
```

This loads the plugin for the current session only.
