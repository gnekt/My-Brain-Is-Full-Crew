# Migrating to Codex CLI

This guide covers how to move an existing My Brain Is Full — Crew installation from Claude Code, Gemini CLI, or OpenCode to Codex CLI. It also explains what transfers automatically and what needs manual attention.

> **If you are doing a fresh install** (not migrating), follow [docs/codex-cli.md](codex-cli.md) instead.

---

## When to reinstall vs update

| Scenario | Recommended action |
|----------|-------------------|
| You have an existing Claude Code / Gemini CLI / OpenCode vault and want to add Codex CLI alongside it | Run `bash scripts/launchme.sh --platform codex-cli` in the same vault — multiple platforms can coexist |
| You want to switch exclusively to Codex CLI | Run `launchme.sh --platform codex-cli`; the other platform files remain but are inactive |
| Your Codex layout is broken or missing files | Run `launchme.sh --platform codex-cli` again — it is idempotent and safe to re-run |
| You pulled new repo changes and want to update Codex | Run `bash scripts/updateme.sh --platform codex-cli` |

You do not need to remove other platform directories. Codex CLI only reads `.codex/` and `.agents/skills/`; it ignores `.claude/`, `.gemini/`, and `.opencode/`.

---

## Path mapping by platform

When you switch to Codex CLI, the project files move to new paths. Use this table to locate your existing files and understand where the equivalent lives in Codex.

| Source platform | Dispatcher | Agents | Skills | MCP or config | Codex target |
|----------------|-----------|--------|--------|--------------|-------------|
| Claude Code | `CLAUDE.md` | `.claude/agents/*.md` | `.claude/skills/` | `.mcp.json` | `AGENTS.md` / `.codex/agents/*.toml` / `.agents/skills/` / `.codex/config.toml` |
| Gemini CLI | `GEMINI.md` | `.gemini/agents/*.md` | `.gemini/skills/` | (none) | `AGENTS.md` / `.codex/agents/*.toml` / `.agents/skills/` / `.codex/config.toml` |
| OpenCode | `AGENTS.md` | `.opencode/agents/*.md` | `.opencode/skills/` | `opencode.json` | `AGENTS.md` / `.codex/agents/*.toml` / `.agents/skills/` / `.codex/config.toml` |

After running `launchme.sh --platform codex-cli`, the Codex files are installed automatically. You do not need to copy the old platform files manually.

---

## Moving from Claude Code

1. Pull the latest repo changes:
   ```bash
   cd /path/to/your-vault/My-Brain-Is-Full-Crew
   git pull
   ```

2. Run the Codex installer:
   ```bash
   bash scripts/launchme.sh --platform codex-cli
   ```

3. The installer creates:
   - `.codex/agents/` — all 8 core agents in TOML format
   - `.agents/skills/` — all 14 skills as plain text instructions
   - `.codex/config.toml` — MCP servers (translated from `mcp/servers.yaml`)
   - `AGENTS.md` — dispatcher with Codex routing header

4. Your existing `.claude/` directory and `CLAUDE.md` are left untouched.

5. MCP configuration: Claude Code uses `.mcp.json`. Codex CLI uses `.codex/config.toml`. If you added custom MCP servers to `.mcp.json` manually, you will need to add them to `.codex/config.toml` as well. See the `[mcp_servers.*]` TOML table format.

