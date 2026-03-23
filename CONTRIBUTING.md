# Contributing to My Brain Is Full - Crew

Thank you for your interest in making the Crew better. This project was born from personal need, and it grows through shared ones.

---

## Ways to contribute

### Improve an existing agent

Found that an agent behaves weirdly, gives poor results, or misses edge cases?

1. Open an issue describing the problem with a concrete example
2. Or submit a PR with the improvement

Agent files live in `agents/<agent-name>.md`. The plugin manifest is at `.claude-plugin/plugin.json`. All agents are written in English, and they automatically respond in the user's language.

To test your changes locally:
```bash
claude --plugin-dir ./
```

### Propose a new core crew member

> **Note**: Users can create custom agents directly within their vault by saying "create a new agent" in Claude Code. The Architect handles the entire process. The section below is for proposing new *core* agents that ship with the project.

Have an idea for a new core agent? Open an issue with:

- **Name**: both a descriptive English name and a short codename
- **Role**: what problem does it solve?
- **Triggers**: when should it activate? (include phrases in multiple languages)
- **Tool access**: which tools does it need? (Read, Write, Edit, Bash, Glob, Grep)
- **Vault integration**: which folders does it read/write?
- **Inter-agent coordination**: which other agents should it suggest chaining to?
- **Why it matters**: what gap in the current crew does it fill?

### Add usage examples

Real-world examples of how you use the Crew help everyone. Add them to `docs/examples.md` or share them in an issue.

### Report a bug

Open an issue with:
- What you asked the agent to do
- What it actually did
- What you expected
- Your vault structure (roughly) if relevant

---

## Agent file structure

Each agent is a Claude Code **subagent**, a standalone `.md` file with YAML frontmatter:

```yaml
---
name: <agent-codename>
description: >
  One paragraph description used for auto-triggering.
  Include trigger phrases in multiple languages (English, Italian, French,
  Spanish, German, Portuguese) for maximum discoverability.
tools: Read, Write, Edit, Glob, Grep
model: sonnet
---

# <Display Name> — <Subtitle>

[Agent instructions in English]
```

### Frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase, hyphens only (e.g., `my-agent`) |
| `description` | Yes | When Claude should auto-invoke this agent. Include multilingual triggers |
| `tools` | Yes | Comma-separated list of allowed tools |
| `disallowedTools` | No | Tools to explicitly deny (e.g., `Write, Edit` for read-only agents) |
| `model` | No | `sonnet`, `opus`, or `haiku` (default: inherits from parent) |

### Key rules for agent files

1. **Write in English.** All agent instructions are in English. Agents respond in the user's language automatically.
2. **Multilingual triggers.** The `description` field should include natural trigger phrases in at least English and Italian, ideally more languages.
3. **Read user profile.** Agents should read `Meta/user-profile.md` for personalization. Never hardcode personal data.
4. **Inter-agent coordination.** Every agent must include the coordination section with `### Suggested next agent` output format. See `references/agent-orchestration.md`.
5. **Conservative by default.** Agents never delete, always archive. They ask before making structural decisions.
6. **Minimal tools.** Only grant the tools the agent actually needs. Read-only agents should use `disallowedTools: Write, Edit`.

---

## Inter-agent coordination

Agents coordinate through a dispatcher-driven orchestration system. When an agent detects work for another agent, it includes a `### Suggested next agent` section in its output. The dispatcher reads this and chains the next agent automatically. The protocol is documented in `references/agent-orchestration.md` and the agent registry is at `references/agents-registry.md`. If your new or improved agent needs to coordinate with existing ones, follow that protocol.

---

## Custom agents vs. core agents

**Custom agents** are created by users within their own vault using the Architect agent. They live in the user's `.claude/agents/` directory and are personal to that vault. Custom agents:
- Are created through a conversational flow with the Architect
- Follow the same file structure and conventions as core agents
- Participate in the dispatcher's routing and orchestration system
- Have lower priority than core agents
- Are tracked in `references/agents-registry.md` and `references/agents.md`

**Core agents** ship with the project and are maintained by contributors. To propose a new core agent, open an issue (see above).

If your custom agent solves a problem that many users would benefit from, consider proposing it as a core agent!

---

## Agent directory

| File | Agent name | Role | Tools |
|------|-----------|------|-------|
| `architect.md` | Architect | Vault Structure & Setup | Read, Write, Edit, Bash, Glob, Grep |
| `scribe.md` | Scribe | Text Capture | Read, Write, Edit, Glob, Grep |
| `sorter.md` | Sorter | Inbox Triage | Read, Write, Edit, Glob, Grep, Bash |
| `seeker.md` | Seeker | Search & Retrieval | Read, Glob, Grep |
| `connector.md` | Connector | Knowledge Graph | Read, Edit, Glob, Grep |
| `librarian.md` | Librarian | Vault Maintenance | Read, Write, Edit, Bash, Glob, Grep |
| `transcriber.md` | Transcriber | Audio & Transcription | Read, Write, Glob, Grep |
| `postman.md` | Postman | Email & Calendar | Read, Write, Edit, Glob, Grep |

---

## Philosophy

This project is built for people who are already overwhelmed. Contributions should make things **simpler**, not more complex.

When in doubt, ask: *"Does this make life easier for someone who's barely keeping it together?"*

If yes, it belongs here.

---

## Code of conduct

Be kind. Treat contributors and users with the same care you'd want when you're not at your best.
