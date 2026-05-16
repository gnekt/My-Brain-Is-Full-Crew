# Codex CLI Guide

This guide covers everything you need to install, update, and run My Brain Is Full — Crew on [Codex CLI](https://openai.com/codex) (`@openai/codex`).

> **Windows note:** Codex CLI's Windows support is experimental. If you are on Windows, running inside WSL (Windows Subsystem for Linux) is strongly recommended.

---

## Install and update commands

### First-time install

```bash
# Install Codex CLI globally
npm i -g @openai/codex@latest

# Clone the repo inside your vault and install the Crew
cd /path/to/your-vault
git clone https://github.com/gnekt/My-Brain-Is-Full-Crew.git
cd My-Brain-Is-Full-Crew
bash scripts/launchme.sh --platform codex-cli
```

The installer accepts an optional `--target` flag if you want to point it at a vault in a non-standard location:

```bash
bash scripts/launchme.sh --platform codex-cli --target /path/to/your-vault
```

### Update after a git pull

```bash
cd /path/to/your-vault/My-Brain-Is-Full-Crew
git pull
bash scripts/updateme.sh --platform codex-cli
```

The updater auto-detects Codex CLI by checking for `.codex/agents` in your vault. If multiple platforms are installed, pass `--platform codex-cli` explicitly.

---

## What installs where

After running `launchme.sh --platform codex-cli`, your vault will contain:

```
your-vault/
├── .codex/
│   ├── agents/          ← 8 core agent files (7 active + 1 migration-gated Postman role)
│   ├── references/      ← shared docs the agents read
│   └── config.toml      ← MCP server definitions + profiles + sandbox policy
├── .agents/
│   └── skills/          ← 14 skill definitions (10 active + 4 migration-gated Postman skills)
├── Meta/
│   └── scripts/         ← orchestra scripts (permission-free agent commands)
└── AGENTS.md            ← dispatcher (project instructions for Codex)
```

## Current Codex scope

The current Codex runtime is intentionally narrower than the full cross-platform source tree:

- Active agents: `architect`, `scribe`, `sorter`, `seeker`, `connector`, `librarian`, `transcriber`
- Active skills: `/onboarding`, `/create-agent`, `/manage-agent`, `/defrag`, `/transcribe`, `/vault-audit`, `/deep-clean`, `/tag-garden`, `/inbox-triage`, `/contact-sync`
- Migration-gated until external integration parity lands: `postman`, `/email-triage`, `/meeting-prep`, `/weekly-agenda`, `/deadline-radar`

Key differences from other platforms:

| Path | Purpose |
|------|---------|
| `.codex/agents/*.toml` | Custom agent definitions (Codex native format) |
| `.agents/skills/` | Repo-scoped skill instructions (shared discovery path) |
| `.codex/config.toml` | MCP servers, approval policy, sandbox mode, model profiles |
| `AGENTS.md` | Dispatcher — Codex reads this as its primary project instruction file |

---

## Architecture differences from Claude Code, Gemini CLI, and OpenCode

### Dispatcher

All platforms use a dispatcher file, but the name and format differ:

| Platform | Dispatcher file |
|----------|----------------|
| Claude Code | `CLAUDE.md` |
| Gemini CLI | `GEMINI.md` |
| OpenCode | `AGENTS.md` |
| Codex CLI | `AGENTS.md` (with root-context routing header) |

Codex CLI shares the `AGENTS.md` name with OpenCode but prepends a routing header that handles orchestration within the `agents.max_depth = 1` constraint (see below).

### Agent format

Claude Code, Gemini CLI, and OpenCode all use Markdown (`.md`) agent files. Codex CLI uses TOML:

```
.claude/agents/architect.md        ← Claude Code
.gemini/agents/architect.md        ← Gemini CLI
.opencode/agents/architect.md      ← OpenCode
.codex/agents/architect.toml       ← Codex CLI
```

### Skills location

Skills install to `.agents/skills/` for Codex (not `.codex/skills/`). Codex CLI discovers skills from this shared path.

### Agent chaining (max_depth constraint)

Codex CLI enforces `agents.max_depth = 1`. This means child agents can only go one level deep. My Brain Is Full — Crew handles this through root-context orchestration:

- The dispatcher embeds orchestration instructions in the root context (not in a child)
- Child agents (`spawn_agent`) finish one bounded task and return to root
- Any next step is decided from the root context, not by a nested child

### Tool name differences

Codex CLI does not have the `AskUserQuestion` or `request_user_input` tools. The equivalent patterns are:

| Source concept | Codex CLI equivalent |
|---|---|
| `AskUserQuestion` | Ask a direct question in the chat thread and wait for the reply |
| `request_user_input` | Same — use the root conversation for follow-up questions |
| `Skill tool` | Follow the skill instructions directly in the root context |
| `Agent tool` | Use `spawn_agent` for a bounded child task; orchestration returns to root |
| `max chain depth 3` | `agents.max_depth = 1` with root-only orchestration |
| `.mcp.json` | `.codex/config.toml` |

### MCP configuration

Claude Code uses `.mcp.json`. Codex CLI uses `.codex/config.toml`. The MCP server, approval policy, sandbox mode, and model profile settings all live in the TOML config. The CLI and Codex IDE extension share this same config file.

---

## Runtime smoke matrix

Use this table to verify the Crew works correctly in a real Codex vault after install or update. Run each row and compare the result against the expected outcome.

| Surface | Name | Prompt or command | Expected result |
|---------|------|-------------------|----------------|
| Agent | Architect | `@Architect Set up my vault structure` | Architect starts onboarding conversation or confirms vault is already set up |
| Agent | Scribe | `@Scribe Save this note: quick test` | Scribe creates a note in 00-Inbox with proper frontmatter |
| Agent | Sorter | `@Sorter Triage my inbox` | Sorter reviews inbox notes and files them, or reports inbox is empty |
| Agent | Seeker | `@Seeker What do I know about this project?` | Seeker searches the vault and returns results with source citations |
| Agent | Connector | `@Connector Find connections in my recent notes` | Connector analyzes the vault graph and suggests wikilinks |
| Agent | Librarian | `@Librarian Run a vault health check` | Librarian scans for broken links, duplicates, and orphan notes |
| Agent | Transcriber | `@Transcriber Process this transcript: [paste text]` | Transcriber generates structured meeting notes |
| Agent | Postman | `@Postman Check my email` | Dispatcher explains that Postman is migration-gated in Codex and does not enter external email/calendar workflows |
| Skill | onboarding | `/onboarding` | Architect starts the full onboarding conversation |
| Skill | create-agent | `/create-agent` | Architect walks through designing a new custom agent |
| Skill | manage-agent | `/manage-agent` | Architect lists, edits, or removes custom agents |
| Skill | defrag | `/defrag` | Architect runs the 5-phase vault defragmentation |
| Skill | email-triage | `/email-triage` | Dispatcher explains that email triage is migration-gated in Codex |
| Skill | meeting-prep | `/meeting-prep` | Dispatcher explains that meeting-email/calendar enrichment is migration-gated in Codex |
| Skill | weekly-agenda | `/weekly-agenda` | Dispatcher explains that external week aggregation is migration-gated in Codex |
| Skill | deadline-radar | `/deadline-radar` | Dispatcher explains that external deadline aggregation is migration-gated in Codex |
| Skill | transcribe | `/transcribe` | Transcriber processes a recording or transcript into structured notes |
| Skill | vault-audit | `/vault-audit` | Librarian runs the full 7-phase vault audit |
| Skill | deep-clean | `/deep-clean` | Librarian runs the extended vault cleanup |
| Skill | tag-garden | `/tag-garden` | Librarian analyzes and cleans up tags |
| Skill | inbox-triage | `/inbox-triage` | Sorter processes and routes all inbox notes |
| Skill | contact-sync | `/contact-sync` | Postman syncs contacts to Apple Contacts |
| Chaining | bounded child-agent chain | `@Sorter Triage my inbox` (with notes present that mention a new project) | Sorter files notes, then dispatcher signals Architect to create the new project folder; child returns to root before Architect runs |
| MCP | MCP visibility | `codex -C <vault> mcp list` | Lists the MCP servers configured in `.codex/config.toml`, or shows the auth/setup state for each server |

### Running the non-interactive discovery smoke

```bash
codex exec -C <vault> "List the project custom agents under .codex/agents, the repo skills under .agents/skills, and the dispatcher file used in this workspace."
```

Expected output references:
- `AGENTS.md` (the dispatcher)
- `.codex/agents` path (custom agents)
- `.agents/skills` path (repo skills)

### Running the MCP visibility smoke

```bash
codex -C <vault> mcp list
```

Expected: lists MCP servers from `.codex/config.toml` (e.g., `Gmail`, `Calendar`) or shows their auth/setup state.

---

## Troubleshooting

### Agents are not discovered

- Verify `.codex/agents/` exists in your vault root and contains `.toml` files.
- Open Codex CLI from your vault directory: `codex -C /path/to/your-vault`
- Check that `AGENTS.md` exists at the vault root (not inside the repo subdirectory).

### Skills are not available

- Verify `.agents/skills/` exists in your vault root and contains subdirectories.
- Skills must be at the vault root level: `<vault>/.agents/skills/<skill-name>/`

### Child agent chain does not return to root

- This is a Codex `agents.max_depth = 1` constraint. Child agents can only go one level deep.
- The dispatcher uses root-context orchestration to work within this constraint.
- If a task seems to require deeper nesting, flatten it: complete the first bounded step in a child, then handle the next step in the root context.

### MCP server not connecting

- MCP configuration lives in `.codex/config.toml` (not `.mcp.json`).
- Check `codex -C <vault> mcp list` to see the current server status.
- Gmail and Google Calendar entries may still appear in `.codex/config.toml`, but the corresponding Postman workflows are migration-gated in the current Codex runtime.
- For Apple Contacts, verify the `apple-contacts` server entry in `.codex/config.toml`.

### Codex errors about approvals

- Child agent approvals surface in the child thread. Approve or deny there, then continue orchestration from the root context after the child returns.
- If a task requires deeper recursion, stop spawning children and flatten the next step into the root context or split the work into separate bounded child tasks.

### Windows users

Codex CLI's Windows support is experimental. Use WSL (Windows Subsystem for Linux) for the most reliable experience. From WSL, follow the standard Linux install path above.

### Reinstall vs update

- **Reinstall** (`launchme.sh`): Use when setting up a new vault or recovering from a broken state.
- **Update** (`updateme.sh`): Use after `git pull` to push new agents, skills, and references to an existing vault. Custom agents are never overwritten.

For a migration from another platform, see [docs/codex-migration.md](codex-migration.md).