6. Custom agents: Claude Code custom agents live in `.claude/agents/`. Codex CLI custom agents must be in `.toml` format in `.codex/agents/`. Custom agents created via the `/create-agent` skill are not automatically migrated — see [Custom agents and what does not migrate automatically](#custom-agents-and-what-does-not-migrate-automatically).

---

## Moving from Gemini CLI

1. Pull the latest repo changes:
   ```bash
   cd /path/to/your-vault/My-Brain-Is-Full-Crew
   git pull
   ```

2. Run the Codex installer:
   ```bash
   bash scripts/launchme.sh --platform codex-cli
   ```

3. The installer creates the full Codex layout (same as above).

4. Your existing `.gemini/` directory and `GEMINI.md` are left untouched.

5. MCP configuration: Gemini CLI does not use `.mcp.json`. If you have MCP servers configured elsewhere, add them to `.codex/config.toml` manually.

6. Custom agents: Gemini CLI custom agents live in `.gemini/agents/`. These are Markdown files. For Codex CLI, custom agents must be TOML files in `.codex/agents/`. See [Custom agents and what does not migrate automatically](#custom-agents-and-what-does-not-migrate-automatically).

---

## Moving from OpenCode

1. Pull the latest repo changes:
   ```bash
   cd /path/to/your-vault/My-Brain-Is-Full-Crew
   git pull
   ```

2. Run the Codex installer:
   ```bash
   bash scripts/launchme.sh --platform codex-cli
   ```

3. The installer creates the full Codex layout. Note that both OpenCode and Codex CLI use `AGENTS.md` as the dispatcher. The installer will overwrite `AGENTS.md` with the Codex-specific version (which includes the root-context routing header). If you are running both platforms from the same vault, be aware that the two platforms share `AGENTS.md`.

4. Your existing `.opencode/` directory is left untouched.

5. MCP configuration: OpenCode uses `opencode.json`. Codex CLI uses `.codex/config.toml`. If you added custom MCP servers to `opencode.json`, add them to `.codex/config.toml` manually.

6. Custom agents: OpenCode custom agents live in `.opencode/agents/` as Markdown files. Codex CLI custom agents must be TOML files in `.codex/agents/`. See [Custom agents and what does not migrate automatically](#custom-agents-and-what-does-not-migrate-automatically).

---

## Custom agents and what does not migrate automatically

When you run the installer, the 8 core crew agents are automatically translated to Codex TOML format. However, **custom agents you created with `/create-agent`** are not automatically migrated because:

- They live in your platform's agents directory (`.claude/agents/`, `.gemini/agents/`, etc.)
- They are Markdown files; Codex requires TOML
- The installer never overwrites or deletes files in the agents directory that it did not create

### To migrate a custom agent manually

1. Locate your custom agent file (e.g., `.claude/agents/budget-tracker.md`)
2. Open Codex CLI in your vault and run `/create-agent`
3. Describe the agent's purpose — the Architect will guide you through creating a new `.toml` file in `.codex/agents/`
4. Alternatively, create the TOML file manually using one of the generated core agents as a template (e.g., `.codex/agents/scribe.toml`)

### What the TOML format looks like

```toml
[agent]
name = "budget-tracker"
description = "Monitors spending notes and flags when you are close to the monthly limit"
model = "o4-mini"

[agent.prompt]
content = """
You are the Budget Tracker agent for the My Brain Is Full — Crew system.
... (your agent instructions here)
"""
```

---

## Verification after migration

After running the installer, verify the Codex layout with these commands:

### Check that files installed correctly

```bash
ls <vault>/.codex/agents/       # Should list *.toml files for all 8 agents
ls <vault>/.agents/skills/      # Should list subdirectories for all 14 skills
ls <vault>/.codex/config.toml   # Should exist with [mcp_servers.*] tables
ls <vault>/AGENTS.md            # Should exist with Codex routing header
```

### Run the non-interactive discovery smoke

```bash
codex exec -C <vault> "List the project custom agents under .codex/agents, the repo skills under .agents/skills, and the dispatcher file used in this workspace."
```

Expected: response references `AGENTS.md`, `.codex/agents`, and `.agents/skills`.

### Check MCP visibility

```bash
codex -C <vault> mcp list
```

Expected: lists MCP servers from `.codex/config.toml`.

### Run the full runtime smoke matrix

See [docs/codex-cli.md — Runtime smoke matrix](codex-cli.md#runtime-smoke-matrix) for the complete list of agents, skills, chaining, and MCP checks.
